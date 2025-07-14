import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import '../notesheet/create_notesheet_screen.dart';
import 'requester_dashboard.dart';
import 'reviewer_dashboard.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    debugPrint('🏠 Dashboard screen initialized');
  }

  @override
  void dispose() {
    debugPrint('🏠 Dashboard screen disposed');
    super.dispose();
  }

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    debugPrint('🏠 Dashboard tab changed to index: $index');
  }

  void _showSignOutDialog(BuildContext context, UserProvider userProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await userProvider.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/signIn');
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.currentUser;
        
        if (user == null) {
          return const Scaffold(
            body: Center(
              child: Text('No user data available'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Welcome, ${user.name}'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => _showSignOutDialog(context, userProvider),
                tooltip: 'Sign Out',
              ),
            ],
          ),
          body: _buildDashboardBody(user),
          bottomNavigationBar: _buildBottomNavBar(user),
          floatingActionButton: _buildFloatingActionButton(user),
        );
      },
    );
  }

  Widget _buildDashboardBody(AppUser user) {
    // Build tabs based on user role
    final tabs = <Widget>[];
    
    if (user.isRequester || user.isAdmin) {
      tabs.add(const RequesterDashboard());
    }
    if (user.isReviewer || user.isAdmin) {
      tabs.add(const ReviewerDashboard());
    }
    
    // If only one tab, show it directly
    if (tabs.length == 1) {
      return tabs.first;
    }
    
    // Multiple tabs, use IndexedStack
    return IndexedStack(
      index: _currentIndex,
      children: tabs,
    );
  }

  Widget? _buildBottomNavBar(AppUser user) {
    final items = <BottomNavigationBarItem>[];
    
    if (user.isRequester || user.isAdmin) {
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.add_box),
        label: 'Submit Request',
      ));
    }
    if (user.isReviewer || user.isAdmin) {
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.rate_review),
        label: 'Review Requests',
      ));
    }
    
    // If only one item, don't show bottom nav
    if (items.length <= 1) {
      return null;
    }
    
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: _onTabChanged,
      items: items,
    );
  }

  Widget? _buildFloatingActionButton(AppUser user) {
    // Only show FAB on requester tab for users who can create notesheets
    if (!(user.isRequester || user.isAdmin)) {
      return null;
    }

    // If we have multiple tabs, check if we're on the requester tab
    if ((user.isRequester || user.isAdmin) && (user.isReviewer || user.isAdmin)) {
      // Multiple tabs - only show FAB on first tab (requester)
      if (_currentIndex != 0) {
        return null;
      }
    }

    return FloatingActionButton(
      onPressed: () => _navigateToCreateNotesheet(context),
      tooltip: 'Create Notesheet',
      child: const Icon(Icons.add),
    );
  }

  void _navigateToCreateNotesheet(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateNotesheetScreen(),
      ),
    );
  }
}
