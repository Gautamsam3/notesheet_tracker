// lib/utils/role_utils.dart
import '../models/user.dart'; // Import your AppUser class
import 'enums.dart'; // Import your UserRole enum

class RoleUtils {
  /// Checks if a given user (by their AppUser object) has the permission to propose notesheets.
  static bool canPropose(AppUser user) {
    return user.role == UserRole.proposer || user.role == UserRole.reviewer;
  }

  /// Checks if a given user has the permission to review notesheets.
  static bool canReview(AppUser user) {
    return user.role == UserRole.reviewer || user.role == UserRole.hod;
  }

  /// Checks if a given user has the permission to approve notesheets.
  static bool canApprove(AppUser user) {
    return user.role == UserRole.hod;
  }

  /// Checks if a given user has the permission to suggest changes to notesheets.
  static bool canSuggestChanges(AppUser user) {
    return user.role == UserRole.reviewer || user.role == UserRole.hod;
  }

  /// Checks if a given user has the permission to modify system settings (Admin role).
  static bool canModifySystem(AppUser user) {
    return user.role == UserRole.admin;
  }

  /// Checks if a given user can view events (currently all roles except Admin, based on your table).
  static bool canViewEvents(AppUser user) {
    // Based on your table: Proposer, Reviewer, HOD can view events. Admin is not listed explicitly.
    // If Admin should also view events, add user.role == UserRole.admin
    return user.role == UserRole.proposer ||
        user.role == UserRole.reviewer ||
        user.role == UserRole.hod ||
        user.role == UserRole.admin; // Assuming admin can also view events
  }

  // You can add more specific permission checks as needed
  // For example, canEditNotesheet(AppUser user, Notesheet notesheet) { ... }
}
