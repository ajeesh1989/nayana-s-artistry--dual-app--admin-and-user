import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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

      debugPrint("📦 Found ${snapshot.size} orders");

      _orders.clear();
      _orders.addAll(snapshot.docs);

      // Sort safely
      _orders.sort((a, b) {
        final aData = a.data() as Map<String, dynamic>?;
        final bData = b.data() as Map<String, dynamic>?;

        final aDate =
            (aData?['orderDate'] as Timestamp?)?.toDate() ?? DateTime(0);
        final bDate =
            (bData?['orderDate'] as Timestamp?)?.toDate() ?? DateTime(0);

        return bDate.compareTo(aDate);
      });
    } catch (e) {
      debugPrint("🔥 Error fetching orders: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateOrderStatus(
    String userId,
    String orderId,
    String newStatus,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('orders')
          .doc(orderId)
          .update({'status': newStatus});

      await fetchOrders(); // Refresh
    } catch (e) {
      debugPrint("🔥 Error updating order status: $e");
    }
  }
}
