import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/user_provider.dart';
import '../../services/supabase_admin_service.dart';
import '../../services/supabase_database_service.dart';
import '../../models/user_model.dart';
import '../../models/notesheet_model.dart';
import '../../theme/app_theme.dart';
import '../notesheet/notesheet_detail_screen.dart';
import '../notesheet/review_notesheet_screen.dart';
import 'admin_activity_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SupabaseAdminService _adminService = SupabaseAdminService();

  @override
  void initState() {
    super.initState();
    debugPrint('👑 AdminDashboard initialized');
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    debugPrint('👑 AdminDashboard disposed');
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.currentUser;
        
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Admin Dashboard'),
                Text(
                  'Welcome, ${user?.name ?? 'Admin'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => _showSignOutDialog(context),
                tooltip: 'Sign Out',
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true, // Add scrollable for better fit
              tabs: const [
                Tab(
                  icon: Icon(Icons.pending_actions),
                  text: 'Pending Users',
                ),
                Tab(
                  icon: Icon(Icons.people),
                  text: 'All Users',
                ),
                Tab(
                  icon: Icon(Icons.rate_review),
                  text: 'Pending Reviews',
                ),
                Tab(
                  icon: Icon(Icons.timeline),
                  text: 'Activity',
                ),
                Tab(
                  icon: Icon(Icons.analytics),
                  text: 'Analytics',
                ),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _PendingUsersTab(adminService: _adminService),
              _AllUsersTab(adminService: _adminService),
              _PendingReviewsTab(),
              const AdminActivityScreen(),
              _AnalyticsTab(adminService: _adminService),
            ],
          ),
        );
      },
    );
  }

  void _showSignOutDialog(BuildContext context) {
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
            onPressed: () {
              Navigator.of(context).pop();
              Provider.of<UserProvider>(context, listen: false).signOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

// Pending Users Tab
class _PendingUsersTab extends StatelessWidget {
  final SupabaseAdminService adminService;

  const _PendingUsersTab({required this.adminService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppUser>>(
      stream: adminService.getPendingUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading pending users',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final pendingUsers = snapshot.data ?? [];

        if (pendingUsers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: Colors.green.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Pending Users',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'All users have been assigned roles',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pendingUsers.length,
          itemBuilder: (context, index) {
            final user = pendingUsers[index];
            return _PendingUserCard(
              user: user,
              onRoleAssigned: (role) => _assignRole(context, user, role),
              onDefaultRole: () => _assignDefaultRole(context, user),
            );
          },
        );
      },
    );
  }

  Future<void> _assignRole(BuildContext context, AppUser user, UserRole role) async {
    try {
      debugPrint('👑 Admin assigning role ${role.name} to user ${user.uid}');
      await adminService.assignUserRole(user.uid, role);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Assigned ${role.displayName} role to ${user.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to assign role: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to assign role: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _assignDefaultRole(BuildContext context, AppUser user) async {
    await _assignRole(context, user, UserRole.requester);
  }
}

// All Users Tab
class _AllUsersTab extends StatelessWidget {
  final SupabaseAdminService adminService;

  const _AllUsersTab({required this.adminService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppUser>>(
      stream: adminService.getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final users = snapshot.data ?? [];

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return _UserCard(
              user: user,
              onRoleChanged: (role) => _changeRole(context, user, role),
            );
          },
        );
      },
    );
  }

  Future<void> _changeRole(BuildContext context, AppUser user, UserRole? role) async {
    try {
      if (role == null) {
        debugPrint('👑 Admin removing role from user ${user.uid}');
        await adminService.updateUser(uid: user.uid, role: null);
      } else {
        debugPrint('👑 Admin changing role to ${role.name} for user ${user.uid}');
        await adminService.assignUserRole(user.uid, role);
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(role == null 
                ? '✅ Removed role from ${user.name}' 
                : '✅ Changed ${user.name}\'s role to ${role.displayName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to change role: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to change role: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Pending Reviews Tab - Shows notesheets waiting for approval
class _PendingReviewsTab extends StatelessWidget {
  const _PendingReviewsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Notesheet>>(
      stream: SupabaseDatabaseService().getPendingNotesheetsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading pending reviews',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey.shade800, // Improved contrast
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700, // Improved contrast
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final pendingNotesheets = snapshot.data ?? [];

        if (pendingNotesheets.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: Colors.green.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Pending Reviews',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey.shade800, // Improved contrast
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'All notesheet requests have been processed',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700, // Improved contrast
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pendingNotesheets.length,
          itemBuilder: (context, index) {
            final notesheet = pendingNotesheets[index];
            return _PendingNotesheetCard(
              notesheet: notesheet,
              onTap: () => _navigateToDetail(context, notesheet),
              onReview: () => _navigateToReview(context, notesheet),
            );
          },
        );
      },
    );
  }

  void _navigateToDetail(BuildContext context, Notesheet notesheet) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NotesheetDetailScreen(notesheet: notesheet),
      ),
    );
  }

  void _navigateToReview(BuildContext context, Notesheet notesheet) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReviewNotesheetScreen(notesheet: notesheet),
      ),
    );
  }
}

// Pending Notesheet Card Widget
class _PendingNotesheetCard extends StatelessWidget {
  final Notesheet notesheet;
  final VoidCallback? onTap;
  final VoidCallback? onReview;

