import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nayanasartistry/user/home/home.dart';
import 'package:nayanasartistry/user/order/invoice.dart';
import 'package:nayanasartistry/user/productview/product_view.dart';
import 'package:provider/provider.dart';
import 'package:nayanasartistry/user/order/order_controller.dart';
import 'package:url_launcher/url_launcher.dart';

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
              final deliveredDate =
                  order['deliveredDate'] ?? order['deliveredAt'];
              final cancelledDate = order['cancelledDate'];

              return ExpansionTile(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Item Price = ₹$total",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (status == 'Cancelled')
                      const Icon(Icons.cancel, color: Colors.red),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          "Status: ",
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          status,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                status == 'Cancelled'
                                    ? Colors.red
                                    : Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (status != 'Cancelled') ...[
                      const SizedBox(height: 6),
                      _buildOrderStatusStepper(order),
                      const SizedBox(height: 15),
                    ],
                    if (status == 'Delivered' &&
                        deliveredDate != null &&
                        order['assignedRiderId'] != null)
                      FutureBuilder<DocumentSnapshot>(
                        future:
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(order['assignedRiderId'])
                                .get(),
                        builder: (context, snapshot) {
                          String riderName = 'CourierX';
                          if (snapshot.hasData && snapshot.data!.exists) {
                            final riderData =
                                snapshot.data!.data() as Map<String, dynamic>;
                            riderName = riderData['name'] ?? 'CourierX';
                          }

                          return Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                "Delivered by $riderName on: ${DateFormat.yMMMd().add_jm().format((deliveredDate as Timestamp).toDate())}",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          );
                        },
                      )
                    else if (status == 'Cancelled' && cancelledDate != null)
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            "❌ Cancelled on: ${DateFormat.yMMMd().add_jm().format((cancelledDate as Timestamp).toDate())}",
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      )
                    else if (status != 'Cancelled')
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            "Delivery by: $deliveryDate",
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),

                    const SizedBox(height: 8),
                    if (order['assignedRiderId'] != null &&
                        status != 'Delivered')
                      FutureBuilder<DocumentSnapshot>(
                        future:
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(order['assignedRiderId'])
                                .get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: Text("Fetching rider info..."),
                            );
                          }
                          if (!snapshot.hasData ||
                              snapshot.data?.data() == null) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: Text("Rider info not available"),
                            );
                          }
                          final riderData =
                              snapshot.data!.data() as Map<String, dynamic>;
                          final riderName = riderData['name'] ?? '-';
                          final riderPhone = riderData['phone'] ?? '-';

                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Icon(Icons.delivery_dining, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  "Rider: ",
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  riderName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                GestureDetector(
                                  onTap: () async {
                                    final Uri phoneUri = Uri(
                                      scheme: 'tel',
                                      path: riderPhone,
                                    );
                                    if (await canLaunchUrl(phoneUri)) {
                                      await launchUrl(phoneUri);
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text("Cannot launch dialer"),
                                        ),
                                      );
                                    }
                                  },
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.phone,
                                        size: 16,
                                        color: Colors.blue,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        riderPhone,
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.w500,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
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
                  _buildActions(context, order),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildActions(BuildContext context, Map<String, dynamic> order) {
    final orderId = order['id'];
    final items = order['items'] ?? [];
    final status = order['status'] ?? 'Placed';

    // If order is cancelled, don't show any action buttons
    if (status == 'Cancelled') {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(right: 16.0, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Show Leave Feedback for all except cancelled
              if (status == 'Delivered')
                Card(
                  child: TextButton.icon(
                    onPressed: () => _handleFeedback(context, orderId, items),
                    icon: const Icon(Icons.feedback, color: Colors.blue),
                    label: const Text(
                      "Leave Feedback",
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ),
              const SizedBox(width: 10),

              // Only show Download Invoice for Delivered orders
              if (status == 'Delivered')
                Card(
                  child: TextButton.icon(
                    onPressed: () => _downloadInvoice(order, context),
                    icon: const Icon(Icons.download, color: Colors.green),
                    label: const Text(
                      "Download Invoice",
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                ),
            ],
          ),
          // Show Cancel option if not delivered or cancelled
          if (status != 'Delivered')
            Card(
              child: TextButton.icon(
                icon: const Icon(Icons.cancel, color: Colors.red),
                label: const Text(
                  "Cancel Order",
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () => _showCancelReasonDialog(context, orderId),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderStatusStepper(Map<String, dynamic> order) {
    final steps = [
      "Placed",
      "Approved",
      "Shipped",
      "Out for Delivery",
      "Delivered",
    ];
    final statusDates = {
      "Approved": order['approvedDate'],
      "Shipped": order['shippedDate'],
      "Out for Delivery": order['outForDeliveryDate'],
      "Delivered": order['deliveredDate'],
    };
    final currentIndex = steps.indexWhere((s) => s == order['status']);

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
                        color: isCompleted ? Colors.green : Colors.grey,
                      ),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          color: isCompleted ? Colors.black : Colors.grey,
                        ),
                      ),
                      if (statusDates[label] != null)
                        Text(
                          DateFormat.MMMd().add_jm().format(
                            (statusDates[label] as Timestamp).toDate(),
                          ),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                  if (idx != steps.length - 1)
                    Container(
                      width: 30,
                      height: 2,
                      color: isCompleted ? Colors.green : Colors.grey,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                ],
              );
            }).toList(),
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
                      await controller.cancelOrder(orderId, selectedReason!);
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

  void _downloadInvoice(
    Map<String, dynamic> order,
    BuildContext context,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => InvoicePreviewPage(order: order)),
    );
  }
}
