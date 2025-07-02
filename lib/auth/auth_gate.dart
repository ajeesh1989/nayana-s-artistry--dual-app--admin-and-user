import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide PhoneAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:nayanasartistry/user/pages/splash/splash.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final logoPath =
            isDark
                ? 'assets/images/logo_white.png'
                : 'assets/images/logo_black.png';

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData) {
          return Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: Image.asset(
                      logoPath,
                      height: MediaQuery.of(context).size.height * 0.3,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Welcome to Nayana’s Artistry",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Sign in to continue",
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: SignInScreen(
                        showAuthActionSwitch: false,
                        headerBuilder:
                            (context, _, __) => const SizedBox.shrink(),
                        subtitleBuilder:
                            (context, _) => const SizedBox.shrink(),
                        footerBuilder: (context, _) => const SizedBox.shrink(),
                        actions: [
                          AuthStateChangeAction<SignedIn>((context, _) async {
                            final user = FirebaseAuth.instance.currentUser;

                            if (user != null) {
                              final token =
                                  await FirebaseMessaging.instance.getToken();
                              final email = user.email;
                              final isAdmin =
                                  email == 'ajeeshrko@gmail.com' ||
                                  email == 'nayanasartistry@gmail.com';

                              final userDoc = FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.uid);
                              final snapshot = await userDoc.get();
                              final existingData = snapshot.data();

                              final userData = {
                                'fcmToken': token,
                                'email': email,
                                if (existingData == null ||
                                    !existingData.containsKey('role'))
                                  'role':
                                      isAdmin
                                          ? 'admin'
                                          : 'user', // ✅ only set if not already set
                                'timestamp': FieldValue.serverTimestamp(),
                              };

                              await userDoc.set(
                                userData,
                                SetOptions(merge: true),
                              );

                              if (isAdmin) {
                                await FirebaseFirestore.instance
                                    .collection('adminTokens')
                                    .doc(user.uid)
                                    .set(userData, SetOptions(merge: true));
                              }

                              debugPrint(
                                "✅ Role set (if not already), token saved",
                              );

                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => const SplashScreen(),
                                ),
                              );
                            }
                          }),
                        ],
                        providers: [
                          GoogleProvider(
                            clientId:
                                '502260348857-k3gmmnr1v7rp5do88h9ntt9pp8uj3r33.apps.googleusercontent.com',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return const SplashScreen();
      },
    );
  }
}
