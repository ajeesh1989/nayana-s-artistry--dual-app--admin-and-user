import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nayanasartistry/user/shimmer.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controller/admin_order_controller.dart';

class AdminOrderListPage extends StatelessWidget {
  AdminOrderListPage({super.key});

  final List<String> statusOptions = [
    "Placed",
    "Pending",
    "Shipped",
    "Out for Delivery",
    "Delivered",
  ];

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<AdminOrderController>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("All Orders"), centerTitle: true),
      body:
          controller.isLoading
              ? const Center(child: ProductShimmer())
              : controller.orders.isEmpty
              ? const Center(child: Text("No orders found."))
              : ListView.builder(
                itemCount: controller.orders.length,
                itemBuilder: (context, index) {
                  final order = controller.orders[index];
                  final data = order.data() as Map<String, dynamic>?;

                  if (data == null) return const SizedBox.shrink();

                  final userId = data['uid'] ?? '';
                  final orderId = order.id;

                  final items = List<Map<String, dynamic>>.from(
                    data['items'] ?? [],
                  );
                  final orderDate = (data['orderDate'] as Timestamp?)?.toDate();
                  final status = data['status'] ?? 'Pending';
                  final currentStatus =
                      statusOptions.contains(status)
                          ? status
                          : statusOptions.first;

                  final customer = data['customerName'] ?? 'Unknown';
                  final phone = data['customerPhone'] ?? '-';
                  final address = data['deliveryAddress'] ?? '-';
                  final payment = data['paymentMethod'] ?? 'Unknown';

                  return ExpansionTile(
                    title: Row(
                      children: [
                        const Text(
                          'Customer: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Flexible(child: Text(customer)),
                      ],
                    ),
                    subtitle: Text(
                      "Status: $currentStatus\n${orderDate != null ? DateFormat.yMMMd().add_jm().format(orderDate) : "No Date"}",
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("📞 $phone"),
                            Text("🏠 $address"),
                            Text("💳 Payment: $payment"),
                            const SizedBox(height: 10),
                            const Text(
                              "🛒 Items:",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            ...items.map((item) {
                              final image = (item['imageUrls'] as List?)?.first;
                              return ListTile(
                                leading:
                                    image != null
                                        ? Image.network(
                                          image,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                        )
                                        : const Icon(Icons.image),
                                title: Text(item['name'] ?? 'Unnamed'),
                                subtitle: Text(
                                  "Qty: ${item['quantity'] ?? 1} | ₹${item['price'] ?? 0}",
                                ),
                              );
                            }).toList(),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Text("📦 Update Status:"),
                                const SizedBox(width: 10),
                                DropdownButton<String>(
                                  value: currentStatus,
                                  onChanged: (newStatus) {
                                    if (newStatus != null) {
                                      controller.updateOrderStatus(
                                        userId,
                                        orderId,
                                        newStatus,
                                      );
                                    }
                                  },
                                  items:
                                      statusOptions.map((statusOption) {
                                        return DropdownMenuItem(
                                          value: statusOption,
                                          child: Text(statusOption),
                                        );
                                      }).toList(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
    );
  }
}
