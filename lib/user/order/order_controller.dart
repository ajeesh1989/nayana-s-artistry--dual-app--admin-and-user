import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class OrderController with ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _orders = [];
  StreamSubscription? _orderSubscription;

  // 🔐 Your FCM server key here
  static const String _fcmServerKey =
      'BPGyPBSmbepf36r_JodaJuYV6-B3hbjtgISzw9b_LYoW2i2aSvEAZLZ9WvOKrotQeqn2A6SIk3bZg8YP2gTNxg8';

  List<Map<String, dynamic>> get orders => _orders;

  /// Save order to Firestore and notify admins
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
    double? longitude, // ✅ Added
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final orderData = {
      'uid': user.uid,
      'items': items,
      'total': amount,
      'orderDate': Timestamp.now(),
      'deliveryDate': deliveryDate,
      'paymentMethod': paymentMethod,
      'status': 'Pending',
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'address': address,
      'deliveryLocation':
          (latitude != null && longitude != null)
              ? GeoPoint(latitude, longitude)
              : null, // ✅ Added deliveryLocation
    };

    try {
      final userOrderRef = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('orders')
          .add(orderData);

      await _firestore
          .collection('admin')
          .doc('orders')
          .collection('allOrders')
          .doc(userOrderRef.id)
          .set(orderData);

      // ✅ Notify all admins
      await _notifyAdmins(customerName, amount);
    } catch (e) {
      debugPrint("❌ Error saving order or sending notification: $e");
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
          final message = {
            "to": token,
            "notification": {
              "title": "🛒 New Order Placed",
              "body":
                  "$customerName placed an order worth ₹${amount.toStringAsFixed(0)}",
            },
            "data": {
              "click_action": "FLUTTER_NOTIFICATION_CLICK",
              "screen": "admin_orders",
            },
          };

          debugPrint("📤 Sending notification to $email");
          debugPrint("📦 Payload: ${jsonEncode(message)}");

          final response = await http.post(
            Uri.parse('https://fcm.googleapis.com/fcm/send'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'key=$_fcmServerKey',
            },
            body: jsonEncode(message),
          );

          debugPrint("📬 Response Status: ${response.statusCode}");
          debugPrint("📬 Response Body: ${response.body}");

          if (response.statusCode != 200) {
            debugPrint('⚠️ Failed to notify $email');
          } else {
            debugPrint('✅ Notification sent successfully to $email');
          }
        } else {
          debugPrint('🚫 Skipped $email: No valid FCM token');
        }
      }
    } catch (e) {
      debugPrint("🔥 Error notifying admins: $e");
    }
  }

  /// Listen to real-time orders
  Future<void> fetchOrders() async {
    await _orderSubscription?.cancel();

    final user = _auth.currentUser;
    if (user == null) return;

    _orderSubscription = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('orders')
        .orderBy('orderDate', descending: true)
        .snapshots()
        .listen((snapshot) {
          _orders =
              snapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return data;
              }).toList();

          notifyListeners();
        });
  }

  /// Cancel order (update status, don't delete)
  Future<void> cancelOrder(String orderId, String reason) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final updates = {'status': 'Cancelled', 'cancelReason': reason};

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('orders')
        .doc(orderId)
        .update(updates);

    await _firestore
        .collection('admin')
        .doc('orders')
        .collection('allOrders')
        .doc(orderId)
        .update(updates);
  }

  Future<void> submitFeedback({
    required String orderId,
    required String feedbackText,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('orders')
        .doc(orderId)
        .update({'feedback': feedbackText});

    await _firestore
        .collection('admin')
        .doc('orders')
        .collection('allOrders')
        .doc(orderId)
        .update({'feedback': feedbackText});
  }

  Future<void> requestReturn(String orderId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('orders')
        .doc(orderId)
        .update({'status': 'Return Requested'});

    await _firestore
        .collection('admin')
        .doc('orders')
        .collection('allOrders')
        .doc(orderId)
        .update({'status': 'Return Requested'});
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    super.dispose();
  }
}
