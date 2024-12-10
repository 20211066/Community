import 'package:flutter/material.dart';
import 'authService.dart';
import 'registerPage.dart'; // 회원가입 페이지
import 'authNaver.dart';
import 'authGoogle.dart';

class InAppLoginPage extends StatefulWidget {
  @override
  _InAppLoginPageState createState() => _InAppLoginPageState();
}

class _InAppLoginPageState extends State<InAppLoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  String? _errorMessage;

  // 로그인 함수
  Future<void> _login() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      final user = await _authService.loginWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (user != null) {
        print('로그인 성공: ${user.email}');
        Navigator.pushReplacementNamed(context, '/home'); // 홈 화면으로 이동
      }
    } catch (e) {
      setState(() {
        _errorMessage = "없는 이메일 정보입니다.";
      });
      print("로그인 실패: $e");
    }
  }

  /*// Google 로그인
  Future<void> _loginWithGoogle() async {
    final googleAuthService = GoogleAuthService();
    final user = await googleAuthService.signInWithGoogle();

    if (user != null) {
      print("Google 로그인 성공: ${user.email}");
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      print("Google 로그인 실패");
    }
  }

  // Naver 로그인
  Future<void> _loginWithNaver() async {
    final naverAuthService = NaverAuthService();
    final user = await naverAuthService.signInWithNaver(context);

    if (user != null) {
      print("Naver 로그인 성공: ${user.email}");
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      print("Naver 로그인 실패");
    }
  }*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF9EF),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 로고나 이미지 자리
              Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  color: Color(0xFFFFDCA2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person,
                  size: 60,
                  color: Color(0xFFFFD289),
                ),
              ),
              SizedBox(height: 30),
              // 이메일 입력 필드
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Color(0xFFFFDCA2),
                  hintText: '이메일 입력',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 20),
              // 비밀번호 입력 필드
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Color(0xFFFFDCA2),
                  hintText: '비밀번호 입력',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 30),
              // 로그인 버튼
              ElevatedButton(
                onPressed: _login,
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Color(0xFFFFD289)),
                  padding: MaterialStateProperty.all(
                    EdgeInsets.symmetric(vertical: 15, horizontal: 80),
                  ),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                child: Text(
                  '로그인',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 20),
              // 회원가입 버튼
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RegisterPage()),
                  );
                },
                child: Text(
                  '회원가입',
                  style: TextStyle(
                    color: Color(0xFFFFD289),
                    fontSize: 14,
                  ),
                ),
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
              /*SizedBox(height: 16),

              // Google 간편 로그인 버튼
              ElevatedButton.icon(
                onPressed: _loginWithGoogle,
                icon: Icon(Icons.g_mobiledata),
                label: Text('Google 간편 로그인'),
                style: ElevatedButton.styleFrom(
                  iconColor: Colors.blueAccent,
                ),
              ),

              SizedBox(height: 8),

              // Naver 간편 로그인 버튼
              ElevatedButton.icon(
                onPressed: _loginWithNaver,
                icon: Icon(Icons.web),
                label: Text('Naver 간편 로그인'),
                style: ElevatedButton.styleFrom(
                  iconColor: Colors.green,
                ),
              ),*/
            ],
          ),
        ),
      ),
    );
  }
}
