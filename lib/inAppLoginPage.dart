import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:zipcode_community/signInWithNaver.dart';
import 'authService.dart';
import 'authGoogle.dart'; // Google 로그인 서비스
import 'authNaver.dart'; // Naver 로그인 서비스
import 'registerPage.dart'; // 회원가입 페이지

class InAppLoginPage extends StatefulWidget {
  const InAppLoginPage({super.key});

  @override
  _InAppLoginPageState createState() => _InAppLoginPageState();
}

class _InAppLoginPageState extends State<InAppLoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();


  // 이메일 형식 검증 함수
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
        r'^[a-zA-Z0-9]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    );
    return emailRegex.hasMatch(email);
  }

  String? _errorMessage;

  // 로그인 함수
  Future<void> _login() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final user = await _authService.loginWithEmailAndPassword(
         email, password,
      );

      // Firestore에서 사용자 확인
      final userDoc = await FirebaseFirestore.instance
          .collection('users') // 사용자가 저장된 Firestore 컬렉션
          .doc(email) // 이메일을 문서 ID로 사용한다고 가정
          .get();

      if (!userDoc.exists) {
        // 사용자가 Firestore에 없으면 로그인 실패 처리
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("로그인 실패: 이메일이 존재하지 않습니다.")),
        );
        return;
      }

      // Firestore에 저장된 비밀번호 확인
      final storedPassword = userDoc.data()?['password'];
      if (storedPassword != password) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("로그인 실패: 비밀번호가 일치하지 않습니다.")),
        );
        return;
      }

      if (email.isEmpty || password.isEmpty) {
        // 필수 입력값이 비어 있으면 알림 표시
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("모든 필드를 입력해주세요.")));
        return;
      }

      if (!_isValidEmail(email)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("제대로 된 이메일 형식이 아닙니다.")),
        );
        return;
      }

      if(password.length < 6){
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("비밀번호를 6자리 이상 입력하시오.")
            ));
      }

      if (user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("로그인 성공!")),
        );
        Navigator.pushReplacementNamed(context, '/home'); // 홈 화면으로 이동
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("로그인 실패했습니다")),
      );
      print("로그인 실패: $e");
    }
  }


  // Google 로그인
  Future<void> _loginWithGoogle() async {
    final googleAuthService = GoogleAuthService();
    try {
      final user = await googleAuthService.signInWithGoogle();
      if (user != null) {
        print("Google 로그인 성공: ${user.email}");
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        print("Google 로그인 실패");
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Google 로그인에 실패했습니다.";
      });
      print("Google 로그인 오류: $e");
    }
  }

  // Naver 로그인
  Future<void> _loginWithNaver() async {
    try {
      final user = await AuthNaver.signInWithNaver(context);
      if (user != null) {
        print("Naver 로그인 성공: ${user.email}");
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        print("Naver 로그인 실패");
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Naver 로그인에 실패했습니다.";
      });
      print("Naver 로그인 오류: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('InApp 로그인')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 이메일 입력
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: '이메일'),
            ),
            const SizedBox(height: 8),
            // 비밀번호 입력
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: '비밀번호'),
              obscureText: true,
            ),
            const SizedBox(height: 16),

            // 로그인 버튼
            ElevatedButton(
              onPressed: _login,
              child: const Text('로그인'),
            ),

            // 오류 메시지
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            const SizedBox(height: 16),

            // 회원가입 버튼
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterPage()),
                );
              },
              child: const Text('회원가입'),
            ),

            const SizedBox(height: 16),

            // Google 간편 로그인 버튼
            ElevatedButton.icon(
              onPressed: _loginWithGoogle,
              icon: const Icon(Icons.g_mobiledata),
              label: const Text('Google 간편 로그인'),
              style: ElevatedButton.styleFrom(
                iconColor: Colors.blueAccent,
              ),
            ),

            const SizedBox(height: 8),

            // Naver 간편 로그인 버튼
            InkWell(
              onTap: _loginWithNaver,
              child: Card(
                margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                elevation: 2,
                child: Ink.image(
                  image: const AssetImage('images/naver.png'),
                  fit: BoxFit.cover,
                  height: 50,
                  width: double.infinity,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
