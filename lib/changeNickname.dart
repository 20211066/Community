import 'package:flutter/material.dart';
import 'nicknameService.dart';

class UpdateNicknameScreen extends StatelessWidget {
  final String userId; // 현재 로그인한 유저의 ID
  const UpdateNicknameScreen({super.key, required this.userId});

  void changeNickname(BuildContext context) async {
    final TextEditingController nicknameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Change Nickname"),
          content: TextField(
            controller: nicknameController,
            decoration: InputDecoration(labelText: "New Nickname"),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                String newNickname = nicknameController.text.trim();

                String? error = await NicknameService.updateNickname(userId, newNickname);
                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error)),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Nickname updated successfully")),
                  );
                  Navigator.pop(context);
                }
              },
              child: Text("Update"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Update Nickname")),
      body: Center(
        child: ElevatedButton(
          onPressed: () => changeNickname(context),
          child: Text("Change Nickname"),
        ),
      ),
    );
  }
}
