import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CompleteProfilePage extends StatelessWidget {
  final TextEditingController _nicknameController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("추가 정보 입력")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nicknameController,
              decoration: InputDecoration(labelText: "닉네임"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _saveAdditionalInfo();
                Navigator.pop(context); // 저장 후 이전 화면으로 이동
              },
              child: Text("저장하기"),
            ),
          ],
        ),
      ),
    );
  }

  // 추가 정보 저장 함수
  Future<void> _saveAdditionalInfo() async {
    final User? user = _auth.currentUser;
    if (user == null) return;

    final userDoc = _firestore.collection('users').doc(user.uid);

    await userDoc.update({
      'nickname': _nicknameController.text,
    });

    print("추가 사용자 정보 Firestore에 저장 완료.");
  }
}
