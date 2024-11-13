import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart'; // 로그인 화면으로 이동

class HomeScreen extends StatelessWidget {
  // 로그아웃 기능
  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut(); // Firebase 로그아웃
    // 로그아웃 후 로그인 화면으로 이동
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('홈')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('로그인 성공!'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _logout(context), // 로그아웃 버튼
              child: Text('로그아웃'),
            ),
          ],
        ),
      ),
    );
  }
}
