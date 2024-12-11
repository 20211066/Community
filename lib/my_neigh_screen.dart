
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'post_screen.dart'; // 게시글 상세 화면 import
import 'post_edit.dart';

class MyNeighborhoodScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('동네생활 활동'),
          bottom: TabBar(
            labelColor: Color(0xFFFFD289),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFFFFD289),
            tabs: [
              Tab(text: '작성한 글'),
              Tab(text: '작성한 댓글'),
              Tab(text: '저장한 글'),
            ],
          ),
        ),
        body: Container(
          color: Color(0xFFFFF8E1), // 전체 배경색 적용
          child: TabBarView(
            children: [
              _buildTabContent(WrittenPostsTab()),
              _buildTabContent(CommentedPostsTab()),
              _buildTabContent(SavedPostsTab()),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildTabContent(Widget tabContent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: tabContent,
        ),
      ],
    );
  }

}



class WrittenPostsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('authorId', isEqualTo: currentUserId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          print("Error: ${snapshot.error}"); // 에러 디버깅 출력
          return Center(child: Text('작성한 글을 불러오는 데 실패했습니다.'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          print("No data found for authorId: $currentUserId"); // 데이터 없음 디버깅
          return Center(child: Text('작성한 글이 없습니다.'));
        }

        final posts = snapshot.data!.docs;

        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            final postData = post.data() as Map<String, dynamic>;

            print("Loaded post: ${post.id}"); // 로드된 게시글 디버깅

            return GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PostScreen(postId: post.id),
                  ),
                );
              },
              child: Card(
                margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                color: Color(0xFFFFDCA2),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              postData['title'] ?? '제목 없음',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8),
                            Text(
                              postData['content'] != null && postData['content'].length > 50
                                  ? '${postData['content'].substring(0, 50)}...'
                                  : (postData['content'] ?? '내용 없음'),
                              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                            ),
                            SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatTimestamp((postData['createdAt'] as Timestamp).toDate()),
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),

                              ],
                            ),
                          ],
                        ),
                      ),
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
                            await _deletePost(context, post.id);
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
    );
  }

  Future<void> _deletePost(BuildContext context, String postId) async {
    try {
      await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('게시글이 삭제되었습니다.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('게시글 삭제에 실패했습니다.')),
      );
    }
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


class CommentedPostsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collectionGroup('comments')
          .where('authorId', isEqualTo: currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          print("Error: ${snapshot.error}");
          return Center(child: Text('댓글단 글을 불러오는 데 실패했습니다.'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('댓글단 글이 없습니다.'));
        }

        final comments = snapshot.data!.docs;

        return ListView.builder(
          itemCount: comments.length,
          itemBuilder: (context, index) {
            final comment = comments[index];
            final commentData = comment.data() as Map<String, dynamic>;
            final parentPostId = comment.reference.parent.parent?.id;

            return GestureDetector(
              onTap: () {
                if (parentPostId != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PostScreen(postId: parentPostId),
                    ),
                  );
                }
              },
              child: Card(
                margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        commentData['content'] ?? '내용 없음',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _formatTimestamp((commentData['createdAt'] as Timestamp).toDate()),
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
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

class SavedPostsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('savedPosts')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('저장한 글을 불러오는 데 실패했습니다.'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('저장한 글이 없습니다.'));
        }

        final savedPosts = snapshot.data!.docs;

        return ListView.builder(
          itemCount: savedPosts.length,
          itemBuilder: (context, index) {
            final post = savedPosts[index];
            final postData = post.data() as Map<String, dynamic>;

            return GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PostScreen(postId: postData['postId']),
                  ),
                );
              },
              child: Card(
                margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              postData['title'] ?? '제목 없음',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8),
                            Text(
                              postData['content'] != null && postData['content'].length > 50
                                  ? '${postData['content'].substring(0, 50)}...'
                                  : (postData['content'] ?? '내용 없음'),
                              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                            ),
                            SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatTimestamp((postData['createdAt'] as Timestamp).toDate()),
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),

                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
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
