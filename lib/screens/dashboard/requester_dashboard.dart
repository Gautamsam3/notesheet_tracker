import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/user_provider.dart';
import '../../services/supabase_database_service.dart';
import '../../models/notesheet_model.dart';
import '../../theme/app_theme.dart';
import '../notesheet/create_notesheet_screen.dart';
import '../notesheet/notesheet_detail_screen.dart';

class RequesterDashboard extends StatelessWidget {
  const RequesterDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final databaseService = SupabaseDatabaseService();

    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<Notesheet>>(
            stream: databaseService.getNotesheetsByCreatorStream(
              userProvider.currentUser!.uid,
            ),
            builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  debugPrint('🔐❌ Error loading notesheets: ${snapshot.error}');
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
                          'Error loading notesheets',
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

                final notesheets = snapshot.data ?? [];

                if (notesheets.isEmpty) {
                  debugPrint('🔐 No notesheets found for user: ${userProvider.currentUser?.uid}');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.description,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No notesheets yet',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create your first notesheet to get started',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => _navigateToCreateNotesheet(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Create Notesheet'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notesheets.length,
                  itemBuilder: (context, index) {
                    final notesheet = notesheets[index];
                    return _NotesheetCard(
                      notesheet: notesheet,
                      onTap: () => _navigateToNotesheetDetail(context, notesheet),
                    );
                  },
                );
              },
          ),
        ),
      ],
    );
  }

  void _navigateToCreateNotesheet(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateNotesheetScreen(),
      ),
    );
  }

  void _navigateToNotesheetDetail(BuildContext context, Notesheet notesheet) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NotesheetDetailScreen(notesheet: notesheet),
      ),
    );
  }
}

class _NotesheetCard extends StatelessWidget {
  final Notesheet notesheet;
  final VoidCallback onTap;

  const _NotesheetCard({
    required this.notesheet,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = AppTheme.getStatusColor(notesheet.status.name);
    final statusIcon = AppTheme.getStatusIcon(notesheet.status.name);
    final approvedCount = notesheet.approvedReviewers.length;
    final totalReviewers = notesheet.reviewFlow.length;
    final progressPercentage = totalReviewers > 0 ? (approvedCount / totalReviewers * 100).round() : 0;
    
    final isOverdue = notesheet.deadline != null && notesheet.deadline!.isBefore(DateTime.now());
    final isUrgent = notesheet.deadline != null && 
        notesheet.deadline!.isBefore(DateTime.now().add(const Duration(days: 2))) &&
        !isOverdue;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isOverdue 
                ? Border.all(color: Colors.red, width: 2) 
                : isUrgent 
                    ? Border.all(color: Colors.orange, width: 2) 
                    : null,
          ),
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
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                statusIcon,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                notesheet.status.name.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isOverdue || isUrgent) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isOverdue ? Colors.red : Colors.orange,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isOverdue ? 'OVERDUE' : 'URGENT',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Description
                Text(
                  notesheet.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),

                // Created date and deadline
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Created: ${DateFormat('dd/MM/yyyy').format(notesheet.createdAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (notesheet.deadline != null) ...[
                      const SizedBox(width: 16),
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: isOverdue ? Colors.red : (isUrgent ? Colors.orange : Colors.grey.shade600),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Deadline: ${DateFormat('dd/MM/yyyy').format(notesheet.deadline!)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isOverdue ? Colors.red : (isUrgent ? Colors.orange : Colors.grey.shade600),
                          fontWeight: (isOverdue || isUrgent) ? FontWeight.w600 : null,
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 12),

                // Progress section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Review Progress: $progressPercentage%',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '($approvedCount/$totalReviewers approved)',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const Spacer(),
                        // Current reviewer info
                        if (notesheet.currentReviewerUid != null && !notesheet.isCompleted && !notesheet.isRejected)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'With ${_getCurrentReviewerName()}',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: totalReviewers > 0 ? approvedCount / totalReviewers : 0,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Action button
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View Details'),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getCurrentReviewerName() {
    if (notesheet.currentReviewerUid == null) return 'Unknown';
    
    try {
      final currentReviewer = notesheet.reviewFlow
          .firstWhere((reviewer) => reviewer.uid == notesheet.currentReviewerUid);
      return currentReviewer.name;
    } catch (e) {
      return 'Unknown';
    }
  }
}
