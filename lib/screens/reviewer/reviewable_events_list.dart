// lib/screens/reviewer/reviewable_events_list.dart
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For current user ID
import '../../models/notesheet.dart'; // Import Notesheet model
import '../../services/notesheet_service.dart'; // Import NotesheetService
import '../../services/auth_service.dart'; // Import AuthService for current user
import '../../utils/enums.dart'; // For capitalize extension and NotesheetStatus
import '../../utils/locator.dart'; // For capitalize extension and NotesheetStatus

class ReviewableEventsList extends StatefulWidget {
  final List<Notesheet> notesheets; // Changed type to List<Notesheet>

  const ReviewableEventsList({super.key, required this.notesheets});

  @override
  State<ReviewableEventsList> createState() => _ReviewableEventsListState();
}

class _ReviewableEventsListState extends State<ReviewableEventsList> {
  final NotesheetService _notesheetService = locator<NotesheetService>();
  final AuthService _authService = locator<AuthService>();

  String? _currentReviewerId;

  @override
  void initState() {
    super.initState();
    _currentReviewerId = _authService.getCurrentFirebaseUser()?.uid;
  }

  void _showEventDetails(BuildContext context, Notesheet notesheet) {
    final TextEditingController commentController = TextEditingController();
    bool isSuggestingChanges = false; // To toggle UI for suggestion

    showDialog(
      context: context,
      builder: (dialogContext) {
        // Use dialogContext to avoid issues with parent context
        return StatefulBuilder(
          // Use StatefulBuilder to update dialog UI
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text(notesheet.title),
              content: SingleChildScrollView(
                // Allow content to scroll
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Proposer: ${notesheet.organizerName}"),
                    Text(
                      "Date: ${notesheet.dateOfEvent.toLocal().toString().split(' ')[0]}",
                    ),
                    Text(
                      "Time: ${notesheet.startTime.toLocal().hour}:${notesheet.startTime.toLocal().minute} - ${notesheet.endTime.toLocal().hour}:${notesheet.endTime.toLocal().minute}",
                    ),
                    Text("Venue: ${notesheet.venue}"),
                    Text("Description: ${notesheet.description}"),
                    Text("Audience Size: ${notesheet.audienceSize}"),
                    Text("Audience Type: ${notesheet.audienceType}"),
                    Text(
                      "Estimated Budget: ₹${notesheet.estimatedBudget.toStringAsFixed(2)}",
                    ),
                    Text("Fund Source: ${notesheet.fundSource}"),
                    Text(
                      "Resources Requested: ${notesheet.resourcesRequested}",
                    ),
                    Text("Additional Note: ${notesheet.additionalNote}"),
                    const SizedBox(height: 16),
                    if (notesheet.approvedBy.contains(_currentReviewerId))
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          'You have already reviewed this notesheet.',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const Text(
                      "Your Comment (Optional for Accept, Required for Suggest Changes):",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextField(
                      controller: commentController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: "Enter your review or comment",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: notesheet.approvedBy.contains(_currentReviewerId)
                      ? null // Disable if already reviewed
                      : () async {
                          if (_currentReviewerId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Error: Reviewer ID not found. Please log in.',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          try {
                            await _notesheetService.reviewNotesheetAccept(
                              notesheet.id!,
                              _currentReviewerId!,
                              reviewDescription:
                                  commentController.text.trim().isNotEmpty
                                  ? commentController.text.trim()
                                  : null,
                            );
                            if (mounted) {
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Notesheet accepted successfully!",
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Failed to accept notesheet: $e',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  child: const Text("Accept"),
                ),
                ElevatedButton(
                  onPressed: notesheet.approvedBy.contains(_currentReviewerId)
                      ? null // Disable if already reviewed
                      : () async {
                          if (_currentReviewerId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Error: Reviewer ID not found. Please log in.',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          if (commentController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Comment is required to suggest changes.',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          try {
                            await _notesheetService.reviewSuggestChanges(
                              notesheet.id!,
                              _currentReviewerId!,
                              commentController.text.trim(),
                            );
                            if (mounted) {
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Suggestions submitted successfully!",
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Failed to submit suggestions: $e',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  child: const Text("Suggest Changes"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.notesheets.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 32.0),
        child: Center(child: Text("No notesheets to review.")),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.notesheets.length,
      itemBuilder: (context, index) {
        final notesheet = widget.notesheets[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListTile(
            title: Text(notesheet.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Proposer: ${notesheet.organizerName}"),
                Text(
                  "Date: ${notesheet.dateOfEvent.toLocal().toString().split(' ')[0]}",
                ),
                Text("Status: ${notesheet.status.name.capitalize()}"),
              ],
            ),
            trailing: ElevatedButton(
              onPressed: () => _showEventDetails(context, notesheet),
              child: const Text("Review Form"),
            ),
          ),
        );
      },
    );
  }

  // Helper function to get color based on status
  Color _getStatusColor(NotesheetStatus status) {
    switch (status) {
      case NotesheetStatus.approved:
        return Colors.green;
      case NotesheetStatus.rejected:
      case NotesheetStatus.rejectedWithSuggestions:
      case NotesheetStatus.expiredDueToApproval:
      case NotesheetStatus.expiredDueToReviews:
        return Colors.red;
      case NotesheetStatus.pendingApproval:
      case NotesheetStatus.underConsideration:
      case NotesheetStatus.awaitingProposerResponse:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

// Extension to capitalize enum names for display (ensure this is available,
// either here or in utils/enums.dart or a common place)
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return '';
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
