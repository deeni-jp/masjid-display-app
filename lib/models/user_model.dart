// lib/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  public,
  moderator,
  admin;

  /// Get display name for the role
  String get displayName {
    switch (this) {
      case UserRole.public:
        return 'Public';
      case UserRole.moderator:
        return 'Moderator';
      case UserRole.admin:
        return 'Admin';
    }
  }

  /// Get role from string
  static UserRole fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'moderator':
        return UserRole.moderator;
      default:
        return UserRole.public;
    }
  }

  /// Convert to string for Firestore
  String toFirestore() {
    return name;
  }
}

class AppUser {
  final String uid;
  final String email;
  final String? displayName;
  final UserRole role;
  final DateTime createdAt;
  final DateTime? lastLogin;

  AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    required this.role,
    required this.createdAt,
    this.lastLogin,
  });

  /// Create empty/default user
  factory AppUser.empty() {
    return AppUser(
      uid: '',
      email: '',
      displayName: null,
      role: UserRole.public,
      createdAt: DateTime.now(),
      lastLogin: null,
    );
  }

  /// Create from Firebase Auth user (new user)
  factory AppUser.fromFirebaseUser({
    required String uid,
    required String email,
    String? displayName,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      displayName: displayName,
      role: UserRole.public,
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
    );
  }

  /// Create from Firestore document
  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      return AppUser.empty();
    }

    DateTime createdAt;
    final createdAtRaw = data['createdAt'];
    if (createdAtRaw is Timestamp) {
      createdAt = createdAtRaw.toDate();
    } else if (createdAtRaw is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(createdAtRaw);
    } else {
      createdAt = DateTime.now();
    }

    DateTime? lastLogin;
    final lastLoginRaw = data['lastLogin'];
    if (lastLoginRaw is Timestamp) {
      lastLogin = lastLoginRaw.toDate();
    } else if (lastLoginRaw is int) {
      lastLogin = DateTime.fromMillisecondsSinceEpoch(lastLoginRaw);
    }

    return AppUser(
      uid: doc.id,
      email: data['email']?.toString() ?? '',
      displayName: data['displayName']?.toString(),
      role: UserRole.fromString(data['role']?.toString()),
      createdAt: createdAt,
      lastLogin: lastLogin,
    );
  }

  /// Create from Map (for local storage)
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      displayName: map['displayName']?.toString(),
      role: UserRole.fromString(map['role']?.toString()),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      lastLogin:
          map['lastLogin'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['lastLogin'])
              : null,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role.toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
      'deleted': false,
      'active': true,
    };
  }

  /// Convert to Map (for local storage)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': role.toFirestore(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastLogin': lastLogin?.millisecondsSinceEpoch,
    };
  }

  /// Check if user is admin
  bool get isAdmin => role == UserRole.admin;

  /// Check if user is moderator
  bool get isModerator => role == UserRole.moderator;

  /// Check if user is public
  bool get isPublic => role == UserRole.public;

  /// Check if user can manage announcements (admin or moderator)
  bool get canManageAnnouncements => isAdmin || isModerator;

  /// Check if user can manage users (admin only)
  bool get canManageUsers => isAdmin;

  /// Check if user can manage iqama times (admin only)
  bool get canManageIqama => isAdmin;

  /// Copy with new values
  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    UserRole? role,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  @override
  String toString() {
    return 'AppUser(uid: $uid, email: $email, role: ${role.displayName})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppUser && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}
