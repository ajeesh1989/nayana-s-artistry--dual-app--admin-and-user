import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    };

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('orders')
        .add(orderData);
  }
}
