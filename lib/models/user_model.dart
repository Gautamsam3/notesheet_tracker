enum UserRole {
  requester,
  reviewer,
  admin;

  String get displayName {
    switch (this) {
      case UserRole.requester:
        return 'Requester';
      case UserRole.reviewer:
        return 'Reviewer';
      case UserRole.admin:
        return 'Admin';
    }
  }
}

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String department;
  final UserRole? role; // null = awaiting admin approval
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.department,
    this.role,
    required this.createdAt,
  });

  // Helper getters
  bool get hasRole => role != null;
  bool get isRequester => role == UserRole.requester;
  bool get isReviewer => role == UserRole.reviewer;
  bool get isAdmin => role == UserRole.admin;
  bool get isPendingApproval => role == null;

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'department': department,
      'role': role?.name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    UserRole? role;
    if (json['role'] != null) {
      role = UserRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => throw ArgumentError('Invalid role: ${json['role']}'),
      );
    }
    
    return AppUser(
      uid: json['uid'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      department: json['department'] as String,
      role: role,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  AppUser copyWith({
    String? uid,
    String? name,
    String? email,
    String? department,
    UserRole? role,
    DateTime? createdAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      department: department ?? this.department,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
