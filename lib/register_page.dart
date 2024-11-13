import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Firebase에 구글 로그인 연동
  Future<User?> signInWithGoogle() async {
    try {
      // 구글 로그인
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null; // 로그인 취소된 경우
      }

      // 구글 로그인 인증 토큰
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Firebase 인증용 크리덴셜 생성
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase 인증 진행
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      return userCredential.user;  // 로그인된 사용자 정보 반환
    } catch (error) {
      print("구글 로그인 에러: $error");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("회원가입"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              decoration: InputDecoration(labelText: '이메일'),
            ),
            SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(labelText: '비밀번호'),
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // 회원가입 버튼 클릭 시 동작
                print("회원가입 버튼 클릭");
              },
              child: Text("회원가입"),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                // 구글 로그인 버튼 클릭 시 구글 로그인 처리
                User? user = await signInWithGoogle();
                if (user != null) {
                  // 로그인 성공 후 처리
                  print('로그인 성공: ${user.displayName}');
                  // 구글 로그인 후, 원하는 페이지로 이동
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => NicknamePage(user: user)),
                  );
                } else {
                  print("구글 로그인 실패");
                }
              },
              child: Text("구글로 연동"),
            ),
          ],
        ),
      ),
    );
  }
}
class NicknamePage extends StatefulWidget {
  final User user;  // 로그인한 사용자 정보

  NicknamePage({required this.user});

  @override
  _NicknamePageState createState() => _NicknamePageState();
}

class _NicknamePageState extends State<NicknamePage> {
  final TextEditingController _nicknameController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 닉네임 업데이트 함수
  Future<void> updateNickname(String nickname) async {
    try {
      // Firebase 사용자 프로필 업데이트
      await widget.user.updateDisplayName(nickname);
      await widget.user.reload();
      User updatedUser = _auth.currentUser!;

      // 업데이트된 사용자 정보 출력 (확인용)
      print('닉네임 업데이트 성공: ${updatedUser.displayName}');
      // 닉네임 업데이트 후, 홈 페이지로 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage(user: updatedUser)),
      );
    } catch (error) {
      print("닉네임 업데이트 실패: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("닉네임 설정"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("구글 계정: ${widget.user.displayName}", style: TextStyle(fontSize: 20)),
            SizedBox(height: 16),
            TextField(
              controller: _nicknameController,
              decoration: InputDecoration(
                labelText: '닉네임을 입력하세요',
              ),
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                String nickname = _nicknameController.text.trim();
                if (nickname.isNotEmpty) {
                  updateNickname(nickname);
                } else {
                  print('닉네임을 입력해주세요.');
                }
              },
              child: Text("닉네임 저장"),
            ),
          ],
        ),
      ),
    );
  }
}

// 예시로 HomePage를 추가
class HomePage extends StatelessWidget {
  final User user;

  HomePage({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("홈페이지"),
      ),
      body: Center(
        child: Text("환영합니다, ${user.displayName}!", style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
