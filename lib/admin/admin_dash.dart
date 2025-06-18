import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../auth/auth_gate.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? "Admin";

    return Scaffold(
      appBar: AppBar(
        leading: Align(
          alignment: Alignment.centerLeft,
          child: Transform.translate(
            offset: const Offset(20, 0), // move it slightly right
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
                  Navigator.pop(context); // Close loading dialog
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

          // Summary Cards
          Row(
            children: const [
              Expanded(child: _DashboardTile(title: "Users", count: "120")),
              SizedBox(width: 8),
              Expanded(child: _DashboardTile(title: "Orders", count: "58")),
              SizedBox(width: 8),
              Expanded(child: _DashboardTile(title: "Revenue", count: "₹12K")),
            ],
          ),
          const SizedBox(height: 30),

          // Action Tiles
          const _ActionTile(
            icon: Icons.shopping_cart_outlined,
            title: "View Orders",
          ),
          const _ActionTile(
            icon: Icons.store_outlined,
            title: "Manage Products",
          ),
          const _ActionTile(icon: Icons.people_outline, title: "Manage Users"),
          const _ActionTile(icon: Icons.settings_outlined, title: "Settings"),
        ],
      ),
    );
  }
}

class _DashboardTile extends StatelessWidget {
  final String title;
  final String count;

  const _DashboardTile({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;

  const _ActionTile({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$title tapped')));
        },
      ),
    );
  }
}
