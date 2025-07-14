import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/notesheet_model.dart';
import '../../providers/user_provider.dart';
import '../../services/supabase_database_service.dart';
import '../../theme/app_theme.dart';
import 'review_notesheet_screen.dart';
import 'edit_notesheet_screen.dart';
import 'pdf_viewer.dart';

class NotesheetDetailScreen extends StatefulWidget {
  final Notesheet notesheet;

  const NotesheetDetailScreen({
    super.key,
    required this.notesheet,
  });

  @override
  State<NotesheetDetailScreen> createState() => _NotesheetDetailScreenState();
}

class _NotesheetDetailScreenState extends State<NotesheetDetailScreen> {
  final SupabaseDatabaseService _databaseService = SupabaseDatabaseService();
  late Stream<Notesheet?> _notesheetStream;

  @override
  void initState() {
    super.initState();
    // Create a stream to get real-time updates of the notesheet
    _notesheetStream = Stream.periodic(const Duration(seconds: 2))
        .asyncMap((_) => _databaseService.getNotesheetById(widget.notesheet.id));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Notesheet?>(
      stream: _notesheetStream,
      initialData: widget.notesheet,
      builder: (context, snapshot) {
        final notesheet = snapshot.data ?? widget.notesheet;
        final statusColor = AppTheme.getStatusColor(notesheet.status.name);
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final isRequester = userProvider.currentUser?.uid == notesheet.creatorUid;

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          body: CustomScrollView(
            slivers: [
              // Modern App Bar
              SliverAppBar(
                expandedHeight: 160,
                floating: false,
                pinned: true,
                backgroundColor: statusColor,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    notesheet.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 2,
                          color: Colors.black45,
                        ),
                      ],
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          statusColor,
                          statusColor.withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Subtle pattern overlay
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                            ),
                          ),
                        ),
                        // Status indicator
                        Positioned(
                          top: 80,
                          right: 16,
                          child: _buildStatusChip(notesheet.status, statusColor),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  if (isRequester && _canEdit(notesheet))
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: () => _navigateToEdit(notesheet),
                        tooltip: 'Edit Notesheet',
                      ),
                    ),
                  if (_canReview(notesheet))
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.rate_review, color: Colors.white),
                        onPressed: () => _navigateToReview(notesheet),
                        tooltip: 'Review Notesheet',
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: () => setState(() {
                      _notesheetStream = Stream.periodic(const Duration(seconds: 2))
                          .asyncMap((_) => _databaseService.getNotesheetById(widget.notesheet.id));
                    }),
                    tooltip: 'Refresh',
                  ),
                ],
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Quick overview cards
                      _buildOverviewCards(notesheet, isRequester),
                      
                      const SizedBox(height: 20),
                      
                      // Description section
                      _buildDescriptionCard(notesheet),
                      
                      const SizedBox(height: 20),
                      
                      // PDF Attachment section (if available)
                      if (notesheet.pdfUrl != null && notesheet.pdfFileName != null)
                        _buildPDFAttachmentCard(notesheet),
                      
                      if (notesheet.pdfUrl != null && notesheet.pdfFileName != null)
                        const SizedBox(height: 20),
                      
                      // Review progress section
                      _buildReviewTimelineCard(notesheet),
                      
                      const SizedBox(height: 20),
                      
                      // Action buttons
                      _buildActionButtons(notesheet, isRequester),
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(NotesheetStatus status, Color color) {
    IconData icon;
    switch (status) {
      case NotesheetStatus.pending:
        icon = Icons.pending_actions;
        break;
      case NotesheetStatus.approved:
        icon = Icons.check_circle;
        break;
      case NotesheetStatus.rejected:
        icon = Icons.cancel;
        break;
      case NotesheetStatus.completed:
        icon = Icons.task_alt;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            status.name.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCards(Notesheet notesheet, bool isRequester) {
    final isOverdue = notesheet.deadline != null && notesheet.deadline!.isBefore(DateTime.now());
    final isUrgent = notesheet.deadline != null && 
        notesheet.deadline!.isBefore(DateTime.now().add(const Duration(days: 2))) &&
        !isOverdue;

    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            icon: Icons.person_outline,
            title: 'Creator',
            value: notesheet.creatorName,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(
            icon: Icons.calendar_today,
            title: 'Created',
            value: DateFormat('dd/MM/yy').format(notesheet.createdAt),
            color: Colors.green,
          ),
        ),
        if (notesheet.deadline != null) ...[
          const SizedBox(width: 12),
          Expanded(
            child: _buildInfoCard(
              icon: Icons.schedule,
              title: 'Deadline',
              value: DateFormat('dd/MM/yy').format(notesheet.deadline!),
              color: isOverdue ? Colors.red : (isUrgent ? Colors.orange : Colors.purple),
              subtitle: _getDeadlineStatus(notesheet),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDescriptionCard(Notesheet notesheet) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.description,
                  color: Colors.blue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            notesheet.description,
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPDFAttachmentCard(Notesheet notesheet) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.picture_as_pdf,
                    color: Colors.red.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Attached Document',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notesheet.pdfFileName!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.red.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _showPDFDialog(notesheet);
                  },
                  icon: const Icon(Icons.visibility),
                  label: const Text('View PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPDFDialog(Notesheet notesheet) {
    print('PDF URL: ${notesheet.pdfUrl}'); // Debug log
    
    if (notesheet.pdfUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF URL not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final String viewId = 'pdf-view-${DateTime.now().millisecondsSinceEpoch}';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              // Header with close button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.picture_as_pdf,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        notesheet.pdfFileName!,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Open in browser button
                    IconButton(
                      onPressed: () => _launchURL(notesheet.pdfUrl!),
                      icon: Icon(
                        Icons.open_in_new,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      tooltip: 'Open in browser',
                    ),
                    // Copy URL button
                    IconButton(
                      onPressed: () => _copyPdfUrl(notesheet.pdfUrl!),
                      icon: Icon(
                        Icons.copy,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      tooltip: 'Copy PDF URL',
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              // PDF Viewer
              Expanded(
                child: PDFViewer(
                  url: notesheet.pdfUrl!,
                  viewId: viewId,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyPdfUrl(String url) async {
    try {
      await Clipboard.setData(ClipboardData(text: url));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF URL copied to clipboard'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error copying URL: $e');
    }
  }

  Future<void> _launchURL(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open URL: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildReviewTimelineCard(Notesheet notesheet) {
    final approvedCount = notesheet.approvedReviewers.length;
    final totalReviewers = notesheet.reviewFlow.length;
    final progress = totalReviewers > 0 ? approvedCount / totalReviewers : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.timeline,
                  color: Colors.purple,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                'Review Progress',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(progress * 100).round()}%',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Modern progress indicator
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: notesheet.isRejected ? Colors.red : Colors.green,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Reviewer steps
          ...notesheet.reviewFlow.asMap().entries.map((entry) {
            final index = entry.key;
            final reviewer = entry.value;
            final isCurrentReviewer = reviewer.uid == notesheet.currentReviewerUid;
            final isLastReviewer = index == notesheet.reviewFlow.length - 1;
            
            return Column(
              children: [
                _buildModernReviewerStep(reviewer, index + 1, isCurrentReviewer),
                if (!isLastReviewer) const SizedBox(height: 12),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildModernReviewerStep(Reviewer reviewer, int step, bool isCurrentReviewer) {
    Color stepColor;
    Color? backgroundColor;

    switch (reviewer.status) {
      case ReviewStatus.approved:
        stepColor = Colors.green;
        backgroundColor = Colors.green.shade50;
        break;
      case ReviewStatus.rejected:
        stepColor = Colors.red;
        backgroundColor = Colors.red.shade50;
        break;
      case ReviewStatus.pending:
        if (isCurrentReviewer) {
          stepColor = Colors.orange;
          backgroundColor = Colors.orange.shade50;
        } else {
          stepColor = Colors.grey.shade400;
          backgroundColor = null;
        }
        break;
      default:
        stepColor = Colors.grey.shade400;
        backgroundColor = null;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentReviewer 
            ? Border.all(color: stepColor, width: 2)
            : Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: stepColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$step',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      reviewer.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: isCurrentReviewer ? stepColor : Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: stepColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        reviewer.status.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          color: stepColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (reviewer.actionDate != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(reviewer.actionDate!),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
                if (reviewer.comments != null && reviewer.comments!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.format_quote,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            reviewer.comments!,
                            style: const TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isCurrentReviewer)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: stepColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.arrow_forward,
                color: Colors.white,
                size: 14,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Notesheet notesheet, bool isRequester) {
    final canReview = _canReview(notesheet);
    
    return Column(
      children: [
        // Review button (for reviewers and admins)
        if (canReview)
          Container(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => _navigateToReview(notesheet),
              icon: const Icon(Icons.rate_review, size: 20),
              label: const Text(
                'Review This Notesheet',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
        
        // Additional actions for requesters
        if (isRequester && notesheet.status == NotesheetStatus.pending) ...[
          if (canReview) const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _navigateToEdit(notesheet),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    side: const BorderSide(color: Colors.blue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _deleteNotesheet(notesheet),
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.grey.shade800,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _canReview(Notesheet notesheet) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;
    
    if (currentUser == null) return false;
    
    // Check if this notesheet is already completed or rejected
    if (notesheet.isCompleted || notesheet.isRejected) {
      return false;
    }
    
    // Check if current user is the current reviewer OR an admin
    return notesheet.currentReviewerUid == currentUser.uid || currentUser.isAdmin;
  }

  void _navigateToReview(Notesheet notesheet) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReviewNotesheetScreen(notesheet: notesheet),
      ),
    );
  }

  bool _canEdit(Notesheet notesheet) {
    // Can edit if:
    // 1. Not completed 
    // 2. Not rejected (or allow resubmission of rejected ones)
    return !notesheet.isCompleted;
  }

  void _navigateToEdit(Notesheet notesheet) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditNotesheetScreen(notesheet: notesheet),
      ),
    ).then((edited) {
      if (edited == true) {
        // Refresh the notesheet data if it was edited
        setState(() {
          _notesheetStream = Stream.periodic(const Duration(seconds: 2))
              .asyncMap((_) => _databaseService.getNotesheetById(widget.notesheet.id));
        });
      }
    });
  }

  void _deleteNotesheet(Notesheet notesheet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notesheet'),
        content: const Text('Are you sure you want to delete this notesheet? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await _databaseService.deleteNotesheet(notesheet.id);
                if (mounted) {
                  Navigator.of(context).pop(); // Go back to previous screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notesheet deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting notesheet: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _getDeadlineStatus(Notesheet notesheet) {
    if (notesheet.deadline == null) return '';
    
    final now = DateTime.now();
    final deadline = notesheet.deadline!;
    final difference = deadline.difference(now).inDays;
    
    if (difference < 0) {
      return 'Overdue by ${-difference} day(s)';
    } else if (difference == 0) {
      return 'Due today';
    } else if (difference <= 2) {
      return 'Due in $difference day(s)';
    } else {
      return 'Due in $difference day(s)';
    }
  }
}
