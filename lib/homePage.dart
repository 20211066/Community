import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'board_screen.dart';
import 'naverMap.dart';
import 'chatListScreen.dart';
import 'my_profile_screen.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = -1; // 초기값을 -1로 설정 (하단 툴바도 숨기기)
  bool _showAppBar = false; // 툴바 표시 여부
  bool _showBottomNavBar = false; // 하단 툴바 표시 여부

  // 각 탭에 매핑되는 화면 위젯
  static final List<Widget> _widgetOptions = <Widget>[
    BoardScreen(), // 놀이터
    ChatListScreen(),
    NaverMapExample(),
    Center(child: Text('알림 화면', style: TextStyle(fontSize: 24))),
    MyProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      // 놀이터 탭을 클릭했을 때만 BoardScreen을 보이도록 설정
      if (index == 0 && _selectedIndex == -1) {
        _selectedIndex = 0;
      } else {
        _selectedIndex = index;
      }
    });
  }

  void _showBottomNavBarFunction() {
    setState(() {
      _showAppBar = true; // 툴바 표시
      _showBottomNavBar = true; // 하단 툴바 표시
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _showAppBar
          ? AppBar(
        title: Text(
          ['놀이터', '톡톡', '지도', '알림', 'MY'][_selectedIndex],
        ),
        actions: _selectedIndex == 4
            ? [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ]
            : null,
      )
          : null, // 툴바 숨기기
      body: _selectedIndex == -1
          ? Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const Text(
                '로그인에 성공했습니다!',
                style: TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _showBottomNavBarFunction(); // 하단 툴바 표시
                  setState(() {
                    _selectedIndex = 1; // 화면을 ChatListScreen으로 변경
                  });
                },
                child: const Text("Go to Chat List"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _showBottomNavBarFunction(); // 하단 툴바 표시
                  setState(() {
                    _selectedIndex = 2; // 화면을 NaverMap으로 변경
                  });
                },
                child: const Text("Go to Naver Map"),
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
            activeIcon: Icon(Icons.home, color: Colors.blue),
            label: '놀이터',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat, color: Colors.grey),
            activeIcon: Icon(Icons.chat, color: Colors.blue),
            label: '톡톡',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map, color: Colors.grey),
            activeIcon: Icon(Icons.map, color: Colors.blue),
            label: '지도',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications, color: Colors.grey),
            activeIcon: Icon(Icons.notifications, color: Colors.blue),
            label: '알림',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, color: Colors.grey),
            activeIcon: Icon(Icons.person, color: Colors.blue),
            label: 'MY',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      )
          : null, // 초기 화면에서는 하단 툴바 숨기기
    );
  }
}
