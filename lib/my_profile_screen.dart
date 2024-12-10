import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'my_profile_edit.dart'; // 프로필 수정 화면 import
import 'my_neigh_screen.dart';
import 'inAppLoginPage.dart'; // 로그인 화면 import
//import 'neighborhood_set_screen.dart'; // 내 동네 설정 화면 import
import 'neighborhood_verify_screen.dart'; // 우리 동네 인증 화면 import
import 'package:firebase_storage/firebase_storage.dart';


class MyProfileScreen extends StatefulWidget {
  @override
  _MyProfileScreenState createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  String nickName = '';
  String profileImageUrl = 'assets/profile.png';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<String> getProfileImageUrl() async {
    final ref = FirebaseStorage.instance.ref().child('default_profile.png');
    return await ref.getDownloadURL();
  }

  Future<void> _loadUserData() async {
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      final userData = userDoc.data() as Map<String, dynamic>;
      setState(() {
        nickName = userData['nickName'] ?? '닉네임을 설정하세요';
        profileImageUrl = userData['profileImageUrl'] ?? 'assets/profile.png';
      });
    }
  }

  Future<void> _deleteAccount() async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Column(
            children: [
              Icon(Icons.delete, size: 50, color: Colors.black),
              SizedBox(height: 10),
              Text('정말 탈퇴하시겠어요?'),
            ],
          ),
          content: Text('탈퇴 버튼 선택 시, 계정은 삭제되며 복구되지 않습니다.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  final userUid = user!.uid;

                  // 익명화: 작성한 게시글과 댓글의 authorId를 "deleted_user"로 변경
                  final userPosts = await FirebaseFirestore.instance
                      .collection('posts')
                      .where('authorId', isEqualTo: userUid)
                      .get();
                  for (var post in userPosts.docs) {
                    await post.reference.update({'authorId': 'deleted_user'});

                    // 댓글 익명화 처리
                    final comments = await post.reference.collection('comments').get();
                    for (var comment in comments.docs) {
                      await comment.reference.update({'authorId': 'deleted_user'});
                    }
                  }

                  // 사용자 데이터 삭제
                  await FirebaseFirestore.instance.collection('users').doc(userUid).delete();

                  // Firebase Auth 계정 삭제
                  await user!.delete();

                  // 로그인 화면으로 이동
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => InAppLoginPage()),
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('계정이 성공적으로 탈퇴되었습니다.')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('계정 삭제 중 오류가 발생했습니다.')),
                  );
                }
              },
              child: Text('탈퇴', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _changePassword() async {
    final TextEditingController currentPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    String errorMessage = '';

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('비밀번호 변경'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: currentPasswordController,
                    decoration: InputDecoration(labelText: '현재 비밀번호'),
                    obscureText: true,
                  ),
                  TextField(
                    controller: newPasswordController,
                    decoration: InputDecoration(labelText: '새 비밀번호'),
                    obscureText: true,
                  ),
                  TextField(
                    controller: confirmPasswordController,
                    decoration: InputDecoration(labelText: '새 비밀번호 확인'),
                    obscureText: true,
                  ),
                  if (errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        errorMessage,
                        style: TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ),
                ],
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
                    if (currentPasswordController.text.isEmpty) {
                      setState(() {
                        errorMessage = '현재 비밀번호를 입력해주세요.';
                      });
                      return;
                    }

                    try {
                      final credential = EmailAuthProvider.credential(
                        email: user!.email!,
                        password: currentPasswordController.text,
                      );

                      await user!.reauthenticateWithCredential(credential);
                    } catch (e) {
                      setState(() {
                        errorMessage = '현재 비밀번호가 일치하지 않습니다.';
                      });
                      return;
                    }

                    if (newPasswordController.text != confirmPasswordController.text) {
                      setState(() {
                        errorMessage = '새 비밀번호가 일치하지 않습니다.';
                      });
                      return;
                    }

                    try {
                      await user!.updatePassword(newPasswordController.text);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('비밀번호가 성공적으로 변경되었습니다.')),
                      );
                      Navigator.of(context).pop();
                    } catch (e) {
                      setState(() {
                        errorMessage = '비밀번호 변경 중 오류가 발생했습니다.';
                      });
                    }
                  },
                  child: Text('변경'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _logout() async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('로그아웃'),
          content: Text('로그아웃 하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('아니요'),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => InAppLoginPage()),
                );
              },
              child: Text('예'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToProfileEdit() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MyProfileEditScreen(),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        nickName = result['nickName'] ?? nickName;
        profileImageUrl = result['profileImageUrl'] ?? profileImageUrl;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '프로필',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFFFFDCA2),
        actions: [
          TextButton(
            onPressed: _navigateToProfileEdit, // 프로필 수정 화면으로 이동
            child: Text(
              '프로필 수정',
              style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Container(
        color: Color(0xFFFFF3E0), // 바탕색 변경
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 프로필 헤더
            Container(
              color: Color(0xFFFFDCA2), // 헤더 배경 색상
              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40, // 프로필 크기
                    backgroundImage: profileImageUrl.startsWith('http')
                        ? NetworkImage(profileImageUrl)
                        : AssetImage(profileImageUrl) as ImageProvider,
                  ),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nickName,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'UID: ${user?.uid.substring(0, 6).toUpperCase()}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(color: Color(0xFFFFDCA2), thickness: 2), // 구분선
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  ListTile(
                    leading: Icon(Icons.article, size: 32),
                    title: Text('우리 동네 모아보기', style: TextStyle(fontSize: 20)),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => MyNeighborhoodScreen()),
                      );
                    },
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.verified_user, size: 32),
                    title: Text('우리 동네 인증', style: TextStyle(fontSize: 20)),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => NeighborhoodVerifyScreen(
                            selectedNeighborhood: '',
                          ),
                        ),
                      );
                    },
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.lock, size: 32),
                    title: Text('비밀번호 변경', style: TextStyle(fontSize: 20)),
                    onTap: _changePassword,
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.logout, size: 32),
                    title: Text('로그아웃', style: TextStyle(fontSize: 20)),
                    onTap: _logout,
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.delete, size: 32),
                    title: Text('회원 탈퇴', style: TextStyle(fontSize: 20)),
                    onTap: _deleteAccount,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
