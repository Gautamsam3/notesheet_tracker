import 'package:notesheet_tracker/pages/dashboard.dart';
import 'package:notesheet_tracker/pages/login.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isUserLoggedIn = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Docket - Dashboard',
      home: isUserLoggedIn ? Dashboard() : LoginPage(),
    );
  }
}