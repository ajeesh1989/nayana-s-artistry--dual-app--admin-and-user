import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RiderHomeProvider extends ChangeNotifier {
  bool isLoading = true;

  List<QueryDocumentSnapshot> assignedOrders = []; // Out for Delivery
  List<QueryDocumentSnapshot> deliveredOrders = []; // Delivered

  String riderName = '';
  String riderPhone = '';
  String riderEmail = '';

  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  /// Loads rider info, assigned & delivered orders
  Future<void> loadInitialData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      riderEmail = user.email ?? '';

      await Future.wait([
        _fetchAssignedOrders(user.uid),
        _fetchDeliveredOrders(user.uid),
        _fetchRiderProfile(user.uid),
      ]);

      debugPrint("✅ Rider data loaded");
    } catch (e) {
      debugPrint("❌ Error loading rider data: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchAssignedOrders(String uid) async {
    final snapshot =
        await FirebaseFirestore.instance
            .collectionGroup('orders')
            .where('status', isEqualTo: 'Out for Delivery')
            .where('assignedRiderId', isEqualTo: uid)
            .get();

    assignedOrders = snapshot.docs;
    debugPrint("📦 Out for delivery: ${assignedOrders.length}");
  }

  Future<void> _fetchDeliveredOrders(String uid) async {
    final snapshot =
        await FirebaseFirestore.instance
            .collectionGroup('orders')
            .where('status', isEqualTo: 'Delivered')
            .where('assignedRiderId', isEqualTo: uid)
            .get();

    deliveredOrders = snapshot.docs;
    debugPrint("✅ Delivered: ${deliveredOrders.length}");
  }

  Future<void> _fetchRiderProfile(String uid) async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data();
    if (data != null) {
      riderName = data['name'] ?? '';
      riderPhone = data['phone'] ?? '';
      nameController.text = riderName;
      phoneController.text = riderPhone;
    }
  }

  /// Updates rider's name and phone in Firestore
  Future<void> updateRiderProfile(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'name': nameController.text.trim(),
      'phone': phoneController.text.trim(),
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Profile updated")));

    await _fetchRiderProfile(user.uid);
    Navigator.pop(context);
    notifyListeners();
  }

  /// Clears all state data during logout
  void clearAll() {
    isLoading = true;
    assignedOrders.clear();
    deliveredOrders.clear();
    riderName = '';
    riderPhone = '';
    riderEmail = '';
    nameController.clear();
    phoneController.clear();
    notifyListeners();
  }
}
