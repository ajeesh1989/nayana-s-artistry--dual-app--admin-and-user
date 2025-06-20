// lib/user/order/order_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class OrderController with ChangeNotifier {
  final List<Map<String, dynamic>> _orders = [];
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> get orders => _orders;

  /// Save order to Firestore
  Future<void> saveOrder({
    required double amount,
    required List<Map<String, dynamic>> items,
    required String paymentMethod,
    required String customerName,
    required String customerPhone,
    required String customerEmail,
    required String address,
    required String deliveryDate,
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
      'status': 'Pending', // ✅ default
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'address': address,
    };

    // ✅ Save to user’s order collection
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('orders')
        .add(orderData);

    // ✅ Also save to admin’s global order view
    await _firestore
        .collection('admin')
        .doc('orders')
        .collection('allOrders')
        .add(orderData);
  }

  /// Fetch orders
  Future<void> fetchOrders() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final snapshot =
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('orders')
            .orderBy('orderDate', descending: true)
            .get();

    _orders.clear();
    for (var doc in snapshot.docs) {
      final data = doc.data();
      data['id'] = doc.id;
      _orders.add(data);
    }
    notifyListeners();
  }

  /// Cancel order
  Future<void> cancelOrder(String orderId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('orders')
        .doc(orderId)
        .delete();

    _orders.removeWhere((order) => order['id'] == orderId);
    notifyListeners();
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

    final index = _orders.indexWhere((o) => o['id'] == orderId);
    if (index != -1) {
      _orders[index]['status'] = 'Return Requested';
      notifyListeners();
    }
  }
}
