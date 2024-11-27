import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uni_links/uni_links.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zipcode_community/main.dart'; // MyApp 정의 파일 임포트

class AuthNaver extends StatefulWidget {
  const AuthNaver({super.key});

  static Future<User?> signInWithNaver(BuildContext context) async {
    try {
      const String clientId = 'CM56KhCXqEBPz4Bxw9mm';
      const String redirectUri = 'https://us-central1-community-2d8f2.cloudfunctions.net/naverLoginCallback';
      String state = Uri.encodeComponent(
          base64Url.encode(List<int>.generate(16, (_) => Random().nextInt(255))));

      Uri url = Uri.parse(
          'https://nid.naver.com/oauth2.0/authorize?response_type=code&client_id=$clientId&state=$state&redirect_uri=$redirectUri');

      if (!await canLaunchUrl(url)) {
        throw Exception("Cannot launch URL");
      }

      await launchUrl(url, mode: LaunchMode.externalApplication);
      print("Launching URL: $url");
      return null; // Further authentication happens in the callback
    } catch (error) {
      print("Error during Naver login: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login failed: $error")),
      );
      return null;
    }
  }

  @override
  State<AuthNaver> createState() => _AuthNaverState();
}

class _AuthNaverState extends State<AuthNaver> {
  StreamSubscription<String?>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    initUniLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  void navigateToMainPage() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => MyApp(),
      ),
    );
  }

  Future<void> initUniLinks() async {
    try {
      final initialLink = await getInitialLink();
      if (initialLink != null) _handleDeepLink(initialLink);

      _linkSubscription = linkStream.listen(
            (String? link) {
          if (link != null) _handleDeepLink(link);
        },
        onError: (err) {
          print("Deep link error: $err");
        },
      );
    } catch (error) {
      print("Error initializing uni links: $error");
    }
  }

  Future<void> _handleDeepLink(String link) async {
    try {
      print("Processing deep link: $link");
      final Uri uri = Uri.parse(link);

      if (uri.path.contains('login-callback')) {
        String? firebaseToken = uri.queryParameters['firebaseToken'];
        if (firebaseToken == null) throw Exception("Firebase token missing");

        await FirebaseAuth.instance.signInWithCustomToken(firebaseToken).then(
              (value) => navigateToMainPage(),
        );
      } else {
        print("Unexpected deep link path: ${uri.path}");
      }
    } catch (error) {
      print("Error handling deep link: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error processing deep link: $error")),
      );
    }
  }

  Future<void> naverLogout() async {
    try {
      await FlutterNaverLogin.logOut();
      print("Logout successful");
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => AuthNaver(),
        ),
      );
    } catch (error) {
      print("Error during logout: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Naver Auth")),
      body: Center(
        child: ElevatedButton(
          onPressed: () => AuthNaver.signInWithNaver(context),
          child: const Text("Login with Naver"),
        ),
      ),
    );
  }
}
