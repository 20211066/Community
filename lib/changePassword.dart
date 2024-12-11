import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 비밀번호 변경
  Future<void> changePassword(String newPassword) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // 현재 사용자 비밀번호 변경
        await user.updatePassword(newPassword);
        print("비밀번호 변경 성공");
      }
    } catch (e) {
      print("비밀번호 변경 실패: $e");
    }
  }
}
