import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/notesheet_model.dart';
import '../models/user_model.dart';

class SupabaseDatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Uuid _uuid = const Uuid();

  // Create a new notesheet
  Future<String> createNotesheet({
    required String title,
    required String description,
    required String creatorUid,
    required String creatorName,
    required List<AppUser> reviewers,
    DateTime? deadline,
    String? pdfUrl,
    String? pdfFileName,
  }) async {
    try {
      final notesheetId = _uuid.v4();
      
      // Convert users to reviewers with first one as current
      final reviewFlow = reviewers.map((user) => Reviewer(
        uid: user.uid,
        name: user.name,
        status: ReviewStatus.pending,
      )).toList();

      final notesheet = Notesheet(
        id: notesheetId,
        title: title,
        description: description,
        creatorUid: creatorUid,
        creatorName: creatorName,
        reviewFlow: reviewFlow,
        currentReviewerUid: reviewFlow.isNotEmpty ? reviewFlow.first.uid : null,
        status: NotesheetStatus.pending,
        createdAt: DateTime.now(),
        deadline: deadline,
        pdfUrl: pdfUrl,
        pdfFileName: pdfFileName,
      );

      await _supabase
          .from('notesheets')
          .insert(notesheet.toJson());
      
      return notesheetId;
    } catch (e) {
      throw Exception('Failed to create notesheet: $e');
    }
  }

  // Submit review for a notesheet
  Future<void> submitReview({
    required String notesheetId,
    required String reviewerUid,
    required ReviewStatus status,
    String? comments,
  }) async {
    try {
      // Get current notesheet
      final response = await _supabase
          .from('notesheets')
          .select()
          .eq('id', notesheetId)
          .single();

      final notesheet = Notesheet.fromJson(response);

      // Update reviewer status
      final updatedReviewFlow = notesheet.reviewFlow.map((reviewer) {
        if (reviewer.uid == reviewerUid) {
          return reviewer.copyWith(
            status: status,
            comments: comments,
            actionDate: DateTime.now(),
          );
        }
        return reviewer;
      }).toList();

      // Determine next reviewer and overall status
      String? nextReviewerUid;
      NotesheetStatus newStatus = NotesheetStatus.pending;

      if (status == ReviewStatus.rejected) {
        newStatus = NotesheetStatus.rejected;
      } else if (status == ReviewStatus.approved) {
        // Find next pending reviewer
        final nextReviewer = updatedReviewFlow.firstWhere(
          (r) => r.status == ReviewStatus.pending,
          orElse: () => Reviewer(uid: '', name: '', status: ReviewStatus.pending),
        );
        
        if (nextReviewer.uid.isNotEmpty) {
          nextReviewerUid = nextReviewer.uid;
          newStatus = NotesheetStatus.pending;
        } else {
          // All reviewers approved
          newStatus = NotesheetStatus.approved;
        }
      }

      // Archive previous version if needed (optional feature)
      final archiveId = _uuid.v4();
      final previousVersionData = notesheet.toJson();
      previousVersionData['archive_id'] = archiveId;
      previousVersionData['archived_at'] = DateTime.now().toIso8601String();
      
      await _supabase
          .from('notesheet_versions')
          .insert(previousVersionData);

      // Update notesheet
      await _supabase
          .from('notesheets')
          .update({
            'review_flow': updatedReviewFlow.map((r) => r.toJson()).toList(),
            'current_reviewer_uid': nextReviewerUid,
            'status': newStatus.name,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notesheetId);

    } catch (e) {
      throw Exception('Failed to submit review: $e');
    }
  }

  // Update notesheet (for revisions)
  Future<void> updateNotesheet({
    required String notesheetId,
    String? title,
    String? description,
    DateTime? deadline,
    String? pdfUrl,
    String? pdfFileName,
  }) async {
    try {
      // Get current notesheet
      final response = await _supabase
          .from('notesheets')
          .select()
          .eq('id', notesheetId)
          .single();

      final notesheet = Notesheet.fromJson(response);

      // Archive current version
      final archiveId = _uuid.v4();
      final previousVersionData = notesheet.toJson();
      previousVersionData['archive_id'] = archiveId;
      previousVersionData['archived_at'] = DateTime.now().toIso8601String();
      
      await _supabase
          .from('notesheet_versions')
          .insert(previousVersionData);

      // Reset review flow for new version
      final resetReviewFlow = notesheet.reviewFlow.map((reviewer) => Reviewer(
        uid: reviewer.uid,
        name: reviewer.name,
        status: ReviewStatus.pending,
      )).toList();

      // Update notesheet with new version
      final updateData = <String, dynamic>{
        'review_flow': resetReviewFlow.map((r) => r.toJson()).toList(),
        'current_reviewer_uid': resetReviewFlow.isNotEmpty ? resetReviewFlow.first.uid : null,
        'status': NotesheetStatus.pending.name,
        'updated_at': DateTime.now().toIso8601String(),
        'is_edited': true,
      };

      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (deadline != null) updateData['deadline'] = deadline.toIso8601String();
      if (pdfUrl != null) updateData['pdf_url'] = pdfUrl;
      if (pdfFileName != null) updateData['pdf_file_name'] = pdfFileName;

      await _supabase
          .from('notesheets')
          .update(updateData)
          .eq('id', notesheetId);

    } catch (e) {
      throw Exception('Failed to update notesheet: $e');
    }
  }

  // Get all notesheets
  Future<List<Notesheet>> getAllNotesheets() async {
    try {
      final response = await _supabase
          .from('notesheets')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((data) => Notesheet.fromJson(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get notesheets: $e');
    }
  }

  // Get notesheets by creator
  Future<List<Notesheet>> getNotesheetsByCreator(String creatorUid) async {
    try {
      final response = await _supabase
          .from('notesheets')
          .select()
          .eq('creator_uid', creatorUid)
          .order('created_at', ascending: false);

      return (response as List)
          .map((data) => Notesheet.fromJson(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get notesheets by creator: $e');
    }
  }

  // Get notesheets by reviewer
  Future<List<Notesheet>> getNotesheetsByReviewer(String reviewerUid) async {
    try {
      final response = await _supabase
          .from('notesheets')
          .select()
          .contains('review_flow', [{'uid': reviewerUid}])
          .order('created_at', ascending: false);

      return (response as List)
          .map((data) => Notesheet.fromJson(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get notesheets by reviewer: $e');
    }
  }

  // Get notesheet by ID
  Future<Notesheet?> getNotesheetById(String notesheetId) async {
    try {
      final response = await _supabase
          .from('notesheets')
          .select()
          .eq('id', notesheetId)
          .maybeSingle();

      if (response != null) {
        return Notesheet.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get notesheet: $e');
    }
  }

  // Update notesheet status
  Future<void> updateNotesheetStatus({
    required String notesheetId,
    required NotesheetStatus status,
  }) async {
    try {
      await _supabase
          .from('notesheets')
          .update({
            'status': status.name,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notesheetId);
    } catch (e) {
      throw Exception('Failed to update notesheet status: $e');
    }
  }

  // Delete notesheet
  Future<void> deleteNotesheet(String notesheetId) async {
    try {
      await _supabase
          .from('notesheets')
          .delete()
          .eq('id', notesheetId);
    } catch (e) {
      throw Exception('Failed to delete notesheet: $e');
    }
  }

  // Get pending notesheets for reviewer
  Future<List<Notesheet>> getPendingNotesheetsForReviewer(String reviewerUid) async {
    try {
      final response = await _supabase
          .from('notesheets')
          .select()
          .eq('current_reviewer_uid', reviewerUid)
          .eq('status', NotesheetStatus.pending.name)
          .order('created_at', ascending: false);

      return (response as List)
          .map((data) => Notesheet.fromJson(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get pending notesheets: $e');
    }
  }

  // Get notesheet statistics for admin
  Future<Map<String, int>> getNotesheetStatistics() async {
    try {
      final allResponse = await _supabase
          .from('notesheets')
          .select('status');

      final all = allResponse as List;
      
      return {
        'total': all.length,
        'pending': all.where((n) => n['status'] == NotesheetStatus.pending.name).length,
        'approved': all.where((n) => n['status'] == NotesheetStatus.approved.name).length,
        'rejected': all.where((n) => n['status'] == NotesheetStatus.rejected.name).length,
      };
    } catch (e) {
      throw Exception('Failed to get notesheet statistics: $e');
    }
  }

  // Search notesheets
  Future<List<Notesheet>> searchNotesheets(String query) async {
    try {
      final response = await _supabase
          .from('notesheets')
          .select()
          .or('title.ilike.%$query%,description.ilike.%$query%,creator_name.ilike.%$query%')
          .order('created_at', ascending: false);

      return (response as List)
          .map((data) => Notesheet.fromJson(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to search notesheets: $e');
    }
  }

  // Get pending notesheets stream for admin
  Stream<List<Notesheet>> getPendingNotesheetsStream() {
    return _supabase
        .from('notesheets')
        .stream(primaryKey: ['id'])
        .eq('status', NotesheetStatus.pending.name)
        .order('created_at', ascending: false)
        .map((data) {
          return data
              .map((item) => Notesheet.fromJson(item))
              .toList();
        });
  }

  // Get notesheets by creator stream
  Stream<List<Notesheet>> getNotesheetsByCreatorStream(String creatorUid) {
    return _supabase
        .from('notesheets')
        .stream(primaryKey: ['id'])
        .eq('creator_uid', creatorUid)
        .order('created_at', ascending: false)
        .map((data) {
          return data
              .map((item) => Notesheet.fromJson(item))
              .toList();
        });
  }

  // Get notesheets for reviewer stream  
  Stream<List<Notesheet>> getNotesheetsForReviewerStream(String reviewerUid) {
    return _supabase
        .from('notesheets')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) {
          return data
              .map((item) => Notesheet.fromJson(item))
              .where((notesheet) {
                // Only show notesheets where:
                // 1. The notesheet is pending
                // 2. The current reviewer is this user
                // 3. This reviewer hasn't approved/rejected yet
                if (notesheet.status != NotesheetStatus.pending) return false;
                if (notesheet.currentReviewerUid != reviewerUid) return false;
                
                // Find this reviewer's status
                final reviewer = notesheet.reviewFlow.firstWhere(
                  (r) => r.uid == reviewerUid,
                  orElse: () => Reviewer(uid: '', name: '', status: ReviewStatus.pending),
                );
                
                // Only show if this reviewer is still pending
                return reviewer.status == ReviewStatus.pending;
              })
              .toList();
        });
  }

  // Get reviewed notesheets by user stream
  Stream<List<Notesheet>> getReviewedNotesheetsByUserStream(String reviewerUid) {
    return _supabase
        .from('notesheets')
        .stream(primaryKey: ['id'])
        .order('updated_at', ascending: false)
        .map((data) {
          return data
              .map((item) => Notesheet.fromJson(item))
              .where((notesheet) {
                // Find the reviewer in the review flow
                final reviewer = notesheet.reviewFlow
                    .firstWhere((r) => r.uid == reviewerUid,
                        orElse: () => Reviewer(uid: '', name: '', status: ReviewStatus.pending));
                
                // Include notesheet if this reviewer has approved or rejected it
                return reviewer.uid.isNotEmpty && 
                       (reviewer.status == ReviewStatus.approved || 
                        reviewer.status == ReviewStatus.rejected);
              })
              .toList();
        });
  }

  // Get all notesheets stream for admin
  Stream<List<Notesheet>> getAllNotesheetsStream() {
    return _supabase
        .from('notesheets')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) {
          return data
              .map((item) => Notesheet.fromJson(item))
              .toList();
        });
  }

  // Get notesheet stream by ID for real-time updates
  Stream<Notesheet?> getNotesheetStream(String notesheetId) {
    return _supabase
        .from('notesheets')
        .stream(primaryKey: ['id'])
        .eq('id', notesheetId)
        .map((data) {
          if (data.isNotEmpty) {
            return Notesheet.fromJson(data.first);
          }
          return null;
        });
  }

  // Get notesheet versions/history
  Future<List<Notesheet>> getNotesheetVersions(String notesheetId) async {
    try {
      final data = await _supabase
          .from('notesheet_versions')
          .select()
          .eq('id', notesheetId)
          .order('archived_at', ascending: false);
      
      return data.map((json) => Notesheet.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get notesheet versions: $e');
    }
  }
}
