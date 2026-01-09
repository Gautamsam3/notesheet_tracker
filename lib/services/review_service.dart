// lib/services/review_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review_entry.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all reviews (might be useful for admin or auditing)
  Stream<List<ReviewEntry>> getAllReviews() {
    return _firestore
        .collection('reviews')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ReviewEntry.fromMap(doc.data(), docId: doc.id))
              .toList(),
        );
  }

  // Retrieve reviews for a specific notesheet
  // This method has been moved here from NotesheetService for better
  // separation of concerns, as it's a read operation for reviews.
  Stream<List<ReviewEntry>> getReviewsForNotesheet(String notesheetId) {
    return _firestore
        .collection('reviews')
        .where('notesheetId', isEqualTo: notesheetId)
        .orderBy('timestamp', descending: true) // Order by latest review first
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ReviewEntry.fromMap(doc.data(), docId: doc.id))
              .toList(),
        );
  }
}
