import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class OrderController with ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _orders = [];
  StreamSubscription? _orderSubscription;

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
      'status': 'Pending',
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'address': address,
    };

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
  }

  /// Listen to real-time orders
  Future<void> fetchOrders() async {
    await _orderSubscription?.cancel(); // Clean old listener

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
  Future<void> cancelOrder(String orderId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('orders')
        .doc(orderId)
        .update({'status': 'Cancelled'});

    await _firestore
        .collection('admin')
        .doc('orders')
        .collection('allOrders')
        .doc(orderId)
        .update({'status': 'Cancelled'});
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
