import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentService {
  late Razorpay _razorpay;

  void initRazorpay({
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onFailure,
    required Function(ExternalWalletResponse) onExternalWallet,
  }) {
    _razorpay = Razorpay();

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (response) {
      onSuccess(response as PaymentSuccessResponse);
    });
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (response) {
      onFailure(response as PaymentFailureResponse);
    });
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (response) {
      onExternalWallet(response as ExternalWalletResponse);
    });
  }

  void openCheckout({
    required double amount, // Accept as double for safer parsing
    required String name,
    required String email,
    required String phone,
  }) {
    final options = {
      'key': 'rzp_test_IUEDjGDmWTLQdv', // ✅ Your Razorpay test key ID
      'amount': (amount * 100).toInt(), // ₹100 => 10000 paise
      'name': name,
      'description': 'Purchase from Nayana\'s Artistry',
      'prefill': {'contact': phone, 'email': email},
      'currency': 'INR',
      'theme': {'color': '#F37254'},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error opening Razorpay checkout: $e');
    }
  }

  void dispose() {
    _razorpay.clear();
  }
}
