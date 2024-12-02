import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  final String chatId;
  final dynamic otherUser;

  ChatScreen({required this.chatId, required this.otherUser});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(otherUser["nickname"] ?? "Chat"),
      ),
      body: Center(
        child: Text("Chat with ${otherUser["nickname"]}!"),
      ),
    );
  }
}
