// lib/services/firebase_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';
import '../utils/constants.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ============ IQAMA TIMES ============

  /// Get iqama times from Firestore
  static Future<Map<String, String>> getIqamaTimes() async {
    try {
      final docRef = _firestore
          .collection(AppConstants.collectionMosque)
          .doc(AppConstants.docIqama);

      final snapshot = await docRef.get();

      if (!snapshot.exists || snapshot.data() == null) {
        return {};
      }

      final data = snapshot.data()!;
      final iqamaMap = <String, String>{};

      data.forEach((key, value) {
        if (value != null) {
          iqamaMap[key] = value.toString();
        }
      });

      return iqamaMap;
    } catch (e) {
      throw FirebaseServiceException('Failed to get iqama times: $e');
    }
  }

  /// Save iqama times to Firestore
  static Future<void> saveIqamaTimes(Map<String, String> iqamaMap) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw FirebaseServiceException('User not authenticated');
      }

      final docRef = _firestore
          .collection(AppConstants.collectionMosque)
          .doc(AppConstants.docIqama);

      await docRef.set(iqamaMap, SetOptions(merge: true));
    } catch (e) {
      throw FirebaseServiceException('Failed to save iqama times: $e');
    }
  }

  /// Listen to iqama times changes
  static Stream<Map<String, String>> listenToIqamaTimes() {
    final docRef = _firestore
        .collection(AppConstants.collectionMosque)
        .doc(AppConstants.docIqama);

    return docRef.snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return <String, String>{};
      }

      final data = snapshot.data()!;
      final iqamaMap = <String, String>{};

      data.forEach((key, value) {
        if (value != null) {
          iqamaMap[key] = value.toString();
        }
      });

      return iqamaMap;
    });
  }

  // ============ NOTIFICATIONS (NEW COLLECTION-BASED) ============

  /// Get notifications collection reference
  static CollectionReference<Map<String, dynamic>> get _notificationsRef =>
      _firestore
          .collection(AppConstants.collectionMosque)
          .doc('data')
          .collection(AppConstants.collectionNotifications);

  /// Get all active notifications
  static Future<List<MosqueNotification>> getNotifications() async {
    try {
      final now = DateTime.now();

      final snapshot = await _notificationsRef
          .where('active', isEqualTo: true)
          .where('expiresAt', isGreaterThan: Timestamp.fromDate(now))
          .orderBy('expiresAt')
          .limit(AppConstants.maxActiveNotifications)
          .get();

      return snapshot.docs
          .map((doc) => MosqueNotification.fromFirestore(doc))
          .toList();
    } catch (e) {
      // If index doesn't exist, try simpler query
      try {
        final snapshot =
            await _notificationsRef.where('active', isEqualTo: true).get();

        final now = DateTime.now();
        return snapshot.docs
            .map((doc) => MosqueNotification.fromFirestore(doc))
            .where((n) => !n.isExpired)
            .toList();
      } catch (e2) {
        throw FirebaseServiceException('Failed to get notifications: $e2');
      }
    }
  }

  /// Get a single notification by ID
  static Future<MosqueNotification?> getNotificationById(String id) async {
    try {
      final doc = await _notificationsRef.doc(id).get();

      if (!doc.exists) {
        return null;
      }

      return MosqueNotification.fromFirestore(doc);
    } catch (e) {
      throw FirebaseServiceException('Failed to get notification: $e');
    }
  }

  /// Create a new notification
  static Future<MosqueNotification> createNotification(
      MosqueNotification notification) async {
    try {
      final user = _auth.currentUser;

      // Update postedBy with current user email if signed in
      final updatedNotification = user != null
          ? notification.copyWith(postedBy: user.email ?? notification.postedBy)
          : notification;

      final docRef = await _notificationsRef.add(
        updatedNotification.toFirestore(useServerTimestamp: true),
      );

      // Return notification with ID
      return updatedNotification.copyWith(id: docRef.id);
    } catch (e) {
      throw FirebaseServiceException('Failed to create notification: $e');
    }
  }

  /// Update an existing notification
  static Future<void> updateNotification(
      MosqueNotification notification) async {
    try {
      if (notification.id.isEmpty) {
        throw FirebaseServiceException(
            'Notification ID is required for update');
      }

      await _notificationsRef.doc(notification.id).update(
            notification.toFirestore(),
          );
    } catch (e) {
      throw FirebaseServiceException('Failed to update notification: $e');
    }
  }

  /// Delete a notification
  static Future<void> deleteNotification(String id) async {
    try {
      await _notificationsRef.doc(id).delete();
    } catch (e) {
      throw FirebaseServiceException('Failed to delete notification: $e');
    }
  }

  /// Deactivate a notification (soft delete)
  static Future<void> deactivateNotification(String id) async {
    try {
      await _notificationsRef.doc(id).update({'active': false});
    } catch (e) {
      throw FirebaseServiceException('Failed to deactivate notification: $e');
    }
  }

  /// Listen to active notifications changes
  static Stream<List<MosqueNotification>> listenToNotifications() {
    return _notificationsRef
        .where('active', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      return snapshot.docs
          .map((doc) => MosqueNotification.fromFirestore(doc))
          .where((n) => !n.isExpired)
          .toList()
        ..sort((a, b) => a.expiresAt.compareTo(b.expiresAt));
    });
  }

  /// Clean up expired notifications (delete permanently)
  static Future<int> cleanupExpiredNotifications() async {
    try {
      final now = DateTime.now();

      // Query expired notifications
      final snapshot = await _notificationsRef
          .where('expiresAt', isLessThan: Timestamp.fromDate(now))
          .get();

      if (snapshot.docs.isEmpty) {
        return 0;
      }

      // Batch delete
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      return snapshot.docs.length;
    } catch (e) {
      // If index error, try alternative approach
      try {
        final snapshot = await _notificationsRef.get();
        final now = DateTime.now();

        final expiredDocs = snapshot.docs.where((doc) {
          final notification = MosqueNotification.fromFirestore(doc);
          return notification.isExpired;
        }).toList();

        if (expiredDocs.isEmpty) {
          return 0;
        }

        final batch = _firestore.batch();
        for (final doc in expiredDocs) {
          batch.delete(doc.reference);
        }
        await batch.commit();

        return expiredDocs.length;
      } catch (e2) {
        throw FirebaseServiceException('Failed to cleanup notifications: $e2');
      }
    }
  }

  /// Get notifications by type
  static Future<List<MosqueNotification>> getNotificationsByType(
      NotificationType type) async {
    try {
      final snapshot = await _notificationsRef
          .where('active', isEqualTo: true)
          .where('type', isEqualTo: type.toFirestore())
          .get();

      final now = DateTime.now();
      return snapshot.docs
          .map((doc) => MosqueNotification.fromFirestore(doc))
          .where((n) => !n.isExpired)
          .toList();
    } catch (e) {
      throw FirebaseServiceException('Failed to get notifications by type: $e');
    }
  }

  /// Get notifications by priority
  static Future<List<MosqueNotification>> getNotificationsByPriority(
      NotificationPriority priority) async {
    try {
      final snapshot = await _notificationsRef
          .where('active', isEqualTo: true)
          .where('priority', isEqualTo: priority.toFirestore())
          .get();

      final now = DateTime.now();
      return snapshot.docs
          .map((doc) => MosqueNotification.fromFirestore(doc))
          .where((n) => !n.isExpired)
          .toList();
    } catch (e) {
      throw FirebaseServiceException(
          'Failed to get notifications by priority: $e');
    }
  }

  /// Get high priority notification with closest expiry
  static Future<MosqueNotification?> getHighPriorityNotification() async {
    try {
      final notifications = await getNotifications();
      final highPriority = notifications.highPriorityOnly.sortedByExpiry;
      return highPriority.isNotEmpty ? highPriority.first : null;
    } catch (e) {
      throw FirebaseServiceException(
          'Failed to get high priority notification: $e');
    }
  }

  // ============ LEGACY NOTIFICATION SUPPORT ============
  // These methods support the old single-document notification system
  // for backward compatibility during migration

  /// Get legacy notification from Firestore (single document)
  static Future<MosqueNotification?> getLegacyNotification() async {
    try {
      final docRef = _firestore
          .collection(AppConstants.collectionMosque)
          .doc(AppConstants.docNotification);

      final snapshot = await docRef.get();

      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }

      // Convert legacy format to new format
      final data = snapshot.data()!;
      return MosqueNotification(
        id: 'legacy',
        title: data['title']?.toString() ?? '',
        message: data['message']?.toString() ?? '',
        type: NotificationType.announcement,
        priority: NotificationPriority.regular,
        active: data['active'] == true,
        postedBy: data['postedBy']?.toString() ?? '',
        createdAt: _parseTimestamp(data['ts']) ?? DateTime.now(),
        expiresAt: DateTime.now().add(AppConstants.defaultAnnouncementExpiry),
      );
    } catch (e) {
      return null;
    }
  }

  /// Migrate legacy notification to new collection
  static Future<void> migrateLegacyNotification() async {
    try {
      final legacy = await getLegacyNotification();
      if (legacy != null && legacy.active && legacy.message.isNotEmpty) {
        // Create in new collection
        await createNotification(legacy);

        // Delete legacy document
        await _firestore
            .collection(AppConstants.collectionMosque)
            .doc(AppConstants.docNotification)
            .delete();
      }
    } catch (e) {
      // Ignore migration errors - not critical
    }
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  // ============ LEGACY NOTIFICATION (for backward compatibility) ============

  /// Save notification (legacy method - redirects to new system)
  @Deprecated('Use createNotification or updateNotification instead')
  static Future<void> saveNotification(MosqueNotification notification) async {
    if (notification.id.isEmpty) {
      await createNotification(notification);
    } else {
      await updateNotification(notification);
    }
  }

  /// Listen to notification (legacy method - redirects to new system)
  @Deprecated('Use listenToNotifications instead')
  static Stream<MosqueNotification> listenToNotification() {
    return listenToNotifications().map((list) {
      if (list.isEmpty) return MosqueNotification.empty();
      return list.priorityNotification ?? list.first;
    });
  }

  // ============ AUTHENTICATION ============

  /// Sign in with email and password
  static Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Check for local admin credentials
      if (email == AppConstants.localAdminEmail &&
          password == AppConstants.localAdminPassword) {
        // Local admin doesn't actually sign in to Firebase
        return null;
      }

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return credential.user;
    } on FirebaseAuthException catch (e) {
      String message = 'Sign-in failed';

      switch (e.code) {
        case 'user-not-found':
          message = 'No user found for that email';
          break;
        case 'wrong-password':
          message = 'Wrong password provided';
          break;
        case 'invalid-email':
          message = 'The email address is not valid';
          break;
        case 'user-disabled':
          message = 'This user account has been disabled';
          break;
        default:
          message = 'Sign-in failed: ${e.message}';
      }

      throw FirebaseServiceException(message);
    } catch (e) {
      throw FirebaseServiceException('Sign-in failed: $e');
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw FirebaseServiceException('Sign-out failed: $e');
    }
  }

  /// Get current user
  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Check if user is signed in
  static bool isSignedIn() {
    return _auth.currentUser != null;
  }

  /// Listen to auth state changes
  static Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  /// Check if email is local admin
  static bool isLocalAdmin(String email, String password) {
    return email == AppConstants.localAdminEmail &&
        password == AppConstants.localAdminPassword;
  }

  // ============ HELPER METHODS ============

  /// Test Firestore connection
  static Future<bool> testConnection() async {
    try {
      final docRef = _firestore
          .collection(AppConstants.collectionMosque)
          .doc(AppConstants.docIqama);

      await docRef.get().timeout(const Duration(seconds: 5));
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// Custom exception for Firebase service errors
class FirebaseServiceException implements Exception {
  final String message;

  FirebaseServiceException(this.message);

  @override
  String toString() => 'FirebaseServiceException: $message';
}
