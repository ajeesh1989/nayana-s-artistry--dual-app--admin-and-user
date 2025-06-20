import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:nayanasartistry/user/account/address_controller.dart';
import 'package:nayanasartistry/user/cart/cart_controller.dart';
import 'package:nayanasartistry/user/home/controller/home_controller.dart';
import 'package:nayanasartistry/user/pages/splash/splash.dart';
import 'package:nayanasartistry/theme/theme_controller.dart';
import 'package:nayanasartistry/user/productview/product_controller.dart';
import 'package:nayanasartistry/user/wishlist/wish_list_controller.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final themeProvider = ThemeProvider();
  await themeProvider.loadThemePreference();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider<HomeProvider>(create: (_) => HomeProvider()),
        ChangeNotifierProvider<ProductController>(
          create: (_) => ProductController(),
        ),
        ChangeNotifierProvider(
          create: (_) => WishlistProvider()..fetchWishlist(),
        ),
        ChangeNotifierProvider(create: (_) => CartProvider()..fetchCart()),
        ChangeNotifierProvider(
          create: (_) => AddressProvider()..fetchAddresses(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: "Nayana's Artistry",
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 16, color: Colors.black87),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 16, color: Colors.white70),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
