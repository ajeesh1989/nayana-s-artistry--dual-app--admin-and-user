import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:nayanasartistry/auth/auth_gate.dart';
import 'package:nayanasartistry/rider/rider_controller.dart';
import 'package:nayanasartistry/rider/user_location.dart';
import 'package:nayanasartistry/theme/theme_controller.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RiderHomePage extends StatelessWidget {
  const RiderHomePage({super.key});

  void showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Logout"),
            content: const Text("Are you sure you want to logout?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final googleSignIn = GoogleSignIn();
                    if (await googleSignIn.isSignedIn()) {
                      await googleSignIn.disconnect();
                    }
                    await FirebaseAuth.instance.signOut();

                    Provider.of<RiderHomeProvider>(
                      context,
                      listen: false,
                    ).clearAll();

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const AuthGate()),
                      (route) => false,
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Logout failed: $e')),
                    );
                  }
                },
                child: const Text("Logout"),
              ),
            ],
          ),
    );
  }

  void showEditProfileDrawer(BuildContext context) {
    final provider = Provider.of<RiderHomeProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (_) => Padding(
            padding: const EdgeInsets.all(
              16,
            ).copyWith(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Edit Profile",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: provider.nameController,
                  decoration: const InputDecoration(labelText: "Name"),
                ),
                TextField(
                  controller: provider.phoneController,
                  decoration: const InputDecoration(labelText: "Phone"),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text("Save"),
                  onPressed: () {
                    if (provider.nameController.text.trim().isEmpty ||
                        provider.phoneController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Name and Phone are required"),
                        ),
                      );
                      return;
                    }
                    provider.updateRiderProfile(context);
                  },
                ),
              ],
            ),
          ),
    );
  }

  Future<void> markAsDelivered(
    DocumentReference orderRef,
    Map<String, dynamic> data,
  ) async {
    await orderRef.update({
      'status': 'Delivered',
      'deliveredAt': Timestamp.now(),
    });
    data['status'] = 'Delivered';
    data['deliveredAt'] = Timestamp.now();
  }

  Future<void> _makePhoneCall(String phoneNumber, BuildContext context) async {
    final Uri uri = Uri(scheme: 'tel', path: phoneNumber);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Dialer not available.")));
      }
    } catch (e) {
      debugPrint("❌ Phone call error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Phone call failed: $e")));
    }
  }

  Widget buildOrderList(
    List<QueryDocumentSnapshot> orders,
    bool isDeliveredTab,
    RiderHomeProvider provider,
  ) {
    if (orders.isEmpty) {
      return Center(
        child: Text(
          isDeliveredTab ? "No delivered items." : "No out for delivery items.",
        ),
      );
    }

    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final doc = orders[index];
        final data = doc.data() as Map<String, dynamic>;

        log("📝 Full order data: $data");

        final customer = data['customerName'] ?? 'Unknown';
        final address = data['deliveryAddress'] ?? '-';
        final phone = data['customerPhone'] ?? '-';
        final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
        final isDelivered = data['status'] == 'Delivered';
        final deliveredAt =
            data['deliveredAt'] != null
                ? (data['deliveredAt'] as Timestamp).toDate()
                : null;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: ExpansionTile(
            title: Text("📦 $customer"),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("📍 $address"),
                GestureDetector(
                  onTap: () => _makePhoneCall(phone, context),
                  child: Text(
                    "📞 $phone",
                    style: const TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                Text("💳 Payment: ${data['paymentMethod'] ?? 'Unknown'}"),
                if (isDelivered && deliveredAt != null)
                  Text(
                    "✅ Delivered on: ${DateFormat('dd MMM yyyy – hh:mm a').format(deliveredAt)}",
                  ),
              ],
            ),

            children: [
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
                    "Qty: ${item['quantity']} | ₹${item['price']}",
                  ),
                );
              }),
              if (!isDelivered) ...[
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.location_on),
                        label: const Text("User Location"),
                        onPressed: () {
                          final name = data['customerName'] ?? 'User';
                          final location = data['deliveryLocation'];

                          log(
                            "🚚 deliveryLocation raw: $location (${location.runtimeType})",
                          );

                          double? lat;
                          double? lng;

                          if (location is GeoPoint) {
                            lat = location.latitude;
                            lng = location.longitude;
                          } else if (location is Map &&
                              location.containsKey('lat') &&
                              location.containsKey('lng')) {
                            lat = (location['lat'] as num?)?.toDouble();
                            lng = (location['lng'] as num?)?.toDouble();
                          }

                          log("✅ Extracted lat: $lat, lng: $lng");

                          if (lat != null && lng != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => UserLocationPage(
                                      customerName: name,
                                      destinationLat: lat!,
                                      destinationLng: lng!,
                                    ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("No delivery location available"),
                              ),
                            );
                          }
                        },
                      ),
                      Checkbox(
                        value: false,
                        onChanged: (_) async {
                          await markAsDelivered(doc.reference, data);
                          await provider.loadInitialData();
                        },
                      ),
                      const Text("Mark as Delivered"),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final riderProvider = Provider.of<RiderHomeProvider>(context);

    if (riderProvider.isLoading &&
        riderProvider.assignedOrders.isEmpty &&
        riderProvider.deliveredOrders.isEmpty) {
      Future.microtask(() => riderProvider.loadInitialData());
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Rider Dashboard"),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: "Logout",
              onPressed: () => showLogoutDialog(context),
            ),
          ],
          bottom: const TabBar(
            tabs: [Tab(text: "Out for Delivery"), Tab(text: "Delivered")],
          ),
        ),
        drawer: Drawer(
          child: ListView(
            children: [
              DrawerHeader(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(radius: 30, child: Icon(Icons.person)),
                    const SizedBox(height: 10),
                    Text(
                      riderProvider.riderName.isEmpty
                          ? "Rider"
                          : riderProvider.riderName,
                      style: const TextStyle(fontSize: 18),
                    ),
                    Text(riderProvider.riderEmail),
                    Text(
                      riderProvider.riderPhone.isEmpty
                          ? "Phone: -"
                          : "Phone: ${riderProvider.riderPhone}",
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text("Edit Profile"),
                onTap: () => showEditProfileDrawer(context),
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text("Dark Mode"),
                trailing: Switch(
                  value: themeProvider.isDarkMode,
                  onChanged: (val) => themeProvider.toggleTheme(val),
                ),
              ),
            ],
          ),
        ),
        body:
            riderProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                  children: [
                    buildOrderList(
                      riderProvider.assignedOrders,
                      false,
                      riderProvider,
                    ),
                    buildOrderList(
                      riderProvider.deliveredOrders,
                      true,
                      riderProvider,
                    ),
                  ],
                ),
      ),
    );
  }
}
