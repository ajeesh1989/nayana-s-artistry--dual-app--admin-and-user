import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nayanasartistry/admin/notification/notification_sender_page.dart';
import 'package:nayanasartistry/admin/widgets/admin_user_list.dart';
import 'package:nayanasartistry/admin/widgets/delete_all_order.dart';
import 'package:nayanasartistry/user/shimmer.dart';
import 'package:provider/provider.dart';

import 'package:nayanasartistry/admin/controller/admin_controller.dart';
import 'package:nayanasartistry/admin/order_list/admin_order_list.dart';
import 'package:nayanasartistry/admin/widgets/action_tile.dart';
import 'package:nayanasartistry/admin/widgets/dashboard_tile.dart';
import 'package:nayanasartistry/auth/auth_gate.dart';
import 'package:nayanasartistry/theme/theme_controller.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminController>(
        context,
        listen: false,
      ).fetchDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? "Admin";
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        leading: Align(
          alignment: Alignment.centerLeft,
          child: Transform.translate(
            offset: const Offset(20, 0),
            child: CircleAvatar(
              radius: 35,
              backgroundImage: NetworkImage(
                user?.photoURL ??
                    'https://ui-avatars.com/api/?name=${Uri.encodeComponent(displayName)}',
              ),
              backgroundColor: Colors.transparent,
            ),
          ),
        ),
        title: const Text("Admin Dashboard"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: Consumer<AdminController>(
        builder: (context, adminController, _) {
          if (adminController.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Welcome, $displayName 👋',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: DashboardTile(
                      title: "Users",
                      count: "${adminController.userCount}",
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DashboardTile(
                      title: "Orders",
                      count: "${adminController.orderCount}",
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DashboardTile(
                      title: "Revenue",
                      count: "₹${adminController.revenue.toStringAsFixed(0)}",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ActionTile(
                icon: Icons.shopping_cart_outlined,
                title: "View Orders",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AdminOrderListPage()),
                  );
                },
              ),
              const ActionTile(
                icon: Icons.store_outlined,
                title: "Manage Store",
              ),
              const ActionTile(icon: Icons.category, title: "All Products"),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ActionTile(
                    icon: Icons.people_outline,
                    title: "Chat with Users",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminUserListPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  StreamBuilder(
                    stream:
                        FirebaseFirestore.instance
                            .collectionGroup('messages')
                            .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Text(
                          'Loading active users...',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                        );
                      }

                      final messages = snapshot.data?.docs ?? [];
                      final activeUsers = <String>{};

                      for (var msg in messages) {
                        final chatId = msg.reference.parent.parent?.id;
                        if (chatId != null &&
                            chatId.startsWith('user_') &&
                            chatId.contains('_admin')) {
                          final userId = chatId
                              .replaceFirst('user_', '')
                              .replaceFirst('_admin', '');
                          activeUsers.add(userId);
                        }
                      }

                      final countText =
                          activeUsers.isEmpty
                              ? 'No active users'
                              : '${activeUsers.length} active users';

                      return Text(
                        countText,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      );
                    },
                  ),
                ],
              ),
              ActionTile(
                icon: Icons.settings_outlined,
                title: "Dark Mode",
                trailing: Switch(
                  value: isDarkMode,
                  onChanged: (val) => themeProvider.toggleTheme(val),
                ),
              ),
              ActionTile(
                icon: Icons.emergency,
                title: "Caution",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EmergencyDeleteOrdersPage(),
                    ),
                  );
                },
              ),
              ActionTile(
                icon: Icons.notifications,
                title: "Notification to users",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationSenderPage(),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Logout"),
            content: const Text("Are you sure you want to log out?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Logout"),
              ),
            ],
          ),
    );

    if (confirm == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: ProductShimmer()),
      );

      try {
        final googleSignIn = GoogleSignIn();
        if (await googleSignIn.isSignedIn()) {
          await googleSignIn.disconnect();
          await googleSignIn.signOut();
        }
        await FirebaseAuth.instance.signOut();
      } catch (e) {
        debugPrint('Logout error: $e');
      }

      if (mounted) {
        Navigator.pop(context);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (route) => false,
        );
      }
    }
  }
}
