import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HomeProvider extends ChangeNotifier {
  int selectedIndex = 0;
  List<String> categories = [];
  bool isLoading = true;

  Future<void> fetchCategories() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('categories').get();
    final fetched = snapshot.docs.map((doc) => doc['title'] as String).toList();

    categories = ['All', ...fetched];
    isLoading = false;
    // Do not call notifyListeners here if fetchCategories is called inside initState
  }

  Stream<QuerySnapshot> fetchProducts(String category) {
    if (category == 'All') {
      return FirebaseFirestore.instance
          .collection('products')
          .orderBy('createdAt', descending: true)
          .snapshots();
    } else {
      return FirebaseFirestore.instance
          .collection('products')
          .where('category', isEqualTo: category)
          .orderBy('createdAt', descending: true)
          .snapshots();
    }
  }

  void setSelectedIndex(int index) {
    selectedIndex = index;
    notifyListeners();
  }
}
