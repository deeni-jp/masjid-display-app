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

  // ============ NOTIFICATIONS ============

  /// Get notification from Firestore
  static Future<MosqueNotification> getNotification() async {
    try {
      final docRef = _firestore
          .collection(AppConstants.collectionMosque)
          .doc(AppConstants.docNotification);

      final snapshot = await docRef.get();

      if (!snapshot.exists || snapshot.data() == null) {
        return MosqueNotification.empty();
      }

      return MosqueNotification.fromFirestore(snapshot.data()!);
    } catch (e) {
      throw FirebaseServiceException('Failed to get notification: $e');
    }
  }

  /// Save notification to Firestore
  static Future<void> saveNotification(MosqueNotification notification) async {
    try {
      final user = _auth.currentUser;

      // Update postedBy with current user email if signed in
      final updatedNotification = user != null
          ? notification.copyWith(postedBy: user.email ?? notification.postedBy)
          : notification;

      final docRef = _firestore
          .collection(AppConstants.collectionMosque)
          .doc(AppConstants.docNotification);

      await docRef.set(
        updatedNotification.toFirestore(useServerTimestamp: true),
        SetOptions(merge: true),
      );
    } catch (e) {
      throw FirebaseServiceException('Failed to save notification: $e');
    }
  }

  /// Listen to notification changes
  static Stream<MosqueNotification> listenToNotification() {
    final docRef = _firestore
        .collection(AppConstants.collectionMosque)
        .doc(AppConstants.docNotification);

    return docRef.snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return MosqueNotification.empty();
      }

      return MosqueNotification.fromFirestore(snapshot.data()!);
    });
  }

  /// Deactivate notification
  static Future<void> deactivateNotification() async {
    try {
      final docRef = _firestore
          .collection(AppConstants.collectionMosque)
          .doc(AppConstants.docNotification);

      await docRef.update({'active': false});
    } catch (e) {
      throw FirebaseServiceException('Failed to deactivate notification: $e');
    }
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
