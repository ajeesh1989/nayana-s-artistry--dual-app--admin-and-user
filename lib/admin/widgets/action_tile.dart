import 'package:flutter/material.dart';
import 'package:nayanasartistry/admin/manage%20product/all_product.dart';
import 'package:nayanasartistry/admin/manage%20product/product_options.dart';

class ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;

  const ActionTile({
    super.key,
    required this.icon,
    required this.title,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
        onTap:
            onTap ??
            () {
              if (title == "Manage Store") {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  builder: (_) => const ManageProductOptionsSheet(),
                );
              } else if (title == "All Products") {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AllProductsScreen()),
                );
              } else {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('$title tapped')));
              }
            },
      ),
    );
  }
}
