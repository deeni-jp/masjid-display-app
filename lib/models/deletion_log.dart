// lib/models/deletion_log.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for user deletion audit trail
/// Stores complete user data snapshot when a user is deleted
class DeletionLog {
  final String logId;
  final String uid;
  final String email;
  final DateTime deletedAt;
  final String deletedBy;
  final String deletedByEmail;
  final Map<String, dynamic> userData;
  final String reason;

  DeletionLog({
    required this.logId,
    required this.uid,
    required this.email,
    required this.deletedAt,
    required this.deletedBy,
    required this.deletedByEmail,
    required this.userData,
    required this.reason,
  });

  /// Create DeletionLog from Firestore document
  factory DeletionLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DeletionLog(
      logId: doc.id,
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      deletedAt: (data['deletedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deletedBy: data['deletedBy'] ?? '',
      deletedByEmail: data['deletedByEmail'] ?? '',
      userData: data['userData'] ?? {},
      reason: data['reason'] ?? 'unknown',
    );
  }

  /// Create DeletionLog from Map (for use with getDeletionLogs)
  factory DeletionLog.fromMap(Map<String, dynamic> data) {
    return DeletionLog(
      logId: data['logId'] ?? '',
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      deletedAt: (data['deletedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deletedBy: data['deletedBy'] ?? '',
      deletedByEmail: data['deletedByEmail'] ?? '',
      userData: data['userData'] ?? {},
      reason: data['reason'] ?? 'unknown',
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'deletedAt': Timestamp.fromDate(deletedAt),
      'deletedBy': deletedBy,
      'deletedByEmail': deletedByEmail,
      'userData': userData,
      'reason': reason,
    };
  }

  /// Get user's display name from stored userData
  String get displayName {
    final name = userData['displayName'] as String?;
    return name?.isNotEmpty == true ? name! : 'No name';
  }

  /// Get user's role from stored userData
  String get role {
    final roleStr = userData['role'] as String?;
    return roleStr ?? 'public';
  }

  /// Get formatted deletion date
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(deletedAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${deletedAt.year}-${deletedAt.month.toString().padLeft(2, '0')}-${deletedAt.day.toString().padLeft(2, '0')}';
    }
  }
}
