// lib/services/firebase_service.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';
import '../utils/constants.dart';
import 'notice_image_service.dart';
import 'prayer_service.dart';

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
      // Validate iqama times before saving
      PrayerService.validateIqamaTimes(iqamaMap);

      final user = _auth.currentUser;
      if (user == null) {
        throw FirebaseServiceException('User not authenticated');
      }

      final docRef = _firestore
          .collection(AppConstants.collectionMosque)
          .doc(AppConstants.docIqama);

      await docRef.set(iqamaMap, SetOptions(merge: true));
    } on PrayerServiceException catch (e) {
      throw FirebaseServiceException('Invalid iqama times: ${e.message}');
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

  /// Notice images, one document per notice, keyed by the notice id.
  /// Kept apart from the notices so the live notices listener stays small.
  static CollectionReference<Map<String, dynamic>> get _imagesRef => _firestore
      .collection(AppConstants.collectionMosque)
      .doc('data')
      .collection('notification_images');

  static Map<String, dynamic> _imageDoc(PreparedImage image) => {
    'data': Blob(image.bytes),
    'contentType': NoticeImageService.contentType,
    'width': image.width,
    'height': image.height,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  /// The image bytes attached to a notice, or null if there are none.
  static Future<Uint8List?> getNotificationImage(String notificationId) async {
    try {
      final doc = await _imagesRef.doc(notificationId).get();
      final data = doc.data()?['data'];
      return data is Blob ? data.bytes : null;
    } catch (e) {
      throw FirebaseServiceException('Failed to load notice image: $e');
    }
  }

  /// Get all active notifications
  static Future<List<MosqueNotification>> getNotifications() async {
    try {
      final now = DateTime.now();

      final snapshot =
          await _notificationsRef
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

  /// Create a new notification, optionally with an [image].
  /// The notice and its image are written in one batch, so readers never see
  /// a notice whose image isn't there yet.
  static Future<MosqueNotification> createNotification(
    MosqueNotification notification, {
    PreparedImage? image,
  }) async {
    try {
      final user = _auth.currentUser;

      // Update postedBy with current user email if signed in
      var updatedNotification =
          user != null
              ? notification.copyWith(
                postedBy: user.email ?? notification.postedBy,
              )
              : notification;

      if (image != null) {
        updatedNotification = updatedNotification.copyWith(
          hasImage: true,
          imageWidth: image.width,
          imageHeight: image.height,
          imageUpdatedAt: DateTime.now(),
        );
      }

      final docRef = _notificationsRef.doc();
      final batch = _firestore.batch();
      batch.set(
        docRef,
        updatedNotification.toFirestore(useServerTimestamp: true),
      );
      if (image != null) {
        batch.set(_imagesRef.doc(docRef.id), _imageDoc(image));
      }
      await batch.commit();

      // Return notification with ID
      return updatedNotification.copyWith(id: docRef.id);
    } catch (e) {
      throw FirebaseServiceException('Failed to create notification: $e');
    }
  }

  /// Update an existing notification. Pass [newImage] to add or replace its
  /// image, or [removeImage] to delete it. Returns the saved notification.
  static Future<MosqueNotification> updateNotification(
    MosqueNotification notification, {
    PreparedImage? newImage,
    bool removeImage = false,
  }) async {
    try {
      if (notification.id.isEmpty) {
        throw FirebaseServiceException(
          'Notification ID is required for update',
        );
      }

      var toSave = notification;
      if (newImage != null) {
        toSave = notification.copyWith(
          hasImage: true,
          imageWidth: newImage.width,
          imageHeight: newImage.height,
          imageUpdatedAt: DateTime.now(),
        );
      } else if (removeImage) {
        toSave = notification.copyWith(hasImage: false);
      }

      final imageRef = _imagesRef.doc(notification.id);
      final batch = _firestore.batch();
      batch.update(
        _notificationsRef.doc(notification.id),
        toSave.toFirestore(),
      );
      if (newImage != null) {
        batch.set(imageRef, _imageDoc(newImage));
      } else if (removeImage) {
        batch.delete(imageRef);
      }
      await batch.commit();

      return toSave;
    } catch (e) {
      throw FirebaseServiceException('Failed to update notification: $e');
    }
  }

  /// Delete a notification (and its image, if any)
  static Future<void> deleteNotification(String id) async {
    try {
      await _deleteWithImages([id]);
    } catch (e) {
      throw FirebaseServiceException('Failed to delete notification: $e');
    }
  }

  /// Deletes notices and their image documents. Deleting an image document
  /// that doesn't exist is a no-op. Commits in chunks to stay under
  /// Firestore's 500-writes-per-batch limit.
  static Future<void> _deleteWithImages(List<String> ids) async {
    const perBatch = 200; // 2 writes each
    for (var i = 0; i < ids.length; i += perBatch) {
      final batch = _firestore.batch();
      for (final id in ids.skip(i).take(perBatch)) {
        batch.delete(_notificationsRef.doc(id));
        batch.delete(_imagesRef.doc(id));
      }
      await batch.commit();
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
    return _notificationsRef.where('active', isEqualTo: true).snapshots().map((
      snapshot,
    ) {
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
      final snapshot =
          await _notificationsRef
              .where('expiresAt', isLessThan: Timestamp.fromDate(now))
              .get();

      if (snapshot.docs.isEmpty) {
        return 0;
      }

      await _deleteWithImages(snapshot.docs.map((d) => d.id).toList());

      return snapshot.docs.length;
    } catch (e) {
      // If index error, try alternative approach
      try {
        final snapshot = await _notificationsRef.get();
        final now = DateTime.now();

        final expiredDocs =
            snapshot.docs.where((doc) {
              final notification = MosqueNotification.fromFirestore(doc);
              return notification.isExpired;
            }).toList();

        if (expiredDocs.isEmpty) {
          return 0;
        }

        await _deleteWithImages(expiredDocs.map((d) => d.id).toList());

        return expiredDocs.length;
      } catch (e2) {
        throw FirebaseServiceException('Failed to cleanup notifications: $e2');
      }
    }
  }

  /// Get notifications by type
  static Future<List<MosqueNotification>> getNotificationsByType(
    NotificationType type,
  ) async {
    try {
      final snapshot =
          await _notificationsRef
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
    NotificationPriority priority,
  ) async {
    try {
      final snapshot =
          await _notificationsRef
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
        'Failed to get notifications by priority: $e',
      );
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
        'Failed to get high priority notification: $e',
      );
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
