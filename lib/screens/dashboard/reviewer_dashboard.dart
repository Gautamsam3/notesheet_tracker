import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/user_provider.dart';
import '../../services/supabase_database_service.dart';
import '../../models/notesheet_model.dart';
import '../../theme/app_theme.dart';
import '../notesheet/review_notesheet_screen.dart';
import '../notesheet/notesheet_detail_screen.dart';

class ReviewerDashboard extends StatefulWidget {
  const ReviewerDashboard({super.key});

  @override
  State<ReviewerDashboard> createState() => _ReviewerDashboardState();
}

class _ReviewerDashboardState extends State<ReviewerDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Enhanced header section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.rate_review,
                    size: 28,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Review Dashboard',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 255, 254, 254),
                          ),
                        ),
                        Text(
                          userProvider.currentUser?.isAdmin == true 
                              ? 'Admin Dashboard • All Departments'
                              : '${userProvider.currentUser?.department ?? ''} Department',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Tab selector
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey.shade600,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.pending_actions, size: 18),
                          SizedBox(width: 8),
                          Text('Pending'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 18),
                          SizedBox(width: 8),
                          Text('Reviewed'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Content section
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _PendingReviewsTab(userProvider: userProvider),
              _ReviewedNotesheetsTab(userProvider: userProvider),
            ],
          ),
        ),
      ],
    );
  }
}

class _PendingReviewsTab extends StatelessWidget {
  final UserProvider userProvider;

  const _PendingReviewsTab({required this.userProvider});

  @override
  Widget build(BuildContext context) {    final databaseService = SupabaseDatabaseService();
    
    return StreamBuilder<List<Notesheet>>(
      stream: databaseService.getNotesheetsForReviewerStream(
        userProvider.currentUser!.uid,
      ),
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
                  color:Colors.grey.shade800,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading reviews',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final notesheets = snapshot.data ?? [];

        if (notesheets.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.rate_review,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No pending reviews',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You have no notesheets waiting for your review',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
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
            return _ReviewCard(
              notesheet: notesheet,
              onTap: () => _navigateToReview(context, notesheet),
            );
          },
        );
      },
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

class _ReviewedNotesheetsTab extends StatelessWidget {
  final UserProvider userProvider;

  const _ReviewedNotesheetsTab({required this.userProvider});

  @override
  Widget build(BuildContext context) {    final databaseService = SupabaseDatabaseService();
    
    return StreamBuilder<List<Notesheet>>(
      stream: databaseService.getReviewedNotesheetsByUserStream(
        userProvider.currentUser!.uid,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          debugPrint('❌ Error in reviewed notesheets: ${snapshot.error}');
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
                  'Error loading reviewed notesheets',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString().contains('PERMISSION_DENIED')
                      ? 'You don\'t have permission to view reviewed notesheets. Please contact an administrator.'
                      : snapshot.error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Force rebuild to retry
                    (context as Element).markNeedsBuild();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final notesheets = snapshot.data ?? [];
        debugPrint('✅ Reviewed notesheets loaded: ${notesheets.length} items');

        if (notesheets.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No reviewed notesheets',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You haven\'t reviewed any notesheets yet',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
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
            return _ReviewedCard(
              notesheet: notesheet,
              userUid: userProvider.currentUser!.uid,
              onTap: () => _navigateToDetail(context, notesheet),
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
}

class _ReviewCard extends StatelessWidget {
  final Notesheet notesheet;
  final VoidCallback onTap;

  const _ReviewCard({
    required this.notesheet,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final approvedReviewers = notesheet.approvedReviewers;
    final totalReviewers = notesheet.reviewFlow.length;
    final isUrgent = notesheet.deadline != null &&
        notesheet.deadline!.isBefore(DateTime.now().add(const Duration(days: 2)));
    final isOverdue = notesheet.deadline != null &&
        notesheet.deadline!.isBefore(DateTime.now());

    final statusColor = AppTheme.getStatusColor(notesheet.status.name);
    final progressPercentage = totalReviewers > 0 ? (approvedReviewers.length / totalReviewers * 100).round() : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isUrgent ? Border.all(color: Colors.orange, width: 2) : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with title and urgency indicator
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notesheet.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color.fromARGB(255, 255, 255, 255),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isOverdue)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'OVERDUE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else if (isUrgent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'URGENT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 8),

                // Creator and created date
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'By ${notesheet.creatorName}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd/MM/yyyy').format(notesheet.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Description preview
                Text(
                  notesheet.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),

                // Progress and deadline info
                Row(
                  children: [
                    // Progress indicator
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Progress: $progressPercentage%',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '(${approvedReviewers.length}/$totalReviewers approved)',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: totalReviewers > 0 ? approvedReviewers.length / totalReviewers : 0,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Deadline info
                    if (notesheet.deadline != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 16,
                                color: isOverdue ? Colors.red : (isUrgent ? Colors.orange : Colors.grey.shade600),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Deadline',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            DateFormat('dd/MM/yyyy').format(notesheet.deadline!),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isOverdue ? Colors.red : (isUrgent ? Colors.orange : Colors.grey.shade700),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

                const SizedBox(height: 8),

                // Action button
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.rate_review, size: 18),
                    label: const Text('Review'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: const Color.fromARGB(255, 0, 0, 0),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
}

class _ReviewedCard extends StatelessWidget {
  final Notesheet notesheet;
  final String userUid;
  final VoidCallback onTap;

  const _ReviewedCard({
    required this.notesheet,
    required this.userUid,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final userReviews = notesheet.reviewFlow.where(
      (reviewer) => reviewer.uid == userUid,
    );
    
    // Safety check - if no review found, don't render the card
    if (userReviews.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final userReview = userReviews.first;

    final statusColor = userReview.status == ReviewStatus.approved
        ? Colors.green
        : Colors.red;

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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      notesheet.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color.fromARGB(255, 255, 255, 255),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      userReview.status.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                notesheet.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Reviewed on ${DateFormat('dd/MM/yyyy').format(userReview.actionDate!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              if (userReview.comments != null && userReview.comments!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.comment, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          userReview.comments!,
                          style: TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
