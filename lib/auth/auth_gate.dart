import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide PhoneAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:nayanasartistry/user/home/home.dart';
import 'package:nayanasartistry/user/pages/splash/splash.dart';

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
          return Scaffold(body: Center(child: CircularProgressIndicator()));
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
                            (context, constraints, _) =>
                                const SizedBox.shrink(),
                        subtitleBuilder:
                            (context, _) => const SizedBox.shrink(),
                        footerBuilder: (context, _) => const SizedBox.shrink(),
                        actions: [
                          AuthStateChangeAction<SignedIn>((context, _) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const SplashScreen(),
                              ),
                            );
                          }),
                        ],
                        providers: [
                          // PhoneAuthProvider(),
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
