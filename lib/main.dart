import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'inAppLoginPage.dart'; // 로그인 페이지
import 'homePage.dart'; // 홈 화면
import 'naverMap.dart'; // 네이버 지도 화면
import 'neighborhood_verify_screen.dart'; // 동네 인증 화면

class RouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint("새로운 라우트로 이동: ${route.settings.name}");
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint("이전 라우트로 복귀: ${previousRoute?.settings.name}");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Firebase 초기화
  await NaverMapSdk.instance.initialize(
      clientId: 'hpa2d8y0jw',
      onAuthFailed: (ex) {
        print("********* 네이버맵 인증오류 : $ex *********");
      });
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Login App',
      navigatorObservers: [RouteObserver()],
      theme: ThemeData(
        primaryColor: Colors.blue,
      ),
      initialRoute: '/', // 로그인 상태에 따라 화면 결정
      routes: {
        '/': (context) => const AuthChecker(),
        '/home': (context) => HomePage(),
        '/login': (context) => InAppLoginPage(),
        '/naverMap': (context) => const NaverMapExample(), // 네이버 지도 경로 추가
      },
    );
  }
}

class AuthChecker extends StatelessWidget {
  const AuthChecker({super.key});

  Future<bool> _isNeighborhoodVerified(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.exists && (doc.data()?['isNeighborhoodVerified'] ?? false);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(), // 사용자 상태 변화를 구독
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('오류 발생: ${snapshot.error}'));
        }

        if (snapshot.hasData && snapshot.data != null) {
          // Firebase Auth를 통해 로그인 상태 확인 후 Firestore에서 인증 상태 조회
          return FutureBuilder<bool>(
            future: _isNeighborhoodVerified(snapshot.data!.uid),
            builder: (context, verifiedSnapshot) {
              if (verifiedSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (verifiedSnapshot.data == true) {
                return HomePage(); // 동네 인증 완료
              } else {
                return NeighborhoodVerifyScreen(selectedNeighborhood: '예시 동네'); // 동네 인증 필요
              }
            },
          );
        } else {
          return InAppLoginPage(); // 로그인 필요
        }
      },
    );
  }
}