  const _PendingNotesheetCard({
    required this.notesheet,
    this.onTap,
    this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and status
            Row(
              children: [
                Expanded(
                  child: Text(
                    notesheet.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.pending_actions,
                        size: 14,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Pending',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Description
            Text(
              notesheet.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade800, // Improved contrast
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            
            // Creator and date info
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: 16,
                  color: Colors.grey.shade700, // Improved contrast
                ),
                const SizedBox(width: 4),
                Text(
                  'Created by ${notesheet.creatorName}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade700, // Improved contrast
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: Colors.grey.shade700, // Improved contrast
                ),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM d, y').format(notesheet.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade700, // Improved contrast
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Current reviewer info
            if (notesheet.currentReviewerUid != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.rate_review,
                    size: 16,
                    color: Colors.blue.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Current reviewer: ${_getCurrentReviewerName(notesheet)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.blue.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            
            // Deadline if exists
            if (notesheet.deadline != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.event,
                    size: 16,
                    color: _isOverdue(notesheet.deadline!) ? Colors.red.shade600 : Colors.green.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Deadline: ${DateFormat('MMM d, y').format(notesheet.deadline!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _isOverdue(notesheet.deadline!) ? Colors.red.shade600 : Colors.green.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_isOverdue(notesheet.deadline!)) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Text(
                        'OVERDUE',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],

            // Action buttons for admin
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('View Details'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onReview,
                    icon: const Icon(Icons.rate_review, size: 18),
                    label: const Text('Review'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ));
  }

  String _getCurrentReviewerName(Notesheet notesheet) {
    final currentReviewer = notesheet.reviewFlow.firstWhere(
      (reviewer) => reviewer.uid == notesheet.currentReviewerUid,
      orElse: () => Reviewer(uid: '', name: 'Unknown', status: ReviewStatus.pending),
    );
    return currentReviewer.name;
  }

  bool _isOverdue(DateTime deadline) {
    return DateTime.now().isAfter(deadline);
  }
}

// Analytics Tab
class _AnalyticsTab extends StatelessWidget {
  final SupabaseAdminService adminService;
  
  const _AnalyticsTab({required this.adminService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppUser>>(
      stream: adminService.getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final users = snapshot.data ?? [];
        final pendingCount = users.where((u) => u.isPendingApproval).length;
        final requesterCount = users.where((u) => u.isRequester).length;
        final reviewerCount = users.where((u) => u.isReviewer).length;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Statistics Cards
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _StatCard(
                      title: 'Total Users',
                      value: users.length.toString(),
                      icon: Icons.people,
                      color: AppTheme.primaryColor,
                    ),
                    _StatCard(
                      title: 'Pending Approval',
                      value: pendingCount.toString(),
                      icon: Icons.pending_actions,
                      color: Colors.orange,
                    ),
                    _StatCard(
                      title: 'Requesters',
                      value: requesterCount.toString(),
                      icon: Icons.add_box,
                      color: Colors.blue,
                    ),
                    _StatCard(
                      title: 'Reviewers',
                      value: reviewerCount.toString(),
                      icon: Icons.rate_review,
                      color: Colors.green,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Pending User Card Widget
class _PendingUserCard extends StatelessWidget {
  final AppUser user;
  final Function(UserRole) onRoleAssigned;
  final VoidCallback? onDefaultRole;

  const _PendingUserCard({
    required this.user,
    required this.onRoleAssigned,
    this.onDefaultRole,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  child: Text(
                    user.name.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.business,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  '${user.department} Department',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Spacer(),
                Text(
                  'Joined: ${DateFormat('MMM d, y').format(user.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                // Quick default role button
                if (onDefaultRole != null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onDefaultRole,
                      icon: const Icon(Icons.person_add),
                      label: const Text('Make Requester (Default)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Or choose specific role:',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                // Role selection buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => onRoleAssigned(UserRole.requester),
                        icon: const Icon(Icons.add_box),
                        label: const Text('Requester'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => onRoleAssigned(UserRole.reviewer),
                        icon: const Icon(Icons.rate_review),
                        label: const Text('Reviewer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => onRoleAssigned(UserRole.admin),
                        icon: const Icon(Icons.admin_panel_settings),
                        label: const Text('Admin'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// User Card Widget
class _UserCard extends StatelessWidget {
  final AppUser user;
  final Function(UserRole?)? onRoleChanged;

  const _UserCard({
    required this.user,
    this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    Color roleColor = user.isPendingApproval 
        ? Colors.orange 
        : user.isAdmin 
            ? Colors.purple 
            : user.isReviewer 
                ? Colors.green 
                : Colors.blue;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: roleColor.withValues(alpha: 0.1),
          child: Text(
            user.name.substring(0, 1).toUpperCase(),
            style: TextStyle(
              color: roleColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(user.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            Text('${user.department} Department'),
          ],
        ),
        trailing: onRoleChanged != null
            ? PopupMenuButton<UserRole?>(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: roleColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user.isPendingApproval ? 'Pending' : user.role!.displayName,
                        style: TextStyle(
                          color: roleColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_drop_down,
                        color: roleColor,
                        size: 16,
                      ),
                    ],
                  ),
                ),
                onSelected: onRoleChanged,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: UserRole.requester,
                    child: Row(
                      children: [
                        Icon(Icons.add_box, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Requester'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: UserRole.reviewer,
                    child: Row(
                      children: [
                        Icon(Icons.rate_review, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Reviewer'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: UserRole.admin,
                    child: Row(
                      children: [
                        Icon(Icons.admin_panel_settings, color: Colors.purple),
                        SizedBox(width: 8),
                        Text('Admin'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: null,
                    child: Row(
                      children: [
                        Icon(Icons.remove_circle, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Remove Role'),
                      ],
                    ),
                  ),
                ],
              )
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: roleColor),
                ),
                child: Text(
                  user.isPendingApproval ? 'Pending' : user.role!.displayName,
                  style: TextStyle(
                    color: roleColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
      ),
    );
  }
}

// Statistics Card Widget
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
