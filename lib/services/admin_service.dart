// lib/services/admin_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';
import '../models/notesheet.dart';
import '../models/event.dart';
import '../utils/enums.dart';
import 'settings_service.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Dependency for global settings
  final SettingsService _settingsService = SettingsService();

  // --- User Management ---

  // Get all users
  Stream<List<AppUser>> getAllUsers() {
    return _firestore
        .collection('users')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AppUser.fromMap(doc.data()!, docId: doc.id))
              .toList(),
        );
  }

  // Create or Update a user's Firestore profile
  // IMPORTANT: This method only handles the Firestore document.
  // Creating a new Firebase Auth user (email/password) from the client-side
  // for another user is NOT supported by Firebase Auth SDK due to security.
  // For an admin to create new users (Firebase Auth + Firestore profile),
  // you would typically use:
  // 1. Firebase Admin SDK (via a Cloud Function that your Flutter app calls).
  // 2. A separate registration flow where new users self-register (e.g., using a signup code given by admin).
  Future<void> createOrUpdateUser(AppUser user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(user.toMap());
    } catch (e) {
      print('Error creating/updating user: $e');
      throw e;
    }
  }

  // Update a user's role
  Future<void> updateUserRole(String userId, UserRole newRole) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': newRole.name,
      });
    } catch (e) {
      print('Error updating user role: $e');
      throw e;
    }
  }

  // --- NEW: User Status Management ---
  Future<void> updateUserStatus(String userId, UserStatus newStatus) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'status': newStatus.name,
      });
      print('User $userId status updated to ${newStatus.name}');
    } catch (e) {
      print('Error updating user status: $e');
      throw e;
    }
  }

  Future<void> activateUser(String userId) async {
    return updateUserStatus(userId, UserStatus.active);
  }

  Future<void> suspendUser(String userId) async {
    return updateUserStatus(userId, UserStatus.suspended);
  }

  Future<void> terminateUser(String userId) async {
    return updateUserStatus(userId, UserStatus.terminated);
  }

  // Delete a user (from Firestore and Firebase Auth)
  // This is a complex operation and requires careful consideration of data integrity.
  // Deleting the Firebase Auth user doesn't delete their Firestore document automatically.
  Future<void> deleteUser(String userId) async {
    try {
      // 1. Delete user's Firestore document
      await _firestore.collection('users').doc(userId).delete();
      print('Firestore user document $userId deleted.');

      // 2. Delete Firebase Auth user:
      // This is the tricky part from a client-side app. Firebase Auth SDK client-side can only delete
      // the *currently logged-in* user after they have recently re-authenticated.
      // For an admin to delete *any* user's Firebase Auth account, you MUST
      // use a Firebase Cloud Function that utilizes the Firebase Admin SDK.
      // Attempting to delete a user other than the currently logged-in one from client-side
      // will fail due to security restrictions.
      //
      // UNCOMMENT AND IMPLEMENT THE CLOUD FUNCTION CALL WHEN READY:
      // await FirebaseFunctions.instance.httpsCallable('deleteUserCallable').call({'uid': userId});
      // print('Firebase Auth user $userId deletion requested via Cloud Function (if implemented).');

      // For now, if current user is being deleted (for testing purposes only):
      if (_firebaseAuth.currentUser?.uid == userId) {
        await _firebaseAuth.currentUser?.delete();
        print('Currently logged-in Firebase Auth user $userId deleted.');
      } else {
        print(
          'Warning: Client-side deleteUser can only delete the currently logged-in user. '
          'For admin to delete other users, a Firebase Cloud Function is required. '
          'Auth user $userId was NOT deleted.',
        );
        throw Exception(
          'Admin user deletion of arbitrary Firebase Auth accounts is not supported client-side. '
          'Please implement a Firebase Cloud Function for this functionality.',
        );
      }

      // 3. Clean up related data (notesheets proposed by, reviews by, etc.)
      // This is highly recommended to maintain data integrity.
      // Typically done with Cloud Functions triggered by user deletion or by iterating:
      // Example (simplified - can be slow for many items):
      final notesheetsSnapshot = await _firestore
          .collection('notesheets')
          .where('proposerId', isEqualTo: userId)
          .get();
      for (var doc in notesheetsSnapshot.docs) {
        await doc.reference.delete();
      }
      final reviewsSnapshot = await _firestore
          .collection('reviews')
          .where('reviewerId', isEqualTo: userId)
          .get();
      for (var doc in reviewsSnapshot.docs) {
        await doc.reference.delete();
      }
      print('Associated notesheets and reviews for $userId deleted.');
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Delete User Error: ${e.message}');
      throw e;
    } catch (e) {
      print('Error deleting user: $e');
      throw e;
    }
  }

  // --- Notesheet Management ---

  // Get all notesheets (for admin view)
  Stream<List<Notesheet>> getAllNotesheets() {
    return _firestore
        .collection('notesheets')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Notesheet.fromMap(doc.data(), docId: doc.id))
              .toList(),
        );
  }

  // Delete a notesheet (and optionally related reviews and events)
  Future<void> deleteNotesheet(String notesheetId) async {
    try {
      // Use a batch write for atomicity if deleting multiple related documents
      WriteBatch batch = _firestore.batch();

      // Delete notesheet document
      batch.delete(_firestore.collection('notesheets').doc(notesheetId));

      // Optional: Delete related reviews
      final reviewsSnapshot = await _firestore
          .collection('reviews')
          .where('notesheetId', isEqualTo: notesheetId)
          .get();
      for (var doc in reviewsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Optional: Delete related event if exists (Event ID is same as notesheet ID)
      batch.delete(_firestore.collection('events').doc(notesheetId));

      await batch.commit(); // Commit all deletions as a single atomic operation
      print('Notesheet $notesheetId and related data deleted successfully.');
    } catch (e) {
      print('Error deleting notesheet: $e');
      throw e;
    }
  }

  // --- Review Management ---

  // Delete a review
  Future<void> deleteReview(String reviewId) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).delete();
    } catch (e) {
      print('Error deleting review: $e');
      throw e;
    }
  }

  // --- Global Settings Management (delegated to SettingsService) ---
  // These methods directly expose SettingsService methods, making it clear
  // that Admin has privileges to call them.
  Future<void> updateReviewThreshold(int newThreshold) async {
    await _settingsService.updateReviewThreshold(newThreshold);
  }

  // --- Warning System (Example) ---
  Future<void> giveUserWarning(String userId, String message) async {
    try {
      // This is a simplistic example. A real warning system might involve:
      // - A 'warnings' subcollection on the user document.
      // - A top-level 'warnings' collection with references to user IDs.
      // - Warning types, timestamps, expiry, etc.
      await _firestore.collection('users').doc(userId).update({
        'warnings': FieldValue.arrayUnion([
          {'message': message, 'timestamp': Timestamp.now()},
        ]),
      });
    } catch (e) {
      print('Error giving user warning: $e');
      throw e;
    }
  }
}
