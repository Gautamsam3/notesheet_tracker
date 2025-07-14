import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class SupabaseAdminService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all users awaiting role assignment
  Stream<List<AppUser>> getPendingUsers() {
    debugPrint('👑 SupabaseAdminService: Fetching pending users');
    
    return _supabase
        .from('users')
        .stream(primaryKey: ['uid'])
        .order('created_at', ascending: false)
        .map((data) {
          final users = data
              .where((item) => item['role'] == null)
              .map((item) => AppUser.fromJson(item))
              .toList();
          
          debugPrint('👑 SupabaseAdminService: Found ${users.length} pending users');
          return users;
        });
  }

  // Get all users in the system (using admin function to bypass RLS)
  Stream<List<AppUser>> getAllUsers() {
    debugPrint('👑 SupabaseAdminService: Fetching all users via admin function');
    
    // Use a periodic stream that calls the admin function
    return Stream.periodic(const Duration(seconds: 2), (_) async {
      try {
        final response = await _supabase.rpc('admin_get_all_users');
        final users = (response as List)
            .map((item) => AppUser.fromJson(item))
            .toList();
        
        // Sort by role status and then by role type
        users.sort((a, b) {
          // First, sort by role status (pending first, then by role type)
          if (a.isPendingApproval && !b.isPendingApproval) return -1;
          if (!a.isPendingApproval && b.isPendingApproval) return 1;
          
          if (!a.isPendingApproval && !b.isPendingApproval) {
            // Both have roles, sort by role type
            final roleOrder = [UserRole.admin, UserRole.reviewer, UserRole.requester];
            final aIndex = roleOrder.indexOf(a.role!);
            final bIndex = roleOrder.indexOf(b.role!);
            if (aIndex != bIndex) return aIndex.compareTo(bIndex);
          }
          
          // Finally, sort by creation date (newest first)
          return b.createdAt.compareTo(a.createdAt);
        });
        
        debugPrint('👑 SupabaseAdminService: Found ${users.length} total users');
        return users;
      } catch (e) {
        debugPrint('❌ SupabaseAdminService: Failed to fetch users: $e');
        return <AppUser>[];
      }
    }).asyncMap((future) => future).distinct();
  }

  // Assign role to user
  Future<void> assignUserRole(String uid, UserRole role) async {
    try {
      debugPrint('👑 SupabaseAdminService: Assigning role ${role.name} to user $uid');
      
      await _supabase
          .from('users')
          .update({
            'role': role.name,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('uid', uid);
      
      debugPrint('✅ SupabaseAdminService: Role assigned successfully');
    } catch (e) {
      debugPrint('❌ SupabaseAdminService: Failed to assign role: $e');
      throw Exception('Failed to assign role: $e');
    }
  }

  // Update user details (admin function)
  Future<void> updateUser({
    required String uid,
    String? name,
    String? email,
    String? department,
    UserRole? role,
  }) async {
    try {
      debugPrint('👑 SupabaseAdminService: Updating user $uid');
      
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      if (name != null) updates['name'] = name;
      if (email != null) updates['email'] = email;
      if (department != null) updates['department'] = department;
      if (role != null) updates['role'] = role.name;

      await _supabase
          .from('users')
          .update(updates)
          .eq('uid', uid);
      
      debugPrint('✅ SupabaseAdminService: User updated successfully');
    } catch (e) {
      debugPrint('❌ SupabaseAdminService: Failed to update user: $e');
      throw Exception('Failed to update user: $e');
    }
  }

  // Delete user (admin function)
  Future<void> deleteUser(String uid) async {
    try {
      debugPrint('👑 SupabaseAdminService: Deleting user $uid');
      
      await _supabase
          .from('users')
          .delete()
          .eq('uid', uid);
      
      debugPrint('✅ SupabaseAdminService: User deleted successfully');
    } catch (e) {
      debugPrint('❌ SupabaseAdminService: Failed to delete user: $e');
      throw Exception('Failed to delete user: $e');
    }
  }

  // Get user by UID
  Future<AppUser?> getUserByUid(String uid) async {
    try {
      debugPrint('👑 SupabaseAdminService: Fetching user $uid');
      
      final response = await _supabase
          .from('users')
          .select()
          .eq('uid', uid)
          .maybeSingle();

      if (response != null) {
        return AppUser.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint('❌ SupabaseAdminService: Failed to get user: $e');
      return null;
    }
  }

  // Get users by role
  Future<List<AppUser>> getUsersByRole(UserRole role) async {
    try {
      debugPrint('👑 SupabaseAdminService: Fetching users with role ${role.name}');
      
      final response = await _supabase
          .from('users')
          .select()
          .eq('role', role.name)
          .order('name');

      return (response as List)
          .map((data) => AppUser.fromJson(data))
          .toList();
    } catch (e) {
      debugPrint('❌ SupabaseAdminService: Failed to get users by role: $e');
      throw Exception('Failed to get users by role: $e');
    }
  }

  // Get available reviewers (users with reviewer role) - accessible to all authenticated users
  Future<List<AppUser>> getAvailableReviewers() async {
    try {
      debugPrint('👑 SupabaseAdminService: Fetching available reviewers via public function');
      
      final response = await _supabase.rpc('get_available_reviewers');
      final reviewers = (response as List)
          .map((data) => AppUser.fromJson(data))
          .toList();
      
      debugPrint('👑 SupabaseAdminService: Found ${reviewers.length} available reviewers');
      return reviewers;
    } catch (e) {
      debugPrint('❌ SupabaseAdminService: Failed to get available reviewers: $e');
      
      // Fallback to direct query (for admins)
      try {
        debugPrint('👑 SupabaseAdminService: Trying fallback method for reviewers');
        return await getUsersByRole(UserRole.reviewer);
      } catch (fallbackError) {
        debugPrint('❌ SupabaseAdminService: Fallback also failed: $fallbackError');
        throw Exception('Failed to get available reviewers: $e');
      }
    }
  }

  // Get user statistics
  Future<Map<String, int>> getUserStatistics() async {
    try {
      debugPrint('👑 SupabaseAdminService: Fetching user statistics');
      
      final allResponse = await _supabase
          .from('users')
          .select('role');

      final all = allResponse as List;
      
      return {
        'total': all.length,
        'pending': all.where((u) => u['role'] == null).length,
        'requesters': all.where((u) => u['role'] == UserRole.requester.name).length,
        'reviewers': all.where((u) => u['role'] == UserRole.reviewer.name).length,
        'admins': all.where((u) => u['role'] == UserRole.admin.name).length,
      };
    } catch (e) {
      debugPrint('❌ SupabaseAdminService: Failed to get user statistics: $e');
      throw Exception('Failed to get user statistics: $e');
    }
  }

  // Bulk approve pending users
  Future<void> bulkAssignRole(List<String> userUids, UserRole role) async {
    try {
      debugPrint('👑 SupabaseAdminService: Bulk assigning role ${role.name} to ${userUids.length} users');
      
      for (final uid in userUids) {
        await assignUserRole(uid, role);
      }
      
      debugPrint('✅ SupabaseAdminService: Bulk role assignment completed');
    } catch (e) {
      debugPrint('❌ SupabaseAdminService: Failed to bulk assign roles: $e');
      throw Exception('Failed to bulk assign roles: $e');
    }
  }

  // Search users
  Future<List<AppUser>> searchUsers(String query) async {
    try {
      debugPrint('👑 SupabaseAdminService: Searching users with query: $query');
      
      final response = await _supabase
          .from('users')
          .select()
          .or('name.ilike.%$query%,email.ilike.%$query%,department.ilike.%$query%')
          .order('name');

      return (response as List)
          .map((data) => AppUser.fromJson(data))
          .toList();
    } catch (e) {
      debugPrint('❌ SupabaseAdminService: Failed to search users: $e');
      throw Exception('Failed to search users: $e');
    }
  }
}
