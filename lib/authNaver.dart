import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore import
import 'package:webview_flutter/webview_flutter.dart';

class NaverAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore 인스턴스

  // Google Cloud Functions의 엔드포인트 URL
  final String cloudFunctionsUrl = "https://us-central1-community-2d8f2.cloudfunctions.net/getNaverAccessToken";

  // 네이버 로그인 메인 함수
  Future<User?> signInWithNaver(BuildContext context) async {
    try {
      // Step 1: 네이버 로그인 페이지에서 Authorization Code 가져오기
      String authCode = await _getNaverAuthCode(context);

      // Step 2: Authorization Code를 Cloud Functions로 전송하여 Access Token 요청
      final accessToken = await _fetchAccessTokenFromServer(authCode);

      if (accessToken != null) {
        // Step 3: Naver User Profile 정보 가져오기
        final naverProfile = await _getNaverUserProfile(accessToken);

        // Step 4: Firestore에 프로필 정보 저장
        await _saveUserProfileToFirestore(naverProfile);

        // Step 5: Firebase 인증 처리
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
    String clientId = 'CM56KhCXqEBPz4Bxw9mm';
    String redirectUri = 'https://us-central1-community-2d8f2.cloudfunctions.net/naverLoginCallback';
    String state = generateState();

    String url = 'https://nid.naver.com/oauth2.0/authorize?response_type=code&client_id=$clientId&state=$state&redirect_uri=$redirectUri';

    final authCode = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NaverLoginWebView(
          loginUrl: url,
          redirectUri: redirectUri,
          state: state,
        ),
      ),
    );

    if (authCode == null) {
      throw Exception("네이버 로그인 실패 또는 취소됨");
    }
    return authCode;
  }

  // Google Cloud Functions에 인증 코드를 보내 Access Token 요청
  Future<String?> _fetchAccessTokenFromServer(String authCode) async {
    try {
      final response = await http.post(
        Uri.parse(cloudFunctionsUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'authCode': authCode}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['access_token'];
      } else {
        debugPrint("서버로부터 Access Token 요청 실패: ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("Access Token 요청 중 에러 발생: $e");
      return null;
    }
  }

  // 네이버 사용자 프로필 가져오기
  Future<Map<String, dynamic>> _getNaverUserProfile(String accessToken) async {
    final profileUrl = 'https://openapi.naver.com/v1/nid/me';

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
        'created_at': DateTime.now().toIso8601String(), // 현재 시간 추가
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
        }, SetOptions(merge: true)); // 기존 데이터 덮어쓰지 않도록 merge 옵션 사용
        debugPrint("Firestore에 사용자 프로필 저장 완료");
      } catch (e) {
        debugPrint("Firestore에 프로필 저장 실패: $e");
      }
    }
  }

  // 로그아웃 처리
  Future<void> signOutNaver() async {
    await _auth.signOut();
    debugPrint("네이버 로그아웃 완료");
  }

  // State 값 생성
  String generateState() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random random = Random();
    return List.generate(16, (index) => chars[random.nextInt(chars.length)]).join();
  }
}

// WebView를 사용해 네이버 로그인 페이지를 열고 인증 코드를 가져오는 화면
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
                if (uri.queryParameters['state'] == state) {
                  Navigator.pop(context, uri.queryParameters['code']);
                } else {
                  Navigator.pop(context, null);
                }
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
            onWebResourceError: (error) {
              debugPrint("WebView 에러: ${error.description}");
              Navigator.pop(context, null);
            },
          ))
          ..loadRequest(Uri.parse(loginUrl)),
      ),
    );
  }
}
