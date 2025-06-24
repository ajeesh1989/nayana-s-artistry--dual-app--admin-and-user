import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nayanasartistry/admin/manage%20product/edit_product.dart';

class AllProductsScreen extends StatefulWidget {
  const AllProductsScreen({super.key});

  @override
  State<AllProductsScreen> createState() => _AllProductsScreenState();
}

class _AllProductsScreenState extends State<AllProductsScreen> {
  String selectedCategory = 'All';
  List<String> categories = ['All'];

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('categories').get();
    final fetchedCategories =
        snapshot.docs.map((doc) => doc['title'] as String).toList();
    setState(() {
      categories.addAll(fetchedCategories);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("All Products")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<String>(
              value: selectedCategory,
              items:
                  categories
                      .map(
                        (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                      )
                      .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    selectedCategory = val;
                  });
                }
              },
              decoration: const InputDecoration(
                labelText: "Filter by Category",
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('products')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs =
                    snapshot.data!.docs.where((doc) {
                      if (selectedCategory == 'All') return true;
                      final data = doc.data() as Map<String, dynamic>;
                      return data['category'] == selectedCategory;
                    }).toList();

                if (docs.isEmpty) {
                  return const Center(child: Text("No products found"));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final id = docs[index].id;
                    final images = List<String>.from(data['imageUrls'] ?? []);

                    return ListTile(
                      leading:
                          images.isNotEmpty
                              ? SizedBox(
                                width: 100,
                                height: 50,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: images.length,
                                  itemBuilder: (context, imgIndex) {
                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => FullScreenImageViewer(
                                                  imageUrl: images[imgIndex],
                                                ),
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          right: 4,
                                        ),
                                        child: Image.network(
                                          images[imgIndex],
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              )
                              : const Icon(Icons.image),
                      title: Text(data['name']),
                      subtitle: Text(
                        "₹${data['price']} • ${data['category']}" +
                            (data['inStock'] == false ? " • Out of Stock" : ""),
                        style:
                            data['inStock'] == false
                                ? const TextStyle(color: Colors.red)
                                : null,
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) async {
                          if (value == 'edit') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) =>
                                        EditProductScreen(id: id, data: data),
                              ),
                            );
                          } else if (value == 'toggle_stock') {
                            await FirebaseFirestore.instance
                                .collection('products')
                                .doc(id)
                                .update({
                                  'inStock': !(data['inStock'] ?? true),
                                });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  (data['inStock'] ?? true)
                                      ? 'Marked as Out of Stock'
                                      : 'Marked as In Stock',
                                ),
                              ),
                            );
                          } else if (value == 'delete') {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: const Text("Delete Product"),
                                    content: const Text(
                                      "Are you sure you want to delete this product?",
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.of(
                                              context,
                                            ).pop(false),
                                        child: const Text("Cancel"),
                                      ),
                                      TextButton(
                                        onPressed:
                                            () =>
                                                Navigator.of(context).pop(true),
                                        child: const Text(
                                          "Delete",
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                            );

                            if (confirm == true) {
                              await FirebaseFirestore.instance
                                  .collection('products')
                                  .doc(id)
                                  .delete();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Product deleted"),
                                ),
                              );
                            }
                          }
                        },
                        itemBuilder:
                            (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: ListTile(
                                  leading: Icon(Icons.edit),
                                  title: Text("Edit"),
                                ),
                              ),
                              PopupMenuItem(
                                value: 'toggle_stock',
                                child: ListTile(
                                  leading: Icon(
                                    data['inStock'] == false
                                        ? Icons.check_circle
                                        : Icons.remove_shopping_cart,
                                    color:
                                        data['inStock'] == false
                                            ? Colors.green
                                            : Colors.red,
                                  ),
                                  title: Text(
                                    data['inStock'] == false
                                        ? "Mark In Stock"
                                        : "Mark Out of Stock",
                                  ),
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                  leading: Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  title: Text("Delete"),
                                ),
                              ),
                            ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Full screen image viewer
class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const FullScreenImageViewer({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(child: InteractiveViewer(child: Image.network(imageUrl))),
    );
  }
}
