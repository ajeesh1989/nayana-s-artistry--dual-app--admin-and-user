import 'package:flutter/material.dart';
import 'package:nayanasartistry/user/account/address_model.dart';
import 'package:nayanasartistry/user/buy_now/order_controller.dart';
import 'package:nayanasartistry/user/cart/cart_controller.dart';
import 'package:nayanasartistry/user/order/order_success.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';

class BuyNowPage extends StatelessWidget {
  final double amount;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final Map<String, dynamic> productData;
  final AddressModel address;

  const BuyNowPage({
    super.key,
    required this.amount,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.productData,
    required this.address,
  });

  String _getDeliveryDate() {
    final now = DateTime.now();
    final delivery = now.add(const Duration(days: 4));
    return DateFormat('MMM dd, yyyy').format(delivery);
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Shimmer.fromColors(
                    baseColor: Colors.grey.shade600,
                    highlightColor: Colors.white,
                    child: const Icon(
                      Icons
                          .hourglass_top_rounded, // You can use Icons.notifications or any other
                      size: 60,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Placing your order...",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Good things take time ✨",
                    style: TextStyle(fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _handleRazorpayPayment(BuildContext context, String deliveryDate) {
    final razorpay = Razorpay();

    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (response) async {
      _showLoadingDialog(context);

      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      final items = productData['items'] ?? [productData];

      await OrderController().saveOrder(
        amount: amount,
        items: List<Map<String, dynamic>>.from(items),
        paymentMethod: "Online",
        customerName: customerName,
        customerPhone: customerPhone,
        customerEmail: customerEmail,
        address: address.address,
        deliveryDate: deliveryDate,
        latitude: address.latitude,
        longitude: address.longitude,
      );

      if (productData.containsKey('items')) {
        cartProvider.clearCart();
      }

      Navigator.pop(context); // Close loading dialog

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (_) => OrderSuccessPage(items: items, deliveryDate: deliveryDate),
        ),
      );
    });

    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (response) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Payment Failed: ${response.message}")),
      );
    });

    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (response) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Wallet: ${response.walletName}")));
    });

    try {
      razorpay.open({
        'key': 'rzp_test_IUEDjGDmWTLQdv',
        'amount': (amount * 100).toInt(),
        'name': 'Nayana’s Artistry',
        'description': 'Order Payment',
        'prefill': {'contact': customerPhone, 'email': customerEmail},
        'theme': {'color': '#F37254'},
      });
    } catch (e) {
      debugPrint("Razorpay error: $e");
    }
  }

  void _handleCOD(BuildContext context, String deliveryDate) async {
    _showLoadingDialog(context);

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final items = productData['items'] ?? [productData];

    await OrderController().saveOrder(
      amount: amount,
      items: List<Map<String, dynamic>>.from(items),
      paymentMethod: "COD",
      customerName: customerName,
      customerPhone: customerPhone,
      customerEmail: customerEmail,
      address: address.address,
      deliveryDate: deliveryDate,
      latitude: address.latitude,
      longitude: address.longitude,
    );

    if (productData.containsKey('items')) {
      cartProvider.clearCart();
    }

    Navigator.pop(context); // Close loading dialog

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (_) => OrderSuccessPage(items: items, deliveryDate: deliveryDate),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    String paymentMethod = 'Online';
    final deliveryDate = _getDeliveryDate();

    return StatefulBuilder(
      builder: (context, setState) {
        return Scaffold(
          appBar: AppBar(title: const Text("Confirm Order"), centerTitle: true),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_outlined),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "$customerName • $customerPhone",
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(address.address),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 30),
                Text("Order Summary", style: theme.textTheme.titleMedium),
                const SizedBox(height: 10),
                if (productData.containsKey('items'))
                  Column(
                    children:
                        (productData['items'] as List).map<Widget>((item) {
                          final imageUrl = item['imageUrls']?[0] ?? '';
                          return ListTile(
                            leading: Image.network(
                              imageUrl,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) => const Icon(Icons.image),
                            ),
                            title: Text(item['name'] ?? ''),
                            subtitle: Text("₹${item['price']}"),
                          );
                        }).toList(),
                  )
                else
                  ListTile(
                    leading: Image.network(
                      productData['imageUrls'][0] ?? '',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.image),
                    ),
                    title: Text(productData['name'] ?? ''),
                    subtitle: Text("₹${productData['price']}"),
                  ),
                const Divider(height: 30),
                Text(
                  "Select Payment Method",
                  style: theme.textTheme.titleMedium,
                ),
                RadioListTile(
                  title: const Text("Pay Now"),
                  value: 'Online',
                  groupValue: paymentMethod,
                  onChanged: (val) => setState(() => paymentMethod = val!),
                ),
                RadioListTile(
                  title: const Text("Cash on Delivery"),
                  value: 'COD',
                  groupValue: paymentMethod,
                  onChanged: (val) => setState(() => paymentMethod = val!),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: colorScheme.primary,
                    ),
                    icon: const Icon(Icons.check_circle),
                    label: Text(
                      "Place Order",
                      style: TextStyle(color: colorScheme.onSecondary),
                    ),
                    onPressed: () {
                      if (paymentMethod == 'Online') {
                        _handleRazorpayPayment(context, deliveryDate);
                      } else {
                        _handleCOD(context, deliveryDate);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }
}
