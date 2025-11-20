// lib/services/notesheet_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notesheet.dart';
import '../models/review_entry.dart';
import '../models/event.dart';
import '../utils/enums.dart';
import 'settings_service.dart';

class NotesheetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SettingsService _settingsService = SettingsService();

  // Helper method to update notesheet status and lastStatusChangeAt
  Future<void> _updateNotesheetStatusAndTimestamp(
    String notesheetId,
    NotesheetStatus newStatus,
  ) async {
    await _firestore.collection('notesheets').doc(notesheetId).update({
      'status': newStatus.name,
      'lastStatusChangeAt':
          Timestamp.now(), // Update timestamp on status change
    });
  }

  // --- Proposer & Reviewer Methods ---

  // Method to create a new notesheet entry
  Future<String> proposeNotesheet(Notesheet notesheet) async {
    try {
      // Ensure createdAt and lastStatusChangeAt are set upon creation
      final notesheetToSave = notesheet.copyWith(
        status:
            NotesheetStatus.underConsideration, // Explicitly set initial status
        approvalCount: 0,
        approvedBy: [],
        createdAt: DateTime.now(),
        lastStatusChangeAt:
            DateTime.now(), // Set initial status change timestamp
      );

      final docRef = await _firestore
          .collection('notesheets')
          .add(notesheetToSave.toMap());
      return docRef.id;
    } catch (e) {
      print('Error proposing notesheet: $e');
      throw e;
    }
  }

  // Stream to retrieve a list of notesheets for Reviewers (Under Consideration & Pending Approval)
  Stream<List<Notesheet>> getNotesheetsForReviewerDashboard() {
    return _firestore
        .collection('notesheets')
        // Retrieve notesheets that are either 'underConsideration' or 'pendingApproval'
        .where(
          'status',
          whereIn: [
            NotesheetStatus.underConsideration.name,
            NotesheetStatus.pendingApproval.name,
          ],
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Notesheet.fromMap(doc.data(), docId: doc.id))
              .toList(),
        );
  }

  // Method for Reviewers to accept/approve a notesheet
  // Handles incrementing approval count and status change if threshold met
  Future<void> reviewNotesheetAccept(
    String notesheetId,
    String reviewerId, {
    String? reviewDescription,
  }) async {
    try {
      // Get the notesheet and global settings in a transaction for atomicity
      await _firestore.runTransaction((transaction) async {
        final notesheetRef = _firestore
            .collection('notesheets')
            .doc(notesheetId);
        final notesheetDoc = await transaction.get(notesheetRef);

        if (!notesheetDoc.exists) {
          throw Exception('Notesheet not found!');
        }

        final currentNotesheet = Notesheet.fromMap(
          notesheetDoc.data()!,
          docId: notesheetDoc.id,
        );

        // Ensure notesheet is in a reviewable state
        if (currentNotesheet.status != NotesheetStatus.underConsideration) {
          throw Exception(
            'Notesheet is not in an "Under Consideration" status for review.',
          );
        }

        // Prevent duplicate approval by the same reviewer
        if (currentNotesheet.approvedBy.contains(reviewerId)) {
          throw Exception('You have already approved this notesheet.');
        }

        // Get the review threshold
        final reviewThreshold = await _settingsService.getReviewThreshold();
        if (reviewThreshold == null) {
          throw Exception('Review threshold not configured.');
        }

        // Increment approval count and add reviewer to approvedBy list
        final newApprovalCount = currentNotesheet.approvalCount + 1;
        final updatedApprovedBy = List<String>.from(currentNotesheet.approvedBy)
          ..add(reviewerId);

        NotesheetStatus newStatus = currentNotesheet.status;
        DateTime newLastStatusChangeAt = currentNotesheet.lastStatusChangeAt;

        if (newApprovalCount >= reviewThreshold) {
          // Status changes only if it's currently under consideration
          newStatus = NotesheetStatus.pendingApproval;
          newLastStatusChangeAt =
              DateTime.now(); // Status changed, update timestamp
        }

        // Update notesheet
        transaction.update(notesheetRef, {
          'approvalCount': newApprovalCount,
          'approvedBy': updatedApprovedBy,
          'status': newStatus.name,
          'lastStatusChangeAt': Timestamp.fromDate(
            newLastStatusChangeAt,
          ), // Update timestamp
        });

        // If a review description is provided, add a review entry
        if (reviewDescription != null && reviewDescription.isNotEmpty) {
          final reviewEntry = ReviewEntry(
            notesheetId: notesheetId,
            reviewerId: reviewerId,
            description: reviewDescription,
            timestamp: DateTime.now(),
          );
          // Review entries can be added outside the transaction for simplicity
          // or use a batched write if you need strict atomicity for this too.
          _firestore.collection('reviews').add(reviewEntry.toMap());
        }
      });
    } catch (e) {
      // IMPORTANT: Print the actual error object to see the Firebase message
      print('Error reviewing notesheet (accept): $e');
      print('Detailed error: ${e.runtimeType}');
      if (e is FirebaseException) {
        // Catch specific Firebase exceptions if possible
        print('Firebase Error Code: ${e.code}');
        print('Firebase Error Message: ${e.message}');
      }
      throw e; // Re-throw the error so the UI still knows it failed
    }
  }

  // Method for Reviewers to suggest changes (add a review entry)
  Future<void> reviewSuggestChanges(
    String notesheetId,
    String reviewerId,
    String reviewDescription,
  ) async {
    if (reviewDescription.isEmpty) {
      throw Exception(
        'Review description cannot be empty for suggesting changes.',
      );
    }
    try {
      final reviewEntry = ReviewEntry(
        notesheetId: notesheetId,
        reviewerId: reviewerId,
        description: reviewDescription,
        timestamp: DateTime.now(),
      );
      await _firestore.collection('reviews').add(reviewEntry.toMap());
    } catch (e) {
      print('Error suggesting changes (reviewer): $e');
      throw e;
    }
  }

  // --- HOD Methods ---

  // Stream to retrieve a list of notesheets in 'Pending Approval' status for HODs
  Stream<List<Notesheet>> getPendingApprovalNotesheets() {
    return _firestore
        .collection('notesheets')
        .where('status', isEqualTo: NotesheetStatus.pendingApproval.name)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Notesheet.fromMap(doc.data(), docId: doc.id))
              .toList(),
        );
  }

  // Method for HOD to approve a notesheet
  Future<void> approveNotesheet(String notesheetId) async {
    try {
      // Use a transaction to ensure atomicity for notesheet status update and event creation
      await _firestore.runTransaction((transaction) async {
        final notesheetRef = _firestore
            .collection('notesheets')
            .doc(notesheetId);
        final notesheetDoc = await transaction.get(notesheetRef);

        if (!notesheetDoc.exists) {
          throw Exception('Notesheet not found!');
        }

        final notesheet = Notesheet.fromMap(
          notesheetDoc.data()!,
          docId: notesheetDoc.id,
        );

        if (notesheet.status != NotesheetStatus.pendingApproval) {
          throw Exception('Notesheet is not in "Pending Approval" status.');
        }

        // Update notesheet status to Approved and its timestamp
        transaction.update(notesheetRef, {
          'status': NotesheetStatus.approved.name,
          'lastStatusChangeAt': Timestamp.now(),
        });

        // Create an Event document, using the notesheetId as the eventId
        final eventData = Event(
          id: notesheetId, // Event ID matches Notesheet ID
          notesheetId: notesheet.id!,
          title: notesheet.title,
          proposerId: notesheet.proposerId,
          organizerName: notesheet.organizerName,
          dateOfEvent: notesheet.dateOfEvent,
          startTime: notesheet.startTime,
          endTime: notesheet.endTime,
          modeOfEvent: notesheet.modeOfEvent,
          typeOfEvent: notesheet.typeOfEvent,
          description: notesheet.description,
          venue: notesheet.venue,
          audienceSize: notesheet.audienceSize,
          audienceType: notesheet.audienceType,
          estimatedBudget: notesheet.estimatedBudget,
          fundSource: notesheet.fundSource,
          resourcesRequested: notesheet.resourcesRequested,
          additionalNote: notesheet.additionalNote,
          eventStatus: EventStatus.upcoming, // Initially upcoming
          createdAt: DateTime.now(), // Event creation time
        ).toMap();

        // Add the event using a transaction set or update
        transaction.set(
          _firestore.collection('events').doc(notesheetId),
          eventData,
        );
        // Note: setting event inside transaction. This is a common pattern.
        // If a lot of data, consider Firebase Cloud Function.
      });
    } catch (e) {
      print('Error approving notesheet: $e');
      throw e;
    }
  }

  // Method for HOD to reject a notesheet
  Future<void> rejectNotesheet(String notesheetId) async {
    try {
      await _updateNotesheetStatusAndTimestamp(
        notesheetId,
        NotesheetStatus.rejected,
      );
    } catch (e) {
      print('Error rejecting notesheet: $e');
      throw e;
    }
  }

  // Method for HOD to suggest changes, creating a "sudo" notesheet
  Future<void> suggestChanges(
    String originalNotesheetId,
    Notesheet modifiedNotesheetData,
  ) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final originalNotesheetRef = _firestore
            .collection('notesheets')
            .doc(originalNotesheetId);
        final originalNotesheetDoc = await transaction.get(
          originalNotesheetRef,
        );

        if (!originalNotesheetDoc.exists) {
          throw Exception('Original notesheet not found!');
        }

        // 1. Update the original notesheet's status to rejectedWithSuggestions
        transaction.update(originalNotesheetRef, {
          'status': NotesheetStatus.rejectedWithSuggestions.name, // NEW Status
          'lastStatusChangeAt': Timestamp.now(), // NEW: Update timestamp
        });

        // 2. Create the "sudo" notesheet
        final sudoNotesheet = modifiedNotesheetData.copyWith(
          id: null, // Ensure new ID for sudo
          status: NotesheetStatus.awaitingProposerResponse,
          approvalCount: 0, // Reset for new review cycle
          approvedBy: [], // Reset for new review cycle
          originalNotesheetId: originalNotesheetId, // Link to original
          hodSuggestedChangesNotesheetId:
              null, // This is the sudo, so this field is null
          createdAt: DateTime.now(), // Sudo creation time
          lastStatusChangeAt: DateTime.now(), // Sudo status change time
        );

        // Generate a new document ID for the sudo notesheet
        final newSudoDocRef = _firestore.collection('notesheets').doc();
        // 3. Create the "sudo" notesheet using the generated reference
        transaction.set(newSudoDocRef, sudoNotesheet.toMap());

        // 4. Link the original notesheet to the sudo notesheet
        transaction.update(originalNotesheetRef, {
          'hodSuggestedChangesNotesheetId': newSudoDocRef.id,
        });
      });
    } catch (e) {
      print('Error suggesting changes: $e');
      throw e;
    }
  }

  // Method for Proposer to accept suggested changes from HOD
  Future<void> acceptSuggestedChanges(String sudoNotesheetId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final sudoNotesheetRef = _firestore
            .collection('notesheets')
            .doc(sudoNotesheetId);
        final sudoNotesheetDoc = await transaction.get(sudoNotesheetRef);

        if (!sudoNotesheetDoc.exists) {
          throw Exception('Suggested notesheet not found!');
        }

        final sudoNotesheet = Notesheet.fromMap(
          sudoNotesheetDoc.data()!,
          docId: sudoNotesheetDoc.id,
        );

        if (sudoNotesheet.status != NotesheetStatus.awaitingProposerResponse) {
          throw Exception(
            'Suggested notesheet is not awaiting proposer response.',
          );
        }

        // 1. Get the original notesheet ref
        final originalNotesheetId = sudoNotesheet.originalNotesheetId;
        if (originalNotesheetId == null) {
          throw Exception(
            'Sudo notesheet does not link to an original notesheet.',
          );
        }
        final originalNotesheetRef = _firestore
            .collection('notesheets')
            .doc(originalNotesheetId);

        // 2. Create a brand new notesheet from the accepted sudo notesheet data
        // This new notesheet starts its own approval cycle with current timestamps
        final newPermanentNotesheet = sudoNotesheet.copyWith(
          id: null, // Let Firestore generate new ID
          status:
              NotesheetStatus.underConsideration, // Restart approval process
          approvalCount: 0,
          approvedBy: [],
          originalNotesheetId: null, // No longer a sudo
          hodSuggestedChangesNotesheetId: null, // No longer a sudo
          createdAt:
              DateTime.now(), // New creation time for the "new" notesheet
          lastStatusChangeAt: DateTime.now(), // New status change time
        );
        final docRef = await _firestore
            .collection('notesheets')
            .add(newPermanentNotesheet.toMap());

        // 3. Mark the original notesheet as rejected
        transaction.update(originalNotesheetRef, {
          'status': NotesheetStatus.rejected.name, // Set original to rejected
          'hodSuggestedChangesNotesheetId': null, // Clear link to sudo
          'lastStatusChangeAt': Timestamp.now(), // NEW: Update timestamp
        });

        // 4. Delete the "sudo" notesheet
        transaction.delete(sudoNotesheetRef);
      });
    } catch (e) {
      print('Error accepting suggested changes: $e');
      throw e;
    }
  }

  // Stream to retrieve notesheets proposed by a specific user
  Stream<List<Notesheet>> getNotesheetsProposedBy(String proposerId) {
    return _firestore
        .collection('notesheets')
        .where('proposerId', isEqualTo: proposerId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Notesheet.fromMap(doc.data(), docId: doc.id))
              .toList(),
        );
  }

  // Method for Proposer to reject suggested changes from HOD
  Future<void> rejectSuggestedChanges(String sudoNotesheetId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final sudoNotesheetRef = _firestore
            .collection('notesheets')
            .doc(sudoNotesheetId);
        final sudoNotesheetDoc = await transaction.get(sudoNotesheetRef);

        if (!sudoNotesheetDoc.exists) {
          throw Exception('Suggested notesheet not found!');
        }

        final sudoNotesheet = Notesheet.fromMap(
          sudoNotesheetDoc.data()!,
          docId: sudoNotesheetDoc.id,
        );

        if (sudoNotesheet.status != NotesheetStatus.awaitingProposerResponse) {
          throw Exception(
            'Suggested notesheet is not awaiting proposer response.',
          );
        }

        final originalNotesheetId = sudoNotesheet.originalNotesheetId;
        if (originalNotesheetId == null) {
          throw Exception(
            'Sudo notesheet does not link to an original notesheet.',
          );
        }
        final originalNotesheetRef = _firestore
            .collection('notesheets')
            .doc(originalNotesheetId);

        // 1. Set original notesheet status to 'Rejected'
        transaction.update(originalNotesheetRef, {
          'status': NotesheetStatus.rejected.name,
          'hodSuggestedChangesNotesheetId': null, // Clear link to sudo
          'lastStatusChangeAt': Timestamp.now(), // NEW: Update timestamp
        });

        // 2. Delete the "sudo" notesheet
        transaction.delete(sudoNotesheetRef);
      });
    } catch (e) {
      print('Error rejecting suggested changes: $e');
      throw e;
    }
  }

  // Method to fetch a single notesheet by ID
  Future<Notesheet?> getNotesheetById(String notesheetId) async {
    try {
      final doc = await _firestore
          .collection('notesheets')
          .doc(notesheetId)
          .get();
      if (doc.exists) {
        return Notesheet.fromMap(doc.data()!, docId: doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting notesheet by ID: $e');
      return null;
    }
  }

  // --- NEW: Time-based Notesheet Expiry Check (Client-Side) ---
  // IMPORTANT: For robust, real-time expiry, Firebase Cloud Functions
  // (scheduled functions) are highly recommended as client-side checks
  // are only performed when the app is active and this method is called.
  Future<void> checkAndExpireNotesheets() async {
    try {
      final now = DateTime.now();

      // Get notesheets that are 'underConsideration' or 'pendingApproval'
      final querySnapshot = await _firestore
          .collection('notesheets')
          .where(
            'status',
            whereIn: [
              NotesheetStatus.underConsideration.name,
              NotesheetStatus.pendingApproval.name,
            ],
          )
          .get();

      for (var doc in querySnapshot.docs) {
        final notesheet = Notesheet.fromMap(doc.data(), docId: doc.id);
        final timeInCurrentStatus = now.difference(
          notesheet.lastStatusChangeAt,
        );

        if (notesheet.status == NotesheetStatus.underConsideration &&
            timeInCurrentStatus.inDays >= 10) {
          print('Notesheet ${notesheet.id} expired due to lack of reviews.');
          await _updateNotesheetStatusAndTimestamp(
            notesheet.id!,
            NotesheetStatus.expiredDueToReviews,
          );
        } else if (notesheet.status == NotesheetStatus.pendingApproval &&
            timeInCurrentStatus.inDays >= 2) {
          print('Notesheet ${notesheet.id} expired due to approval timeout.');
          await _updateNotesheetStatusAndTimestamp(
            notesheet.id!,
            NotesheetStatus.expiredDueToApproval,
          );
        }
      }
    } catch (e) {
      print('Error checking and expiring notesheets: $e');
    }
  }

  Stream<List<Notesheet>> getAllNotesheets() {
    return _firestore
        .collection('notesheets')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Notesheet.fromMap(doc.data()!, docId: doc.id))
              .toList(),
        );
  }
}
