// lib/models/notesheet.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/enums.dart';

class Notesheet {
  final String?
  id; // Nullable for new notesheets before they have a Firestore ID
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

  // Dynamic fields
  final NotesheetStatus status;
  final int approvalCount;
  final List<String> approvedBy; // List of reviewer IDs who approved

  // For 'suggestedChanges' workflow
  final String? hodSuggestedChangesNotesheetId; // Links to the "sudo" notesheet
  final String?
  originalNotesheetId; // For "sudo" notesheets, links back to original

  final DateTime createdAt; // When the notesheet was initially created
  final DateTime lastStatusChangeAt; // Timestamp when the status last changed

  const Notesheet({
    this.id,
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
    this.status = NotesheetStatus.underConsideration, // Default status
    this.approvalCount = 0, // Default approval count
    this.approvedBy = const [], // Default empty list
    this.hodSuggestedChangesNotesheetId,
    this.originalNotesheetId,
    required this.createdAt,
    required this.lastStatusChangeAt,
  });

  // Factory constructor to create a Notesheet from a Firestore document
  factory Notesheet.fromMap(Map<String, dynamic> map, {String? docId}) {
    return Notesheet(
      id: docId ?? map['id'] as String?, // Use provided docId or map's id
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
      estimatedBudget: (map['estimatedBudget'] as num)
          .toDouble(), // Handle int/double
      fundSource: map['fundSource'] as String,
      resourcesRequested: map['resourcesRequested'] as String,
      additionalNote: map['additionalNote'] as String,
      status: NotesheetStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => NotesheetStatus.underConsideration,
      ),
      approvalCount: map['approvalCount'] as int,
      approvedBy: List<String>.from(map['approvedBy'] ?? []), // Handle null
      hodSuggestedChangesNotesheetId:
          map['hodSuggestedChangesNotesheetId'] as String?,
      originalNotesheetId: map['originalNotesheetId'] as String?,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastStatusChangeAt: (map['lastStatusChangeAt'] as Timestamp).toDate(),
    );
  }

  // Method to convert a Notesheet object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
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
      'status': status.name,
      'approvalCount': approvalCount,
      'approvedBy': approvedBy,
      'hodSuggestedChangesNotesheetId': hodSuggestedChangesNotesheetId,
      'originalNotesheetId': originalNotesheetId,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastStatusChangeAt': Timestamp.fromDate(lastStatusChangeAt),
    };
  }

  // Optional: For updating specific fields
  Notesheet copyWith({
    String? id, // <-- NEW: Added as named parameter
    NotesheetStatus? status,
    int? approvalCount,
    List<String>? approvedBy,
    String? hodSuggestedChangesNotesheetId,
    String? originalNotesheetId,
    String? title,
    String? organizerName,
    DateTime? dateOfEvent,
    DateTime? startTime,
    DateTime? endTime,
    String? modeOfEvent,
    String? typeOfEvent,
    String? description,
    String? venue,
    int? audienceSize,
    String? audienceType,
    double? estimatedBudget,
    String? fundSource,
    String? resourcesRequested,
    String? additionalNote,
    DateTime? createdAt, // <-- NEW: Added as named parameter
    DateTime? lastStatusChangeAt,
  }) {
    return Notesheet(
      id: id ?? this.id, // <-- NEW: Use provided id or current id
      title: title ?? this.title,
      proposerId: proposerId, // Proposer ID should not change after creation
      organizerName: organizerName ?? this.organizerName,
      dateOfEvent: dateOfEvent ?? this.dateOfEvent,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      modeOfEvent: modeOfEvent ?? this.modeOfEvent,
      typeOfEvent: typeOfEvent ?? this.typeOfEvent,
      description: description ?? this.description,
      venue: venue ?? this.venue,
      audienceSize: audienceSize ?? this.audienceSize,
      audienceType: audienceType ?? this.audienceType,
      estimatedBudget: estimatedBudget ?? this.estimatedBudget,
      fundSource: fundSource ?? this.fundSource,
      resourcesRequested: resourcesRequested ?? this.resourcesRequested,
      additionalNote: additionalNote ?? this.additionalNote,
      status: status ?? this.status,
      approvalCount: approvalCount ?? this.approvalCount,
      approvedBy: approvedBy ?? this.approvedBy,
      hodSuggestedChangesNotesheetId:
          hodSuggestedChangesNotesheetId ?? this.hodSuggestedChangesNotesheetId,
      originalNotesheetId: originalNotesheetId ?? this.originalNotesheetId,
      createdAt:
          createdAt ??
          this.createdAt, // <-- NEW: Use provided createdAt or current createdAt
      lastStatusChangeAt: lastStatusChangeAt ?? this.lastStatusChangeAt,
    );
  }
}
