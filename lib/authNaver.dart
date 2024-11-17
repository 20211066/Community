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
  final storage = FlutterSecureStorage(); // Secure Storage 인스턴스

  final String cloudFunctionsUrl = "https://us-central1-community-2d8f2.cloudfunctions.net/getNaverAccessToken";



  // 네이버 로그인 메인 함수
  Future<User?> signInWithNaver(BuildContext context) async {
    try {
      String authCode = await _getNaverAuthCode(context);
      final accessToken = await _fetchAccessTokenFromServer(authCode);

      if (accessToken != null) {
        final naverProfile = await _getNaverUserProfile(accessToken);

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

  // state 값 일치 확인 함수

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
        }, SetOptions(merge: true)); // 기존 데이터 덮어쓰지 않도록 merge 옵션 사용
        debugPrint("Firestore에 사용자 프로필 저장 완료");
      } catch (e) {
        debugPrint("Firestore에 프로필 저장 실패: $e");
      }
    }
  }

  // Access Token 유효성 확인 및 갱신
  Future<String?> getValidAccessToken() async {
    final tokens = await getTokens();
    final accessToken = tokens['access_token'];
    final refreshToken = tokens['refresh_token'];
    final expiration = tokens['token_expiration'];

    if (accessToken == null || refreshToken == null || expiration == null) {
      throw Exception("토큰 정보가 없습니다.");
    }

    final expirationTime = DateTime.parse(expiration);
    if (DateTime.now().isBefore(expirationTime)) {
      return accessToken; // 유효한 토큰 반환
    } else {
      // 토큰 갱신
      return await refreshAccessToken(refreshToken);
    }
  }

  // Refresh Token을 사용하여 Access Token 갱신
  Future<String?> refreshAccessToken(String refreshToken) async {
    final refreshUrl = 'https://nid.naver.com/oauth2.0/token';
    final response = await http.post(
      Uri.parse(refreshUrl),
      body: {
        'grant_type': 'refresh_token',
        'client_id': 'YOUR_CLIENT_ID',
        'client_secret': 'YOUR_CLIENT_SECRET',
        'refresh_token': refreshToken,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final newAccessToken = data['access_token'];
      final expiresIn = int.parse(data['expires_in']);

      // 새로운 토큰 저장
      await saveTokens(newAccessToken, refreshToken, expiresIn);
      return newAccessToken;
    } else {
      throw Exception("Access Token 갱신 실패: ${response.body}");
    }
  }

  // Firestore에 저장된 토큰을 가져오기
  Future<Map<String, String?>> getTokens() async {
    final accessToken = await storage.read(key: 'access_token');
    final refreshToken = await storage.read(key: 'refresh_token');
    final expiration = await storage.read(key: 'token_expiration');
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'token_expiration': expiration,
    };
  }

  // 토큰을 Secure Storage에 저장
  Future<void> saveTokens(String accessToken, String refreshToken, int expiresIn) async {
    final expirationTime = DateTime.now().add(Duration(seconds: expiresIn)).toIso8601String();
    await storage.write(key: 'access_token', value: accessToken);
    await storage.write(key: 'refresh_token', value: refreshToken);
    await storage.write(key: 'token_expiration', value: expirationTime);

  }

  // 로그아웃 처리
  Future<void> signOutNaver() async {
    await _auth.signOut();
    await storage.deleteAll(); // 모든 저장된 토큰 삭제
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

  bool validateState(String returnedState, String expectedState) {
    return returnedState == expectedState;
  }

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
                String? returnedState = uri.queryParameters['state'];

                if (returnedState != null && returnedState == state) {
                  Navigator.pop(context, uri.queryParameters['code']);
                } else {
                  debugPrint("State 값이 일치하지 않습니다.");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("로그인 오류: 상태 값 불일치")),
                  );
                  Navigator.pop(context, null); // state 불일치 시 실패 처리
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
