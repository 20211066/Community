import 'package:flutter/material.dart';
import 'common_layout.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CommonLayout(
      title: '프로필',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 프로필 사진과 닉네임
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 프로필 사진
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Color(0xFFFFDCA2),
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: Color(0xFFFFD289),
                  ),
                ),
                SizedBox(width: 16),
                // 닉네임
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '닉네임',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      'user@example.com',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(color: Color(0xFFFFDCA2), thickness: 1),
          // 작성글, 댓글, 즐겨찾기 서랍
          Expanded(
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  TabBar(
                    labelColor: Color(0xFFFFD289),
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Color(0xFFFFD289),
                    tabs: [
                      Tab(text: '작성 글'),
                      Tab(text: '댓글'),
                      Tab(text: '즐겨찾기'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // 작성 글
                        Center(
                          child: Text(
                            '작성 글 목록이 표시됩니다.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        // 댓글
                        Center(
                          child: Text(
                            '댓글 목록이 표시됩니다.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        // 즐겨찾기
                        Center(
                          child: Text(
                            '즐겨찾기한 글 목록이 표시됩니다.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
