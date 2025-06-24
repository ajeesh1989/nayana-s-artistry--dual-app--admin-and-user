import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:nayanasartistry/user/home/home.dart';

class OrderSuccessPage extends StatefulWidget {
  final List<dynamic> items;
  final String deliveryDate;

  const OrderSuccessPage({
    super.key,
    required this.items,
    required this.deliveryDate,
  });

  @override
  State<OrderSuccessPage> createState() => _OrderSuccessPageState();
}

class _OrderSuccessPageState extends State<OrderSuccessPage> {
  @override
  void initState() {
    super.initState();
    // Start timer for auto-redirect
    Timer(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
          (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Order Confirmed"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Lottie.asset(
              'assets/lottie/order_success.json', // Add your Lottie file in assets
              width: 200,
              repeat: false,
            ),
            const SizedBox(height: 12),
            const Text(
              "🎉 Your order has been placed!",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text("Expected Delivery: ${widget.deliveryDate}"),
            const Divider(height: 30),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Items:",
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: widget.items.length,
                itemBuilder: (_, index) {
                  final item = widget.items[index];
                  return ListTile(
                    leading: Image.network(
                      item['imageUrls'][0],
                      width: 50,
                      fit: BoxFit.cover,
                    ),
                    title: Text(item['name']),
                    subtitle: Text("₹${item['price']}"),
                  );
                },
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomePage()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.home),
              label: const Text("Back to Home"),
            ),
          ],
        ),
      ),
    );
  }
}
