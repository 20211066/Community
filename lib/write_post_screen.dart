import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WritePostScreen extends StatefulWidget {
  @override
  _WritePostScreenState createState() => _WritePostScreenState();
}

class _WritePostScreenState extends State<WritePostScreen> {
  String? _selectedCategory;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  Future<void> _submitPost() async {
    if (_selectedCategory != null && _titleController.text.isNotEmpty && _contentController.text.isNotEmpty) {
      final user = FirebaseAuth.instance.currentUser; // 현재 로그인한 사용자 가져오기
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('로그인이 필요합니다.'),
        ));
        return;
      }

      final post = {
        "category": _selectedCategory,
        "title": _titleController.text,
        "content": _contentController.text,
        "createdAt": FieldValue.serverTimestamp(),
        "views": 0, // 조회 수 필드 추가
        "comments": 0, // 댓글 수 필드 추가
        "authorId": user.uid, // 작성자의 UID 저장
      };

      try {
        await FirebaseFirestore.instance.collection('posts').add(post);
        Navigator.of(context).pop(); // 성공적으로 저장 후 화면 닫기
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('게시글 작성에 실패했습니다.'),
        ));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('모든 항목을 작성해주세요.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('게시글 작성'),
        actions: [
          TextButton(
            onPressed: _submitPost,
            child: Text(
              '완료',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                _showCategorySelection();
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedCategory ?? '게시글의 종류를 선택해주세요',
                      style: TextStyle(fontSize: 16),
                    ),
                    Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: '제목',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _contentController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: '내용',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategorySelection() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return ListView(
          children: ['행사', '소리함', '마을 소식', '우리 동네 장터', '우리의 선택', '자원봉사']
              .map((category) => ListTile(
            title: Text(category),
            onTap: () {
              setState(() {
                _selectedCategory = category;
              });
              Navigator.pop(context);
            },
          ))
              .toList(),
        );
      },
    );
  }
}