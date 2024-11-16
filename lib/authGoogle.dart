import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GoogleAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Google 로그인 함수
  Future<User?> signInWithGoogle() async {
    try {
      // Google 로그인
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print("사용자가 Google 로그인을 취소했습니다.");
        return null;
      }

      // Google 인증 정보 가져오기
      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      // Firebase Credential 생성
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase 로그인
      UserCredential userCredential =
      await _auth.signInWithCredential(credential);

      // Firestore에 기본 정보 저장 (닉네임과 userid는 사용자가 입력)
      await saveInitialUserData(userCredential.user);

      return userCredential.user;
    } catch (e) {
      print("Google 로그인 에러: $e");
      return null;
    }
  }

  // 기본 사용자 정보 저장
  Future<void> saveInitialUserData(User? user) async {
    if (user == null) return;

    final userDoc = _firestore.collection('users').doc(user.uid);

    final docSnapshot = await userDoc.get();

    if (!docSnapshot.exists) {
      // 기본 정보 저장 (추가 정보는 나중에 입력)
      await userDoc.set({
        'email': user.email,
        'profileImageUrl': 'gs://community-2d8f2.firebasestorage.app/default_profile.png', //기본 이미지
        'loginMethod': 'google',
        'nickName': null, // 사용자 입력 필요
        'createdAt': FieldValue.serverTimestamp(), //생성 날짜
      });
      print("기본 사용자 정보 Firestore에 저장 완료.");
    } else {
      print("사용자 정보가 이미 Firestore에 존재합니다.");
    }
  }

  // 로그아웃 함수
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    print("Google 로그아웃 완료");
  }
}
