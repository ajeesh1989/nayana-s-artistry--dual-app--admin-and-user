import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:nayanasartistry/user/account/select_address.dart';
import 'package:nayanasartistry/user/buy_now/buy_now.dart';
import 'package:nayanasartistry/user/cart/cart.dart';
import 'package:nayanasartistry/user/cart/cart_controller.dart';
import 'package:nayanasartistry/user/productview/image_preview_screen.dart';
import 'package:nayanasartistry/user/productview/product_controller.dart';
import 'package:nayanasartistry/user/account/address_controller.dart';
import 'package:nayanasartistry/user/account/address_model.dart';
import 'package:provider/provider.dart';

class ProductViewScreen extends StatelessWidget {
  final Map<String, dynamic> productData;

  const ProductViewScreen({super.key, required this.productData});

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final addressProvider = Provider.of<AddressProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final name = productData['name'] ?? '';
    final price = productData['price'] ?? 0;
    final images = List<String>.from(productData['imageUrls'] ?? []);
    final category = productData['category'] ?? '';
    final description = productData['description'] ?? 'No description provided';
    final rating = productData['rating'] ?? 4.2;

    final addresses = addressProvider.addresses;
    final selectedAddress = addresses.firstWhere(
      (a) => a.isDefault,
      orElse:
          () =>
              addresses.isNotEmpty
                  ? addresses.first
                  : AddressModel(id: '', fullName: '', phone: '', address: ''),
    );

    return ChangeNotifierProvider(
      create: (_) => ProductController(),
      child: Consumer<ProductController>(
        builder: (context, controller, _) {
          return Scaffold(
            appBar: AppBar(
              title: Text("$name", style: TextStyle(fontSize: 18)),
              centerTitle: true,
            ),
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (images.isNotEmpty)
                    Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        CarouselSlider.builder(
                          itemCount: images.length,
                          options: CarouselOptions(
                            height: 400,
                            viewportFraction: 1,
                            enableInfiniteScroll: false,
                            onPageChanged: (index, reason) {
                              controller
                                  .notifyListeners(); // just to rebuild dots
                            },
                          ),
                          itemBuilder: (context, index, realIndex) {
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => ImagePreviewScreen(
                                          images: images,
                                          initialIndex: index,
                                        ),
                                  ),
                                );
                              },
                              child: Image.network(
                                images[index],
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            );
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children:
                              images.asMap().entries.map((entry) {
                                return Container(
                                  width: 8.0,
                                  height: 8.0,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4.0,
                                    vertical: 8.0,
                                  ),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                );
                              }).toList(),
                        ),
                      ],
                    ),

                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Description",
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(description), const SizedBox(height: 8),

                        Text(
                          "₹$price",
                          style: textTheme.headlineSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Chip(label: Text(category)),
                            const SizedBox(width: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.orange,
                                  size: 20,
                                ),
                                Text("$rating"),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 30),

                        /// ✅ Address Section
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on_outlined),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${selectedAddress.fullName} • ${selectedAddress.phone}",
                                    style: textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    selectedAddress.address.isEmpty
                                        ? "No address selected"
                                        : selectedAddress.address,
                                    style: textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SelectAddressPage(),
                                  ),
                                );
                              },
                              child: const Text("Change"),
                            ),
                          ],
                        ),

                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await cartProvider.addToCart(productData);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Added to cart')),
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => CartPage()),
                        );
                      },
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text("Add to Cart"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => BuyNowPage(
                                  amount: price.toDouble(),
                                  customerName: selectedAddress.fullName,
                                  customerPhone: selectedAddress.phone,
                                  customerEmail: 'test@example.com',
                                  address: selectedAddress,
                                  productData: productData,
                                ),
                          ),
                        );
                      },
                      child: Text(
                        "Buy Now",
                        style: TextStyle(color: colorScheme.onPrimary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
