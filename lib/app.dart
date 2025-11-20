// lib/app.dart
import 'package:flutter/material.dart';
import 'screens/dashboard/admin_dashboard.dart';
import 'screens/dashboard/hod_dashboard.dart';
import 'screens/dashboard/proposer_dashboard.dart';
import 'screens/dashboard/reviewer_dashboard.dart';
import 'screens/role_selector_screen.dart';
import 'screens/login.dart';
import 'screens/register.dart';

class AppRoutes {
  static const login = '/login'; // New login route
  static const register = '/register'; // New register route
  static const roleSelector = '/role_selector'; // Changed from '/'
  static const adminDashboard = '/admin';
  static const proposerDashboard = '/proposer';
  static const reviewerDashboard = '/reviewer';
  static const hodDashboard = '/hod';
}

Map<String, WidgetBuilder> routes = {
  AppRoutes.login: (context) => const LoginScreen(), // Added login route
  AppRoutes.register: (context) =>
      const RegistrationScreen(), // Added registration route
  AppRoutes.roleSelector: (context) => const RoleSelectorScreen(),
  AppRoutes.adminDashboard: (context) => const AdminDashboard(),
  AppRoutes.proposerDashboard: (context) => ProposerDashboard(),
  AppRoutes.reviewerDashboard: (context) => const ReviewerDashboard(),
  AppRoutes.hodDashboard: (context) => const HodDashboard(),
};
