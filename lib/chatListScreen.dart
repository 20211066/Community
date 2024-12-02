import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chatScreen.dart';

class ChatListScreen extends StatefulWidget {
  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final TextEditingController searchController = TextEditingController();
  List<QueryDocumentSnapshot>? searchResults;

  get otherUserId_ => null;

  Future<void> searchUser(String nickname) async {
    final result = await FirebaseFirestore.instance
        .collection("users")
        .where("nickname", isEqualTo: nickname)
        .get();

    setState(() {
      searchResults = result.docs;
    });
  }

  Future<String> createOrGetChatRoom(String otherUserId) async {
    final chatId = currentUserId.compareTo(otherUserId) < 0
        ? "$currentUserId$otherUserId"
        : "$otherUserId_$currentUserId";

    final chatDoc = FirebaseFirestore.instance.collection("chats").doc(chatId);
    final chatExists = (await chatDoc.get()).exists;

    if (!chatExists) {
      await chatDoc.set({
        "participants": [currentUserId, otherUserId],
      });
    }

    return chatId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chats"),
      ),
      body: Column(
        children: [
          // 검색 바
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: "Search by nickname",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    searchUser(searchController.text.trim());
                  },
                ),
              ],
            ),
          ),
          // 검색 결과 또는 채팅 리스트
          Expanded(
            child: searchResults == null
                ? buildChatList() // 기존 채팅 리스트
                : buildSearchResults(), // 검색 결과
          ),
        ],
      ),
    );
  }

  Widget buildChatList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("chats")
          .where("participants", arrayContains: currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator()); // 로딩 상태
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}")); // 에러 처리
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("No chats available")); // 데이터 없음 처리
        }

        var chats = snapshot.data!.docs;
        return ListView.builder(
          itemCount: chats.length,
          itemBuilder: (context, index) {
            var chat = chats[index];
            var otherUserId = (chat["participants"] as List)
                .firstWhere((uid) => uid != currentUserId);

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection("users").doc(
                  otherUserId).get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return ListTile(
                    title: Center(
                        child: CircularProgressIndicator()), // 유저 로딩 상태
                  );
                }
                if (userSnapshot.hasError) {
                  return ListTile(
                    title: Text("Error loading user"),
                  ); // 에러 처리
                }
                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                  return ListTile(
                    title: Text("User not found"),
                  ); // 데이터 없음 처리
                }

                var user = userSnapshot.data!;
                return ListTile(
                  title: Text(user["nickname"]),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ChatScreen(
                              chatId: chat.id,
                              otherUser: user,
                            ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget buildSearchResults() {
    if (searchResults!.isEmpty) {
      return Center(
        child: Text("No users found"), // 검색 결과 없음
      );
    }
    return ListView.builder(
      itemCount: searchResults!.length,
      itemBuilder: (context, index) {
        final user = searchResults![index];
        final userId = user.id;
        final nickname = user["nickname"];

        return ListTile(
          title: Text(nickname),
          onTap: () async {
            final chatId = await createOrGetChatRoom(userId);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ChatScreen(
                      chatId: chatId,
                      otherUser: user,
                    ),
              ),
            );
          },
        );
      },
    );
  }
}

