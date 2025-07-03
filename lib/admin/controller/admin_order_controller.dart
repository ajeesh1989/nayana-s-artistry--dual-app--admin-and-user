import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdminOrderController with ChangeNotifier {
  final List<QueryDocumentSnapshot> _orders = [];
  bool _isLoading = true;

  List<QueryDocumentSnapshot> get orders => _orders;
  bool get isLoading => _isLoading;

  final String _serverKey = 'YOUR_FCM_SERVER_KEY_HERE'; // 🔐 Replace this!

  Future<void> fetchOrders() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot =
          await FirebaseFirestore.instance.collectionGroup('orders').get();

      _orders.clear();
      _orders.addAll(snapshot.docs);

      _orders.sort((a, b) {
        final aDate = (a['orderDate'] as Timestamp?)?.toDate() ?? DateTime(0);
        final bDate = (b['orderDate'] as Timestamp?)?.toDate() ?? DateTime(0);
        return bDate.compareTo(aDate);
      });
    } catch (e) {
      debugPrint("🔥 Error fetching orders: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> assignRider(String orderPath, String riderUid) async {
    try {
      await FirebaseFirestore.instance.doc(orderPath).update({
        'assignedRiderId': riderUid,
      });
      await fetchOrders();
    } catch (e) {
      debugPrint("🔥 Error assigning rider: $e");
    }
  }

  Future<void> updateOrderStatus(String orderPath, String newStatus) async {
    if (orderPath.isEmpty) {
      debugPrint("❗ Invalid order document path");
      return;
    }

    try {
      final docRef = FirebaseFirestore.instance.doc(orderPath);
      final snapshot = await docRef.get();

      final data = snapshot.data();
      final userFcmToken = data?['userFcmToken'];

      await docRef.update({'status': newStatus});
      await fetchOrders();

      if (userFcmToken != null && userFcmToken.toString().isNotEmpty) {
        await sendFcmNotification(
          token: userFcmToken,
          title: "Order Status Updated",
          body: "Your order status has been updated to $newStatus.",
        );
      } else {
        debugPrint("⚠️ No FCM token found for user.");
      }
    } catch (e) {
      debugPrint("🔥 Error updating order status: $e");
    }
  }

  Future<void> sendFcmNotification({
    required String token,
    required String title,
    required String body,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$_serverKey',
        },
        body: jsonEncode({
          'to': token,
          'notification': {'title': title, 'body': body, 'sound': 'default'},
        }),
      );

      if (response.statusCode == 200) {
        debugPrint("📬 FCM sent successfully");
      } else {
        debugPrint("❌ Failed to send FCM: ${response.body}");
      }
    } catch (e) {
      debugPrint("🔥 FCM Exception: $e");
    }
  }
}
