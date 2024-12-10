import 'package:flutter/material.dart';

class CommonLayout extends StatelessWidget {
  final String title; // 상단 제목
  final Widget child; // 각 화면의 콘텐츠

  const CommonLayout({required this.title, required this.child, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF9EF),
      body: SafeArea(
        child: Column(
          children: [
            AppBar(
              backgroundColor: Color(0xFFFFDCA2),
              title: Text(
                title,
                style: TextStyle(
                  color: Color(0xFFFFD289),
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
              elevation: 0,
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
