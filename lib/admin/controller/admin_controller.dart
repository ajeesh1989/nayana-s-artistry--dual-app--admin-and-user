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
      // 🔍 USERS COLLECTION
      final usersSnapshot = await _firestore.collection('users').get();
      debugPrint("📦 Users found: ${usersSnapshot.size}");

      // 🔍 ORDERS - Assumes orders are subcollections named 'orders'
      final ordersSnapshot = await _firestore.collectionGroup('orders').get();
      debugPrint("🧾 Orders found: ${ordersSnapshot.size}");

      double totalRevenue = 0.0;

      for (var order in ordersSnapshot.docs) {
        final total = order.data()['total'];

        if (total is int) {
          totalRevenue += total.toDouble();
        } else if (total is double) {
          totalRevenue += total;
        } else {
          debugPrint("⚠️ Skipped order with invalid 'total': ${order.data()}");
        }
      }

      _userCount = usersSnapshot.size;
      _orderCount = ordersSnapshot.size;
      _revenue = totalRevenue;

      debugPrint("✅ Revenue calculated: ₹$_revenue");
    } catch (e) {
      debugPrint('🔥 Error fetching dashboard stats: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
