// lib/services/fcm_notification_sender.dart
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/notification_model.dart';
import '../utils/env_config.dart';

/// Asks the push worker (push-worker/, a Cloudflare Worker) to send a push
/// notification for a notice to all users.
///
/// The worker holds the Firebase service-account key, checks that the
/// signed-in user is a moderator/admin, and builds the message from the
/// notice in Firestore. No credentials are kept in the app.
class FCMNotificationSender {
  /// Sends a push for [notification] (which must already be saved).
  /// Returns true if the worker accepted it.
  static Future<bool> sendNotificationToTopic({
    required MosqueNotification notification,
  }) async {
    final workerUrl = EnvConfig.pushWorkerUrl;
    if (workerUrl.isEmpty) {
      if (kDebugMode) {
        print('⚠️ PUSH_WORKER_URL is not set in .env; skipping push');
      }
      return false;
    }

    try {
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) {
        if (kDebugMode) print('❌ Not signed in; cannot send push');
        return false;
      }

      final response = await http
          .post(
            Uri.parse('$workerUrl/notify'),
            headers: {
              'Authorization': 'Bearer $idToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'notificationId': notification.id}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        if (kDebugMode) print('✅ Push notification sent');
        return true;
      }
      if (kDebugMode) {
        print(
          '❌ Push worker returned ${response.statusCode}: '
          '${response.body}',
        );
      }
      return false;
    } catch (e) {
      if (kDebugMode) print('❌ Error sending push notification: $e');
      return false;
    }
  }
}
