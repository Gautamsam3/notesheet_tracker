// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'utils/locator.dart';
import 'services/auth_service.dart';
import 'screens/login.dart';
import 'screens/role_selector_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  setupLocator(); // Call the setup function to register services
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the AuthService instance from the locator
    final AuthService authService = locator<AuthService>();

    return MaterialApp(
      title: 'Event Management',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      // Use a builder to access context for StreamBuilder
      home: StreamBuilder<User?>(
        stream: authService.authStateChanges, // Listen to auth state changes
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show a loading indicator while checking auth state
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData && snapshot.data != null) {
            // User is logged in, navigate to RoleSelectorScreen
            // This is a simplified approach. In a real app, you might
            // fetch the AppUser role and directly navigate to their dashboard.
            return const RoleSelectorScreen();
          } else {
            // User is not logged in, show LoginScreen
            return const LoginScreen();
          }
        },
      ),
      // Define routes for navigation within the app
      routes: routes,
    );
  }
}
