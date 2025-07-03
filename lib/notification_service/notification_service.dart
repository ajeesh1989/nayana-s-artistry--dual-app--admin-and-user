import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationService {
  final String baseUrl =
      'https://nayana-s-artistry-dual-app-admin-and-user.onrender.com';

  Future<bool> sendNotificationToAdmin({
    required String adminToken,
    required String customerName,
    required String amount,
  }) async {
    final url = Uri.parse('$baseUrl/send-notification');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'adminToken': adminToken,
        'customerName': customerName,
        'amount': amount,
      }),
    );

    return response.statusCode == 200;
  }

  Future<bool> broadcastToAllUsers({
    required String title,
    required String body,
    String? image,
  }) async {
    final url = Uri.parse('$baseUrl/send-to-users');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'topic': 'all_users',
        'title': title,
        'body': body,
        'image': image ?? '',
      }),
    );

    return response.statusCode == 200;
  }
}
