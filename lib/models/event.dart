// lib/models/event.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/enums.dart';

class Event {
  final String id; // Matches the notesheetId for direct mapping
  final String notesheetId; // Redundant but good for clarity/querying
  final String title;
  final String proposerId;
  final String organizerName;
  final DateTime dateOfEvent;
  final DateTime startTime;
  final DateTime endTime;
  final String modeOfEvent;
  final String typeOfEvent;
  final String description;
  final String venue;
  final int audienceSize;
  final String audienceType;
  final double estimatedBudget;
  final String fundSource;
  final String resourcesRequested;
  final String additionalNote;

  final EventStatus eventStatus; // Dynamic: upcoming, ongoing, occurred
  final DateTime
  createdAt; // When the event object was created (notesheet approved)

  const Event({
    required this.id, // <--- THIS MUST BE HERE AND BE A NAMED PARAMETER
    required this.notesheetId,
    required this.title,
    required this.proposerId,
    required this.organizerName,
    required this.dateOfEvent,
    required this.startTime,
    required this.endTime,
    required this.modeOfEvent,
    required this.typeOfEvent,
    required this.description,
    required this.venue,
    required this.audienceSize,
    required this.audienceType,
    required this.estimatedBudget,
    required this.fundSource,
    required this.resourcesRequested,
    required this.additionalNote,
    required this.eventStatus,
    required this.createdAt,
  });

  // Factory constructor to create an Event from a Firestore document
  factory Event.fromMap(Map<String, dynamic> map, {String? docId}) {
    return Event(
      id: docId ?? map['id'] as String, // Use provided docId or map's id
      notesheetId: map['notesheetId'] as String,
      title: map['title'] as String,
      proposerId: map['proposerId'] as String,
      organizerName: map['organizerName'] as String,
      dateOfEvent: (map['dateOfEvent'] as Timestamp).toDate(),
      startTime: (map['startTime'] as Timestamp).toDate(),
      endTime: (map['endTime'] as Timestamp).toDate(),
      modeOfEvent: map['modeOfEvent'] as String,
      typeOfEvent: map['typeOfEvent'] as String,
      description: map['description'] as String,
      venue: map['venue'] as String,
      audienceSize: map['audienceSize'] as int,
      audienceType: map['audienceType'] as String,
      estimatedBudget: (map['estimatedBudget'] as num).toDouble(),
      fundSource: map['fundSource'] as String,
      resourcesRequested: map['resourcesRequested'] as String,
      additionalNote: map['additionalNote'] as String,
      eventStatus: EventStatus.values.firstWhere(
        (e) => e.name == map['eventStatus'],
        orElse: () => EventStatus.upcoming, // Default if not found
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  // Method to convert an Event object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'notesheetId': notesheetId,
      'title': title,
      'proposerId': proposerId,
      'organizerName': organizerName,
      'dateOfEvent': Timestamp.fromDate(dateOfEvent),
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'modeOfEvent': modeOfEvent,
      'typeOfEvent': typeOfEvent,
      'description': description,
      'venue': venue,
      'audienceSize': audienceSize,
      'audienceType': audienceType,
      'estimatedBudget': estimatedBudget,
      'fundSource': fundSource,
      'resourcesRequested': resourcesRequested,
      'additionalNote': additionalNote,
      'eventStatus': eventStatus.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Optional: For updating specific fields like eventStatus
  Event copyWith({EventStatus? eventStatus}) {
    return Event(
      id: id,
      notesheetId: notesheetId,
      title: title,
      proposerId: proposerId,
      organizerName: organizerName,
      dateOfEvent: dateOfEvent,
      startTime: startTime,
      endTime: endTime,
      modeOfEvent: modeOfEvent,
      typeOfEvent: typeOfEvent,
      description: description,
      venue: venue,
      audienceSize: audienceSize,
      audienceType: audienceType,
      estimatedBudget: estimatedBudget,
      fundSource: fundSource,
      resourcesRequested: resourcesRequested,
      additionalNote: additionalNote,
      eventStatus: eventStatus ?? this.eventStatus,
      createdAt: createdAt,
    );
  }
}
