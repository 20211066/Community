import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:webview_flutter/webview_flutter.dart';

class NaverAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String _receivedState;  // 로그인 요청 시 생성된 state 값

  // 네이버 로그인
  Future<User?> signInWithNaver() async {
    try {
      // 네이버 로그인 페이지에서 받은 코드
      String authCode = await _getNaverAuthCode();

      // 코드로 AccessToken을 요청
      final accessToken = await _getAccessToken(authCode);

      if (accessToken != null) {
        // Firebase OAuth로 네이버 계정 등록
        final AuthCredential credential = OAuthProvider("naver.com").credential(
          accessToken: accessToken,
        );

        UserCredential userCredential = await _auth.signInWithCredential(credential);

        // Firestore에 기본 정보 저장
        await _saveInitialUserData(userCredential.user);

        return userCredential.user;
      } else {
        print("액세스 토큰 획득 실패");
        return null;
      }
    } catch (e) {
      print("네이버 로그인 에러: $e");
      return null;
    }
  }

  // 네이버 로그인 페이지에서 Authorization Code를 가져오는 함수
  Future<String> _getNaverAuthCode() async {
    String clientId = 'CM56KhCXqEBPz4Bxw9mm';
    String redirectUri = 'myapp://callback';
    String state = _generateRandomState();
    _receivedState = state;  // 로그인 시 요청한 state 값 저장

    // 네이버 로그인 페이지 URL
    String url =
        'https://nid.naver.com/oauth2.0/authorize?response_type=code&client_id=$clientId&redirect_uri=$redirectUri&state=$state';

    // WebView로 네이버 로그인 페이지 띄우기
    final result = await _launchWebView(url);

    // 리디렉션된 URL에서 `state`와 `code` 추출
    Uri uri = Uri.parse(result);
    _verifyStateAndCode(uri);

    // URL에서 반환된 `code` 값을 리턴
    String? returnedCode = uri.queryParameters['code'];
    if (returnedCode != null) {
      return returnedCode;
    } else {
      throw Exception("인증 코드가 반환되지 않았습니다.");
    }
  }

  // WebView를 띄우고 URL을 반환하는 함수
  Future<String> _launchWebView(String url) async {
    final Completer<String> resultCompleter = Completer<String>();

    // WebView를 설정하는 위젯
    final WebViewController webViewController = WebViewController();

    await webViewController.loadRequest(
        Uri.parse(url)
    );

    // WebView 내에서 URL 변경을 감지하여 리디렉션된 URL을 반환합니다.
    await webViewController.setNavigationDelegate(
      NavigationDelegate(
        onNavigationRequest: (NavigationRequest request) {
          if (request.url.startsWith('myapp://callback')) {
            resultCompleter.complete(request.url);  // 리디렉션된 URL 반환
          }
          return NavigationDecision.navigate;
        },
      ),
    );

    return resultCompleter.future;
  }

  // Authorization Code로 AccessToken을 요청하는 함수
  Future<String?> _getAccessToken(String authCode) async {
    try {
      String clientId = 'CM56KhCXqEBPz4Bxw9mm';
      String clientSecret = '85Je7DtZHx';
      String redirectUri = 'myapp://callback';

      final response = await http.post(
        Uri.parse('https://nid.naver.com/oauth2.0/token'),
        body: {
          'grant_type': 'authorization_code',
          'client_id': clientId,
          'client_secret': clientSecret,
          'code': authCode,
          'redirect_uri': redirectUri,
        },
      );

      if (response.statusCode == 200) {
        // 액세스 토큰을 JSON으로 파싱
        Map<String, dynamic> data = json.decode(response.body);
        return data['access_token'];
      } else {
        print("Access Token 요청 실패: ${response.body}");
        return null;
      }
    } catch (e) {
      print("액세스 토큰 요청 에러: $e");
      return null;
    }
  }

  // 기본 사용자 정보 Firestore에 저장
  Future<void> _saveInitialUserData(User? user) async {
    if (user == null) return;

    final userDoc = _firestore.collection('users').doc(user.uid);

    final docSnapshot = await userDoc.get();

    if (!docSnapshot.exists) {
      // 기본 정보 저장
      await userDoc.set({
        'email': user.email,
        'profileImageUrl': 'gs://community-2d8f2.firebasestorage.app/default_profile.png',
        'loginMethod': 'naver',
        'nickName': null, // 사용자 입력 필요
        'createdAt': FieldValue.serverTimestamp(), // 생성 날짜
      });
      print("기본 사용자 정보 Firestore에 저장 완료.");
    } else {
      print("사용자 정보가 이미 Firestore에 존재합니다.");
    }
  }

  // 네이버 로그아웃
  Future<void> signOutNaver() async {
    await _auth.signOut();
    print("네이버 로그아웃 완료");
  }

  // 로그인 요청 시 생성된 state 값 랜덤으로 생성하기
  String _generateRandomState() {
    const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    Random random = Random();
    String state = List.generate(16, (index) => characters[random.nextInt(characters.length)]).join();
    return state;
  }

  // 리디렉션된 URL에서 반환된 state 값과 code 값 비교
  void _verifyStateAndCode(Uri uri) {
    String? returnedState = uri.queryParameters['state'];
    String? returnedCode = uri.queryParameters['code'];

    if (returnedState == _receivedState && returnedCode != null) {
      // state 값이 일치하고 code 값이 있다면 정상 처리
      print("로그인 성공, 반환된 code: $returnedCode");
      // 액세스 토큰 요청 등의 후속 작업 처리
    } else {
      print("CSRF 공격 가능성 있음, 상태 값이 일치하지 않음");
    }
  }
}
