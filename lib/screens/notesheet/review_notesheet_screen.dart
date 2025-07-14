import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/notesheet_model.dart';
import '../../providers/user_provider.dart';
import '../../services/supabase_database_service.dart';
import '../../theme/app_theme.dart';
import 'pdf_viewer.dart';
import 'package:url_launcher/url_launcher.dart';

class ReviewNotesheetScreen extends StatefulWidget {
  final Notesheet notesheet;

  const ReviewNotesheetScreen({
    super.key,
    required this.notesheet,
  });

  @override
  State<ReviewNotesheetScreen> createState() => _ReviewNotesheetScreenState();
}

class _ReviewNotesheetScreenState extends State<ReviewNotesheetScreen> {
  final _commentsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final SupabaseDatabaseService _databaseService = SupabaseDatabaseService();
  
  bool _isLoading = false;
  ReviewStatus? _selectedAction;

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_selectedAction == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an action (Approve or Reject)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedAction == ReviewStatus.rejected && 
        _commentsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide comments when rejecting'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUser = userProvider.currentUser!;

      await _databaseService.submitReview(
        notesheetId: widget.notesheet.id,
        reviewerUid: currentUser.uid,
        status: _selectedAction!,
        comments: _commentsController.text.trim().isNotEmpty 
            ? _commentsController.text.trim() 
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedAction == ReviewStatus.approved 
                  ? 'Notesheet approved successfully!' 
                  : 'Notesheet rejected successfully!',
            ),
            backgroundColor: _selectedAction == ReviewStatus.approved 
                ? Colors.green 
                : Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('❌ Failed to submit review: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit review: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = AppTheme.getStatusColor(widget.notesheet.status.name);
    final statusIcon = AppTheme.getStatusIcon(widget.notesheet.status.name);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Notesheet'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (widget.notesheet.isEdited)
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: _showVersionHistory,
              tooltip: 'View Edit History',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Notesheet Header Card
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  statusIcon,
                                  color: statusColor,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.notesheet.title,
                                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (widget.notesheet.isEdited)
                                        Container(
                                          margin: const EdgeInsets.only(top: 4),
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.shade100,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.orange.shade300),
                                          ),
                                          child: Text(
                                            'EDITED',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.orange.shade700,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              'Status',
                              widget.notesheet.status.name.toUpperCase(),
                              statusColor,
                            ),
                            _buildInfoRow(
                              'Created by',
                              widget.notesheet.creatorName,
                              null,
                            ),
                            _buildInfoRow(
                              'Created on',
                              DateFormat('dd/MM/yyyy HH:mm').format(widget.notesheet.createdAt),
                              null,
                            ),
                            if (widget.notesheet.deadline != null)
                              _buildInfoRow(
                                'Deadline',
                                DateFormat('dd/MM/yyyy').format(widget.notesheet.deadline!),
                                _isDeadlineClose() ? Colors.red : null,
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Description Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Description',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.notesheet.description,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // PDF Attachment Card (if available)
                    if (widget.notesheet.pdfUrl != null && widget.notesheet.pdfFileName != null)
                      _buildPDFAttachmentCard(),

                    if (widget.notesheet.pdfUrl != null && widget.notesheet.pdfFileName != null)
                      const SizedBox(height: 16),

                    // Review Flow Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Review Flow',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...widget.notesheet.reviewFlow.asMap().entries.map((entry) {
                              final index = entry.key;
                              final reviewer = entry.value;
                              final isCurrentReviewer = reviewer.uid == widget.notesheet.currentReviewerUid;
                              
                              return _buildReviewerTile(reviewer, index + 1, isCurrentReviewer);
                            }).toList(),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Review Action Section
                    if (_canReview())
                      Card(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Review',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Action Selection
                              Row(
                                children: [
                                  Expanded(
                                    child: RadioListTile<ReviewStatus>(
                                      title: const Text('Approve'),
                                      value: ReviewStatus.approved,
                                      groupValue: _selectedAction,
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedAction = value;
                                        });
                                      },
                                      activeColor: Colors.green,
                                    ),
                                  ),
                                  Expanded(
                                    child: RadioListTile<ReviewStatus>(
                                      title: const Text('Reject'),
                                      value: ReviewStatus.rejected,
                                      groupValue: _selectedAction,
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedAction = value;
                                        });
                                      },
                                      activeColor: Colors.red,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Comments field
                              TextFormField(
                                controller: _commentsController,
                                decoration: InputDecoration(
                                  labelText: _selectedAction == ReviewStatus.rejected 
                                      ? 'Comments (Required for rejection)'
                                      : 'Comments (Optional)',
                                  hintText: 'Enter your review comments...',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.comment),
                                  alignLabelWithHint: true,
                                ),
                                maxLines: 4,
                                textCapitalization: TextCapitalization.sentences,
                              ),

                              const SizedBox(height: 20),

                              // Submit button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _submitReview,
                                  icon: Icon(_selectedAction == ReviewStatus.approved 
                                      ? Icons.check_circle 
                                      : Icons.cancel),
                                  label: Text(_selectedAction == ReviewStatus.approved 
                                      ? 'Approve Notesheet' 
                                      : 'Reject Notesheet'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _selectedAction == ReviewStatus.approved 
                                        ? Colors.green 
                                        : Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Card(
                        color: Colors.grey.shade100,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _getReviewStatusMessage(),
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color? valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: valueColor,
                fontWeight: valueColor != null ? FontWeight.w600 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewerTile(Reviewer reviewer, int step, bool isCurrentReviewer) {
    Color? tileColor;
    IconData icon;
    Color iconColor;

    switch (reviewer.status) {
      case ReviewStatus.approved:
        icon = Icons.check_circle;
        iconColor = Colors.green;
        tileColor = Colors.green.shade50;
        break;
      case ReviewStatus.rejected:
        icon = Icons.cancel;
        iconColor = Colors.red;
        tileColor = Colors.red.shade50;
        break;
      case ReviewStatus.pending:
        if (isCurrentReviewer) {
          icon = Icons.pending;
          iconColor = Colors.orange;
          tileColor = Colors.orange.shade50;
        } else {
          icon = Icons.radio_button_unchecked;
          iconColor = Colors.grey;
          tileColor = null;
        }
        break;
      default:
        icon = Icons.radio_button_unchecked;
        iconColor = Colors.grey;
        tileColor = null;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        color: tileColor ?? Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: isCurrentReviewer 
            ? Border.all(color: Colors.orange, width: 2)
            : Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: isCurrentReviewer ? Colors.orange : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$step',
                  style: TextStyle(
                    color: isCurrentReviewer ? Colors.white : Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, color: iconColor),
          ],
        ),
        title: Text(
          reviewer.name,
          style: TextStyle(
            fontWeight: isCurrentReviewer ? FontWeight.bold : FontWeight.normal,
            color: Colors.grey.shade800, // Darker text for visibility
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              reviewer.status.name.toUpperCase(),
              style: TextStyle(
                color: Colors.grey.shade700, // Darker text for visibility
              ),
            ),
            if (reviewer.actionDate != null)
              Text(
                'Reviewed on ${DateFormat('dd/MM/yyyy HH:mm').format(reviewer.actionDate!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600, // Darker text for visibility
                ),
              ),
            if (reviewer.comments != null && reviewer.comments!.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  reviewer.comments!,
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade800, // Darker text for visibility
                  ),
                ),
              ),
          ],
        ),
        trailing: isCurrentReviewer 
            ? const Icon(Icons.arrow_forward, color: Colors.orange)
            : null,
      ),
    );
  }

  bool _canReview() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;
    
    if (currentUser == null) return false;
    
    // Check if this notesheet is already completed or rejected
    if (widget.notesheet.isCompleted || widget.notesheet.isRejected) {
      return false;
    }
    
    // Check if current user is the current reviewer
    return widget.notesheet.currentReviewerUid == currentUser.uid;
  }

  String _getReviewStatusMessage() {
    if (widget.notesheet.isCompleted) {
      return 'This notesheet has been approved by all reviewers.';
    }
    
    if (widget.notesheet.isRejected) {
      return 'This notesheet has been rejected.';
    }
    
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;
    
    if (currentUser != null && widget.notesheet.currentReviewerUid != currentUser.uid) {
      final currentReviewer = widget.notesheet.reviewFlow
          .firstWhere((r) => r.uid == widget.notesheet.currentReviewerUid);
      return 'Waiting for review from ${currentReviewer.name}.';
    }
    
    return 'You cannot review this notesheet at this time.';
  }

  bool _isDeadlineClose() {
    if (widget.notesheet.deadline == null) return false;
    final now = DateTime.now();
    final deadline = widget.notesheet.deadline!;
    final difference = deadline.difference(now).inDays;
    return difference <= 2 && difference >= 0; // Within 2 days
  }

  void _showVersionHistory() async {
    try {
      final versions = await _databaseService.getNotesheetVersions(widget.notesheet.id);
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Edit History'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView(
              children: [
                // Current version
                _buildVersionCard(
                  version: 'Current Version',
                  date: widget.notesheet.updatedAt ?? widget.notesheet.createdAt,
                  title: widget.notesheet.title,
                  description: widget.notesheet.description,
                  isCurrent: true,
                ),
                // Previous versions
                ...versions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final versionData = entry.value;
                  return _buildVersionCard(
                    version: index == versions.length - 1 ? 'Original' : 'Version ${versions.length - index}',
                    date: versionData.updatedAt ?? versionData.createdAt,
                    title: versionData.title,
                    description: versionData.description,
                    isCurrent: false,
                  );
                }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading version history: $e')),
        );
      }
    }
  }

  Widget _buildVersionCard({
    required String version,
    required DateTime date,
    required String title,
    required String description,
    required bool isCurrent,
  }) {
    final color = isCurrent ? Colors.green : Colors.blue;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isCurrent ? Icons.check_circle : Icons.history,
                  color: color,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  version,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('MMM dd, HH:mm').format(date),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Title: $title',
              style: const TextStyle(fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'Description: $description',
              style: TextStyle(color: Colors.grey.shade700),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPDFAttachmentCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.picture_as_pdf,
                  color: Colors.red.shade600,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Attached Document',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800, // Darker text for visibility
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.picture_as_pdf,
                    color: Colors.red.shade600,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.notesheet.pdfFileName!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade800, // Darker text for visibility
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      _showPDFDialog();
                    },
                    icon: const Icon(Icons.visibility),
                    label: const Text('View'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPDFDialog() {
    if (widget.notesheet.pdfUrl == null) {
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,  // Lighter background for better text visibility
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.picture_as_pdf,
                      color: Colors.grey.shade800,  // Darker icon for visibility
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.notesheet.pdfFileName!,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey.shade800,  // Darker text for visibility
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Open in browser button
                    IconButton(
                      onPressed: () => _launchURL(widget.notesheet.pdfUrl!),
                      icon: Icon(
                        Icons.open_in_new,
                        color: Colors.grey.shade800,
                      ),
                      tooltip: 'Open in browser',
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              // PDF Viewer
              Expanded(
                child: PDFViewer(
                  url: widget.notesheet.pdfUrl!,
                  viewId: viewId,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
}
