// lib/services/user_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  static const String _usersCollection = 'users';

  // ============ CURRENT USER ============

  /// Get current Firebase Auth user
  static User? getCurrentAuthUser() {
    return _auth.currentUser;
  }

  /// Get current app user from Firestore
  static Future<AppUser?> getCurrentUser() async {
    final authUser = _auth.currentUser;
    if (authUser == null) return null;

    try {
      return await getUserById(authUser.uid);
    } catch (e) {
      return null;
    }
  }

  /// Get user by ID
  static Future<AppUser?> getUserById(String uid) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();

      if (!doc.exists) {
        return null;
      }

      return AppUser.fromFirestore(doc);
    } catch (e) {
      throw UserServiceException('Failed to get user: $e');
    }
  }

  /// Get user by email
  static Future<AppUser?> getUserByEmail(String email) async {
    try {
      final query =
          await _firestore
              .collection(_usersCollection)
              .where('email', isEqualTo: email.toLowerCase().trim())
              .limit(1)
              .get();

      if (query.docs.isEmpty) {
        return null;
      }

      return AppUser.fromFirestore(query.docs.first);
    } catch (e) {
      throw UserServiceException('Failed to get user by email: $e');
    }
  }

  // ============ USER CREATION & UPDATE ============

  /// Create or update user document on sign in
  static Future<AppUser> createOrUpdateUserOnSignIn(User authUser) async {
    try {
      final docRef = _firestore.collection(_usersCollection).doc(authUser.uid);
      final doc = await docRef.get();

      if (doc.exists) {
        final userData = doc.data();

        // Check if user has been deleted
        if (userData?['deleted'] == true) {
          // Sign out the user
          await _auth.signOut();
          throw UserServiceException(
            'This account has been deleted. Please contact an administrator.',
          );
        }

        // Update last login
        await docRef.update({'lastLogin': FieldValue.serverTimestamp()});
        return AppUser.fromFirestore(await docRef.get());
      } else {
        // Create new user with public role
        final newUser = AppUser.fromFirebaseUser(
          uid: authUser.uid,
          email: authUser.email ?? '',
          displayName: authUser.displayName,
        );

        await docRef.set(newUser.toFirestore());
        return newUser;
      }
    } catch (e) {
      throw UserServiceException('Failed to create/update user: $e');
    }
  }

  /// Update user role (Admin only)
  static Future<void> updateUserRole({
    required String uid,
    required UserRole newRole,
  }) async {
    try {
      // Verify current user is admin
      final currentUser = await getCurrentUser();
      if (currentUser == null || !currentUser.isAdmin) {
        throw UserServiceException('Only admins can change user roles');
      }

      // Prevent admin from changing their own role
      if (currentUser.uid == uid) {
        throw UserServiceException('You cannot change your own role');
      }

      await _firestore.collection(_usersCollection).doc(uid).update({
        'role': newRole.toFirestore(),
      });
    } catch (e) {
      if (e is UserServiceException) rethrow;
      throw UserServiceException('Failed to update user role: $e');
    }
  }

  // ============ USER LISTING & SEARCH ============

  /// Get all users (Admin only)
  /// Excludes deleted users
  static Future<List<AppUser>> getAllUsers() async {
    try {
      final query =
          await _firestore.collection(_usersCollection).orderBy('email').get();

      // Filter out deleted users (handles both deleted: true and missing field)
      return query.docs
          .where((doc) {
            final data = doc.data();
            return data['deleted'] != true;
          })
          .map((doc) => AppUser.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw UserServiceException('Failed to get users: $e');
    }
  }

  /// Search users by email (Admin only)
  static Future<List<AppUser>> searchUsersByEmail(String emailQuery) async {
    try {
      if (emailQuery.trim().isEmpty) {
        return await getAllUsers();
      }

      final query = emailQuery.toLowerCase().trim();

      // Firestore doesn't support LIKE queries, so we use range query
      final snapshot =
          await _firestore
              .collection(_usersCollection)
              .where('email', isGreaterThanOrEqualTo: query)
              .where('email', isLessThanOrEqualTo: '$query\uf8ff')
              .limit(50)
              .get();

      return snapshot.docs.map((doc) => AppUser.fromFirestore(doc)).toList();
    } catch (e) {
      throw UserServiceException('Failed to search users: $e');
    }
  }

  /// Get users by role
  static Future<List<AppUser>> getUsersByRole(UserRole role) async {
    try {
      final query =
          await _firestore
              .collection(_usersCollection)
              .where('role', isEqualTo: role.toFirestore())
              .orderBy('email')
              .get();

      return query.docs.map((doc) => AppUser.fromFirestore(doc)).toList();
    } catch (e) {
      throw UserServiceException('Failed to get users by role: $e');
    }
  }

  /// Stream all users (for real-time updates)
  static Stream<List<AppUser>> streamAllUsers() {
    return _firestore
        .collection(_usersCollection)
        .orderBy('email')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => AppUser.fromFirestore(doc)).toList(),
        );
  }

  // ============ AUTH OPERATIONS ============

  /// Sign in with email and password
  static Future<AppUser?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw UserServiceException('Sign-in failed');
      }

      // Create or update user in Firestore
      return await createOrUpdateUserOnSignIn(credential.user!);
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

      throw UserServiceException(message);
    } catch (e) {
      if (e is UserServiceException) rethrow;
      throw UserServiceException('Sign-in failed: $e');
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw UserServiceException('Sign-out failed: $e');
    }
  }

  /// Listen to auth state changes
  static Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  /// Check if user is signed in
  static bool isSignedIn() {
    return _auth.currentUser != null;
  }

  // ============ PERMISSION CHECKS ============

  /// Check if current user can manage announcements
  static Future<bool> canManageAnnouncements() async {
    final user = await getCurrentUser();
    return user?.canManageAnnouncements ?? false;
  }

  /// Check if current user can manage users
  static Future<bool> canManageUsers() async {
    final user = await getCurrentUser();
    return user?.canManageUsers ?? false;
  }

  /// Check if current user can manage iqama
  static Future<bool> canManageIqama() async {
    final user = await getCurrentUser();
    return user?.canManageIqama ?? false;
  }

  // ============ ADMIN USER MANAGEMENT ============

  /// Send password reset email to user (Admin only)
  static Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      // Verify current user is admin
      final currentUser = await getCurrentUser();
      if (currentUser == null || !currentUser.isAdmin) {
        throw UserServiceException('Only admins can reset user passwords');
      }

      // Send password reset email via Firebase Auth
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      String message = 'Failed to send password reset email';

      switch (e.code) {
        case 'user-not-found':
          message = 'No account found with this email';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Please try again later';
          break;
        default:
          message = e.message ?? message;
      }

      throw UserServiceException(message);
    } catch (e) {
      if (e is UserServiceException) rethrow;
      throw UserServiceException('Failed to send password reset email: $e');
    }
  }

  /// Check if user can be safely deleted
  /// Returns error message if cannot delete, null if can delete
  static Future<String?> canDeleteUser(String uid) async {
    final currentUser = await getCurrentUser();

    if (currentUser == null || !currentUser.isAdmin) {
      return 'Only admins can delete users';
    }

    if (currentUser.uid == uid) {
      return 'You cannot delete your own account';
    }

    // Check if deleting last admin
    final admins = await getUsersByRole(UserRole.admin);
    if (admins.length == 1 && admins.first.uid == uid) {
      return 'Cannot delete the last admin user';
    }

    return null; // Can delete
  }

  /// Delete user (Soft delete for Spark plan compatibility)
  /// Marks user as deleted in Firestore and disables their account
  /// Creates audit log in deletion_logs collection
  /// NOTE: For full deletion (Auth + Firestore), upgrade to Blaze plan
  /// and use Cloud Functions
  static Future<void> deleteUser({
    required String uid,
    required String email,
  }) async {
    try {
      // Safety checks
      final canDelete = await canDeleteUser(uid);
      if (canDelete != null) {
        throw UserServiceException(canDelete);
      }

      // Get user data before deletion for audit log
      final userDoc =
          await _firestore.collection(_usersCollection).doc(uid).get();

      if (!userDoc.exists) {
        throw UserServiceException('User not found');
      }

      final userData = userDoc.data()!;

      // Create audit log BEFORE marking as deleted
      await logDeletion(uid: uid, email: email, userData: userData);

      // Soft delete: Mark user as deleted in Firestore
      // This prevents them from accessing the app
      await _firestore.collection(_usersCollection).doc(uid).update({
        'deleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': _auth.currentUser?.uid,
        'active': false,
      });

      // Note: Firebase Auth account remains (can't delete from client)
      // To fully delete Auth account, upgrade to Blaze plan and use Cloud Functions
    } catch (e) {
      if (e is UserServiceException) rethrow;
      throw UserServiceException('Failed to delete user: $e');
    }
  }

  /// Hard delete user (Firestore + Auth) via Cloud Function
  /// Only works on Blaze plan after deploying the deleteUser Cloud Function
  static Future<void> hardDeleteUser({
    required String uid,
    required String email,
  }) async {
    try {
      // Safety checks
      final canDelete = await canDeleteUser(uid);
      if (canDelete != null) {
        throw UserServiceException(canDelete);
      }

      // Call Cloud Function to delete user
      final callable = _functions.httpsCallable('deleteUser');
      final result = await callable.call({'uid': uid, 'email': email});

      if (result.data['success'] != true) {
        throw UserServiceException(
          result.data['error'] ?? 'Failed to delete user',
        );
      }
    } on FirebaseFunctionsException catch (e) {
      throw UserServiceException(
        'Server error: ${e.message ?? 'Failed to delete user'}',
      );
    } catch (e) {
      if (e is UserServiceException) rethrow;
      throw UserServiceException('Failed to delete user: $e');
    }
  }

  /// Log user deletion for audit trail
  /// Stores complete user data snapshot in deletion_logs collection
  static Future<void> logDeletion({
    required String uid,
    required String email,
    required Map<String, dynamic> userData,
  }) async {
    try {
      await _firestore.collection('deletion_logs').add({
        'uid': uid,
        'email': email,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': _auth.currentUser?.uid,
        'deletedByEmail': _auth.currentUser?.email,
        'userData': userData,
        'reason': 'admin_deletion',
      });
    } catch (e) {
      // Log warning but don't fail deletion if audit logging fails
      print('Warning: Failed to log deletion: $e');
    }
  }

  /// Delete user with audit trail (recommended approach)
  /// 1. Logs complete user data to deletion_logs collection
  /// 2. Hard deletes user from Auth and Firestore
  /// This allows deleted users to re-signup while maintaining audit records
  static Future<void> deleteUserWithAudit({
    required String uid,
    required String email,
  }) async {
    try {
      // Safety checks
      final canDelete = await canDeleteUser(uid);
      if (canDelete != null) {
        throw UserServiceException(canDelete);
      }

      // Get user document before deletion
      final userDoc =
          await _firestore.collection(_usersCollection).doc(uid).get();
      if (!userDoc.exists) {
        throw UserServiceException('User not found');
      }

      final userData = userDoc.data()!;

      // 1. Log deletion first (for audit trail)
      await logDeletion(uid: uid, email: email, userData: userData);

      // 2. Then hard delete (removes Auth + Firestore)
      await hardDeleteUser(uid: uid, email: email);
    } catch (e) {
      if (e is UserServiceException) rethrow;
      throw UserServiceException('Failed to delete user: $e');
    }
  }

  /// Get all deletion logs (Admin only)
  /// Returns list of deleted users for audit purposes
  static Future<List<Map<String, dynamic>>> getDeletionLogs() async {
    try {
      // Verify current user is admin
      final currentUser = await getCurrentUser();
      if (currentUser == null || !currentUser.isAdmin) {
        throw UserServiceException('Only admins can view deletion logs');
      }

      final query =
          await _firestore
              .collection('deletion_logs')
              .orderBy('deletedAt', descending: true)
              .get();

      return query.docs.map((doc) {
        final data = doc.data();
        data['logId'] = doc.id; // Add document ID for permanent deletion
        return data;
      }).toList();
    } catch (e) {
      if (e is UserServiceException) rethrow;
      throw UserServiceException('Failed to get deletion logs: $e');
    }
  }

  /// Permanently delete a deletion log (Admin only)
  /// Used for cleaning up test user records from audit trail
  static Future<void> permanentlyDeleteLog(String logId) async {
    try {
      // Verify current user is admin
      final currentUser = await getCurrentUser();
      if (currentUser == null || !currentUser.isAdmin) {
        throw UserServiceException('Only admins can delete logs');
      }

      await _firestore.collection('deletion_logs').doc(logId).delete();
    } catch (e) {
      if (e is UserServiceException) rethrow;
      throw UserServiceException('Failed to delete log: $e');
    }
  }
}

/// Custom exception for user service errors
class UserServiceException implements Exception {
  final String message;

  UserServiceException(this.message);

  @override
  String toString() => message;
}
