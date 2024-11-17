import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'authService.dart';
import 'addPageInApp.dart';

class RegisterPage extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nickNameController = TextEditingController();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("회원가입")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: "이메일"),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: "비밀번호"),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final User? user = await _authService.registerUser(
                  _nickNameController.text,
                  _emailController.text,
                  _passwordController.text,
                );

                if (user != null) {
                  print("회원가입 성공: ${user.email}");
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => NickNameInputPage()),
                  );
                } else {
                  print("회원가입 실패");
                }
              },
              child: Text("회원가입"),
            ),
          ],
        ),
      ),
    );
  }
}
