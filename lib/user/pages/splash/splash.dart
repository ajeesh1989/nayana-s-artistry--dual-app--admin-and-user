// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:nayanasartistry/admin/widgets/admin_dash.dart';
import 'package:nayanasartistry/auth/auth_gate.dart';
import 'package:nayanasartistry/rider/rider_home.dart';
import 'package:nayanasartistry/user/home/home.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), navigateBasedOnAuth);
  }

  Future<void> navigateBasedOnAuth() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthGate()),
      );
      return;
    }

    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

    final role = doc.data()?['role'];

    // 🚀 Get FCM token
    final token = await FirebaseMessaging.instance.getToken();
    log('🔐 Current FCM token: $token');

    // 💾 Save token to Firestore
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'fcmToken': token,
    });

    // 🔔 Role-based topic subscription
    if (role == 'admin') {
      await FirebaseMessaging.instance.subscribeToTopic('admin_broadcast');
      await FirebaseMessaging.instance.unsubscribeFromTopic('user_broadcast');
      log('🔔 Subscribed to admin_broadcast');
    } else if (role == 'user') {
      await FirebaseMessaging.instance.subscribeToTopic('user_broadcast');
      await FirebaseMessaging.instance.unsubscribeFromTopic('admin_broadcast');
      log('🔔 Subscribed to user_broadcast');
    } else {
      // Unsubscribe from both if rider or other role
      await FirebaseMessaging.instance.unsubscribeFromTopic('admin_broadcast');
      await FirebaseMessaging.instance.unsubscribeFromTopic('user_broadcast');
      log('🔕 Unsubscribed from all topics');
    }

    // 🚪 Navigate based on role
    if (role == 'admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboard()),
      );
    } else if (role == 'rider') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RiderHomePage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logoPath =
        isDark
            ? 'assets/images/logo_white.png'
            : 'assets/images/logo_black.png';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Image.asset(logoPath, width: 300, fit: BoxFit.contain),
      ),
    );
  }
}
