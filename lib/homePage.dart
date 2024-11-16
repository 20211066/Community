import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('홈 화면')),
      body: Center(
        child: Text(
          '로그인에 성공했습니다!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
