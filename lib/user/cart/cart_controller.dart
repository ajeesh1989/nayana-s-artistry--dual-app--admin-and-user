import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CartProvider with ChangeNotifier {
  List<Map<String, dynamic>> cartItems = [];

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Fetch Cart Items from Firebase
  Future<void> fetchCart() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final snapshot =
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('cart')
            .get();

    cartItems =
        snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id; // preserve the document ID
          return data;
        }).toList();

    notifyListeners();
  }

  /// Add to Cart in Firebase
  Future<void> addToCart(Map<String, dynamic> product) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final cartRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('cart');

    // Avoid duplicates
    final existing = await cartRef.where('id', isEqualTo: product['id']).get();
    if (existing.docs.isNotEmpty) return;

    await cartRef.doc(product['id']).set(product);
    cartItems.add(product);
    notifyListeners();
  }

  /// Remove from Cart
  Future<void> removeFromCart(String productId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final cartRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('cart');

    await cartRef.doc(productId).delete();
    cartItems.removeWhere((item) => item['id'] == productId);
    notifyListeners();
  }
}
