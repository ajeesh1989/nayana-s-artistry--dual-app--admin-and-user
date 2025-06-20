import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class EditProductScreen extends StatefulWidget {
  final String id;
  final Map<String, dynamic> data;

  const EditProductScreen({super.key, required this.id, required this.data});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  late TextEditingController nameController;
  late TextEditingController descriptionController;
  late TextEditingController priceController;
  String? selectedCategory;
  List<String> existingImageUrls = [];
  List<XFile> newPickedImages = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.data['name']);
    descriptionController = TextEditingController(
      text: widget.data['description'],
    );
    priceController = TextEditingController(
      text: widget.data['price'].toString(),
    );
    selectedCategory = widget.data['category'];
    existingImageUrls = List<String>.from(widget.data['imageUrls'] ?? []);
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('categories').get();
    setState(() {
      _categories =
          snapshot.docs
              .map((doc) => {'id': doc.id, 'title': doc['title']})
              .toList();
    });
  }

  Future<void> pickNewImages() async {
    final picked = await ImagePicker().pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        newPickedImages = picked;
      });
    }
  }

  Future<List<String>> uploadImages(List<XFile> files) async {
    List<String> urls = [];
    for (var file in files) {
      final fileName = path.basename(file.path);
      final ref = FirebaseStorage.instance.ref('product_images/$fileName');
      await ref.putFile(File(file.path));
      final url = await ref.getDownloadURL();
      urls.add(url);
    }
    return urls;
  }

  Future<void> updateProduct() async {
    if (nameController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        priceController.text.isEmpty ||
        selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("All fields are required")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      List<String> imageUrls = List.from(existingImageUrls);

      if (newPickedImages.isNotEmpty) {
        final uploaded = await uploadImages(newPickedImages);
        imageUrls.addAll(uploaded); // append new images
      }

      await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.id)
          .update({
            'name': nameController.text.trim(),
            'description': descriptionController.text.trim(),
            'price': double.tryParse(priceController.text.trim()) ?? 0,
            'category': selectedCategory,
            'imageUrls': imageUrls,
            'updatedAt': Timestamp.now(),
          });

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("✅ Product updated")));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Product")),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      items:
                          _categories
                              .map(
                                (cat) => DropdownMenuItem<String>(
                                  value:
                                      cat['title'] as String, // <-- force cast
                                  child: Text(cat['title']),
                                ),
                              )
                              .toList(),

                      onChanged:
                          (val) => setState(() => selectedCategory = val),
                      decoration: const InputDecoration(labelText: "Category"),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: "Name"),
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: "Description",
                      ),
                    ),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Price"),
                    ),
                    const SizedBox(height: 10),
                    if (existingImageUrls.isNotEmpty)
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: existingImageUrls.length,
                          itemBuilder: (context, index) {
                            final url = existingImageUrls[index];
                            return Stack(
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: NetworkImage(url),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        existingImageUrls.removeAt(index);
                                      });
                                    },
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: pickNewImages,
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text("Pick Additional Images"),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: updateProduct,
                        child: const Text("Update Product"),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
