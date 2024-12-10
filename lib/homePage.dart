import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'board_screen.dart';
import 'naverMap.dart';
import 'chatListScreen.dart';
import 'my_profile_screen.dart';
import 'notification_screen.dart';

class HomePage extends StatefulWidget {
  late final int initialIndex;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  int _selectedIndex = -1; // 초기값을 -1로 설정 (하단 툴바도 숨기기)
  bool _showBottomNavBar = false; // 하단 툴바 표시 여부

  // 각 탭에 매핑되는 화면 위젯
  static final List<Widget> _widgetOptions = <Widget>[
    BoardScreen(), // 놀이터
    ChatListScreen(),
    NaverMapExample(),
    NotificationsScreen(),
    MyProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showBottomNavBarFunction() {
    setState(() {
      _showBottomNavBar = true; // 하단 툴바 표시
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF9EF),
      body: _selectedIndex == -1
          ? Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const Text(
                '로그인에 성공했습니다!',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.black, // 검정색 글자
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _showBottomNavBarFunction(); // 하단 툴바 표시
                  setState(() {
                    _selectedIndex = 1; // 화면을 ChatListScreen으로 변경
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFFDCA2),
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Go to Chat List",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black, // 검정색 글자
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _showBottomNavBarFunction(); // 하단 툴바 표시
                  setState(() {
                    _selectedIndex = 2; // 화면을 NaverMap으로 변경
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFFDCA2),
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Go to Naver Map",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black, // 검정색 글자
                  ),
                ),
              ),
            ],
          ),
        ),
      )
          : _widgetOptions[_selectedIndex], // 나머지 화면들
      bottomNavigationBar: _showBottomNavBar
          ? BottomNavigationBar(
        backgroundColor: Colors.black87,
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: Colors.grey),
            activeIcon: Icon(Icons.home, color: Color(0xFFFFDCA2)),
            label: '놀이터',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat, color: Colors.grey),
            activeIcon: Icon(Icons.chat, color: Color(0xFFFFDCA2)),
            label: '톡톡',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map, color: Colors.grey),
            activeIcon: Icon(Icons.map, color: Color(0xFFFFDCA2)),
            label: '지도',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications, color: Colors.grey),
            activeIcon: Icon(Icons.notifications, color: Color(0xFFFFDCA2)),
            label: '알림',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, color: Colors.grey),
            activeIcon: Icon(Icons.person, color: Color(0xFFFFDCA2)),
            label: 'MY',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Color(0xFFFFDCA2),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      )
          : null, // 초기 화면에서는 하단 툴바 숨기기
    );
  }
}
