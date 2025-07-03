import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

class NotificationSenderPage extends StatefulWidget {
  const NotificationSenderPage({super.key});

  @override
  State<NotificationSenderPage> createState() => _NotificationSenderPageState();
}

class _NotificationSenderPageState extends State<NotificationSenderPage> {
  final titleController = TextEditingController();
  final bodyController = TextEditingController();
  File? selectedImage;
  bool sending = false;

  Future<String?> uploadImage(File image) async {
    try {
      final fileName = p.basename(image.path);
      final ref = FirebaseStorage.instance.ref().child(
        'notifications/$fileName',
      );
      final uploadTask = await ref.putFile(image);
      return await ref.getDownloadURL();
    } catch (e) {
      log('❌ Upload failed: $e');
      return null;
    }
  }

  Future<void> sendNotification() async {
    if (titleController.text.isEmpty || bodyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🚨 Title and Body are required')),
      );
      return;
    }

    setState(() => sending = true);

    String? imageUrl;
    if (selectedImage != null) {
      imageUrl = await uploadImage(selectedImage!);
    }

    final response = await http.post(
      Uri.parse(
        'https://nayana-s-artistry-dual-app-admin-and-user.onrender.com/send-to-users',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'topic': 'user_broadcast',
        'title': titleController.text,
        'body': bodyController.text,
        'image': imageUrl,
      }),
    );

    log('📬 Server response: ${response.body}');
    setState(() {
      sending = false;

      // ✅ Clear fields after send
      if (response.statusCode == 200) {
        titleController.clear();
        bodyController.clear();
        selectedImage = null;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          response.statusCode == 200
              ? '✅ Notification sent!'
              : '❌ Failed to send: ${response.body}',
        ),
      ),
    );
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.gallery);
    if (result != null) {
      setState(() => selectedImage = File(result.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Notification to Users'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: bodyController,
              decoration: const InputDecoration(labelText: 'Body'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            if (selectedImage != null)
              Stack(
                alignment: Alignment.topRight,
                children: [
                  Image.file(selectedImage!, height: 150),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => selectedImage = null),
                  ),
                ],
              ),
            TextButton.icon(
              icon: const Icon(Icons.image),
              label: const Text('Pick Image'),
              onPressed: pickImage,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.send),
              label: Text(sending ? 'Sending...' : 'Send Notification'),
              onPressed: sending ? null : sendNotification,
            ),
          ],
        ),
      ),
    );
  }
}
