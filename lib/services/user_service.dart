// lib/services/user_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

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
      final query = await _firestore
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
        // Update last login
        await docRef.update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
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
  static Future<List<AppUser>> getAllUsers() async {
    try {
      final query =
          await _firestore.collection(_usersCollection).orderBy('email').get();

      return query.docs.map((doc) => AppUser.fromFirestore(doc)).toList();
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
      final snapshot = await _firestore
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
      final query = await _firestore
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
        .map((snapshot) =>
            snapshot.docs.map((doc) => AppUser.fromFirestore(doc)).toList());
  }

  // ============ AUTH OPERATIONS ============

  /// Sign in with email and password
  static Future<AppUser?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Check for local admin credentials
      if (email == AppConstants.localAdminEmail &&
          password == AppConstants.localAdminPassword) {
        // Return a local admin user (not saved to Firestore)
        return AppUser(
          uid: 'local_admin',
          email: AppConstants.localAdminEmail,
          displayName: 'Local Admin',
          role: UserRole.admin,
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
        );
      }

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
}

/// Custom exception for user service errors
class UserServiceException implements Exception {
  final String message;

  UserServiceException(this.message);

  @override
  String toString() => message;
}
