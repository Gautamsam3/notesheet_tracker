// lib/services/user_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart'; // Assuming AppUser model is in models/user.dart
import '../utils/enums.dart'; // Assuming UserRole enum is in utils/enums.dart

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream to get all registered AppUsers
  Stream<List<AppUser>> getAllAppUsers() {
    return _firestore
        .collection('users')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AppUser.fromMap(doc.data()!, docId: doc.id))
              .toList(),
        );
  }

  // Update a user's role
  Future<void> updateUserRole(String userId, UserRole newRole) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': newRole.name, // Store enum name as string
      });
    } catch (e) {
      print('Error updating user role for $userId: $e');
      rethrow;
    }
  }

  // Delete a user's document from Firestore
  // IMPORTANT: This does NOT delete the user from Firebase Authentication.
  // For full user deletion, a Firebase Cloud Function is recommended.
  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
    } catch (e) {
      print('Error deleting user document for $userId: $e');
      rethrow;
    }
  }
}
