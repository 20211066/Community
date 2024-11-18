import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NaverAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage storage = FlutterSecureStorage();

  // 민감한 정보는 환경 변수로 관리
  final String cloudFunctionsUrl = "https://us-central1-community-2d8f2.cloudfunctions.net/getNaverAccessToken";
  final String clientId = 'CM56KhCXqEBPz4Bxw9mm';
  final String redirectUri = 'https://us-central1-community-2d8f2.cloudfunctions.net/naverLoginCallback';
  final String clientSecret = '85Je7DtZHx';

  String _stateStorage = ''; // state 값을 저장할 변수

  // 네이버 로그인 메인 함수
  Future<User?> signInWithNaver(BuildContext context) async {
    try {
      String authCode = await _getNaverAuthCode(context);
      String? accessToken = await _fetchAccessTokenFromServer(authCode);

      if (accessToken != null) {
        Map<String, dynamic> naverProfile = await _getNaverUserProfile(accessToken);

        await _saveUserProfileToFirestore(naverProfile);

        final credential = OAuthProvider("naver.com").credential(accessToken: accessToken);
        UserCredential userCredential = await _auth.signInWithCredential(credential);

        return userCredential.user;
      } else {
        throw Exception("Access Token을 가져올 수 없습니다.");
      }
    } catch (e) {
      debugPrint("네이버 로그인 에러: $e");
      return null;
    }
  }

  // 네이버 로그인 페이지에서 Authorization Code 가져오기
  Future<String> _getNaverAuthCode(BuildContext context) async {
    _stateStorage = generateState(); // state 값 생성
    String url = 'https://nid.naver.com/oauth2.0/authorize?response_type=code&client_id=$clientId&state=$_stateStorage&redirect_uri=$redirectUri';

    final authCode = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NaverLoginWebView(
          loginUrl: url,
          redirectUri: redirectUri,
          state: _stateStorage,
        ),
      ),
    );

    if (authCode == null) {
      throw Exception("네이버 로그인 실패 또는 취소됨");
    }
    return authCode;
  }

  // Access Token 요청
  Future<String?> _fetchAccessTokenFromServer(String authCode) async {
    final String tokenUrl = 'https://nid.naver.com/oauth2.0/token';
    final response = await http.post(
      Uri.parse(tokenUrl),
      body: {
        'grant_type': 'authorization_code',
        'client_id': clientId,
        'client_secret': clientSecret,
        'code': authCode,
        'state': _stateStorage,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['access_token'];
    } else {
      debugPrint("Access Token 요청 실패: ${response.body}");
      return null;
    }
  }

  // 네이버 사용자 프로필 가져오기
  Future<Map<String, dynamic>> _getNaverUserProfile(String accessToken) async {
    const profileUrl = 'https://openapi.naver.com/v1/nid/me';

    final response = await http.get(
      Uri.parse(profileUrl),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'email': data['response']['email'],
        'profile_image_url': data['response']['profile_image'],
        'login_method': 'naver',
        'nickname': data['response']['nickname'],
        'created_at': DateTime.now().toIso8601String(),
      };
    } else {
      throw Exception("네이버 프로필 정보 요청 실패");
    }
  }

  // Firestore에 사용자 프로필 정보 저장
  Future<void> _saveUserProfileToFirestore(Map<String, dynamic> profile) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'email': profile['email'],
          'profile_image_url': profile['profile_image_url'],
          'login_method': profile['login_method'],
          'nickname': profile['nickname'],
          'created_at': profile['created_at'],
        }, SetOptions(merge: true));
        debugPrint("Firestore에 사용자 프로필 저장 완료");
      } catch (e) {
        debugPrint("Firestore에 프로필 저장 실패: $e");
      }
    }
  }

  // State 값 생성
  String generateState() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random random = Random();
    return List.generate(16, (index) => chars[random.nextInt(chars.length)]).join();
  }

  // 로그아웃 처리
  Future<void> signOutNaver() async {
    await _auth.signOut();
    await storage.deleteAll(); // 모든 저장된 토큰 삭제
    debugPrint("네이버 로그아웃 완료");
  }
}

// 네이버 로그인 후 Firebase Custom Token으로 로그인
Future<User?> signInWithFirebaseToken(String firebaseToken) async {
  try {
    UserCredential userCredential = await FirebaseAuth.instance.signInWithCustomToken(firebaseToken);
    return userCredential.user;
  } catch (e) {
    debugPrint("Firebase 로그인 실패: $e");
    return null;
  }
}

// WebView에서 Redirect 후 처리
class NaverLoginWebView extends StatelessWidget {
  final String loginUrl;
  final String redirectUri;
  final String state;

  const NaverLoginWebView({
    Key? key,
    required this.loginUrl,
    required this.redirectUri,
    required this.state,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("네이버 로그인")),
      body: WebViewWidget(
        controller: WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(NavigationDelegate(
            onNavigationRequest: (NavigationRequest request) {
              if (request.url.startsWith(redirectUri)) {
                Uri uri = Uri.parse(request.url);
                String? firebaseToken = uri.queryParameters['firebaseToken'];

                if (firebaseToken != null) {
                  signInWithFirebaseToken(firebaseToken).then((user) {
                    if (user != null) {
                      debugPrint("Firebase 로그인 성공: ${user.email}");
                      Navigator.pop(context, user);
                    } else {
                      debugPrint("Firebase 로그인 실패");
                      Navigator.pop(context, null);
                    }
                  });
                } else {
                  debugPrint("Firebase Token 누락");
                  Navigator.pop(context, null);
                }
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
          ))
          ..loadRequest(Uri.parse(loginUrl)),
      ),
    );
  }
}

