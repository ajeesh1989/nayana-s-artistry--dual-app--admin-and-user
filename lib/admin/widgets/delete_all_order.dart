import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyDeleteOrdersPage extends StatelessWidget {
  const EmergencyDeleteOrdersPage({super.key});

  Future<void> deleteAllOrdersEverywhere() async {
    final firestore = FirebaseFirestore.instance;

    // Delete subcollection orders (user-side)
    final subOrders = await firestore.collectionGroup('orders').get();
    for (final doc in subOrders.docs) {
      await doc.reference.delete();
    }

    // Delete top-level orders (admin-side)
    final topOrders = await firestore.collection('orders').get();
    for (final doc in topOrders.docs) {
      await doc.reference.delete();
    }

    print("🔥 All orders deleted from everywhere.");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.red.shade900,
        title: const Text(
          "☢️ EMERGENCY ZONE",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Colors.red.shade900],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.yellowAccent,
                  size: 100,
                ),
                const SizedBox(height: 20),
                const Text(
                  "⚠️ DANGER ZONE ⚠️",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "You're about to delete ALL ORDERS\nThis action is irreversible.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder:
                          (_) => AlertDialog(
                            backgroundColor: Colors.grey.shade900,
                            title: const Text(
                              "ARE YOU SURE?",
                              style: TextStyle(color: Colors.redAccent),
                            ),
                            content: const Text(
                              "💀 This will permanently delete all orders from the database.\n\nDo you wish to proceed?",
                              style: TextStyle(color: Colors.white),
                            ),
                            actions: [
                              TextButton(
                                onPressed:
                                    () => Navigator.of(context).pop(false),
                                child: const Text(
                                  "Cancel",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed:
                                    () => Navigator.of(context).pop(true),
                                child: const Text("DELETE EVERYTHING"),
                              ),
                            ],
                          ),
                    );

                    if (confirm == true) {
                      await deleteAllOrdersEverywhere();

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "🔥 All orders deleted successfully.",
                            ),
                            backgroundColor: Colors.redAccent,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.delete_forever, size: 28),
                  label: const Text("🔥 DELETE ALL ORDERS"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 18,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                    shadowColor: Colors.redAccent,
                    elevation: 8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
