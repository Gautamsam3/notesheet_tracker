import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
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
                onPressed: () async {
                  debugPrint('🚪 User logout initiated');
                  await userProvider.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacementNamed('/signIn');
                  }
                },
                tooltip: 'Sign Out',
              ),
            ],
          ),
          body: IndexedStack(
            index: _currentIndex,
            children: const [
              RequesterDashboard(),
              ReviewerDashboard(),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabChanged,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.add_box),
                label: 'Submit Request',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.rate_review),
                label: 'Review Requests',
              ),
            ],
          ),
        );
      },
    );
  }
}
