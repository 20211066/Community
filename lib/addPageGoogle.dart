import 'package:flutter/material.dart';
import 'google_auth_service.dart';
import 'complete_profile_page.dart';

class GoogleSignInPage extends StatelessWidget {
  final GoogleAuthService authService = GoogleAuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Google 로그인")),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            User? user = await authService.signInWithGoogle();
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
          child: Text("Google로 로그인"),
        ),
      ),
    );
  }
}
