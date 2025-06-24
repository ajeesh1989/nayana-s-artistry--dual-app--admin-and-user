import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nayanasartistry/user/cart/cart_controller.dart';
import 'package:nayanasartistry/user/home/controller/home_controller.dart';
import 'package:nayanasartistry/user/productview/product_view.dart';
import 'package:nayanasartistry/user/shimmer.dart';
import 'package:nayanasartistry/user/wishlist/wish_list_controller.dart';
import 'package:provider/provider.dart';
import 'package:nayanasartistry/user/cart/cart.dart';
import 'package:nayanasartistry/user/pages/chat/chat.dart';
import 'package:nayanasartistry/user/wishlist/wishlist.dart';
import 'package:nayanasartistry/user/bottomnavitems/profile/profile.dart';
import 'package:nayanasartistry/user/account/account.dart';
import 'package:nayanasartistry/theme/theme_controller.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<HomeProvider>(context, listen: false);
      await provider.fetchCategories();
      if (mounted) {
        setState(() {
          _tabController = TabController(
            length: provider.categories.length,
            vsync: this,
          );
          _tabController!.addListener(() {
            setState(() {});
          });
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final provider = Provider.of<HomeProvider>(context);
    final categories = provider.categories;
    final selectedIndex = provider.selectedIndex;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final logoPath =
        isDark
            ? 'assets/images/logo_white.png'
            : 'assets/images/logo_black.png';

    return Scaffold(
      appBar:
          selectedIndex == 0
              ? AppBar(
                title: Image.asset(logoPath, height: 80, fit: BoxFit.contain),
                centerTitle: true,
                actions: [
                  Consumer<CartProvider>(
                    builder: (context, cartProvider, _) {
                      final cartCount = cartProvider.cartItems.length;
                      return Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.shopping_cart_outlined),
                            onPressed: () {
                              Provider.of<HomeProvider>(
                                context,
                                listen: false,
                              ).setSelectedIndex(2);
                            },
                          ),
                          if (cartCount > 0)
                            Positioned(
                              right: 6,
                              top: 6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade300,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 20,
                                  minHeight: 20,
                                ),
                                child: Text(
                                  '$cartCount',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
                bottom:
                    categories.length > 1 && _tabController != null
                        ? TabBar(
                          controller: _tabController,
                          isScrollable: true,
                          indicatorColor: colorScheme.primary,
                          labelColor: colorScheme.primary,
                          unselectedLabelColor:
                              Theme.of(context).unselectedWidgetColor,
                          tabs: categories.map((c) => Tab(text: c)).toList(),
                        )
                        : null,
              )
              : null,
      drawer:
          selectedIndex == 0
              ? Drawer(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    UserAccountsDrawerHeader(
                      accountName: Text(user?.displayName ?? 'Guest User'),
                      accountEmail: Text(user?.email ?? 'No email'),
                      currentAccountPicture: CircleAvatar(
                        backgroundImage:
                            user?.photoURL != null
                                ? NetworkImage(user!.photoURL!)
                                : null,
                        child:
                            user?.photoURL == null
                                ? const Icon(Icons.person)
                                : null,
                      ),
                      decoration: BoxDecoration(color: colorScheme.primary),
                    ),
                    SwitchListTile(
                      title: const Text("Dark Mode"),
                      secondary: const Icon(Icons.brightness_6),
                      value: themeProvider.isDarkMode,
                      onChanged: themeProvider.toggleTheme,
                    ),
                    ListTile(
                      leading: const Icon(Icons.home),
                      title: const Text('Home'),
                      onTap: () => Navigator.pop(context),
                    ),
                    ListTile(
                      leading: const Icon(Icons.person),
                      title: const Text('Account'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AccountPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              )
              : null,
      body:
          selectedIndex == 0
              ? (categories.length <= 1 || _tabController == null)
                  ? const Center(child: ProductShimmer())
                  : TabBarView(
                    controller: _tabController,
                    children:
                        categories.map((category) {
                          return StreamBuilder<QuerySnapshot>(
                            stream: provider.fetchProducts(category),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const ProductShimmer();
                              }

                              final products = snapshot.data!.docs;

                              if (products.isEmpty) {
                                return const Center(
                                  child: Text("No products found"),
                                );
                              }

                              return SingleChildScrollView(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Column(
                                  children: [
                                    const SizedBox(height: 10),
                                    CarouselSlider(
                                      options: CarouselOptions(
                                        height: 180.0,
                                        autoPlay: true,
                                        enlargeCenterPage: true,
                                        viewportFraction: 0.9,
                                      ),
                                      items:
                                          [
                                            'https://picsum.photos/id/1005/400/200',
                                            'https://picsum.photos/id/1021/400/200',
                                            'https://picsum.photos/id/1045/400/200',
                                          ].map((imageUrl) {
                                            return ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Image.network(
                                                imageUrl,
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                              ),
                                            );
                                          }).toList(),
                                    ),
                                    const SizedBox(height: 10),
                                    GridView.builder(
                                      padding: const EdgeInsets.all(12),
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            childAspectRatio: 0.7,
                                            crossAxisSpacing: 12,
                                            mainAxisSpacing: 12,
                                          ),
                                      itemCount: products.length,
                                      itemBuilder: (context, index) {
                                        final rawData =
                                            products[index].data()
                                                as Map<String, dynamic>;
                                        final productId = products[index].id;
                                        rawData['id'] = productId;

                                        final data = rawData;
                                        final images = List<String>.from(
                                          data['imageUrls'] ?? [],
                                        );
                                        final name = data['name'] ?? '';
                                        final price = data['price'] ?? 0;
                                        final category = data['category'] ?? '';
                                        final isInStock =
                                            data['inStock'] ?? true;

                                        final isInWishlist =
                                            Provider.of<WishlistProvider>(
                                              context,
                                            ).isInWishlist(productId);

                                        return GestureDetector(
                                          onTap: () {
                                            if (isInStock) {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (context) =>
                                                          ProductViewScreen(
                                                            productData: data,
                                                          ),
                                                ),
                                              );
                                            } else {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    "This item is currently unavailable.",
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                          child: Card(
                                            elevation: 2,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Stack(
                                              children: [
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    AspectRatio(
                                                      aspectRatio: 1.2,
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            const BorderRadius.vertical(
                                                              top:
                                                                  Radius.circular(
                                                                    12,
                                                                  ),
                                                            ),
                                                        child: Stack(
                                                          children: [
                                                            images.isNotEmpty
                                                                ? Image.network(
                                                                  images[0],
                                                                  fit:
                                                                      BoxFit
                                                                          .cover,
                                                                  width:
                                                                      double
                                                                          .infinity,
                                                                  height:
                                                                      double
                                                                          .infinity,
                                                                )
                                                                : Container(
                                                                  color:
                                                                      Colors
                                                                          .grey[300],
                                                                  child: const Center(
                                                                    child: Icon(
                                                                      Icons
                                                                          .image,
                                                                      size: 40,
                                                                      color:
                                                                          Colors
                                                                              .grey,
                                                                    ),
                                                                  ),
                                                                ),
                                                            if (!isInStock)
                                                              Container(
                                                                color: Colors
                                                                    .black
                                                                    .withOpacity(
                                                                      0.4,
                                                                    ),
                                                                alignment:
                                                                    Alignment
                                                                        .center,
                                                                child: const Text(
                                                                  'Out of Stock',
                                                                  style: TextStyle(
                                                                    color:
                                                                        Colors
                                                                            .white,
                                                                    fontSize:
                                                                        16,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                              ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            8.0,
                                                          ),
                                                      child: Text(
                                                        name,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodyLarge
                                                            ?.copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                        maxLines: 2,
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                          ),
                                                      child: Text(
                                                        "₹$price",
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodyMedium
                                                            ?.copyWith(
                                                              color:
                                                                  Theme.of(
                                                                        context,
                                                                      )
                                                                      .colorScheme
                                                                      .primary,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                      child: Text(
                                                        category,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodySmall
                                                            ?.copyWith(
                                                              color:
                                                                  Colors
                                                                      .grey[600],
                                                            ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                // Wishlist button — only if in stock
                                                if (isInStock)
                                                  Positioned(
                                                    right: 8,
                                                    top: 8,
                                                    child: InkWell(
                                                      onTap: () {
                                                        Provider.of<
                                                          WishlistProvider
                                                        >(
                                                          context,
                                                          listen: false,
                                                        ).toggleWishlistItem(
                                                          data,
                                                          context,
                                                        );
                                                      },
                                                      child: CircleAvatar(
                                                        radius: 16,
                                                        backgroundColor:
                                                            Colors.white,
                                                        child: Icon(
                                                          isInWishlist
                                                              ? Icons.favorite
                                                              : Icons
                                                                  .favorite_border,
                                                          size: 18,
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        }).toList(),
                  )
              : selectedIndex == 1
              ? const WishlistPage()
              : selectedIndex == 2
              ? const CartPage()
              : selectedIndex == 3
              ? const ChatPage()
              : selectedIndex == 4
              ? const ProfilePage()
              : const Center(child: Text("Unknown tab")),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) => provider.setSelectedIndex(index),
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurface.withOpacity(0.6),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: 'Wishlist',
          ),
          BottomNavigationBarItem(
            icon: Consumer<CartProvider>(
              builder: (context, cartProvider, _) {
                final cartCount = cartProvider.cartItems.length;
                return Stack(
                  children: [
                    const Icon(Icons.shopping_cart_outlined),
                    if (cartCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade300,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$cartCount',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            label: 'Cart',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chat',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
