import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'chatListScreen.dart';
import 'naverMapPage.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name ?? 'Unknown';
    return Scaffold(
      appBar: AppBar(
        title: const Text('홈 화면'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut(); // Firebase 로그아웃
              Navigator.of(context).pushReplacementNamed('/login'); // 로그인 페이지로 이동
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Centers items vertically
            crossAxisAlignment: CrossAxisAlignment.center, // Centers items horizontally
            children: <Widget>[
              const Text(
                '로그인에 성공했습니다!',
                style: TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 20), // Adds space between the Text and the Button
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => ChatListScreen()),
                  );
                },
                child: const Text("Go to Chat List"),
              ),
              const SizedBox(height: 20), // Adds space between the buttons
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => NaverMapPage()), // 네이버 맵 페이지로 이동
                  );
                },
                child: const Text("Go to Naver Map"),
              ),
            ],
          ),
        )
      ),
    );
  }
}
