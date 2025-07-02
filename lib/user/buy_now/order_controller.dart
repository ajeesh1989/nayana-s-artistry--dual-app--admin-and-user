import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:nayanasartistry/user/order/send_notification.dart';

class OrderController {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> saveOrder({
    required double amount,
    required List<Map<String, dynamic>> items,
    required String paymentMethod,
    required String customerName,
    required String customerPhone,
    required String customerEmail,
    required String address,
    required String deliveryDate,
    double? latitude,
    double? longitude,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final orderData = {
      'amount': amount,
      'items': items,
      'paymentMethod': paymentMethod,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'deliveryAddress': address,
      'deliveryDate': deliveryDate,
      'orderDate': DateTime.now(),
      'status': 'Placed',
      'deliveryLocation':
          (latitude != null && longitude != null)
              ? GeoPoint(latitude, longitude)
              : null,
    };

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('orders')
          .add(orderData);

      debugPrint("📦 Order saved. Now notifying admins...");
      await _notifyAdmins(customerName, amount);
    } catch (e) {
      debugPrint("❌ Error saving order: $e");
    }
  }

  Future<void> _notifyAdmins(String customerName, double amount) async {
    try {
      final adminSnapshot =
          await _firestore
              .collection('users')
              .where('role', isEqualTo: 'admin')
              .get();

      debugPrint("🔍 Found ${adminSnapshot.docs.length} admin(s)");

      for (var doc in adminSnapshot.docs) {
        final token = doc['fcmToken'];
        final email = doc['email'] ?? 'Unknown';

        if (token != null && token.toString().isNotEmpty) {
          debugPrint("📤 Sending HTTP v1 notification to $email");
          await sendPushNotification(
            adminToken: token,
            customerName: customerName,
            amount: amount,
          );
        } else {
          debugPrint("🚫 Skipping $email: No valid FCM token");
        }
      }
    } catch (e) {
      debugPrint("🔥 Error notifying admins: $e");
    }
  }
}
