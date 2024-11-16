import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NickNameInputPage extends StatelessWidget {
  final TextEditingController _nickNameController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("닉네임 설정")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nickNameController,
              decoration: InputDecoration(labelText: "닉네임 입력"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _saveNickName();
                Navigator.pop(context); // 저장 후 이전 화면으로 이동
              },
              child: Text("저장하기"),
            ),
          ],
        ),
      ),
    );
  }

  // Firestore에 닉네임 저장
  Future<void> _saveNickName() async {
    final User? user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'nickName': _nickNameController.text,
    });

    print('닉네임 저장 완료');
  }
}
