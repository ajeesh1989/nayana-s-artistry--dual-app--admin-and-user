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
    "Approved",
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

                  final orderPath = order.reference.path;
                  final items = List<Map<String, dynamic>>.from(
                    data['items'] ?? [],
                  );
                  final orderDate = (data['orderDate'] as Timestamp?)?.toDate();
                  final status = data['status'] ?? 'Pending';
                  final currentStatus =
                      statusOptions.contains(status)
                          ? status
                          : statusOptions.first;

                  final customerName = data['customerName'] ?? 'Unknown';
                  final email = data['customerEmail'] ?? 'No Email';
                  final phone = data['customerPhone'] ?? '-';
                  final address = data['deliveryAddress'] ?? '-';
                  final payment = data['paymentMethod'] ?? 'Unknown';

                  return ExpansionTile(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Name: ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Flexible(child: Text(customerName)),
                          ],
                        ),
                        Text(
                          email,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
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
                            ElevatedButton.icon(
                              icon: const Icon(Icons.edit),
                              label: const Text("Update Status"),
                              onPressed: () async {
                                String? selectedStatus = currentStatus;

                                await showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text("Select Order Status"),
                                      content: SingleChildScrollView(
                                        child: Column(
                                          children:
                                              statusOptions.map((statusOption) {
                                                final isPastStatus =
                                                    statusOptions.indexOf(
                                                      statusOption,
                                                    ) <
                                                    statusOptions.indexOf(
                                                      currentStatus,
                                                    );

                                                return RadioListTile<String>(
                                                  value: statusOption,
                                                  groupValue: selectedStatus,
                                                  onChanged:
                                                      isPastStatus
                                                          ? null
                                                          : (val) {
                                                            selectedStatus =
                                                                val;
                                                            Navigator.of(
                                                              context,
                                                            ).pop();
                                                          },
                                                  title: Text(
                                                    statusOption,
                                                    style: TextStyle(
                                                      color:
                                                          isPastStatus
                                                              ? Colors.grey
                                                              : null,
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                        ),
                                      ),
                                    );
                                  },
                                );

                                if (selectedStatus != null &&
                                    selectedStatus != currentStatus) {
                                  await controller.updateOrderStatus(
                                    orderPath,
                                    selectedStatus!,
                                  );

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Status updated to $selectedStatus",
                                      ),
                                    ),
                                  );
                                }
                              },
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
