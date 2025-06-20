import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:nayanasartistry/user/order/order_controller.dart';

class OrderHistoryPage extends StatelessWidget {
  const OrderHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Order History"), centerTitle: true),
      body: FutureBuilder(
        future:
            Provider.of<OrderController>(context, listen: false).fetchOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final orders =
              Provider.of<OrderController>(context, listen: false).orders;

          if (orders.isEmpty) {
            return const Center(child: Text("No orders found."));
          }

          return ListView.separated(
            itemCount: orders.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (context, index) {
              final order = orders[index];
              final List items = order['items'] ?? [];
              final orderId = order['id'];
              final deliveryDate = order['deliveryDate'] ?? 'N/A';
              final total = order['total'] ?? 0.0;
              final paymentMethod = order['paymentMethod'] ?? 'N/A';
              final orderDate =
                  order['orderDate'] != null
                      ? DateFormat.yMMMd().add_jm().format(
                        (order['orderDate'] as Timestamp).toDate(),
                      )
                      : '';

              return ExpansionTile(
                title: Text(""),
                subtitle: Text("Delivery by: $deliveryDate"),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Payment: $paymentMethod"),
                        const SizedBox(height: 4),
                        Text("Ordered on: $orderDate"),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  ...items.map<Widget>((item) {
                    final imageUrl =
                        item['imageUrls'] != null &&
                                item['imageUrls'].isNotEmpty
                            ? item['imageUrls'][0]
                            : null;
                    final name = item['name'] ?? 'Item';
                    final price = item['price'] ?? 0.0;
                    final qty = item['quantity'] ?? 1;

                    return ListTile(
                      leading:
                          imageUrl != null
                              ? Image.network(
                                imageUrl,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, __, ___) => const Icon(Icons.image),
                              )
                              : const Icon(Icons.image),
                      title: Text(name),
                      subtitle: Text("Qty: $qty  |  ₹$price"),
                    );
                  }).toList(),
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0, bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => _handleReturnOrder(context),
                          icon: const Icon(Icons.undo, color: Colors.orange),
                          label: const Text(
                            "Return Order",
                            style: TextStyle(color: Colors.orange),
                          ),
                        ),
                        const SizedBox(width: 10),
                        TextButton.icon(
                          onPressed: () => _handleFeedback(context),
                          icon: const Icon(Icons.feedback, color: Colors.blue),
                          label: const Text(
                            "Leave Feedback",
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0, bottom: 8),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        label: const Text(
                          "Cancel Order",
                          style: TextStyle(color: Colors.red),
                        ),
                        onPressed: () {
                          _confirmCancelOrder(
                            context,
                            orderId,
                            Provider.of<OrderController>(
                              context,
                              listen: false,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _handleFeedback(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Leave Feedback"),
            content: const TextField(
              decoration: InputDecoration(hintText: "Type your feedback here"),
              maxLines: 3,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Submit"),
              ),
            ],
          ),
    );
  }

  void _handleReturnOrder(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Return Order"),
            content: const Text("Do you want to return this order?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("No"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Return request submitted.")),
                  );
                },
                child: const Text("Yes"),
              ),
            ],
          ),
    );
  }

  void _confirmCancelOrder(
    BuildContext context,
    String orderId,
    OrderController controller,
  ) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Cancel Order"),
            content: const Text("Are you sure you want to cancel this order?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("No"),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await controller.cancelOrder(orderId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Order cancelled successfully."),
                    ),
                  );
                },
                child: const Text("Yes, Cancel"),
              ),
            ],
          ),
    );
  }
}
