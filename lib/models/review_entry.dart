// lib/models/review_entry.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewEntry {
  final String? id; // Nullable for new reviews
  final String notesheetId;
  final String reviewerId;
  final String description;
  final DateTime timestamp;

  const ReviewEntry({
    this.id,
    required this.notesheetId,
    required this.reviewerId,
    required this.description,
    required this.timestamp,
  });

  // Factory constructor to create a ReviewEntry from a Firestore document
  factory ReviewEntry.fromMap(Map<String, dynamic> map, {String? docId}) {
    return ReviewEntry(
      id: docId ?? map['id'] as String?,
      notesheetId: map['notesheetId'] as String,
      reviewerId: map['reviewerId'] as String,
      description: map['description'] as String,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  // Method to convert a ReviewEntry object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      // 'id': id, // Usually not stored in the map itself
      'notesheetId': notesheetId,
      'reviewerId': reviewerId,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
