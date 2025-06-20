// wish_list_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class WishlistProvider with ChangeNotifier {
  final List<Map<String, dynamic>> _wishlist = [];
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> get wishlist => _wishlist;

  bool isInWishlist(String productId) {
    return _wishlist.any((item) => item['id'] == productId);
  }

  Future<void> toggleWishlistItem(
    Map<String, dynamic> product,
    BuildContext context,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final wishlistRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('wishlist');
    final docRef = wishlistRef.doc(product['id']);

    final doc = await docRef.get();

    if (doc.exists) {
      await docRef.delete();
      _wishlist.removeWhere((item) => item['id'] == product['id']);
      notifyListeners();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Removed from wishlist')));
    } else {
      await docRef.set(product);
      _wishlist.add(product);
      notifyListeners();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Added to wishlist')));
    }
  }

  Future<void> fetchWishlist() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('wishlist')
            .get();

    _wishlist.clear();
    for (var doc in snapshot.docs) {
      final data = doc.data();
      data['id'] = doc.id;
      _wishlist.add(data);
    }

    notifyListeners();
  }
}
