import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class MyProfileEditScreen extends StatefulWidget {
  @override
  _MyProfileEditScreenState createState() => _MyProfileEditScreenState();
}

class _MyProfileEditScreenState extends State<MyProfileEditScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController _nicknameController = TextEditingController();
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      final userData = userDoc.data() as Map<String, dynamic>;
      _nicknameController.text = userData['nickName'] ?? '';
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (user == null) return;

    final newNickName = _nicknameController.text.trim();

    if (newNickName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('닉네임을 입력해주세요.')));
      return;
    }

    try {
      // 닉네임 중복 확인
      final nickNameQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('nickName', isEqualTo: newNickName)
          .get();

      if (nickNameQuery.docs.isNotEmpty && nickNameQuery.docs.first.id != user!.uid) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('이미 사용중인 닉네임입니다.')));
        return;
      }

      String? profileImageUrl;

      // 프로필 이미지 업로드
      if (_imageFile != null) {
        final ref = FirebaseStorage.instance.ref().child('user_profiles').child(user!.uid + '.jpg');
        await ref.putFile(_imageFile!);
        profileImageUrl = await ref.getDownloadURL();
      }

      // Firestore 업데이트
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
        'nickName': newNickName,
        if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
      });

      // 확인 팝업 표시
      final result = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('변경 사항을 적용하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('아니요'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('예'),
              ),
            ],
          );
        },
      );



      if (result == true) {
        // 변경 사항 전달 및 화면 복귀
        Navigator.of(context).pop({
          'nickName': newNickName,
          if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
        });
      }
    } catch (e) {
      print('프로필 업데이트 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('프로필 업데이트에 실패했습니다.')));
    }
  }



  Future<void> _requestStoragePermission() async {
    // 저장공간 권한 요청 로직 추가 필요
    // 현재는 단순하게 권한이 없을 경우 알림을 띄우도록만 구현
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('저장공간 권한이 꺼져있습니다.'),
        content: Text('사진 업로드를 위해서는 [권한] 설정에서 저장공간 권한을 허용해야 합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () {
              // 설정 화면으로 이동하는 로직 필요
              Navigator.of(context).pop();
            },
            child: Text('설정으로 가기'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text('프로필 수정', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: Text('완료', style: TextStyle(color: Colors.black, fontSize: 18)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[300], // 배경색 설정
                  child: _imageFile != null
                      ? ClipOval(
                    child: Image.file(
                      _imageFile!,
                      fit: BoxFit.cover,
                      width: 100,
                      height: 100,
                    ),
                  )
                      : Icon(Icons.person, size: 50, color: Colors.grey[700]),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () async {
                      bool permissionGranted = true; // 실제 권한 체크 로직 필요
                      if (!permissionGranted) {
                        await _requestStoragePermission();
                      } else {
                        await _pickImage();
                      }
                    },
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.camera_alt, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            TextField(
              controller: _nicknameController,
              decoration: InputDecoration(
                labelText: '닉네임',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
