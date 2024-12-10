import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'write_post_screen.dart';
import 'board_list_screen.dart';
import 'common_layout.dart';  // CommonLayout import 추가
import 'neighborhood_verify_screen.dart'; // 동네 인증 화면 추가

class BoardScreen extends StatelessWidget {

  Future<bool> _isNeighborhoodVerified() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return doc.exists && (doc.data()?['isNeighborhoodVerified'] ?? false);
  }


  Future<void> _showVerificationRequiredDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('동네 인증 필요'),
          content: Text('게시글을 작성하려면 동네 인증이 필요합니다. 동네 인증 화면으로 이동하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('아니요'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => NeighborhoodVerifyScreen(selectedNeighborhood: '')),
                );
              },
              child: Text('예'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('광장'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildBoardCategory(context, '자유 광장', Icons.chat),
              SizedBox(height: 10),
              _buildBoardCategory(context, '행사', Icons.event),
              SizedBox(height: 10),
              _buildBoardCategory(context, '소리함', Icons.report_problem),
              SizedBox(height: 10),
              _buildBoardCategory(context, '마을 소식', Icons.info),
              SizedBox(height: 10),
              _buildBoardCategory(context, '우리 동네 장터', Icons.store),
              SizedBox(height: 10),
              _buildBoardCategory(context, '우리의 선택', Icons.assignment),
              SizedBox(height: 10),
              _buildBoardCategory(context, '자원봉사', Icons.volunteer_activism),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          bool isVerified = await _isNeighborhoodVerified();
          if (isVerified) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => WritePostScreen()),
            );
          } else {
            _showVerificationRequiredDialog(context);
          }
        },
        child: Icon(Icons.create),
        backgroundColor: Colors.blue,
      ),
    );
  }


  // 모든 게시판을 일자 네모박스로 바꿈
  Widget _buildBoardCategory(BuildContext context, String title, IconData icon) {
    return GestureDetector(
      onTap: () {
        // 사용자가 특정 카테고리를 클릭했을 때 해당 카테고리의 게시글 목록 화면으로 이동
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => BoardListScreen(category: title),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        height: 80, // 일자 네모박스 형태로 크기 설정
        decoration: BoxDecoration(
          color: Color(0xFFFFDCA2), // 배경 색상
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.black, size: 30), // 아이콘 색상 검은색으로 변경
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold), // 글자 색상 검은색
              ),
            ],
          ),
        ),
      ),
    );
  }
}


Widget _buildFreeBoardCategory(BuildContext context) {
  return GestureDetector(
    onTap: () {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => BoardListScreen(category: '자유 광장')),
      );
    },
    child: Container(
      width: double.infinity,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          '자유 광장',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    ),
  );
}