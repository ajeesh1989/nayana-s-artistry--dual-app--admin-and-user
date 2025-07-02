import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nayanasartistry/user/account/select_address.dart';
import 'package:nayanasartistry/user/buy_now/buy_now.dart';
import 'package:nayanasartistry/user/cart/cart.dart';
import 'package:nayanasartistry/user/cart/cart_controller.dart';
import 'package:nayanasartistry/user/productview/image_preview_screen.dart';
import 'package:nayanasartistry/user/productview/product_controller.dart';
import 'package:nayanasartistry/user/account/address_controller.dart';
import 'package:nayanasartistry/user/account/address_model.dart';
import 'package:nayanasartistry/user/wishlist/wish_list_controller.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class ProductViewScreen extends StatelessWidget {
  final Map<String, dynamic> productData;

  const ProductViewScreen({super.key, required this.productData});

  double calculateAverageRating(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) return 0.0;
    final total = docs
        .map((doc) => (doc['rating'] ?? 0).toDouble())
        .reduce((a, b) => a + b);
    return total / docs.length;
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final addressProvider = Provider.of<AddressProvider>(context);
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final name = productData['name'] ?? '';
    final price = productData['price'] ?? 0;
    final images = List<String>.from(productData['imageUrls'] ?? []);
    final category = productData['category'] ?? '';
    final description = productData['description'] ?? 'No description provided';

    final addresses = addressProvider.addresses;
    final selectedAddress = addresses.firstWhere(
      (a) => a.isDefault,
      orElse:
          () =>
              addresses.isNotEmpty
                  ? addresses.first
                  : AddressModel(
                    id: '',
                    fullName: '',
                    phone: '',
                    address: '',
                    userId: '',
                  ),
    );

    final isInWishlist = wishlistProvider.isInWishlist(productData['id']);

    return ChangeNotifierProvider(
      create: (_) => ProductController(),
      child: Consumer<ProductController>(
        builder: (context, controller, _) {
          return Scaffold(
            appBar: AppBar(
              title: Text(name, style: const TextStyle(fontSize: 18)),
              centerTitle: true,
            ),
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (images.isNotEmpty)
                    Stack(
                      children: [
                        CarouselSlider.builder(
                          itemCount: images.length,
                          options: CarouselOptions(
                            height: 400,
                            viewportFraction: 1,
                            enableInfiniteScroll: false,
                          ),
                          itemBuilder: (context, index, _) {
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
                        Positioned(
                          right: 12,
                          top: 12,
                          child: InkWell(
                            onTap: () {
                              wishlistProvider.toggleWishlistItem(
                                productData,
                                context,
                              );
                            },
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.black.withOpacity(0.4),
                              child: Icon(
                                isInWishlist
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isInWishlist ? Colors.red : Colors.white,
                              ),
                            ),
                          ),
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
                        const SizedBox(height: 2),
                        Text(description),
                        const SizedBox(height: 8),
                        Text(
                          "₹$price",
                          style: textTheme.headlineSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FutureBuilder<QuerySnapshot>(
                          future:
                              FirebaseFirestore.instance
                                  .collection('order_feedback')
                                  .where(
                                    'productId',
                                    isEqualTo: productData['id'],
                                  )
                                  .get(),
                          builder: (context, snapshot) {
                            double avgRating = 0.0;
                            int reviewCount = 0;

                            if (snapshot.hasData &&
                                snapshot.data!.docs.isNotEmpty) {
                              reviewCount = snapshot.data!.docs.length;
                              avgRating = calculateAverageRating(
                                snapshot.data!.docs,
                              );
                            }

                            return Row(
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
                                    Text(
                                      "${avgRating.toStringAsFixed(1)}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (reviewCount > 0)
                                      Text(
                                        " ($reviewCount reviews)",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),

                        const Divider(height: 30),
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
                        const Divider(height: 30),
                        Text(
                          "User Reviews",
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FutureBuilder<QuerySnapshot>(
                          future:
                              FirebaseFirestore.instance
                                  .collection('order_feedback')
                                  .where(
                                    'productId',
                                    isEqualTo: productData['id'],
                                  )
                                  .orderBy('timestamp', descending: true)
                                  .get(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (snapshot.hasError) {
                              return Text("Error: ${snapshot.error}");
                            }

                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return const Text("No reviews yet.");
                            }

                            final reviews = snapshot.data!.docs;

                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: reviews.length,
                              separatorBuilder:
                                  (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final review = reviews[index];
                                final feedback = review['feedback'] ?? '';
                                final rating =
                                    review['rating']?.toDouble() ?? 0.0;
                                final timestamp =
                                    review['timestamp'] != null
                                        ? (review['timestamp'] as Timestamp)
                                            .toDate()
                                        : null;
                                final customerName =
                                    review['customerName'] ?? 'User';

                                return ListTile(
                                  leading: CircleAvatar(
                                    child: Text(
                                      customerName.isNotEmpty
                                          ? customerName[0].toUpperCase()
                                          : "?",
                                    ),
                                  ),
                                  title: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        customerName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          ...List.generate(5, (i) {
                                            return Icon(
                                              i < rating
                                                  ? Icons.star
                                                  : Icons.star_border,
                                              size: 16,
                                              color: Colors.amber,
                                            );
                                          }),
                                          const SizedBox(width: 6),
                                          if (timestamp != null)
                                            Text(
                                              DateFormat(
                                                'dd/MM/yyyy',
                                              ).format(timestamp),
                                              style:
                                                  Theme.of(
                                                    context,
                                                  ).textTheme.bodySmall,
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  subtitle: Text(feedback),
                                );
                              },
                            );
                          },
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
                                  customerEmail:
                                      FirebaseAuth
                                          .instance
                                          .currentUser
                                          ?.email ??
                                      'unknown@example.com',
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
