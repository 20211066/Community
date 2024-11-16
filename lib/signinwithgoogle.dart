import 'package:flutter/material.dart';
import 'authservice_google.dart';

class GoogleSignInPage extends StatelessWidget {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Google Sign-In")),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            User? user = await _authService.signInWithGoogle();
            if (user != null) {
              print("Google Sign-In Successful: ${user.displayName}");
            } else {
              print("Google Sign-In Failed or Cancelled");
            }
          },
          child: Text("Sign in with Google"),
        ),
      ),
    );
  }
}
