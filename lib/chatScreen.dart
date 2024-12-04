import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class ChatScreen extends StatefulWidget {
  final String chatId; // 채팅방 ID
  final DocumentSnapshot otherUser; // 상대방 유저 정보

  const ChatScreen({
    Key? key,
    required this.chatId,
    required this.otherUser,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController messageController = TextEditingController();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUser["nickName"]),
      ),
      body: Column(
        children: [
          // 채팅 메시지 리스트
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("chats")
                  .doc(widget.chatId)
                  .collection("messages")
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No messages yet"));
                }

                var messages = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true, // 최신 메시지가 위로 오도록 정렬
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var message = messages[index];
                    bool isMe = message["senderId"] == currentUserId;
                    return buildMessageBubble(message["text"], isMe);
                  },
                );
              },
            ),
          ),
          // 메시지 입력 창
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9a-zA-Zㄱ-ㅎ가-힣]')),
                    ],
                    decoration: InputDecoration(
                      hintText: "메시지를 입력하세요",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.text, // 텍스트 입력 유형 설정
                    textInputAction: TextInputAction.done, // 엔터 키 액션
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 메시지 버블 위젯
  Widget buildMessageBubble(String text, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Text(
          text,
          style: TextStyle(color: isMe ? Colors.white : Colors.black),
        ),
      ),
    );
  }

  // 메시지 전송 로직
  Future<void> sendMessage() async {
    final messageText = messageController.text.trim();
    if (messageText.isEmpty) return;

    // 메시지 Firestore에 저장
    await FirebaseFirestore.instance
        .collection("chats")
        .doc(widget.chatId)
        .collection("messages")
        .add({
      "text": messageText,
      "senderId": currentUserId,
      "timestamp": FieldValue.serverTimestamp(),
    });

    // 입력 필드 초기화
    messageController.clear();
  }
}
