import 'package:flutter/material.dart';
import 'naver_auth_service.dart';
import 'complete_profile_page.dart';

class NaverSignInPage extends StatelessWidget {
  final NaverAuthService authService = NaverAuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Naver 로그인")),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            User? user = await authService.signInWithNaver();
            if (user != null) {
              print("로그인 성공: ${user.email}");
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CompleteProfilePage()),
              );
            } else {
              print("로그인 실패");
            }
          },
          child: Text("네이버로 로그인"),
        ),
      ),
    );
  }
}
