import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

Future<void> sendPushNotification({
  required String adminToken,
  required String customerName,
  required double amount,
}) async {
  final url = Uri.parse(
    'https://nayana-s-artistry-dual-app-admin-and-user.onrender.com/send-notification',
  );

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'adminToken': adminToken,
        'customerName': customerName,
        'amount': amount,
      }),
    );

    if (response.statusCode == 200) {
      log('📬 Notification sent successfully via server');
      log('📨 Response: ${response.body}');
    } else {
      log('⚠️ Server error: ${response.statusCode}');
      log('📨 Body: ${response.body}');
    }
  } catch (e) {
    log('❌ Failed to contact notification server: $e');
  }
}
