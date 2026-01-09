// lib/services/settings_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _settingsCollection = 'settings';
  static const String _globalSettingsDocId = 'global_settings';
  static const int _defaultReviewThreshold = 1; // Fallback default

  // Get the current review threshold
  Future<int> getReviewThreshold() async {
    try {
      final doc = await _firestore
          .collection(_settingsCollection)
          .doc(_globalSettingsDocId)
          .get();
      if (doc.exists && doc.data()!.containsKey('reviewThreshold')) {
        return doc.data()!['reviewThreshold'] as int;
      }
      // If document or field doesn't exist, create it with a default value
      await _firestore
          .collection(_settingsCollection)
          .doc(_globalSettingsDocId)
          .set(
            {'reviewThreshold': _defaultReviewThreshold},
            SetOptions(
              merge: true,
            ), // Use merge to not overwrite other potential settings
          );
      return _defaultReviewThreshold;
    } catch (e) {
      print('Error getting review threshold: $e');
      return _defaultReviewThreshold; // Fallback in case of error
    }
  }

  // Update the review threshold (Admin only)
  Future<void> updateReviewThreshold(int newThreshold) async {
    try {
      if (newThreshold <= 0) {
        throw Exception('Review threshold must be a positive integer.');
      }
      await _firestore
          .collection(_settingsCollection)
          .doc(_globalSettingsDocId)
          .set({'reviewThreshold': newThreshold}, SetOptions(merge: true));
    } catch (e) {
      print('Error updating review threshold: $e');
      rethrow;
    }
  }
}
