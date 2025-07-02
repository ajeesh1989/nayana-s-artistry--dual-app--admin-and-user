import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminOrderController with ChangeNotifier {
  final List<QueryDocumentSnapshot> _orders = [];
  bool _isLoading = true;

  List<QueryDocumentSnapshot> get orders => _orders;
  bool get isLoading => _isLoading;

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

  Future<void> updateOrderStatus(String orderPath, String newStatus) async {
    if (orderPath.isEmpty) {
      debugPrint("❗ Invalid order document path");
      return;
    }

    try {
      await FirebaseFirestore.instance.doc(orderPath).update({
        'status': newStatus,
      });
      await fetchOrders();
    } catch (e) {
      debugPrint("🔥 Error updating order status: $e");
    }
  }
}
