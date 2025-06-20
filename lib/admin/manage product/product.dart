// 🧠 Add these imports if not already
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:nayanasartistry/admin/manage%20product/all_product.dart';
import 'package:path/path.dart' as path;

class ManageProductsScreen extends StatefulWidget {
  const ManageProductsScreen({super.key});

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();

  String? selectedCategory;
  List<Map<String, dynamic>> _categories = [];
  List<XFile> _pickedImages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('categories')
            .orderBy('createdAt', descending: true)
            .get();

    setState(() {
      _categories =
          snapshot.docs
              .map(
                (doc) => {
                  'id': doc.id,
                  'title': doc['title'],
                  'description': doc['description'],
                },
              )
              .toList();

      if (_categories.isNotEmpty && selectedCategory == null) {
        selectedCategory = _categories.first['title'];
      }
    });
  }

  Future<void> pickImages() async {
    final picked = await ImagePicker().pickMultiImage();
    if (picked != null && picked.isNotEmpty) {
      setState(() {
        _pickedImages = picked;
      });
    }
  }

  Future<List<String>> uploadImagesToStorage(List<XFile> files) async {
    List<String> downloadUrls = [];

    for (final file in files) {
      final fileName = path.basename(file.path);
      final storageRef = FirebaseStorage.instance.ref(
        'product_images/$fileName',
      );
      await storageRef.putFile(File(file.path));
      final url = await storageRef.getDownloadURL();
      downloadUrls.add(url);
    }

    return downloadUrls;
  }

  Future<void> addProduct() async {
    if (nameController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        priceController.text.isEmpty ||
        _pickedImages.isEmpty ||
        selectedCategory!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields and pick at least one image.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final imageUrls = await uploadImagesToStorage(_pickedImages);

      await FirebaseFirestore.instance.collection('products').add({
        'name': nameController.text.trim(),
        'description': descriptionController.text.trim(),
        'price': double.tryParse(priceController.text.trim()) ?? 0,
        'category': selectedCategory,
        'imageUrls': imageUrls,
        'createdAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added successfully!')),
      );

      nameController.clear();
      descriptionController.clear();
      priceController.clear();
      setState(() {
        _pickedImages = [];
        selectedCategory = ''; // Reset
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error saving product: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> deleteProduct(String id) async {
    await FirebaseFirestore.instance.collection('products').doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Products")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _categories.isEmpty
                  ? const CircularProgressIndicator()
                  : DropdownButtonFormField<String>(
                    value: selectedCategory,
                    items:
                        _categories
                            .map(
                              (cat) => DropdownMenuItem<String>(
                                value: cat['title'],
                                child: Text(cat['title']),
                              ),
                            )
                            .toList(),
                    onChanged: (val) => setState(() => selectedCategory = val),
                    decoration: const InputDecoration(labelText: "Category"),
                  ),
              const SizedBox(height: 10),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Product Name"),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: "Description"),
              ),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Price"),
              ),
              const SizedBox(height: 10),
              _pickedImages.isNotEmpty
                  ? SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _pickedImages.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Image.file(
                            File(_pickedImages[index].path),
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    ),
                  )
                  : const Text("No images selected"),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: pickImages,
                icon: const Icon(Icons.photo_library),
                label: const Text("Pick Product Images"),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child:
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                          onPressed: addProduct,
                          child: const Text("Add Product"),
                        ),
              ),
              const Divider(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.list),
                  label: const Text("View All Products"),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AllProductsScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
