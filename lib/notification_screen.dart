import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // 알림 데이터
  List<Map<String, String>> notifications = [
    {
      "title": "새로운 댓글",
      "description": "당신의 글에 새로운 댓글이 달렸습니다.",
    },
    {
      "title": "알림 테스트",
      "description": "알림 기능이 정상적으로 작동합니다.",
    },
  ];

  // 알림 삭제 함수
  void _removeNotification(int index) {
    setState(() {
      notifications.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('알림이 삭제되었습니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF9EF),
      appBar: AppBar(
        backgroundColor: Color(0xFFFFDCA2),
        title: Text(
          '알림',
          style: TextStyle(
            color: Color(0xFFFFD289),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: notifications.isEmpty
          ? Center(
        child: Text(
          '새로운 알림이 없습니다.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black,
          ),
        ),
      )
          : ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: ListTile(
              contentPadding:
              EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              title: Text(
                notification["title"]!,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              subtitle: Text(
                notification["description"]!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black.withOpacity(0.7),
                ),
              ),
              trailing: IconButton(
                icon: Icon(Icons.delete, color: Color(0xFFFFD289)),
                onPressed: () => _removeNotification(index),
              ),
            ),
          );
        },
      ),
    );
  }
}
