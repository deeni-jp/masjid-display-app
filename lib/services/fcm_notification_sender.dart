// lib/services/fcm_notification_sender.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import '../models/notification_model.dart';

/// Service to send push notifications to users via FCM HTTP v1 API
/// This works without Cloud Functions by sending directly from the app
class FCMNotificationSender {
  // Firebase project ID
  static const String _projectId = 'dticc-app';

  // FCM HTTP v1 endpoint
  static String get _fcmEndpoint =>
      'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send';

  /// Build service account JSON from environment variables
  /// Credentials are stored securely in .env file (gitignored)
  static String _buildServiceAccountJson() {
    return jsonEncode({
      'type': 'service_account',
      'project_id': dotenv.env['FCM_PROJECT_ID'],
      'private_key_id': dotenv.env['FCM_PRIVATE_KEY_ID'],
      'private_key': dotenv.env['FCM_PRIVATE_KEY'],
      'client_email': dotenv.env['FCM_CLIENT_EMAIL'],
      'client_id': dotenv.env['FCM_CLIENT_ID'],
      'auth_uri': dotenv.env['FCM_AUTH_URI'],
      'token_uri': dotenv.env['FCM_TOKEN_URI'],
      'auth_provider_x509_cert_url': dotenv.env['FCM_AUTH_PROVIDER_CERT_URL'],
      'client_x509_cert_url': dotenv.env['FCM_CLIENT_CERT_URL'],
      'universe_domain': dotenv.env['FCM_UNIVERSE_DOMAIN'],
    });
  }

  /// Get OAuth2 access token
  static Future<String?> _getAccessToken() async {
    try {
      // Validate that required environment variables are set
      if (dotenv.env['FCM_PROJECT_ID'] == null ||
          dotenv.env['FCM_PRIVATE_KEY'] == null ||
          dotenv.env['FCM_CLIENT_EMAIL'] == null) {
        if (kDebugMode) {
          print(
              '⚠️ FCM credentials not configured in .env file. Please add FCM_* variables to .env');
        }
        return null;
      }

      final accountCredentials = auth.ServiceAccountCredentials.fromJson(
        jsonDecode(_buildServiceAccountJson()),
      );

      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

      final client = await auth.clientViaServiceAccount(
        accountCredentials,
        scopes,
      );

      final accessToken = client.credentials.accessToken.data;
      client.close();

      return accessToken;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting access token: $e');
      }
      return null;
    }
  }

  /// Send push notification to all users via topic
  static Future<bool> sendNotificationToTopic({
    required MosqueNotification notification,
    String topic = 'mosque_notifications',
  }) async {
    try {
      // Get OAuth2 access token
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        if (kDebugMode) {
          print('❌ Failed to get access token');
        }
        return false;
      }

      // Prepare FCM HTTP v1 payload
      final payload = {
        'message': {
          'topic': topic,
          'notification': {
            'title': notification.title.isNotEmpty
                ? notification.title
                : 'New Mosque Notification',
            'body': _body(notification),
          },
          'data': {
            'notificationId': notification.id,
            'type': notification.type.name,
            'priority': notification.priority.name,
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          },
          'android': {
            'priority': _getAndroidPriority(notification.priority),
            'notification': {
              'channel_id': _getChannelId(notification.priority),
              'sound': notification.priority != NotificationPriority.low
                  ? 'default'
                  : null,
            },
          },
          'apns': {
            'payload': {
              'aps': {
                'sound': notification.priority != NotificationPriority.low
                    ? 'default'
                    : null,
                'badge': 1,
              },
            },
          },
        },
      };

      // Send request to FCM HTTP v1 API
      final response = await http.post(
        Uri.parse(_fcmEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('✅ Push notification sent successfully');
          print('Response: ${response.body}');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('❌ Failed to send push notification');
          print('Status: ${response.statusCode}');
          print('Response: ${response.body}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending push notification: $e');
      }
      return false;
    }
  }

  /// Send push notification to specific user by FCM token
  static Future<bool> sendNotificationToToken({
    required MosqueNotification notification,
    required String fcmToken,
  }) async {
    try {
      // Get OAuth2 access token
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        return false;
      }

      // Prepare FCM HTTP v1 payload
      final payload = {
        'message': {
          'token': fcmToken,
          'notification': {
            'title': notification.title.isNotEmpty
                ? notification.title
                : 'New Mosque Notification',
            'body': _body(notification),
          },
          'data': {
            'notificationId': notification.id,
            'type': notification.type.name,
            'priority': notification.priority.name,
          },
          'android': {
            'priority': _getAndroidPriority(notification.priority),
            'notification': {
              'channel_id': _getChannelId(notification.priority),
            },
          },
        },
      };

      // Send request to FCM HTTP v1 API
      final response = await http.post(
        Uri.parse(_fcmEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(payload),
      );

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending push notification: $e');
      }
      return false;
    }
  }

  /// Send push notification to multiple users (sends to each token individually)
  static Future<bool> sendNotificationToUsers({
    required MosqueNotification notification,
    required List<String> fcmTokens,
  }) async {
    if (fcmTokens.isEmpty) {
      if (kDebugMode) {
        print('⚠️ No FCM tokens provided');
      }
      return false;
    }

    int successCount = 0;
    for (final token in fcmTokens) {
      final sent = await sendNotificationToToken(
        notification: notification,
        fcmToken: token,
      );
      if (sent) successCount++;
    }

    if (kDebugMode) {
      print(
          '✅ Push notifications sent to $successCount/${fcmTokens.length} users');
    }

    return successCount > 0;
  }

  /// Get all user FCM tokens from Firestore
  static Future<List<String>> getAllUserTokens() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('users').get();

      final tokens = <String>[];
      for (final doc in snapshot.docs) {
        final token = doc.data()['fcmToken'] as String?;
        if (token != null && token.isNotEmpty) {
          tokens.add(token);
        }
      }

      if (kDebugMode) {
        print('📱 Found ${tokens.length} user FCM tokens');
      }

      return tokens;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting user tokens: $e');
      }
      return [];
    }
  }

  /// Helper: Get Android priority for FCM HTTP v1 API
  /// Note: FCM v1 API only accepts "HIGH" or "NORMAL" (case-sensitive)
  static String _getAndroidPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.high:
        return 'HIGH';
      case NotificationPriority.low:
        return 'NORMAL';
      default:
        return 'HIGH'; // Default to HIGH for regular priority
    }
  }

  /// Helper: Get notification channel ID
  static String _getChannelId(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.high:
        return 'high_importance_channel';
      case NotificationPriority.low:
        return 'low_importance_channel';
      default:
        return 'regular_channel';
    }
  }

  /// Push body: the description, or a prompt for image-only notices.
  static String _body(MosqueNotification notification) =>
      notification.hasMessage
          ? notification.message
          : '📷 New image notice — open the app to view';
}
