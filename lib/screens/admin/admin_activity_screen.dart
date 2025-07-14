import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/notesheet_model.dart';
import '../../services/supabase_database_service.dart';
import '../notesheet/notesheet_detail_screen.dart';

class AdminActivityScreen extends StatefulWidget {
  const AdminActivityScreen({super.key});

  @override
  State<AdminActivityScreen> createState() => _AdminActivityScreenState();
}

class _AdminActivityScreenState extends State<AdminActivityScreen> {
  final SupabaseDatabaseService _databaseService = SupabaseDatabaseService();
  List<NotesheetActivity> _activities = [];
  Map<String, List<NotesheetActivity>> _groupedActivities = {};
  bool _isLoading = true;
  String _selectedFilter = 'all';
  bool _groupByNotesheet = true; // New toggle for grouping
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // For now, let's use a different approach that doesn't require admin-level access
      // We'll get notesheets the user has access to instead of all notesheets
      List<Notesheet> notesheets = [];
      
      // Try to get all notesheets if user is admin, otherwise fallback to user's notesheets
      try {
        notesheets = await _databaseService.getAllNotesheets();
      } catch (adminError) {
        // If admin access fails, try to get notesheets the user can access
        print('Admin access failed, using fallback approach: $adminError');
        
        // This is a temporary fallback - in a real app, you'd have proper user-based queries
        setState(() {
          _isLoading = false;
          _errorMessage = 'Admin access required. This feature is only available to administrators.';
        });
        return;
      }
      
      List<NotesheetActivity> activities = [];

      for (final notesheet in notesheets) {
        // Add creation activity
        activities.add(NotesheetActivity(
          id: '${notesheet.id}_created',
          notesheetId: notesheet.id,
          notesheetTitle: notesheet.title,
          activityType: ActivityType.created,
          userName: notesheet.creatorName,
          userId: notesheet.creatorUid,
          timestamp: notesheet.createdAt,
          status: notesheet.status,
        ));

        // Add review activities
        for (final reviewer in notesheet.reviewFlow) {
          if (reviewer.actionDate != null) {
            activities.add(NotesheetActivity(
              id: '${notesheet.id}_${reviewer.uid}_${reviewer.status.name}',
              notesheetId: notesheet.id,
              notesheetTitle: notesheet.title,
              activityType: reviewer.status == ReviewStatus.approved
                  ? ActivityType.approved
                  : ActivityType.rejected,
              userName: reviewer.name,
              userId: reviewer.uid,
              timestamp: reviewer.actionDate!,
              status: notesheet.status,
              comments: reviewer.comments,
            ));
          }
        }

        // Add completion activity if completed
        if (notesheet.status == NotesheetStatus.completed) {
          activities.add(NotesheetActivity(
            id: '${notesheet.id}_completed',
            notesheetId: notesheet.id,
            notesheetTitle: notesheet.title,
            activityType: ActivityType.completed,
            userName: 'System',
            userId: 'system',
            timestamp: notesheet.updatedAt ?? notesheet.createdAt,
            status: notesheet.status,
          ));
        }
      }

      // Sort by timestamp (newest first)
      activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Group activities by notesheet
      final Map<String, List<NotesheetActivity>> grouped = {};
      for (final activity in activities) {
        if (!grouped.containsKey(activity.notesheetId)) {
          grouped[activity.notesheetId] = [];
        }
        grouped[activity.notesheetId]!.add(activity);
      }

      setState(() {
        _activities = activities;
        _groupedActivities = grouped;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      
      print('Error loading activities: $e');
    }
  }

