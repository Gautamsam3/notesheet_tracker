// lib/models/user.dart
import '../../utils/enums.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final UserStatus status;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.createdAt,
    this.lastLoginAt,
  });

  factory AppUser.fromMap(Map<String, dynamic> map, {String? docId}) {
    return AppUser(
      id: docId ?? map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.proposer,
      ),
      status: UserStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => UserStatus.active, // Default status if not found
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastLoginAt: (map['lastLoginAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt != null
          ? Timestamp.fromDate(lastLoginAt!)
          : null,
    };
  }

  @override
  String toString() {
    return 'AppUser(id: $id, name: $name, email: $email, role: $role, status: $status, createdAt: $createdAt)';
  }

  AppUser copyWith({
    String? name,
    String? email,
    UserRole? role,
    UserStatus? status,
    DateTime? lastLoginAt,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}
