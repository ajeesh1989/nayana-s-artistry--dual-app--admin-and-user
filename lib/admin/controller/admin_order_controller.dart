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
      final orderId = data['orderId'] ?? docRef.id;

      await docRef.update({'status': newStatus});
      await fetchOrders();

      if (userFcmToken != null && userFcmToken.toString().isNotEmpty) {
        await sendFcmNotification(
          token: userFcmToken,
          orderId: orderId.toString(),
          status: newStatus,
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
    required String orderId,
    required String status,
  }) async {
    try {
      final url = Uri.parse(
        'https://nayana-s-artistry-dual-app-admin-and-user.onrender.com/send-user-status-update',
      );

      final payload = {
        'userToken': token,
        'orderId': orderId,
        'status': status,
      };

      debugPrint(
        "🚀 Sending status update with payload: ${jsonEncode(payload)}",
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      debugPrint("📨 Response status: ${response.statusCode}");
      debugPrint("📨 Response body: ${response.body}");

      if (response.statusCode == 200) {
        debugPrint("✅ Notification sent successfully to user");
      } else {
        debugPrint("❌ Server responded with an error");
      }
    } catch (e) {
      debugPrint("🔥 Exception while sending notification: $e");
    }
  }
}
