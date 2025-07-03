import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nayanasartistry/user/shimmer.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controller/admin_order_controller.dart';

class AdminOrderListPage extends StatefulWidget {
  const AdminOrderListPage({super.key});

  @override
  State<AdminOrderListPage> createState() => _AdminOrderListPageState();
}

class _AdminOrderListPageState extends State<AdminOrderListPage>
    with SingleTickerProviderStateMixin {
  final List<String> statusTabs = [
    "Placed",
    "Approved",
    "Shipped",
    "Out for Delivery",
    "Delivered",
    "Cancelled",
  ];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: statusTabs.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<AdminOrderController>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("All Orders"),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: statusTabs.map((status) => Tab(text: status)).toList(),
        ),
      ),
      body:
          controller.isLoading
              ? const Center(child: ProductShimmer())
              : TabBarView(
                controller: _tabController,
                children:
                    statusTabs.map((status) {
                      final filteredOrders =
                          controller.orders.where((order) {
                            final data = order.data() as Map<String, dynamic>?;
                            return data?['status'] == status;
                          }).toList();

                      if (filteredOrders.isEmpty) {
                        return const Center(
                          child: Text("No orders in this status."),
                        );
                      }

                      return ListView.builder(
                        itemCount: filteredOrders.length,
                        itemBuilder: (context, index) {
                          final order = filteredOrders[index];
                          final data = order.data() as Map<String, dynamic>;

                          final orderPath = order.reference.path;
                          final items = List<Map<String, dynamic>>.from(
                            data['items'] ?? [],
                          );
                          final orderDate =
                              (data['orderDate'] as Timestamp?)?.toDate();
                          final customerName =
                              data['customerName'] ?? 'Unknown';
                          final email = data['customerEmail'] ?? 'No Email';
                          final phone = data['customerPhone'] ?? '-';
                          final address = data['deliveryAddress'] ?? '-';
                          final payment = data['paymentMethod'] ?? 'Unknown';
                          final assignedRiderId = data['assignedRiderId'];
                          final status = data['status'] ?? 'Placed';
                          final cancelReason = data['cancelReason'];

                          return Container(
                            decoration:
                                status == "Cancelled"
                                    ? BoxDecoration(
                                      border: Border.all(color: Colors.red),
                                      borderRadius: BorderRadius.circular(8),
                                    )
                                    : null,
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: ExpansionTile(
                              title: Text("$customerName - $email"),
                              subtitle: Text(
                                DateFormat.yMMMd().add_jm().format(
                                  orderDate ?? DateTime.now(),
                                ),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text("📞 $phone"),
                                      Text("🏠 $address"),
                                      Text("💳 Payment: $payment"),
                                      if (status == "Cancelled") ...[
                                        const SizedBox(height: 10),
                                        Text(
                                          "❌ Reason: ${cancelReason ?? 'Not specified'}",
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 10),
                                      const Text(
                                        "🛒 Items:",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      ...items.map((item) {
                                        final image =
                                            (item['imageUrls'] as List?)?.first;
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
                                          title: Text(
                                            item['name'] ?? 'Unnamed',
                                          ),
                                          subtitle: Text(
                                            "Qty: ${item['quantity']} | ₹${item['price']}",
                                          ),
                                        );
                                      }).toList(),
                                      const SizedBox(height: 10),
                                      if (status != "Cancelled")
                                        ElevatedButton.icon(
                                          icon: const Icon(Icons.edit),
                                          label: const Text("Update Status"),
                                          onPressed:
                                              () => _showStatusDialog(
                                                context,
                                                status,
                                                orderPath,
                                                controller,
                                              ),
                                        ),
                                      if (status == "Out for Delivery")
                                        ElevatedButton.icon(
                                          icon: const Icon(
                                            Icons.delivery_dining,
                                          ),
                                          label: const Text("Assign Rider"),
                                          onPressed:
                                              () => _showAssignRiderDialog(
                                                context,
                                                orderPath,
                                                controller,
                                              ),
                                        ),
                                      if (assignedRiderId != null)
                                        FutureBuilder<DocumentSnapshot>(
                                          future:
                                              FirebaseFirestore.instance
                                                  .collection('users')
                                                  .doc(assignedRiderId)
                                                  .get(),
                                          builder: (context, snapshot) {
                                            if (!snapshot.hasData) {
                                              return const Padding(
                                                padding: EdgeInsets.only(
                                                  top: 10,
                                                ),
                                                child: Text(
                                                  "Fetching rider info...",
                                                ),
                                              );
                                            }
                                            final rider =
                                                snapshot.data!.data()
                                                    as Map<String, dynamic>?;
                                            if (rider == null) {
                                              return const Text(
                                                "Rider not found",
                                              );
                                            }
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                top: 10,
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    "🚴 Assigned Rider:",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    "Name: ${rider['name']}",
                                                  ),
                                                  Text(
                                                    "Phone: ${rider['phone']}",
                                                  ),
                                                  Text(
                                                    "Email: ${rider['email']}",
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    }).toList(),
              ),
    );
  }

  Future<void> _showStatusDialog(
    BuildContext context,
    String currentStatus,
    String orderPath,
    AdminOrderController controller,
  ) async {
    final statusOptions = ["Placed", "Approved", "Shipped", "Out for Delivery"];
    String? selectedStatus = currentStatus;
    bool isUpdating = false;

    await showDialog(
      context: context,
      barrierDismissible: !isUpdating,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Select Order Status"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...statusOptions.map((statusOption) {
                    final isPast =
                        statusOptions.indexOf(statusOption) <
                        statusOptions.indexOf(currentStatus);
                    return RadioListTile<String>(
                      value: statusOption,
                      groupValue: selectedStatus,
                      onChanged:
                          isPast || isUpdating
                              ? null
                              : (val) => setState(() => selectedStatus = val),
                      title: Text(
                        statusOption,
                        style: TextStyle(color: isPast ? Colors.grey : null),
                      ),
                    );
                  }).toList(),
                  if (isUpdating) ...[
                    const SizedBox(height: 16),
                    const CircularProgressIndicator(),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isUpdating ? null : () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed:
                      isUpdating ||
                              selectedStatus == null ||
                              selectedStatus == currentStatus
                          ? null
                          : () async {
                            setState(() => isUpdating = true);
                            await controller.updateOrderStatus(
                              orderPath,
                              selectedStatus!,
                            );
                            setState(() => isUpdating = false);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Status updated to $selectedStatus",
                                  ),
                                ),
                              );
                            }
                          },
                  child:
                      isUpdating
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : const Text("Update"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showAssignRiderDialog(
    BuildContext context,
    String orderPath,
    AdminOrderController controller,
  ) async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'rider')
            .get();

    if (snapshot.docs.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No riders available")));
      return;
    }

    String? selectedRiderId;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Select Rider"),
              content: DropdownButtonFormField<String>(
                items:
                    snapshot.docs.map((doc) {
                      final data = doc.data();
                      return DropdownMenuItem(
                        value: doc.id,
                        child: Text("${data['name']}"),
                      );
                    }).toList(),
                onChanged: (val) {
                  setState(() {
                    selectedRiderId = val;
                  });
                },
                hint: const Text("Choose a rider"),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed:
                      selectedRiderId == null
                          ? null
                          : () async {
                            await controller.assignRider(
                              orderPath,
                              selectedRiderId!,
                            );
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Rider assigned")),
                            );
                          },
                  child: const Text("Assign"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
