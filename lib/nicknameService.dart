import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class NicknameService {
  /// 16진수 닉네임 생성
  static String generateHexNickname() {
    final random = Random();
    final length = random.nextInt(4) + 8; // 8~12자리의 16진수 생성
    final buffer = StringBuffer();
    for (int i = 0; i < length; i++) {
      buffer.write(random.nextInt(16).toRadixString(16));
    }
    return buffer.toString().toUpperCase(); // 대문자로 표시
  }

  /// 고유 16진수 닉네임 생성 및 등록
  static Future<String> registerWithHexNickname(String userId) async {
    String nickname;
    bool exists;

    do {
      nickname = generateHexNickname();

      // Firestore에서 닉네임 중복 확인
      final snapshot = await FirebaseFirestore.instance
          .collection("users")
          .where("nickname", isEqualTo: nickname)
          .get();

      exists = snapshot.docs.isNotEmpty;
    } while (exists);

    // 고유 닉네임 Firestore에 저장
    await FirebaseFirestore.instance.collection("users").doc(userId).set({
      "nickname": nickname,
      "createdAt": FieldValue.serverTimestamp(),
    });

    return nickname;
  }

  /// 사용자 닉네임 변경
  static Future<String?> updateNickname(String userId, String newNickname) async {
    // 닉네임 중복 확인
    final snapshot = await FirebaseFirestore.instance
        .collection("users")
        .where("nickname", isEqualTo: newNickname)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return "Nickname already taken"; // 닉네임 중복
    }

    // 닉네임 Firestore 업데이트
    await FirebaseFirestore.instance.collection("users").doc(userId).update({
      "nickname": newNickname,
    });

    return null; // 성공
  }
}
