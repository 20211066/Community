import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 회원가입 및 Firestore에 기본 정보 저장
  Future<User?> registerUser(String nickName, String email,
      String password) async {
    try {
      // Firebase Authentication에 사용자 생성
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Firestore에 기본 사용자 정보 저장
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'profileImageUrl': 'gs://community-2d8f2.firebasestorage.app/default_profile.png',
        'loginMethod': 'InApp',
        'createdAt': FieldValue.serverTimestamp(),
        'nickName': nickName, // 사용자 입력 필요
      });

      print('회원가입 및 기본 사용자 정보 저장 완료');
      return userCredential.user;
    } catch (e) {
      print('회원가입 실패: $e');
      return null;
    }
  }

  Future<User?> loginWithEmailAndPassword(String email, String password) async {
    try {
      // Firebase Authentication으로 로그인 처리
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 로그인 성공 시 사용자 정보 반환
      return userCredential.user;
    } catch (e) {
      print("로그인 실패: $e");
      return null; // 로그인 실패 시 null 반환
    }
  }

  // 로그아웃 함수
  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<User?> registerWithEmailAndPassword(String email,
      String password) async {
    try {
      // Firebase 또는 다른 인증 서비스에서 회원가입 처리
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print("회원가입 실패: $e");
      return null;
    }
  }
  Future<void> registerWithEmail(String email, String password) async {
    try {
      // 이메일 사용 여부 확인
      List<String> methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      if (methods.isNotEmpty) {
        print("이미 존재하는 이메일입니다.");
        return;
      }

      // Firestore에서도 이메일 중복 확인
      final QuerySnapshot result = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();
      if (result.docs.isNotEmpty) {
        print("Firestore에 이미 존재하는 이메일입니다.");
        return;
      }

      // 회원가입
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Firestore에 사용자 정보 저장
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'createdAt': Timestamp.now(),
      });

      print("회원가입 성공!");
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        print("이미 사용 중인 이메일입니다.");
      } else {
        print("회원가입 오류: ${e.message}");
      }
    } catch (e) {
      print("오류 발생: $e");
    }
  }
}
