import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nayanasartistry/admin/widgets/admin_chat.dart';

class AdminUserListPage extends StatelessWidget {
  const AdminUserListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat with Users'), centerTitle: true),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collectionGroup('messages')
                .where('fromUser', isEqualTo: true)
                .orderBy('timestamp', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No active chats yet.'));
          }

          final messages = snapshot.data!.docs;
          final Map<String, QueryDocumentSnapshot> latestByUser = {};

          for (var msg in messages) {
            final chatId = msg.reference.parent.parent!.id;
            if (chatId.startsWith('user_') && chatId.contains('_admin')) {
              final userId = chatId
                  .replaceFirst('user_', '')
                  .replaceFirst('_admin', '');

              if (!latestByUser.containsKey(userId)) {
                latestByUser[userId] = msg;
              }
            }
          }

          if (latestByUser.isEmpty) {
            return const Center(child: Text('No valid user chats found.'));
          }

          final chatList = latestByUser.entries.toList();

          return ListView.builder(
            itemCount: chatList.length,
            itemBuilder: (context, index) {
              final userId = chatList[index].key;
              final msg = chatList[index].value;
              final chatId = msg.reference.parent.parent!.id;

              final data = msg.data() as Map<String, dynamic>;
              final lastText = data['text'] ?? '';
              final userName = data['userName'] ?? 'User';
              final userEmail = data['userEmail'] ?? '';

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                    ),
                  ),
                  title: Text(
                    userName,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(lastText),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => AdminChatPage(
                              chatId: chatId,
                              userName: userName,
                            ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
