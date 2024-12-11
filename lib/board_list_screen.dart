import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'post_screen.dart';
import 'common_layout.dart';  // CommonLayout import 추가
import 'post_edit.dart';

class BoardListScreen extends StatefulWidget {
  final String category;

  BoardListScreen({required this.category});

  @override
  _BoardListScreenState createState() => _BoardListScreenState();
}

class _BoardListScreenState extends State<BoardListScreen> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  Future<void> _deletePost(String postId) async {
    try {
      await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('게시글이 삭제되었습니다.')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('게시글 삭제에 실패했습니다.')));
    }
  }

  // 조회수 증가 함수
  Future<void> _incrementViews(String postId) async {
    await FirebaseFirestore.instance.collection('posts').doc(postId).update({
      'views': FieldValue.increment(1),
    });
  }

  @override
  Widget build(BuildContext context) {
    return CommonLayout(
      title: '${widget.category}',
      child: StreamBuilder<QuerySnapshot>(
        stream: widget.category == '자유 광장'
            ? FirebaseFirestore.instance.collection('posts').orderBy('createdAt', descending: true).snapshots() // 모든 게시글 가져오기
            : FirebaseFirestore.instance
            .collection('posts')
            .where('category', isEqualTo: widget.category)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('데이터를 불러오는데 실패했습니다.'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('게시글이 없습니다.'));
          }

          final posts = snapshot.data!.docs;

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final postData = post.data() as Map<String, dynamic>;
              final isAuthor = postData['authorId'] == currentUserId;
              // createdAt 필드가 Firestore 타임스탬프인지 확인하고 형식 변환
              DateTime createdAt = (postData['createdAt'] as Timestamp).toDate();
              String formattedTime = _formatTimestamp(createdAt);

              return GestureDetector(
                onTap: () async {
                  // 게시글 클릭 시 조회 수 증가
                  await _incrementViews(post.id);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PostScreen(postId: post.id), // postId를 전달
                    ),
                  );
                },
                child: Card(
                  margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  color: Color(0xFFFFDCA2), // 게시판 카드 배경 색상 변경
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 자유게시판에서만 카테고리 표시
                        if (widget.category == '자유 광장')
                          Text(
                            postData['category'] ?? '카테고리 없음',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        SizedBox(height: 8),
                        // 게시글 제목
                        Text(
                          postData['title'] ?? '제목 없음',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        // 게시글 내용 일부
                        Text(
                          postData['content'] != null && postData['content'].length > 50
                              ? '${postData['content'].substring(0, 50)}...'
                              : (postData['content'] ?? '내용 없음'),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 16),
                        // 게시글 하단 정보 (작성 시간, 조회 수, 댓글 수)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              formattedTime,
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            Row(
                              children: [
                                Text(
                                  '조회 ${postData['views'] ?? 0}', // 조회 수
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                SizedBox(width: 16),
                                Row(
                                  children: [
                                    Icon(Icons.comment, size: 16, color: Colors.grey),
                                    SizedBox(width: 4),
                                    Text(
                                      '${postData['comments'] ?? 0}', // 댓글 수
                                      style: TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (isAuthor) // 작성자일 경우에만 표시
                          PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'edit') {
                                // 수정 화면으로 이동
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => PostEditScreen(
                                      postId: post.id,
                                      initialTitle: postData['title'] ?? '제목 없음',
                                      initialContent: postData['content'] ?? '내용 없음',
                                    ),
                                  ),
                                );
                              } else if (value == 'delete') {
                                // 삭제 기능
                                await _deletePost(post.id);
                              }
                            },
                            itemBuilder: (BuildContext context) {
                              return [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('수정'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('삭제'),
                                ),
                              ];
                            },
                            icon: Icon(Icons.more_vert),
                          ),


                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }
}
