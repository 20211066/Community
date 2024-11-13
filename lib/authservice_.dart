import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 회원가입 API 호출 및 Firebase에 저장
  Future<void> registerUser(String email, String password, String nickname) async {
    final url = Uri.parse('https://yourapi.com/api/users/register');

    // API로 사용자 데이터 전송
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'nickname': nickname,
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      // Firebase Authentication에 사용자 생성
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Firestore에 추가 사용자 정보 저장
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'phoneNumber': nickname,
        'userId': userCredential.user!.uid,
      });

      print('User registered and data saved to Firebase.');
    } else {
      print('Failed to register user: ${response.body}');
    }
  }
}
