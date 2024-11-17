import 'package:flutter/material.dart';
import 'authService.dart';
import 'authGoogle.dart'; // Google 로그인 서비스
import 'authNaver.dart'; // Naver 로그인 서비스
import 'registerPage.dart'; // 회원가입 페이지

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

  Future<void> _register() async {
    setState(() {
      _errorMessage = null;
    });

    // 비밀번호 길이 체크
    if (_passwordController.text.trim().length < 6) {
      setState(() {
        _errorMessage = "비밀번호를 6자리 이상으로 입력하세요.";
      });
      return;
    }

    try {
      // 이메일과 비밀번호로 회원가입 처리
      final user = await _authService.registerWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (user != null) {
        print('회원가입 성공: ${user.email}');
        Navigator.pushReplacementNamed(context, '/home'); // 홈 화면으로 이동
      }
    } catch (e) {
      setState(() {
        _errorMessage = "회원가입에 실패했습니다. 다시 시도해주세요.";
      });
      print("회원가입 실패: $e");
    }
  }

  // Google 로그인
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('InApp 로그인')),
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
              controller: _passwordController,
              decoration: InputDecoration(labelText: '비밀번호'),
              obscureText: true,
            ),
            SizedBox(height: 16),

            // 로그인 버튼
            ElevatedButton(
              onPressed: _login,
              child: Text('로그인'),
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

            SizedBox(height: 16),

            // 회원가입 버튼
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterPage()),
                );
              },
              child: Text('회원가입'),
            ),

            SizedBox(height: 16),

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
            ),
          ],
        ),
      ),
    );
  }
}
