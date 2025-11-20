// lib/utils/enums.dart

/// Defines the different roles a user can have in the application.
enum UserRole { admin, proposer, reviewer, hod }

/// Defines the different administrative statuses for a user account.
enum UserStatus {
  active, // User can log in and perform assigned role tasks
  suspended, // User can log in but cannot access role-assigned methods, with a message
  terminated, // User cannot log in (account disabled)
}

/// Defines the possible statuses for a Notesheet.
enum NotesheetStatus {
  underConsideration, // Initial status after proposal
  pendingApproval, // After sufficient reviewer approvals
  approved, // Approved by HOD, an Event is created
  rejected, // Explicitly rejected by HOD
  rejectedWithSuggestions, // Original notesheet status when HOD suggests changes
  awaitingProposerResponse, // Sudo notesheet status, waiting for proposer's decision
  expiredDueToReviews, // Notesheet expired due to lack of reviews within timeframe
  expiredDueToApproval, // Notesheet expired due to HOD not approving within timeframe
}

/// Defines the lifecycle statuses for an Event.
enum EventStatus {
  upcoming, // Event date is in the future
  ongoing, // Event is currently happening
  occurred, // Event has finished (your "completed")
  cancelled, // Optional: If events can be cancelled
}

/// Defines possible decisions a reviewer can make.
enum ReviewDecision {
  accept,
  reject, // Reviewer rejecting (not leading to final rejection, but not accepting)
  suggestChanges, // Reviewer suggesting changes
}

/// Defines possible decisions an HOD can make regarding a notesheet.
enum HODDecision { approve, reject, suggestChanges }
