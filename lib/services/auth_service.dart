// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../utils/enums.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream to listen to authentication state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Get the currently logged-in Firebase user
  User? getCurrentFirebaseUser() {
    return _firebaseAuth.currentUser;
  }

  // Get the AppUser (from Firestore) for the currently logged-in user
  Future<AppUser?> getCurrentAppUser() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      return null;
    }
    try {
      final doc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();
      if (doc.exists) {
        return AppUser.fromMap(doc.data()!, docId: doc.id);
      }
      return null; // User document not found in Firestore
    } catch (e) {
      print('Error getting current AppUser: $e');
      return null;
    }
  }

  // --- Authentication Methods ---

  // Register a new user with Email and Password
  // This will create a Firebase Auth user and a corresponding AppUser document in Firestore
  Future<AppUser?> signUpWithEmailAndPassword(
    String email,
    String password,
    String name,
    UserRole role,
  ) async {
    try {
      UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      final firebaseUser = userCredential.user;
      if (firebaseUser != null) {
        // Create a new AppUser object with default 'active' status
        final appUser = AppUser(
          id: firebaseUser.uid,
          name: name,
          email: firebaseUser.email!,
          role: role,
          status: UserStatus.active, // <-- NEW: Default to active status
          createdAt: DateTime.now(),
        );

        // Store the AppUser data in Firestore
        await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .set(appUser.toMap());
        return appUser;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Sign Up Error: ${e.message}');
      // You can throw a custom exception or return null based on your error handling strategy
      throw e;
    } catch (e) {
      print('Generic Sign Up Error: $e');
      throw e;
    }
  }

  // Sign in an existing user with Email and Password
  Future<AppUser?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      final firebaseUser = userCredential.user;
      if (firebaseUser != null) {
        // Retrieve the full AppUser data to check status
        final appUser = await getCurrentAppUser();

        if (appUser == null) {
          // This case should ideally not happen if userCredential.user is not null,
          // but it's a safeguard if the Firestore document is missing.
          await _firebaseAuth
              .signOut(); // Sign out the partially logged-in user
          throw Exception('User profile not found in database.');
        }

        // --- NEW: Check user status ---
        if (appUser.status == UserStatus.terminated) {
          await _firebaseAuth.signOut(); // Prevent login for terminated users
          throw Exception('Your account has been terminated.');
        }
        // For suspended users, allow login but indicate restricted access (UI will handle message)
        if (appUser.status == UserStatus.suspended) {
          // You might want to return a specific AppUser object or flag
          // that indicates suspended status, so UI can show a message.
          // For now, we'll just allow login and let the UI check appUser.status.
          print('User ${appUser.email} is suspended. Access might be limited.');
        }

        await _firestore.collection('users').doc(firebaseUser.uid).update({
          'lastLoginAt': Timestamp.now(),
        });
        return appUser;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Sign In Error: ${e.message}');
      throw e;
    } catch (e) {
      print('Generic Sign In Error: $e');
      throw e;
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      throw e;
    }
  }
}
