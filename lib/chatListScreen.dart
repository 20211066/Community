import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chatScreen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final TextEditingController searchController = TextEditingController();
  List<QueryDocumentSnapshot>? searchResults;

  // Firestore에서 nickname 검색
  Future<void> searchUser(String nickname) async {
    try {
      final result = await FirebaseFirestore.instance
          .collectionGroup('users') // 하위 컬렉션 전역 검색
          .where('nickName', isEqualTo: nickname) // 정확한 필드 이름 사용
          .get();

      if (result.docs.isEmpty) {
        print("No users found");
      } else {
        print("Search results: ${result.docs.map((e) => e.data())}");
      }

      setState(() {
        searchResults = result.docs;
      });
    } catch (e) {
      print("Error searching user: $e");
    }
  }


  // 새로운 채팅방을 생성하거나 기존 채팅방 ID 가져오기
  Future<String> createOrGetChatRoom(String otherUserId) async {
    final chatId = currentUserId.compareTo(otherUserId) < 0
        ? "$currentUserId$otherUserId"
        : "$otherUserId$currentUserId";

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
        title: Text("Chat List"),
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
                    decoration: const InputDecoration(
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
          // 검색 결과 또는 기존 채팅 목록
          Expanded(
            child: searchResults == null
                ? buildChatList() // 기존 채팅 목록
                : buildSearchResults(), // 검색 결과
          ),
        ],
      ),
    );
  }

  // 기존 채팅 목록 위젯
  Widget buildChatList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("chats")
          .where("participants", arrayContains: currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No chats found"));
        }

        final chats = snapshot.data!.docs;
        return ListView.builder(
          itemCount: chats.length,
          itemBuilder: (context, index) {
            final chat = chats[index];
            final otherUserId = (chat["participants"] as List)
                .firstWhere((uid) => uid != currentUserId);

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection("users").doc(otherUserId).get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const ListTile(
                    title: Center(child: CircularProgressIndicator()),
                  );
                }
                if (userSnapshot.hasError) {
                  return const ListTile(
                    title: Text("Error loading user"),
                  );
                }
                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                  return const ListTile(
                    title: Text("User not found"),
                  );
                }

                final user = userSnapshot.data!;
                return ListTile(
                  title: Text(user["nickName"]),
                  onTap: () async {
                    final chatId = chat.id;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          chatId: chatId,
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

  // 검색 결과 위젯
  Widget buildSearchResults() {
    if (searchResults!.isEmpty) {
      return const Center(
        child: Text("No users found"),
      );
    }
    return ListView.builder(
      itemCount: searchResults!.length,
      itemBuilder: (context, index) {
        final user = searchResults![index];
        final userId = user.id;
        final nickname = user["nickName"];

        return ListTile(
          title: Text(nickname),
          onTap: () async {
            final chatId = await createOrGetChatRoom(userId);
            // Firestore에서 해당 유저의 DocumentSnapshot 가져오기
            final userDoc = await FirebaseFirestore.instance
                .collection("users")
                .doc(userId)
                .get();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  chatId: chatId,
                  otherUser: userDoc,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
