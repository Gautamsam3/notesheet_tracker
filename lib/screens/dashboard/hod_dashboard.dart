// lib/screens/dashboard/hod_dashboard.dart
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For current user ID
import '../../widgets/greeting_section.dart';
import '../../widgets/events_carousel.dart';
import '../../screens/hod/threshold_approved_events_list.dart'; // Import the updated list
import '../../services/auth_service.dart';
import '../../services/notesheet_service.dart'; // Import NotesheetService
import '../../services/event_service.dart'; // Import EventService
import '../../models/user.dart';
import '../../models/notesheet.dart';
import '../../models/event.dart';
import '../../utils/locator.dart';
import '../../utils/enums.dart'; // For enums and capitalize extension

class HodDashboard extends StatefulWidget {
  const HodDashboard({super.key});

  @override
  State<HodDashboard> createState() => _HodDashboardState();
}

class _HodDashboardState extends State<HodDashboard> {
  final AuthService _authService = locator<AuthService>();
  final NotesheetService _notesheetService = locator<NotesheetService>();
  final EventService _eventService = locator<EventService>();

  AppUser? _currentUser;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    // Trigger time-based checks on dashboard load for both notesheets and events
    _notesheetService.checkAndExpireNotesheets();
    _eventService.checkAllEventsForStatusUpdates();
  }

  Future<void> _loadCurrentUser() async {
    final firebaseUser = _authService.getCurrentFirebaseUser();
    if (firebaseUser != null) {
      _currentUserId = firebaseUser.uid;
      final appUser = await _authService.getCurrentAppUser();
      if (mounted) {
        setState(() {
          _currentUser = appUser;
        });
      }
    }
  }

  void _logout() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to log out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading indicator if user data is not yet loaded
    if (_currentUser == null && _authService.getCurrentFirebaseUser() != null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("HOD Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            UserAccountsDrawerHeader(
              accountName: Text(_currentUser?.name ?? 'Guest User'),
              accountEmail: Text(_currentUser?.email ?? 'Not logged in'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  _currentUser?.name.isNotEmpty == true
                      ? _currentUser!.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(fontSize: 40.0, color: Colors.blue),
                ),
              ),
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(
                'Role: ${_currentUser?.role.name.toUpperCase() ?? 'N/A'}',
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                _logout();
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GreetingSection(userName: _currentUser?.name ?? 'HOD'),
            const SizedBox(height: 24),

            // Section: Upcoming Events (HOD can view all events)
            Text(
              'Upcoming Events',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<Event>>(
              stream: _eventService.getEvents([EventStatus.upcoming]),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No upcoming events.'));
                }
                final List<Map<String, String>> eventsData = snapshot.data!.map(
                  (event) {
                    return {
                      'title': event.title,
                      'date': event.dateOfEvent.toLocal().toString().split(
                        ' ',
                      )[0],
                      'venue': event.venue,
                    };
                  },
                ).toList();
                return EventCarouselWidget(
                  title: '',
                  events: eventsData,
                  scrollDirection: AxisDirection.left,
                );
              },
            ),
            const SizedBox(height: 24),

            // Section: Past Events (HOD can view all events)
            Text('Past Events', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            StreamBuilder<List<Event>>(
              stream: _eventService.getEvents([EventStatus.occurred]),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No past events.'));
                }
                final List<Map<String, String>> eventsData = snapshot.data!.map(
                  (event) {
                    return {
                      'title': event.title,
                      'date': event.dateOfEvent.toLocal().toString().split(
                        ' ',
                      )[0],
                      'venue': event.venue,
                    };
                  },
                ).toList();
                return EventCarouselWidget(
                  title: '',
                  events: eventsData,
                  scrollDirection: AxisDirection.right,
                );
              },
            ),
            const SizedBox(height: 24),

            const Text(
              'Events Awaiting Your Approval',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<Notesheet>>(
              stream: _notesheetService.getPendingApprovalNotesheets(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No notesheets pending HOD approval.'),
                  );
                }
                // Pass Notesheet objects directly to ThresholdApprovedEventsList
                return ThresholdApprovedEventsList(notesheets: snapshot.data!);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Extension to capitalize enum names for display (ensure this is available)
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return '';
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
