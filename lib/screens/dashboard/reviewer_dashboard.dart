// lib/screens/dashboard/reviewer_dashboard.dart
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For current user ID
import '../../widgets/event_submission_form.dart';
import '../../widgets/greeting_section.dart';
import '../../widgets/events_carousel.dart'; // Ensure this widget accepts List<Map<String, String>>
import '../../widgets/proposed_events_list.dart'; // This will need to be updated to take Notesheet objects
import '../../screens/reviewer/reviewable_events_list.dart'; // This will need to be updated to take Notesheet objects
import '../../services/auth_service.dart';
import '../../services/notesheet_service.dart'; // Import NotesheetService
import '../../services/event_service.dart'; // Import EventService
import '../../models/user.dart';
import '../../models/notesheet.dart'; // Import Notesheet model
import '../../models/event.dart'; // Import Event model
import '../../utils/locator.dart';
import '../../utils/enums.dart'; // For EventStatus enum

class ReviewerDashboard extends StatefulWidget {
  const ReviewerDashboard({super.key});

  @override
  State<ReviewerDashboard> createState() => _ReviewerDashboardState();
}

class _ReviewerDashboardState extends State<ReviewerDashboard> {
  final AuthService _authService = locator<AuthService>();
  final NotesheetService _notesheetService = locator<NotesheetService>();
  final EventService _eventService = locator<EventService>();

  AppUser? _currentUser; // To hold the logged-in AppUser data
  String? _currentUserId; // To hold the Firebase Auth UID

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
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
        // After logout, StreamBuilder in main.dart will navigate to LoginScreen
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
        title: const Text("Reviewer Dashboard"),
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
                Navigator.pop(context); // Close the drawer
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
            // Greeting section now uses loaded user data
            GreetingSection(userName: _currentUser?.name ?? 'Reviewer'),
            const SizedBox(height: 24),

            // Section: Upcoming Events
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
                // Convert Event objects to the Map<String, String> format expected by EventCarouselWidget
                final List<Map<String, String>> eventsData = snapshot.data!.map(
                  (event) {
                    return {
                      'title': event.title,
                      'date': event.dateOfEvent.toLocal().toString().split(
                        ' ',
                      )[0], // Simple date string
                      'venue': event.venue,
                    };
                  },
                ).toList();
                return EventCarouselWidget(
                  title: '', // Title is already displayed above
                  events: eventsData, // <--- Correctly passing eventsData here
                  scrollDirection: AxisDirection.left,
                );
              },
            ),
            const SizedBox(height: 24),

            // Section: Past Events
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
                  events: eventsData, // <--- Correctly passing eventsData here
                  scrollDirection: AxisDirection.right,
                );
              },
            ),
            const SizedBox(height: 24),

            // Section: Events to Review
            Text(
              'Events to Review',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<Notesheet>>(
              stream: _notesheetService.getNotesheetsForReviewerDashboard(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No notesheets to review.'));
                }
                // Pass Notesheet objects directly to ReviewableEventsList (you'll need to update this widget)
                return ReviewableEventsList(notesheets: snapshot.data!);
              },
            ),
            const SizedBox(height: 32),

            // Section: Your Proposed Events
            Text(
              'Your Proposed Events',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            // Only show proposed events if a user is logged in
            _currentUserId == null
                ? const Center(
                    child: Text('Login to view your proposed events.'),
                  )
                : StreamBuilder<List<Notesheet>>(
                    stream: _notesheetService.getNotesheetsProposedBy(
                      _currentUserId!,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text('You have not proposed any events.'),
                        );
                      }
                      // Pass Notesheet objects directly to ProposedEventsList (you'll need to update this widget)
                      return ProposedEventsList(notesheets: snapshot.data!);
                    },
                  ),
            const SizedBox(height: 32),

            // Reviewer can submit proposals too
            const EventSubmissionForm(),
          ],
        ),
      ),
    );
  }
}

// Extension to capitalize enum names for display (if not already in enums.dart or a common place)
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return '';
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
