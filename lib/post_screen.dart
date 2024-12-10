import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'board_list_screen.dart'; // 각 카테고리 게시판으로 이동하기 위해 import

class PostScreen extends StatefulWidget {
  final String postId;

  PostScreen({required this.postId});

  @override
  _PostScreenState createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  late DocumentSnapshot postData;
  bool isLoading = true;
  bool isSaved = false; // 저장 버튼 상태
  final TextEditingController _commentController = TextEditingController(); // 댓글 입력 컨트롤러
  final TextEditingController _editCommentController = TextEditingController(); // 댓글 수정 컨트롤러
  int commentCount = 0; // 댓글 수 저장
  bool isDescending = false; // 정렬 기준
  String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _loadPostData();
    _loadCommentCount();
    _checkIfSaved();
  }

  // 게시글 데이터 불러오기
  Future<void> _loadPostData() async {
    try {
      postData = await FirebaseFirestore.instance.collection('posts').doc(widget.postId).get();
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('게시글 데이터를 불러오는 중 오류 발생: $e');
    }
  }

  // 댓글 수 가져오기
  void _loadCommentCount() {
    FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .snapshots()
        .listen((snapshot) {
      setState(() {
        commentCount = snapshot.docs.length;
      });
    });
  }

  // 저장 상태 확인
  Future<void> _checkIfSaved() async {
    if (currentUserId.isEmpty) return;
    final savedPost = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('savedPosts')
        .doc(widget.postId)
        .get();

    setState(() {
      isSaved = savedPost.exists;
    });
  }

  // 게시글 저장/해제
  Future<void> _toggleSavePost() async {
    if (currentUserId.isEmpty) return;

    final savedPostsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('savedPosts')
        .doc(widget.postId);

    if (isSaved) {
      // 저장 해제
      await savedPostsRef.delete();
    } else {
      // 저장
      await savedPostsRef.set({
        'postId': widget.postId,
        'title': postData['title'],
        'content': postData['content'],
        'createdAt': postData['createdAt'],
      });
    }

    setState(() {
      isSaved = !isSaved;
    });
  }

  // 댓글 추가하기
  Future<void> _addComment() async {
    if (_commentController.text.isEmpty) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('로그인이 필요합니다.')));
        return;
      }

      final comment = {
        'authorId': user.uid,
        'content': _commentController.text,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .add(comment);

      _commentController.clear();
    } catch (e) {
      print('댓글 작성에 실패했습니다: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('댓글 작성에 실패했습니다.')));
    }
  }

  // 댓글 수정하기
  Future<void> _editComment(String commentId) async {
    if (_editCommentController.text.isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .doc(commentId)
          .update({'content': _editCommentController.text});

      _editCommentController.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('댓글이 수정되었습니다.')));
    } catch (e) {
      print('댓글 수정에 실패했습니다: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('댓글 수정에 실패했습니다.')));
    }
  }

  // 댓글 삭제하기
  Future<void> _deleteComment(String commentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .doc(commentId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('댓글이 삭제되었습니다.')));
    } catch (e) {
      print('댓글 삭제에 실패했습니다: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('댓글 삭제에 실패했습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          title: Text('게시글 상세보기'),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final post = postData.data() as Map<String, dynamic>;
    final authorId = post['authorId'];
    final title = post['title'];
    final content = post['content'];
    final createdAt = (post['createdAt'] as Timestamp).toDate();
    final formattedTime = _formatTimestamp(createdAt);
    final category = post['category'] ?? '카테고리 없음';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          if (currentUserId != authorId) // 본인이 작성한 게시글이 아닐 경우만 표시
            IconButton(
              icon: Icon(
                isSaved ? Icons.star : Icons.star_border,
                color: isSaved ? Colors.yellow : Colors.grey,
              ),
              onPressed: _toggleSavePost,
            ),
        ],
        title: Text('게시글 상세보기'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 카테고리 버튼 (프로필 위에 위치, 화면에 고정하지 않음)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () {
                // 해당 카테고리의 게시판으로 이동
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => BoardListScreen(category: category),
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          // 작성자 정보
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(authorId).get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }

                if (snapshot.hasError) {
                  return Text('작성자 정보를 불러오는 데 실패했습니다.');
                }

                if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                  return Text('존재하지 않는 사용자', style: TextStyle(fontWeight: FontWeight.bold));
                }

                final authorData = snapshot.data!.data() as Map<String, dynamic>;
                final authorName = authorData['nickName'] ?? '존재하지 않는 사용자';

                final profileUrl = authorData['profileImageUrl'] ?? '';

                return Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: profileUrl.isNotEmpty
                          ? NetworkImage(profileUrl)
                          : AssetImage('assets/default_profile.png') as ImageProvider,
                    ),
                    SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authorName,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          formattedTime,
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // 게시글 제목과 내용
                Text(
                  title ?? '제목 없음',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  content ?? '내용 없음',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),

                // 조회수
                Text(
                  '조회수: ${post['views'] ?? 0}',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),

                // 댓글 헤더 (댓글 개수, 정렬 버튼)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '댓글 $commentCount',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                isDescending = false;
                              });
                            },
                            child: Text(
                              '등록순',
                              style: TextStyle(
                                color: isDescending ? Colors.grey : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                isDescending = true;
                              });
                            },
                            child: Text(
                              '최신순',
                              style: TextStyle(
                                color: isDescending ? Colors.black : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 댓글 목록
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .doc(widget.postId)
                      .collection('comments')
                      .orderBy('createdAt', descending: isDescending)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('댓글을 불러오는 데 실패했습니다.'));
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(child: Text('댓글이 없습니다.'));
                    }

                    final comments = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: comments.length,
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        final commentData = comment.data() as Map<String, dynamic>;
                        final commentContent = commentData['content'];
                        final commentAuthorId = commentData['authorId'];
                        final commentCreatedAt = (commentData['createdAt'] as Timestamp).toDate();
                        final commentFormattedTime = _formatTimestamp(commentCreatedAt);
                        final isAuthor = commentAuthorId == FirebaseAuth.instance.currentUser?.uid;

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 12.0),
                          padding: const EdgeInsets.all(18.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey[100],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundImage: AssetImage('assets/default_profile.png'),
                              ),
                              SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        FutureBuilder<DocumentSnapshot>(
                                          future: FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(commentAuthorId)
                                              .get(),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState == ConnectionState.waiting) {
                                              return Text('로딩 중...', style: TextStyle(fontSize: 14));
                                            }
                                            if (snapshot.hasError) {
                                              if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                                                return Text('존재하지 않는 사용자', style: TextStyle(fontWeight: FontWeight.bold));
                                              }
                                            }
                                            final authorData = snapshot.data?.data() as Map<String, dynamic>?;
                                            final nickname = authorData?['nickName'] ?? '존재하지 않는 사용자';
                                            return Text(
                                              nickname,
                                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                            );
                                          },
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          commentFormattedTime,
                                          style: TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      commentContent ?? '내용 없음',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    if (isAuthor)
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: PopupMenuButton<String>(
                                          onSelected: (value) {
                                            if (value == 'edit') {
                                              _editCommentController.text = commentData['content'] ?? '';
                                              showDialog(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  title: Text('댓글 수정'),
                                                  content: TextField(
                                                    controller: _editCommentController,
                                                    decoration: InputDecoration(hintText: '댓글을 수정하세요'),
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.of(context).pop();
                                                      },
                                                      child: Text('취소'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () async {
                                                        await _editComment(comment.id);
                                                        Navigator.of(context).pop();
                                                      },
                                                      child: Text('저장'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            } else if (value == 'delete') {
                                              _deleteComment(comment.id);
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            PopupMenuItem(
                                              value: 'edit',
                                              child: Text('수정'),
                                            ),
                                            PopupMenuItem(
                                              value: 'delete',
                                              child: Text('삭제'),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          // 댓글 입력창
          Container(
            padding: EdgeInsets.all(8.0),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: '댓글을 입력해주세요...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _addComment,
                ),
              ],
            ),
          ),
        ],
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
