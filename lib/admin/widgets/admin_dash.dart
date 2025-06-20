import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nayanasartistry/admin/widgets/action_tile.dart';
import 'package:nayanasartistry/admin/widgets/dashboard_tile.dart';
import 'package:nayanasartistry/auth/auth_gate.dart';
import 'package:provider/provider.dart';
import 'package:nayanasartistry/theme/theme_controller.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

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
            onPressed: () async {
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
                  builder:
                      (_) => const Center(child: CircularProgressIndicator()),
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

                if (context.mounted) {
                  Navigator.pop(context);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthGate()),
                    (route) => false,
                  );
                }
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Welcome, $displayName 👋',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            children: const [
              Expanded(child: DashboardTile(title: "Users", count: "120")),
              SizedBox(width: 8),
              Expanded(child: DashboardTile(title: "Orders", count: "58")),
              SizedBox(width: 8),
              Expanded(child: DashboardTile(title: "Revenue", count: "₹12K")),
            ],
          ),
          const SizedBox(height: 30),
          const ActionTile(
            icon: Icons.shopping_cart_outlined,
            title: "View Orders",
          ),
          const ActionTile(icon: Icons.store_outlined, title: "Manage Store"),
          const ActionTile(icon: Icons.category, title: "All Products"),
          const ActionTile(icon: Icons.people_outline, title: "Manage Users"),
          // 🌓 Dark Mode Toggle in Settings
          ActionTile(
            icon: Icons.settings_outlined,
            title: "Dark Mode",
            trailing: Switch(
              value: isDarkMode,
              onChanged: (val) {
                themeProvider.toggleTheme(val); // ✅ correctly pass bool
              },
            ),
            onTap: null, // Disable tap since we're using the switch
          ),
        ],
      ),
    );
  }
}