  List<NotesheetActivity> get _filteredActivities {
    if (_selectedFilter == 'all') return _activities;

    return _activities.where((activity) {
      switch (_selectedFilter) {
        case 'created':
          return activity.activityType == ActivityType.created;
        case 'approved':
          return activity.activityType == ActivityType.approved;
        case 'rejected':
          return activity.activityType == ActivityType.rejected;
        case 'completed':
          return activity.activityType == ActivityType.completed;
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_groupByNotesheet ? Icons.view_list : Icons.view_module),
            onPressed: () {
              setState(() {
                _groupByNotesheet = !_groupByNotesheet;
              });
            },
            tooltip: _groupByNotesheet ? 'Show Individual Activities' : 'Group by Notesheet',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadActivities,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter selector
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('Filter: ', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'All',
                          value: 'all',
                          selectedValue: _selectedFilter,
                          onSelected: (value) {
                            setState(() {
                              _selectedFilter = value;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Created',
                          value: 'created',
                          selectedValue: _selectedFilter,
                          onSelected: (value) {
                            setState(() {
                              _selectedFilter = value;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Approved',
                          value: 'approved',
                          selectedValue: _selectedFilter,
                          onSelected: (value) {
                            setState(() {
                              _selectedFilter = value;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Rejected',
                          value: 'rejected',
                          selectedValue: _selectedFilter,
                          onSelected: (value) {
                            setState(() {
                              _selectedFilter = value;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Completed',
                          value: 'completed',
                          selectedValue: _selectedFilter,
                          onSelected: (value) {
                            setState(() {
                              _selectedFilter = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildErrorView()
                    : _groupByNotesheet
                        ? _buildGroupedView()
                        : _buildListView(),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    final activities = _filteredActivities;
    
    if (activities.isEmpty) {
      return const Center(
        child: Text('No activities found'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadActivities,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: activities.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final activity = activities[index];
          return _ActivityCard(
            activity: activity,
            onTap: () => _viewNotesheetDetail(activity.notesheetId),
          );
        },
      ),
    );
  }

  Widget _buildGroupedView() {
    if (_groupedActivities.isEmpty) {
      return const Center(
        child: Text('No activities found'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadActivities,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _groupedActivities.length,
        itemBuilder: (context, index) {
          final entry = _groupedActivities.entries.elementAt(index);
          final notesheetId = entry.key;
          final activities = entry.value;
          final latestActivity = activities.first;

          return _GroupedActivityCard(
            notesheetId: notesheetId,
            notesheetTitle: latestActivity.notesheetTitle,
            activities: activities,
            onTap: () => _showActivityDetails(activities),
            onViewNotesheet: () => _viewNotesheetDetail(notesheetId),
          );
        },
      ),
    );
  }

  Future<void> _viewNotesheetDetail(String notesheetId) async {
    try {
      final notesheet = await _databaseService.getNotesheetById(notesheetId);
      if (notesheet != null && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => NotesheetDetailScreen(notesheet: notesheet),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading notesheet: $e')),
        );
      }
    }
  }

  void _showActivityDetails(List<NotesheetActivity> activities) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Activities for ${activities.first.notesheetTitle}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.separated(
            itemCount: activities.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final activity = activities[index];
              final activityColor = _getActivityColor(activity.activityType);
              final activityIcon = _getActivityIcon(activity.activityType);
              
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: activityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    activityIcon,
                    color: activityColor,
                    size: 20,
                  ),
                ),
                title: Text(_getActivityDescription(activity)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'By ${activity.userName}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      DateFormat('MMM dd, yyyy HH:mm').format(activity.timestamp),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    if (activity.comments != null && activity.comments!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          activity.comments!,
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _viewNotesheetDetail(activities.first.notesheetId);
            },
            child: const Text('View Notesheet'),
          ),
        ],
      ),
    );
  }

  Color _getActivityColor(ActivityType type) {
    switch (type) {
      case ActivityType.created:
        return Colors.blue;
      case ActivityType.approved:
        return Colors.green;
      case ActivityType.rejected:
        return Colors.red;
      case ActivityType.completed:
        return Colors.purple;
    }
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.created:
        return Icons.add_circle;
      case ActivityType.approved:
        return Icons.check_circle;
      case ActivityType.rejected:
        return Icons.cancel;
      case ActivityType.completed:
        return Icons.task_alt;
    }
  }

  String _getActivityDescription(NotesheetActivity activity) {
    switch (activity.activityType) {
      case ActivityType.created:
        return 'Notesheet created';
      case ActivityType.approved:
        return 'Approved by ${activity.userName}';
      case ActivityType.rejected:
        return 'Rejected by ${activity.userName}';
      case ActivityType.completed:
        return 'Notesheet completed';
    }
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Access Denied',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!.contains('PERMISSION_DENIED') 
                ? 'You don\'t have permission to view admin activities. Please contact an administrator.'
                : 'Error loading activities: $_errorMessage',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadActivities,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String selectedValue;
  final ValueChanged<String> onSelected;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.selectedValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selectedValue;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(value),
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      checkmarkColor: Theme.of(context).colorScheme.primary,
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final NotesheetActivity activity;
  final VoidCallback onTap;

  const _ActivityCard({
    required this.activity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activityColor = _getActivityColor(activity.activityType);
    final activityIcon = _getActivityIcon(activity.activityType);

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: activityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  activityIcon,
                  color: activityColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.notesheetTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getActivityDescription(activity),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'By ${activity.userName}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          DateFormat('MMM dd, HH:mm').format(activity.timestamp),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    if (activity.comments != null && activity.comments!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          activity.comments!,
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getActivityColor(ActivityType type) {
    switch (type) {
      case ActivityType.created:
        return Colors.blue;
      case ActivityType.approved:
        return Colors.green;
      case ActivityType.rejected:
        return Colors.red;
      case ActivityType.completed:
        return Colors.purple;
    }
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.created:
        return Icons.add_circle;
      case ActivityType.approved:
        return Icons.check_circle;
      case ActivityType.rejected:
        return Icons.cancel;
      case ActivityType.completed:
        return Icons.task_alt;
    }
  }

  String _getActivityDescription(NotesheetActivity activity) {
    switch (activity.activityType) {
      case ActivityType.created:
        return 'Notesheet created';
      case ActivityType.approved:
        return 'Approved';
      case ActivityType.rejected:
        return 'Rejected';
      case ActivityType.completed:
        return 'Notesheet completed';
    }
  }
}

class _GroupedActivityCard extends StatelessWidget {
  final String notesheetId;
  final String notesheetTitle;
  final List<NotesheetActivity> activities;
  final VoidCallback onTap;
  final VoidCallback onViewNotesheet;

  const _GroupedActivityCard({
    required this.notesheetId,
    required this.notesheetTitle,
    required this.activities,
    required this.onTap,
    required this.onViewNotesheet,
  });

  @override
  Widget build(BuildContext context) {
    final latestActivity = activities.first;
    final activityCount = activities.length;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      notesheetTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$activityCount activities',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Latest: ${_getActivityDescription(latestActivity)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'By ${latestActivity.userName} • ${DateFormat('MMM dd, yyyy HH:mm').format(latestActivity.timestamp)}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onTap,
                      child: const Text('View Activities'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onViewNotesheet,
                      child: const Text('View Notesheet'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getActivityDescription(NotesheetActivity activity) {
    switch (activity.activityType) {
      case ActivityType.created:
        return 'Created';
      case ActivityType.approved:
        return 'Approved by ${activity.userName}';
      case ActivityType.rejected:
        return 'Rejected by ${activity.userName}';
      case ActivityType.completed:
        return 'Completed';
    }
  }
}

// Models for activity tracking
class NotesheetActivity {
  final String id;
  final String notesheetId;
  final String notesheetTitle;
  final ActivityType activityType;
  final String userName;
  final String userId;
  final DateTime timestamp;
  final NotesheetStatus status;
  final String? comments;

  NotesheetActivity({
    required this.id,
    required this.notesheetId,
    required this.notesheetTitle,
    required this.activityType,
    required this.userName,
    required this.userId,
    required this.timestamp,
    required this.status,
    this.comments,
  });
}

enum ActivityType {
  created,
  approved,
  rejected,
  completed,
}
