// lib/services/event_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';
import '../utils/enums.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream to retrieve a list of events based on provided statuses
  // This is accessible to Proposer, Reviewer, HOD
  Stream<List<Event>> getEvents(List<EventStatus> statuses) {
    final statusNames = statuses.map((s) => s.name).toList();
    return _firestore
        .collection('events')
        .where('eventStatus', whereIn: statusNames)
        .orderBy('dateOfEvent', descending: false) // Order by date for display
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Event.fromMap(doc.data(), docId: doc.id))
              .toList(),
        );
  }

  // Method to get a single event by its ID
  Future<Event?> getEventById(String eventId) async {
    try {
      final doc = await _firestore.collection('events').doc(eventId).get();
      if (doc.exists) {
        return Event.fromMap(doc.data()!, docId: doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting event by ID: $e');
      return null;
    }
  }

  // --- Manual Event Status Updates ---

  // Method to manually update an event's status to Cancelled
  // This method would typically be called by an Admin or the event's Proposer.
  // Access control should be enforced via Firestore Security Rules.
  Future<void> cancelEvent(String eventId) async {
    try {
      await _firestore.collection('events').doc(eventId).update({
        'eventStatus': EventStatus.cancelled.name,
        // Optionally add a 'cancelledAt' timestamp or 'cancelledBy' field
      });
    } catch (e) {
      print('Error cancelling event $eventId: $e');
      throw e;
    }
  }

  // --- Automatic Event Status Checks (Client-Side, with limitations) ---

  // Private helper to check and apply status updates for a single event.
  // This is useful when loading a specific event, to ensure its status is up-to-date.
  Future<void> _checkAndApplyStatusUpdateForEvent(String eventId) async {
    try {
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (!eventDoc.exists) return;

      final event = Event.fromMap(eventDoc.data()!, docId: eventDoc.id);
      final now = DateTime.now();

      EventStatus newStatus = event.eventStatus;

      // Only check if current status is upcoming or ongoing
      if (event.eventStatus == EventStatus.upcoming) {
        // Transition from Upcoming to Ongoing
        // An event is ongoing if the current time is after its start time
        if (now.isAfter(event.startTime)) {
          newStatus = EventStatus.ongoing;
        }
      }

      if (event.eventStatus == EventStatus.ongoing) {
        // Transition from Ongoing to Occurred
        // An event has occurred if the current time is after its end time
        if (now.isAfter(event.endTime)) {
          newStatus = EventStatus.occurred;
        }
      }

      // If the status has changed, update it in Firestore
      if (newStatus != event.eventStatus) {
        await _firestore.collection('events').doc(eventId).update({
          'eventStatus': newStatus.name,
          // You might also want to add a 'lastStatusChangeAt' field to Event model
          // if you want to track when its status was last automatically updated.
        });
        print('Event $eventId status updated to ${newStatus.name}');
      }
    } catch (e) {
      print('Error checking/updating event status for $eventId: $e');
      // Do not rethrow here, as this is a background check
    }
  }

  // Public method to trigger a check for all relevant events.
  // IMPORTANT: For robust, real-time status updates (e.g., changing from ongoing to occurred
  // even when no client is active), Firebase Cloud Functions (scheduled functions) are
  // highly recommended. This client-side method is only effective when the app is active
  // and this method is explicitly called (e.g., on dashboard load).
  Future<void> checkAllEventsForStatusUpdates() async {
    try {
      // Fetch events that might need a status update (upcoming or ongoing)
      final querySnapshot = await _firestore
          .collection('events')
          .where(
            'eventStatus',
            whereIn: [EventStatus.upcoming.name, EventStatus.ongoing.name],
          )
          .get();

      for (var doc in querySnapshot.docs) {
        // Call the private helper for each event
        await _checkAndApplyStatusUpdateForEvent(doc.id);
      }
      print('Finished checking all events for status updates.');
    } catch (e) {
      print('Error checking all events for status updates: $e');
    }
  }

  Stream<List<Event>> getAllEvents() {
    return _firestore
        .collection('events')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Event.fromMap(doc.data()!, docId: doc.id))
              .toList(),
        );
  }
}
