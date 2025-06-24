import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminChatPage extends StatefulWidget {
  final String chatId; // user_<uid>_admin
  final String userName;

  const AdminChatPage({
    super.key,
    required this.chatId,
    required this.userName,
  });

  @override
  State<AdminChatPage> createState() => _AdminChatPageState();
}

class _AdminChatPageState extends State<AdminChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add({
          'text': text,
          'fromUser': false, // admin message
          'timestamp': FieldValue.serverTimestamp(),
        });

    _controller.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
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
        title: Text('Chat with ${widget.userName}'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('chats')
                      .doc(widget.chatId)
                      .collection('messages')
                      .orderBy('timestamp')
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                if (messages.isEmpty) {
                  return const Center(child: Text('No messages yet'));
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
                              ? Alignment.centerLeft
                              : Alignment.centerRight,
                      child: Column(
                        crossAxisAlignment:
                            fromUser
                                ? CrossAxisAlignment.start
                                : CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color:
                                  fromUser
                                      // ignore: deprecated_member_use
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
                      hintText: 'Type your reply...',
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
