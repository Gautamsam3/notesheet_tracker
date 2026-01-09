// lib/screens/dashboard/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/greeting_section.dart';
import '../../services/auth_service.dart';
import '../../services/notesheet_service.dart';
import '../../services/event_service.dart';
import '../../services/settings_service.dart';
import '../../services/user_service.dart'; // Import UserService
import '../../models/user.dart';
import '../../models/notesheet.dart';
import '../../models/event.dart';
import '../../utils/locator.dart';
import '../../utils/enums.dart'; // For UserRole and capitalize extension

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AuthService _authService = locator<AuthService>();
  final NotesheetService _notesheetService = locator<NotesheetService>();
  final EventService _eventService = locator<EventService>();
  final SettingsService _settingsService = locator<SettingsService>();
  final UserService _userService = locator<UserService>(); // Get UserService

  AppUser? _currentUser;
  int _reviewThreshold = 1; // Default value, will be loaded from settings

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadReviewThreshold();
    // Trigger time-based checks on dashboard load
    _notesheetService.checkAndExpireNotesheets();
    _eventService.checkAllEventsForStatusUpdates();
  }

  Future<void> _loadCurrentUser() async {
    final firebaseUser = _authService.getCurrentFirebaseUser();
    if (firebaseUser != null) {
      final appUser = await _authService.getCurrentAppUser();
      if (mounted) {
        setState(() {
          _currentUser = appUser;
        });
      }
    }
  }

  Future<void> _loadReviewThreshold() async {
    final threshold = await _settingsService.getReviewThreshold();
    if (mounted) {
      // getReviewThreshold now returns int, so no null check needed for 'threshold'
      setState(() {
        _reviewThreshold = threshold;
      });
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

  Future<void> _updateReviewThreshold(int newThreshold) async {
    if (newThreshold <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review threshold must be at least 1.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    try {
      await _settingsService.updateReviewThreshold(newThreshold);
      if (mounted) {
        setState(() {
          _reviewThreshold = newThreshold;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review threshold updated successfully!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update threshold: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showChangeRoleDialog(BuildContext context, AppUser user) {
    UserRole? selectedRole = user.role; // Default to current role

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Change Role for ${user.name}'),
          content: DropdownButtonFormField<UserRole>(
            value: selectedRole,
            items: UserRole.values.map((role) {
              return DropdownMenuItem(
                value: role,
                child: Text(role.name.capitalize()),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                // This setState is for the dialog's StatefulBuilder
                selectedRole = value;
              });
            },
            decoration: const InputDecoration(labelText: 'New Role'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedRole != null && selectedRole != user.role) {
                  try {
                    await _userService.updateUserRole(user.id!, selectedRole!);
                    if (mounted) {
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Role for ${user.name} updated to ${selectedRole!.name.capitalize()}',
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to update role: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                } else {
                  Navigator.pop(dialogContext); // No change or no role selected
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteUserConfirmation(BuildContext context, AppUser user) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text(
            'Are you sure you want to delete the user "${user.name}" (${user.email})? This will only delete their profile from Firestore, not their Firebase Authentication account.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _userService.deleteUser(user.id!);
                  if (mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'User ${user.name} deleted from Firestore.',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete user: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null && _authService.getCurrentFirebaseUser() != null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
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
                'Role: ${_currentUser?.role.name.capitalize() ?? 'N/A'}',
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
            GreetingSection(userName: _currentUser?.name ?? 'Admin'),
            const SizedBox(height: 24),

            // --- Global Settings Section ---
            Text(
              'Global Settings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Card(
              margin: const EdgeInsets.only(bottom: 24),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Review Threshold: $_reviewThreshold',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: _reviewThreshold.toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'New Threshold',
                              border: OutlineInputBorder(),
                            ),
                            onFieldSubmitted: (value) {
                              final newThreshold = int.tryParse(value);
                              if (newThreshold != null) {
                                _updateReviewThreshold(newThreshold);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            // Access the text from the TextFormField's controller directly
                            // This assumes the TextFormField is a direct child of the Expanded widget
                            // and the controller is managed by the TextFormField itself,
                            // or you would need to give it a specific controller here.
                            // For simplicity, let's assume the onFieldSubmitted handles it,
                            // or we add a TextEditingController to this StatefulWidget.
                            // For now, let's make it simpler and rely on a local controller for the dialog.
                            // Or, we can use a simpler approach for the update button.
                            // For a quick fix, let's make sure the TextFormField has a controller.
                            showDialog(
                              context: context,
                              builder: (context) {
                                final TextEditingController tempController =
                                    TextEditingController(
                                      text: _reviewThreshold.toString(),
                                    );
                                return AlertDialog(
                                  title: const Text('Update Review Threshold'),
                                  content: TextField(
                                    controller: tempController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Enter new threshold',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        final newThreshold = int.tryParse(
                                          tempController.text,
                                        );
                                        if (newThreshold != null) {
                                          _updateReviewThreshold(newThreshold);
                                          Navigator.pop(context);
                                        } else {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Please enter a valid number.',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      },
                                      child: const Text('Update'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: const Text('Update'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // --- User Management Section ---
            Text(
              'User Management',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<AppUser>>(
              stream: _userService.getAllAppUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading users: ${snapshot.error}'),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No users found.'));
                }
                final users = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        title: Text(user.name),
                        subtitle: Text(
                          '${user.email}\nRole: ${user.role.name.capitalize()}',
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () =>
                                  _showChangeRoleDialog(context, user),
                              tooltip: 'Change Role',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  _showDeleteUserConfirmation(context, user),
                              tooltip: 'Delete User',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),

            // --- Notesheet Overview Section ---
            Text(
              'Notesheet Overview',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<Notesheet>>(
              stream: _notesheetService
                  .getAllNotesheets(), // Assuming this method exists or you'll create it
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading notesheets: ${snapshot.error}'),
                  );
                }
                final notesheets = snapshot.data ?? [];
                final total = notesheets.length;
                final pendingApproval = notesheets
                    .where((n) => n.status == NotesheetStatus.pendingApproval)
                    .length;
                final underConsideration = notesheets
                    .where(
                      (n) => n.status == NotesheetStatus.underConsideration,
                    )
                    .length;
                final approved = notesheets
                    .where((n) => n.status == NotesheetStatus.approved)
                    .length;
                final rejected = notesheets
                    .where(
                      (n) =>
                          n.status == NotesheetStatus.rejected ||
                          n.status == NotesheetStatus.rejectedWithSuggestions,
                    )
                    .length;

                return Card(
                  margin: const EdgeInsets.only(bottom: 24),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Notesheets: $total',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Pending Approval: $pendingApproval',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Under Consideration: $underConsideration',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Approved: $approved',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          'Rejected: $rejected',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // --- Event Overview Section ---
            Text(
              'Event Overview',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<Event>>(
              stream: _eventService
                  .getAllEvents(), // Assuming this method exists or you'll create it
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading events: ${snapshot.error}'),
                  );
                }
                final events = snapshot.data ?? [];
                final totalEvents = events.length;
                final upcomingEvents = events
                    .where((e) => e.eventStatus == EventStatus.upcoming)
                    .length;
                final occurredEvents = events
                    .where((e) => e.eventStatus == EventStatus.occurred)
                    .length;

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Events: $totalEvents',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Upcoming Events: $upcomingEvents',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Occurred Events: $occurredEvents',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                );
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
