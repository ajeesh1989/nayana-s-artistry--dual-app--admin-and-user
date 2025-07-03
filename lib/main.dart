import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:nayanasartistry/user/user_notifications/user_notification_controller.dart';
import 'package:nayanasartistry/user/user_notifications/user_notifications.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import 'firebase_options.dart';
import 'theme/theme_controller.dart';
import 'user/pages/splash/splash.dart';
import 'admin/controller/admin_controller.dart';
import 'admin/controller/admin_order_controller.dart';
import 'user/account/address_controller.dart';
import 'user/cart/cart_controller.dart';
import 'user/home/controller/home_controller.dart';
import 'user/order/order_controller.dart';
import 'user/productview/product_controller.dart';
import 'user/wishlist/wish_list_controller.dart';
import 'rider/rider_controller.dart';
import 'rider/user_location_controller.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  log('📩 BG message received: ${message.data}');
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'Used for important messages with images',
  importance: Importance.high,
);

// ... keep all imports as is

Future<void> showRichNotification(RemoteMessage message) async {
  final title = message.data['title'] ?? '';
  final body = message.data['body'] ?? '';
  final imageUrl = message.data['image'];

  String? bigPicturePath;
  if (imageUrl != null && imageUrl.toString().trim().isNotEmpty) {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      final tempDir = await getTemporaryDirectory();
      final filePath = p.join(tempDir.path, 'notif_image.jpg');
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      bigPicturePath = filePath;
    } catch (e) {
      log('❌ Error loading image: $e');
    }
  }

  final androidDetails = AndroidNotificationDetails(
    channel.id,
    channel.name,
    channelDescription: channel.description,
    importance: Importance.high,
    priority: Priority.high,
    styleInformation:
        bigPicturePath != null
            ? BigPictureStyleInformation(
              FilePathAndroidBitmap(bigPicturePath),
              contentTitle: title,
              summaryText: body,
            )
            : null,
    icon: '@mipmap/ic_launcher',
  );

  final notificationDetails = NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    title.hashCode,
    title,
    body,
    notificationDetails,
  );
}

// ✅ Removed saveNotificationIfNew()

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final themeProvider = ThemeProvider();
  await themeProvider.loadThemePreference();

  if (Platform.isAndroid) {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  await FirebaseMessaging.instance.requestPermission();
  await FirebaseMessaging.instance.subscribeToTopic('user_broadcast');
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final token = await FirebaseMessaging.instance.getToken();
  final user = FirebaseAuth.instance.currentUser;
  if (user != null && token != null) {
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'fcmToken': token,
    }, SetOptions(merge: true));
  }

  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fcmToken': newToken,
      }, SetOptions(merge: true));
    }
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => ProductController()),
        ChangeNotifierProvider(
          create: (_) => WishlistProvider()..fetchWishlist(),
        ),
        ChangeNotifierProvider(create: (_) => CartProvider()..fetchCart()),
        ChangeNotifierProvider(
          create: (_) => AddressProvider()..fetchAddresses(),
        ),
        ChangeNotifierProvider(
          create: (_) {
            final c = OrderController();
            c.fetchOrders();
            return c;
          },
        ),
        ChangeNotifierProvider(
          create: (_) => AdminController()..fetchDashboardStats(),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminOrderController()..fetchOrders(),
        ),
        ChangeNotifierProvider(create: (_) => RiderHomeProvider()),
        ChangeNotifierProvider(create: (_) => UserLocationProvider()),
        ChangeNotifierProvider(create: (_) => UserNotificationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      await showRichNotification(message); // ✅ Only show, don't save
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      if (message.data['screen'] == 'user_notifications') {
        Navigator.pushNamed(context, '/userNotifications');
      }
    });

    FirebaseMessaging.instance.getInitialMessage().then((
      RemoteMessage? message,
    ) {
      if (message != null) {
        if (message.data['screen'] == 'user_notifications') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushNamed(context, '/userNotifications');
          });
        }
      }
    });
  }

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
      routes: {
        '/userNotifications': (context) => const UserNotificationsPage(),
      },
      home: const SplashScreen(),
    );
  }
}
