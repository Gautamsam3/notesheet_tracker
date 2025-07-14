import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';

void main() => runApp(const NotesheetApp());

class NotesheetApp extends StatelessWidget {
  const NotesheetApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF6B46C1),
      onPrimary: Colors.white,
      secondary: Color(0xFF68D391),
      onSecondary: Color(0xFF4A5568),
      background: Color(0xFFFAF5FF),
      onBackground: Color(0xFF4A5568),
      surface: Colors.white,
      onSurface: Color(0xFF4A5568),
      error: Colors.red,
      onError: Colors.white,
    );

    return MaterialApp(
      title: 'Notesheet Tracker',
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        fontFamily: 'Roboto',
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        scaffoldBackgroundColor: colorScheme.background,
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: colorScheme.onBackground,
          displayColor: colorScheme.onBackground,
        ),
      ),
      home: const HomePage(),
      routes: {
        '/login': (_) => const LoginPage(),
        '/register': (_) => const RegisterPage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
