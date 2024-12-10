import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'common_layout.dart';
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
          .collectionGroup('users')
          .where('nickName', isEqualTo: nickname)
          .get();

      setState(() {
        searchResults = result.docs;
      });
    } catch (e) {
      print("Error searching user: $e");
    }
  }

  // 새로운 채팅방 생성 또는 기존 채팅방 ID 가져오기
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
    return CommonLayout(
      title: '채팅',
      child: Column(
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
                      labelText: "닉네임으로 검색",
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

  // 기존 채팅 목록 UI
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
          return Center(child: Text("오류: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("채팅방이 없습니다."));
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
                    title: Text("사용자 정보를 불러오는데 실패했습니다."),
                  );
                }
                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                  return const ListTile(
                    title: Text("사용자를 찾을 수 없습니다."),
                  );
                }

                final user = userSnapshot.data!;
                return ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(
                    user["nickName"],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD5E5FF),
                    ),
                  ),
                  subtitle: Text(
                    "최근 메시지가 없습니다.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFFD5E5FF).withOpacity(0.7),
                    ),
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Color(0xFFFFDCA2),
                    child: Icon(Icons.chat_bubble_outline, color: Color(0xFFFFD289)),
                  ),
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

  // 검색 결과 UI
  Widget buildSearchResults() {
    if (searchResults!.isEmpty) {
      return const Center(
        child: Text("사용자를 찾을 수 없습니다."),
      );
    }
    return ListView.builder(
      itemCount: searchResults!.length,
      itemBuilder: (context, index) {
        final user = searchResults![index];
        final userId = user.id;
        final nickname = user["nickName"];

        return ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Text(
            nickname,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD5E5FF),
            ),
          ),
          leading: CircleAvatar(
            backgroundColor: Color(0xFFFFDCA2),
            child: Icon(Icons.search, color: Color(0xFFFFD289)),
          ),
          onTap: () async {
            final chatId = await createOrGetChatRoom(userId);
            final userDoc = await FirebaseFirestore.instance.collection("users").doc(userId).get();
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
