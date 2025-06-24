import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nayanasartistry/user/home/home.dart';
import 'package:nayanasartistry/user/productview/product_view.dart';
import 'package:provider/provider.dart';
import 'package:nayanasartistry/user/order/order_controller.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  @override
  void initState() {
    super.initState();
    Provider.of<OrderController>(context, listen: false).fetchOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Order History"), centerTitle: true),
      body: Consumer<OrderController>(
        builder: (context, controller, _) {
          final orders = controller.orders;

          if (orders.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      size: 80,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No Orders Yet!",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Looks like you haven't placed any orders.",
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey.shade500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Start",
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: Colors.grey.shade500),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const HomePage(),
                              ),
                            );
                          },
                          child: const Text(
                            'Shopping',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        Text(
                          "now!",
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            itemCount: orders.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (context, index) {
              final order = orders[index];
              final List items = order['items'] ?? [];
              final orderId = order['id'];
              final itemsTotal = items.fold<double>(
                0.0,
                (sum, item) =>
                    sum + ((item['price'] ?? 0.0) * (item['quantity'] ?? 1)),
              );
              final total = itemsTotal + 100;
              final paymentMethod = order['paymentMethod'] ?? 'N/A';
              final orderDate =
                  order['orderDate'] != null
                      ? DateFormat.yMMMd().add_jm().format(
                        (order['orderDate'] as Timestamp).toDate(),
                      )
                      : '';
              final deliveryDate = order['deliveryDate'] ?? 'N/A';
              final status = order['status'] ?? 'Placed';
              final deliveredDate = order['deliveredDate'];

              return ExpansionTile(
                title: Text("₹$total"),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Status: $status",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    _buildOrderStatusStepper(status),
                    const SizedBox(height: 4),
                    if (status == 'Delivered' && deliveredDate != null)
                      Text("Delivered on: $deliveredDate")
                    else
                      Text("Delivery by: $deliveryDate"),
                  ],
                ),
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
                        (item['imageUrls'] != null &&
                                item['imageUrls'].isNotEmpty)
                            ? item['imageUrls'][0]
                            : null;
                    final name = item['name'] ?? 'Item';
                    final price = item['price'] ?? 0.0;
                    final qty = item['quantity'] ?? 1;

                    return ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => ProductViewScreen(productData: item),
                          ),
                        );
                      },
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
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text("Qty: $qty  |  ₹$price"),
                    );
                  }).toList(),
                  _buildActions(context, orderId, items),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildOrderStatusStepper(String status) {
    final steps = [
      "Placed",
      "Approved",
      "Shipped",
      "Out for Delivery",
      "Delivered",
    ];

    final currentIndex = steps.indexWhere((s) => s == status);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            steps.asMap().entries.map((entry) {
              final idx = entry.key;
              final label = entry.value;
              final isCompleted = idx <= currentIndex;

              return Row(
                children: [
                  Column(
                    children: [
                      Icon(
                        isCompleted
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: isCompleted ? Colors.grey : Colors.blue,
                      ),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          color: isCompleted ? Colors.grey : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  if (idx != steps.length - 1)
                    Container(
                      width: 30,
                      height: 2,
                      color: isCompleted ? Colors.grey : Colors.blue,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                ],
              );
            }).toList(),
      ),
    );
  }

  Widget _buildActions(BuildContext context, String orderId, List items) {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _handleFeedback(context, orderId, items),
                icon: const Icon(Icons.feedback, color: Colors.blue),
                label: const Text(
                  "Leave Feedback",
                  style: TextStyle(color: Colors.blue),
                ),
              ),
              const SizedBox(width: 10),
              TextButton.icon(
                onPressed: () => _downloadInvoice({}, context),
                icon: const Icon(Icons.download, color: Colors.green),
                label: const Text(
                  "Download Invoice",
                  style: TextStyle(color: Colors.green),
                ),
              ),
            ],
          ),
          TextButton.icon(
            icon: const Icon(Icons.cancel, color: Colors.red),
            label: const Text(
              "Cancel Order",
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () => _showCancelReasonDialog(context, orderId),
          ),
        ],
      ),
    );
  }

  Future<void> _showCancelReasonDialog(
    BuildContext context,
    String orderId,
  ) async {
    final reasons = [
      "Ordered by mistake",
      "Found cheaper elsewhere",
      "Shipping is too slow",
      "Change of mind",
      "Other",
    ];
    String? selectedReason;

    await showDialog(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text("Cancel Order"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children:
                      reasons.map((reason) {
                        return RadioListTile<String>(
                          title: Text(reason),
                          value: reason,
                          groupValue: selectedReason,
                          onChanged:
                              (val) => setState(() => selectedReason = val),
                        );
                      }).toList(),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("No"),
                  ),
                  TextButton(
                    onPressed: () async {
                      if (selectedReason == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please select a reason"),
                          ),
                        );
                        return;
                      }
                      Navigator.pop(context);
                      final controller = Provider.of<OrderController>(
                        context,
                        listen: false,
                      );
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
              );
            },
          ),
    );
  }

  void _handleFeedback(BuildContext context, String orderId, List items) {
    final textController = TextEditingController();
    double rating = 0;

    showDialog(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text("Leave Feedback"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: textController,
                      decoration: const InputDecoration(
                        hintText: "Type your feedback here",
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 10),
                    const Text("Rating"),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                          ),
                          onPressed: () => setState(() => rating = index + 1.0),
                        );
                      }),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () async {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) return;

                      for (var item in items) {
                        await FirebaseFirestore.instance
                            .collection('order_feedback')
                            .add({
                              'uid': user.uid,
                              'orderId': orderId,
                              'productId': item['id'],
                              'customerName': user.displayName ?? 'User',
                              'feedback': textController.text,
                              'rating': rating,
                              'timestamp': FieldValue.serverTimestamp(),
                            });
                      }
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Feedback submitted!")),
                      );
                    },
                    child: const Text("Submit"),
                  ),
                ],
              );
            },
          ),
    );
  }

  void _downloadInvoice(Map<String, dynamic> order, BuildContext context) {
    debugPrint("Download invoice for order: ${order['id']}");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Invoice download not implemented yet")),
    );
  }
}
