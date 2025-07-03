import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdminOrderController with ChangeNotifier {
  final List<QueryDocumentSnapshot> _orders = [];
  bool _isLoading = true;

  List<QueryDocumentSnapshot> get orders => _orders;
  bool get isLoading => _isLoading;

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
      if (data == null) {
        debugPrint("❌ Order data is null");
        return;
      }

      final userFcmToken = data['userFcmToken'];
      final userName = data['customerName'] ?? 'Customer';
      final orderAmount = data['amount'] ?? 0.0;

      await docRef.update({'status': newStatus});
      await fetchOrders();

      if (userFcmToken != null && userFcmToken.toString().isNotEmpty) {
        final title = "📦 Order Status Update";
        final body =
            "Hi $userName, your order of ₹${orderAmount.toStringAsFixed(2)} has been $newStatus.";

        await sendFcmNotification(
          token: userFcmToken,
          title: title,
          body: body,
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
      final url = Uri.parse(
        'https://nayana-s-artistry-dual-app-admin-and-user.onrender.com/send-notification',
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'adminToken': token, // Device FCM token
          'customerName': title, // Notification title
          'amount': body, // Notification body (renamed on server is better)
        }),
      );

      if (response.statusCode == 200) {
        debugPrint("📬 Notification sent via server");
      } else {
        debugPrint("❌ Server error: ${response.statusCode}");
        debugPrint("📨 Response: ${response.body}");
      }
    } catch (e) {
      debugPrint("🔥 Exception sending via server: $e");
    }
  }
}
