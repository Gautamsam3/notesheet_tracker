// lib/widgets/proposed_events_list.dart
import 'package:flutter/material.dart';
import '../models/notesheet.dart'; // Import Notesheet model
import '../utils/enums.dart'; // Import NotesheetStatus enum and capitalize extension

class ProposedEventsList extends StatelessWidget {
  final List<Notesheet> notesheets; // Changed type to List<Notesheet>

  const ProposedEventsList({super.key, required this.notesheets});

  @override
  Widget build(BuildContext context) {
    if (notesheets.isEmpty) {
      return Card(
        color: Colors.grey[100],
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Text(
              'No event proposed yet.',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true, // Important for nested list views
      physics:
          const NeverScrollableScrollPhysics(), // Important for nested list views
      itemCount: notesheets.length,
      itemBuilder: (context, index) {
        final notesheet = notesheets[index];
        // Check if the event date is in the past
        final isPast = notesheet.dateOfEvent.isBefore(DateTime.now());

        return Card(
          color: isPast ? Colors.grey[300] : Colors.lightBlue[50],
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            title: Text(notesheet.title),
            subtitle: Text(
              'Date: ${notesheet.dateOfEvent.toLocal().toString().split(' ')[0]} • Venue: ${notesheet.venue}',
            ),
            trailing: Chip(
              label: Text(
                notesheet.status.name
                    .capitalize(), // Access enum name and capitalize
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: _getStatusColor(
                notesheet.status,
              ), // Pass enum directly
            ),
          ),
        );
      },
    );
  }

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
        return Colors.grey; // Fallback for any unhandled status
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
