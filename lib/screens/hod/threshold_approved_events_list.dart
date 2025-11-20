// lib/screens/hod/threshold_approved_events_list.dart
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For current user ID (if needed for future rules)
import '../../models/notesheet.dart'; // Import Notesheet model
import '../../services/notesheet_service.dart'; // Import NotesheetService for HOD actions
import '../../services/auth_service.dart'; // Import AuthService (for current user)
import '../../utils/enums.dart'; // For NotesheetStatus enum and capitalize extension
import '../hod/suggest_edit_form_dialog.dart'; // Import the dialog
import '../../utils/locator.dart';

class ThresholdApprovedEventsList extends StatefulWidget {
  final List<Notesheet> notesheets; // Changed type to List<Notesheet>

  const ThresholdApprovedEventsList({super.key, required this.notesheets});

  @override
  State<ThresholdApprovedEventsList> createState() =>
      _ThresholdApprovedEventsListState();
}

class _ThresholdApprovedEventsListState
    extends State<ThresholdApprovedEventsList> {
  final NotesheetService _notesheetService = locator<NotesheetService>();
  final AuthService _authService = locator<AuthService>();

  String? _currentHodId; // To store the HOD's UID

  @override
  void initState() {
    super.initState();
    _currentHodId = _authService.getCurrentFirebaseUser()?.uid;
  }

  // --- HOD Specific Actions Dialog ---
  void _showNotesheetApprovalDetails(
    BuildContext context,
    Notesheet notesheet,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        // Use dialogContext to avoid issues with parent context
        return AlertDialog(
          title: Text('Review Notesheet: ${notesheet.title}'),
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
                Text("Resources Requested: ${notesheet.resourcesRequested}"),
                Text("Additional Note: ${notesheet.additionalNote}"),
                const SizedBox(height: 16),
                Text("Current Approval Count: ${notesheet.approvalCount}"),
                const SizedBox(height: 16),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _notesheetService.approveNotesheet(notesheet.id!);
                  if (mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Notesheet approved and event created!"),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to approve notesheet: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text("Approve"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _notesheetService.rejectNotesheet(notesheet.id!);
                  if (mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Notesheet rejected.")),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to reject notesheet: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text("Reject"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Open the SuggestEditFormDialog, passing the Notesheet object
                Navigator.pop(dialogContext); // Close current dialog first
                _openSuggestionForm(context, notesheet);
              },
              child: const Text("Suggest Changes"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  void _openSuggestionForm(BuildContext context, Notesheet notesheet) {
    showDialog(
      context: context,
      builder: (context) => SuggestEditFormDialog(
        initialNotesheet: notesheet,
      ), // Pass Notesheet object
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.notesheets.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 32.0),
        child: Center(child: Text("No notesheets awaiting your approval.")),
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notesheet.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text("Proposer: ${notesheet.organizerName}"),
                      Text(
                        "Date: ${notesheet.dateOfEvent.toLocal().toString().split(' ')[0]}",
                      ),
                      Text("Venue: ${notesheet.venue}"),
                      Text("Approval Count: ${notesheet.approvalCount}"),
                      Text("Status: ${notesheet.status.name.capitalize()}"),
                    ],
                  ),
                ),

                // Buttons: Review (which opens details), Approve, Reject, Suggest Edits
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: () =>
                          _showNotesheetApprovalDetails(context, notesheet),
                      child: const Text('Review'),
                    ),
                    const SizedBox(height: 8),
                    // Removed direct Approve/Reject/Suggest buttons here to avoid redundancy with the dialog
                    // The dialog handles these actions after showing full details.
                  ],
                ),
              ],
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
      case NotesheetStatus.underConsideration:
      case NotesheetStatus.pendingApproval:
      case NotesheetStatus.awaitingProposerResponse:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

// Extension to capitalize enum names for display (ensure this is available)
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return '';
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
