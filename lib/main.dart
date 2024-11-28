import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'inAppLoginPage.dart'; // 로그인 페이지
import 'homePage.dart'; // 홈 화면

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Firebase 초기화
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Login App',
      theme: ThemeData(
        primaryColor: Colors.blue,
      ),
      home: AuthChecker(), // 로그인 상태에 따라 화면 결정
      routes: {
        '/home': (context) => HomePage(), // 홈 화면
        '/login': (context) => InAppLoginPage(), // 로그인 화면
      },
    );
  }
}

class AuthChecker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // FirebaseAuth를 사용하여 현재 사용자가 있는지 확인
    final User? user = FirebaseAuth.instance.currentUser;

    // 로그인 상태라면 홈 화면, 아니면 로그인 화면으로 이동
    if (user != null) {
      return HomePage(); // 이미 로그인된 경우 홈 화면으로 이동
    } else {
      return InAppLoginPage(); // 로그인이 필요하면 로그인 화면으로 이동
    }
  }
}
