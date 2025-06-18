import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nayanasartistry/auth/auth_gate.dart';
import 'package:nayanasartistry/bottomnavitems/profile/profile.dart';
import 'package:nayanasartistry/pages/account/account.dart';
import 'package:nayanasartistry/pages/cart/cart.dart';
import 'package:nayanasartistry/pages/chat/chat.dart';
import 'package:nayanasartistry/pages/wishlist/wishlist.dart';
import 'package:nayanasartistry/theme/theme_controller.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late TabController _tabController;

  final List<String> categories = [
    'All',
    'Mural',
    'Gifts',
    'Illustration',
    'Pencil',
    'Watercolor',
  ];

  final Map<String, List<String>> recommendations = {
    'All': List.generate(2, (index) => "🖌️ Rec All #$index"),
    'Mural': List.generate(2, (index) => "🖌️ Mural Rec #$index"),
    'Gifts': List.generate(2, (index) => "🖌️ Gifts Rec #$index"),
    'Illustration': List.generate(2, (index) => "🖌️ Illustration Rec #$index"),
    'Pencil': List.generate(2, (index) => "🖌️ Pencil Rec #$index"),
    'Watercolor': List.generate(2, (index) => "🖌️ Watercolor Rec #$index"),
  };

  final List<String> carouselImages = [
    'https://picsum.photos/id/1005/400/200',
    'https://picsum.photos/id/1021/400/200',
    'https://picsum.photos/id/1045/400/200',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: categories.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final logoPath =
        isDark
            ? 'assets/images/logo_white.png'
            : 'assets/images/logo_black.png';

    final currentCategory = categories[_tabController.index];

    return Scaffold(
      appBar:
          _selectedIndex == 0
              ? AppBar(
                title: Image.asset(logoPath, height: 80, fit: BoxFit.contain),
                centerTitle: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.search),
                    tooltip: 'Search',
                    onPressed: () {},
                  ),
                ],

                bottom: TabBar(
                  dividerColor: Colors.transparent,
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: colorScheme.primary,
                  labelColor: colorScheme.primary,
                  unselectedLabelColor: Theme.of(context).unselectedWidgetColor,
                  tabs:
                      categories
                          .map((category) => Tab(text: category))
                          .toList(),
                ),
              )
              : null,

      drawer:
          _selectedIndex == 0
              ? Drawer(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    UserAccountsDrawerHeader(
                      accountName: Text(
                        user?.displayName ?? 'Guest User',
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.onPrimary,
                        ),
                      ),
                      accountEmail: Text(
                        user?.email ?? 'No email',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onPrimary,
                        ),
                      ),
                      currentAccountPicture: CircleAvatar(
                        backgroundColor: colorScheme.primaryContainer,
                        backgroundImage:
                            user?.photoURL != null
                                ? NetworkImage(user!.photoURL!)
                                : null,
                        child:
                            user?.photoURL == null
                                ? Icon(
                                  Icons.person,
                                  size: 40,
                                  color: colorScheme.onPrimary,
                                )
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
                            builder: (context) => AccountPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              )
              : null,

      body:
          _selectedIndex == 0
              ? Column(
                children: [
                  const SizedBox(height: 10),

                  // 🖼️ Carousel
                  CarouselSlider(
                    options: CarouselOptions(
                      height: 180.0,
                      autoPlay: true,
                      enlargeCenterPage: true,
                      viewportFraction: 0.9,
                    ),
                    items:
                        carouselImages.map((imageUrl) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          );
                        }).toList(),
                  ),

                  // Category Tab Content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children:
                          categories.map((category) {
                            return SingleChildScrollView(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                      vertical: 8,
                                    ),
                                    child: Text(
                                      "$category Drawings",
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 160,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      itemCount: 8,
                                      separatorBuilder:
                                          (_, __) => const SizedBox(width: 12),
                                      itemBuilder:
                                          (_, index) => Container(
                                            width: 120,
                                            decoration: BoxDecoration(
                                              color:
                                                  colorScheme
                                                      .surfaceContainerHighest,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.04),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Center(
                                              child: Text(
                                                "🎨 $category #$index",
                                                style: textTheme.bodyMedium,
                                              ),
                                            ),
                                          ),
                                    ),
                                  ),

                                  // 💡 Recommended Section
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                      vertical: 8,
                                    ),
                                    child: Text(
                                      "$category Recommended",
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 150,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      itemCount:
                                          recommendations[category]?.length ??
                                          0,
                                      separatorBuilder:
                                          (_, __) => const SizedBox(width: 12),
                                      itemBuilder: (_, index) {
                                        final recommendation =
                                            recommendations[category]![index];
                                        return Container(
                                          width:
                                              MediaQuery.of(
                                                context,
                                              ).size.width *
                                              0.7,
                                          decoration: BoxDecoration(
                                            color: colorScheme.onPrimary,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                // ignore: deprecated_member_use
                                                color: Colors.black.withOpacity(
                                                  0.05,
                                                ),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(12.0),
                                            child: Center(
                                              child: Text(
                                                recommendation,
                                                style: textTheme.bodyMedium,
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ],
              )
              : _selectedIndex == 1
              ? const WishlistPage()
              : _selectedIndex == 2
              ? const CartPage()
              : _selectedIndex == 3
              ? const ChatPage()
              : _selectedIndex == 4
              ? const ProfilePage()
              : Center(
                child: Text(
                  [
                    'Home',
                    'Wishlist',
                    'Cart',
                    'Chat',
                    'Profile',
                  ][_selectedIndex],
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (int index) {
          setState(() => _selectedIndex = index);
        },
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurface.withOpacity(0.6),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: 'Wishlist',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
