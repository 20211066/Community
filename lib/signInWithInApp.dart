import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:zipcode_community/homePage.dart';
import 'authService.dart';

class RegisterPage extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();

  final AuthService _authService = AuthService();

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("회원가입")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            SizedBox(height: 8),
            Text(
              "비밀번호를 6자리 이상으로 생성하십시오",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _nicknameController,
              decoration: InputDecoration(labelText: "닉네임"),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  final String email = _emailController.text.trim();
                  final String password = _passwordController.text.trim();
                  final String nickname = _nicknameController.text.trim();
                  try {
                    final User? user =
                    await _authService.registerUser(nickname, email, password);

                    if (user != null) {
                      print("회원가입 성공: ${user.email}");
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => HomePage()),
                      );
                    } else {
                      throw Exception("알 수 없는 이유로 회원가입에 실패했습니다.");
                    }
                  } catch (e) {
                    print("회원가입 실패: ${e.toString()}");
                    _showSnackBar(context, "회원가입 실패: ${e.toString()}");
                  }
                },
                child: Text("회원가입"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
