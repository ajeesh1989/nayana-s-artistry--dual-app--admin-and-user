import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminController with ChangeNotifier {
  int _userCount = 0;
  int _orderCount = 0;
  double _revenue = 0.0;
  bool _isLoading = true;

  int get userCount => _userCount;
  int get orderCount => _orderCount;
  double get revenue => _revenue;
  bool get isLoading => _isLoading;

  final _firestore = FirebaseFirestore.instance;

  Future<void> fetchDashboardStats() async {
    _isLoading = true;
    notifyListeners();

    try {
      // USERS
      final usersSnapshot = await _firestore.collection('users').get();
      _userCount = usersSnapshot.size;

      // ORDERS
      final ordersSnapshot = await _firestore.collectionGroup('orders').get();
      _orderCount = ordersSnapshot.size;

      double totalRevenue = 0.0;

      for (var order in ordersSnapshot.docs) {
        final data = order.data();
        final status = data['status'] ?? '';

        // ✅ Count only orders that are not cancelled / pending — modify as needed
        if (status == 'Delivered' ||
            status == 'Approved' ||
            status == 'Shipped' ||
            status == 'Out for Delivery') {
          final amount = data['amount'];

          if (amount is int) {
            totalRevenue += amount.toDouble();
          } else if (amount is double) {
            totalRevenue += amount;
          } else {
            debugPrint("⚠️ Invalid amount: ${order.id} -> $amount");
          }
        }
      }

      _revenue = totalRevenue;
      debugPrint("✅ Final revenue calculated: ₹$_revenue");
    } catch (e) {
      debugPrint('🔥 Error fetching dashboard stats: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
