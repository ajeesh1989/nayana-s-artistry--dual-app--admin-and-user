import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final String chatId;
  late final String userId;

  String? userName;
  String? userEmail;

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser!;
    userId = currentUser.uid;
    chatId = 'user_${userId}_admin';

    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userDoc.exists) {
      final data = userDoc.data()!;
      setState(() {
        userName = data['name'] ?? '';
        userEmail = data['email'] ?? '';
      });
    } else {
      setState(() {
        userName = FirebaseAuth.instance.currentUser?.displayName ?? '';
        userEmail = FirebaseAuth.instance.currentUser?.email ?? '';
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
          'text': text,
          'fromUser': true,
          'userId': userId,
          'userName': userName ?? '',
          'userEmail': userEmail ?? '',
          'timestamp': FieldValue.serverTimestamp(),
        });

    _controller.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _sendSelectedDefaultMessage(String text) async {
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
          'text': text,
          'fromUser': true,
          'userId': userId,
          'userName': userName ?? '',
          'userEmail': userEmail ?? '',
          'timestamp': FieldValue.serverTimestamp(),
        });

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _clearChat() async {
    final messages =
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .get();

    for (var doc in messages.docs) {
      await doc.reference.delete();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Support'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'clear') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder:
                      (_) => AlertDialog(
                        title: const Text('Clear Chat'),
                        content: const Text(
                          'Are you sure you want to clear the chat?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                );
                if (confirm == true) {
                  await _clearChat();
                }
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'clear',
                    child: Text('Clear Chat'),
                  ),
                ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('chats')
                      .doc(chatId)
                      .collection('messages')
                      .orderBy('timestamp')
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                if (messages.isEmpty) {
                  final defaultMessages = [
                    'Hello!',
                    'I need help with my order.',
                    'Can someone assist me?',
                  ];

                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat, size: 80, color: colorScheme.primary),
                        const SizedBox(height: 16),
                        Text(
                          'No conversation yet',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Select a message to get started:',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children:
                              defaultMessages.map((msg) {
                                return ElevatedButton(
                                  onPressed:
                                      () => _sendSelectedDefaultMessage(msg),
                                  child: Text(msg),
                                );
                              }).toList(),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final text = msg['text'] ?? '';
                    final fromUser = msg['fromUser'] ?? false;
                    final timestamp =
                        (msg['timestamp'] as Timestamp?)?.toDate();

                    return Align(
                      alignment:
                          fromUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment:
                            fromUser
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color:
                                  fromUser
                                      ? colorScheme.primary.withOpacity(0.2)
                                      : Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.grey.shade600
                                      : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(text),
                          ),
                          if (timestamp != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                _formatTimestamp(timestamp),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: colorScheme.primary,
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final time = TimeOfDay.fromDateTime(timestamp);
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}
