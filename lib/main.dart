import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'inAppLoginPage.dart'; // 로그인 페이지
import 'homePage.dart'; // 홈 화면

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();  // Firebase 초기화
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
      initialRoute: '/',
      routes: {
        '/': (context) => InAppLoginPage(), // 기본 로그인 화면
        '/home': (context) => HomePage(), // 로그인 후 홈 화면
      },
    );
  }
}
