import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'authService.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nickNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  String? _errorMessage;

  // 회원가입 함수
  Future<void> _register() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      final nickName = _nickNameController.text;
      final email = _emailController.text;
      final password = _passwordController.text;

      if (nickName.isEmpty || email.isEmpty || password.isEmpty) {
        // 필수 입력값이 비어 있으면 알림 표시
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("모든 필드를 입력해주세요.")));
        return;
      }

      // 회원가입 처리 (AuthService의 registerUser 호출)
      User? user = await _authService.registerUser(nickName, email, password);

      if (user != null) {
        print('회원가입 성공: ${user.email}');
        Navigator.pop(context); // 회원가입 후 로그인 페이지로 이동
      }
    } catch (e) {
      setState(() {
        _errorMessage = "회원가입 실패: ${e.toString()}";
      });
      print("회원가입 실패: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Color(0xFFFFF9EF),),
      backgroundColor: Color(0xFFFFF9EF),
      body: Padding(

        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 이메일 입력
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: '이메일'),
            ),
            SizedBox(height: 8),
            // 비밀번호 입력
            TextField(
              controller: _passwordController, // 비밀번호 입력 필드 추가
              decoration: InputDecoration(labelText: '비밀번호'),
              obscureText: true,
            ),
            SizedBox(height: 8),
            // 사용자 ID 입력
            SizedBox(height: 8),
            // 닉네임 입력
            TextField(
              controller: _nickNameController,
              decoration: InputDecoration(labelText: '닉네임'),
            ),
            SizedBox(height: 16),

            // 회원가입 버튼
            ElevatedButton(
              onPressed: _register,
              child: Text('회원가입'),
            ),

            // 오류 메시지
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
