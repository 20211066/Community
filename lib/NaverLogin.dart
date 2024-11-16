import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NaverLoginExample extends StatefulWidget {
  const NaverLoginExample({super.key});

  @override
  _NaverLoginExampleState createState() => _NaverLoginExampleState();
}

class _NaverLoginExampleState extends State<NaverLoginExample> {
  String? _accessToken;
  Map<String, dynamic>? _userInfo;

  // 네이버 사용자 정보 API URL
  final String _userInfoApiUrl = 'https://openapi.naver.com/v1/nid/me';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Naver Login Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _loginAndFetchUserInfo,
              child: Text('네이버 로그인 및 사용자 정보 가져오기'),
            ),
            if (_userInfo != null)
              Column(
                children: [
                  Text('이름: ${_userInfo!['name']}'),
                  Text('이메일: ${_userInfo!['email']}'),
                  Text('닉네임: ${_userInfo!['nickname']}'),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // 네이버 로그인 후 사용자 정보 가져오기
  Future<void> _loginAndFetchUserInfo() async {
    try {
      // 1. 네이버 로그인 및 액세스 토큰 가져오기
      String? accessToken = await _getAccessToken();
      if (accessToken == null) {
        print('로그인 실패: 액세스 토큰을 가져오지 못했습니다.');
        return;
      }
      setState(() {
        _accessToken = accessToken;
      });

      // 2. 사용자 정보 가져오기
      Map<String, dynamic>? userInfo = await _fetchUserInfo(accessToken);
      if (userInfo != null) {
        setState(() {
          _userInfo = userInfo;
        });
      }
    } catch (e) {
      print('오류 발생: $e');
    }
  }

  // 액세스 토큰 가져오기 (네이버 로그인 구현 필요)
  Future<String?> _getAccessToken() async {
    // 네이버 로그인 SDK나 OAuth2 인증을 통해 액세스 토큰 획득
    // 아래 코드는 예제이며 실제 네이버 로그인 로직과 연동 필요
    return 'YOUR_ACCESS_TOKEN'; // 여기에 실제 액세스 토큰 반환 로직 추가
  }

  // 사용자 정보 요청
  Future<Map<String, dynamic>?> _fetchUserInfo(String accessToken) async {
    final response = await http.get(
      Uri.parse(_userInfoApiUrl),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data['resultcode'] == '00') {
        return data['response']; // 사용자 정보 반환
      } else {
        print('사용자 정보 가져오기 실패: ${data['message']}');
      }
    } else {
      print('HTTP 요청 실패: ${response.statusCode}');
    }
    return null;
  }
}


final storage = FlutterSecureStorage();

// 저장
await storage.write(key: 'access_token', value: _accessToken);

// 복원
String? token = await storage.read(key: 'access_token');
