import 'package:flutter/material.dart';
import 'package:nayanasartistry/admin/manage%20category/category.dart';
import 'package:nayanasartistry/admin/manage%20product/product.dart';

class ManageProductOptionsSheet extends StatelessWidget {
  const ManageProductOptionsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        ListTile(
          leading: const Icon(Icons.category_outlined),
          title: const Text("Manage Categories"),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ManageCategoriesScreen()),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.inventory_2_outlined),
          title: const Text("Manage Products"),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ManageProductsScreen()),
            );
          },
        ),
      ],
    );
  }
}
