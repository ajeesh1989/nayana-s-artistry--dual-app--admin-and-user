// order_success_page.dart
import 'package:flutter/material.dart';

class OrderSuccessPage extends StatelessWidget {
  final List<dynamic> items;
  final String deliveryDate;

  const OrderSuccessPage({
    super.key,
    required this.items,
    required this.deliveryDate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Order Confirmed"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "🎉 Your order has been placed!",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text("Expected Delivery: $deliveryDate"),
            const Divider(height: 30),
            Text("Items:", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (_, index) {
                  final item = items[index];
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
          ],
        ),
      ),
    );
  }
}
