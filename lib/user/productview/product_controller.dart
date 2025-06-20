import 'package:flutter/material.dart';

class ProductController with ChangeNotifier {
  int quantity = 1;

  void increaseQuantity() {
    quantity++;
    notifyListeners();
  }

  void decreaseQuantity() {
    if (quantity > 1) {
      quantity--;
      notifyListeners();
    }
  }

  void resetQuantity() {
    quantity = 1;
    notifyListeners();
  }
}
