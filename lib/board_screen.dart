import 'package:flutter/material.dart';
import 'write_post_screen.dart';
import 'board_list_screen.dart';
import 'common_layout.dart';  // CommonLayout import 추가

class BoardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CommonLayout(
      title: '우리 동네 놀이터',
      child: SingleChildScrollView(  // 전체를 SingleChildScrollView로 감싸 스크롤 가능하게 함
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // 자유게시판을 다른 게시판들과 동일한 방식으로 일자 네모박스로 만들기
              _buildBoardCategory(context, '자유게시판', Icons.chat),
              SizedBox(height: 10),
              // 다른 게시판들
              _buildBoardCategory(context, '행사', Icons.event),
              SizedBox(height: 10),
              _buildBoardCategory(context, '민원', Icons.report_problem),
              SizedBox(height: 10),
              _buildBoardCategory(context, '정보', Icons.info),
              SizedBox(height: 10),
              _buildBoardCategory(context, '장터', Icons.store),
              SizedBox(height: 10),
              _buildBoardCategory(context, '의제', Icons.assignment),
              SizedBox(height: 10),
              _buildBoardCategory(context, '자원봉사', Icons.volunteer_activism),
            ],
          ),
        ),
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
