// lib/services/push_notification_service.dart
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/notification_model.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('Handling background message: ${message.messageId}');
  }

  // You can process the notification here if needed
  // For example, save to local storage, update badge count, etc.
}

/// Service to handle push notifications using Firebase Cloud Messaging
class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  final StreamController<RemoteMessage> _messageStreamController =
      StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get messageStream => _messageStreamController.stream;

  bool _initialized = false;

  /// Initialize push notification service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Request permission for notifications
      final settings = await _requestPermission();

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        if (kDebugMode) {
          print('Push notification permission granted');
        }

        // Initialize local notifications
        await _initializeLocalNotifications();

        // Get and save FCM token
        await _initializeFCMToken();

        // Setup message handlers
        _setupMessageHandlers();

        // Listen for token refresh
        _messaging.onTokenRefresh.listen(_onTokenRefresh);

        _initialized = true;

        if (kDebugMode) {
          print('Push notification service initialized successfully');
        }
      } else {
        if (kDebugMode) {
          print('Push notification permission denied');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing push notifications: $e');
      }
    }
  }

  /// Request notification permissions from user
  Future<NotificationSettings> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    return settings;
  }

  /// Initialize local notifications for showing notifications when app is in foreground
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _createNotificationChannels();
    }
  }

  /// Create Android notification channels
  Future<void> _createNotificationChannels() async {
    const highImportanceChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Priority Notifications',
      description: 'This channel is used for high priority notifications',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    const regularChannel = AndroidNotificationChannel(
      'regular_channel',
      'Regular Notifications',
      description: 'This channel is used for regular notifications',
      importance: Importance.defaultImportance,
      enableVibration: true,
      playSound: true,
    );

    const lowChannel = AndroidNotificationChannel(
      'low_importance_channel',
      'Low Priority Notifications',
      description: 'This channel is used for low priority notifications',
      importance: Importance.low,
      enableVibration: false,
      playSound: false,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(highImportanceChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(regularChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(lowChannel);
  }

  /// Get the FCM token. Pushes go to the 'mosque_notifications' topic, so
  /// the token isn't stored anywhere.
  Future<void> _initializeFCMToken() async {
    try {
      _fcmToken = await _messaging.getToken();

      if (_fcmToken != null) {
        debugPrint('FCM Token: $_fcmToken');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting FCM token: $e');
      }
    }
  }

  /// Handle token refresh
  Future<void> _onTokenRefresh(String token) async {
    _fcmToken = token;

    if (kDebugMode) {
      print('FCM token refreshed: $token');
    }
  }

  /// Setup message handlers for different app states
  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle messages when app is opened from background state
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Handle initial message if app was opened from terminated state
    _getInitialMessage();

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  /// Handle messages received while app is in foreground
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (kDebugMode) {
      print('Received foreground message: ${message.messageId}');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
      print('Data: ${message.data}');
    }

    // Show local notification
    await _showLocalNotification(message);

    // Add to stream for app to handle
    _messageStreamController.add(message);
  }

  /// Handle message when app is opened from background
  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    if (kDebugMode) {
      print('Message opened app: ${message.messageId}');
    }

    // Add to stream for app to handle (e.g., navigate to notifications tab)
    _messageStreamController.add(message);
  }

  /// Get initial message if app was opened from terminated state
  Future<void> _getInitialMessage() async {
    final message = await _messaging.getInitialMessage();

    if (message != null) {
      if (kDebugMode) {
        print(
          'App opened from terminated state by message: ${message.messageId}',
        );
      }

      // Add to stream for app to handle
      _messageStreamController.add(message);
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    // Determine notification priority from data
    final priorityString = message.data['priority'] as String?;
    final priority = NotificationPriority.fromString(priorityString);

    // Select channel based on priority
    String channelId;
    Importance importance;
    Priority androidPriority;

    switch (priority) {
      case NotificationPriority.high:
        channelId = 'high_importance_channel';
        importance = Importance.high;
        androidPriority = Priority.high;
        break;
      case NotificationPriority.low:
        channelId = 'low_importance_channel';
        importance = Importance.low;
        androidPriority = Priority.low;
        break;
      default:
        channelId = 'regular_channel';
        importance = Importance.defaultImportance;
        androidPriority = Priority.defaultPriority;
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      _getChannelName(priority),
      channelDescription: _getChannelDescription(priority),
      importance: importance,
      priority: androidPriority,
      icon: '@mipmap/ic_launcher',
      enableVibration: priority != NotificationPriority.low,
      playSound: priority != NotificationPriority.low,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Use notification ID from data if available, otherwise use timestamp
    final notificationId =
        message.data['notificationId'] != null
            ? int.tryParse(message.data['notificationId']) ??
                DateTime.now().millisecondsSinceEpoch ~/ 1000
            : DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await _localNotifications.show(
      notificationId,
      notification.title ?? 'Mosque Notification',
      notification.body ?? '',
      notificationDetails,
      payload:
          message
              .data['notificationId'], // Pass notification ID for handling tap
    );
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      print('Notification tapped with payload: ${response.payload}');
    }

    // You can navigate to specific screen based on payload
    // This will be handled by the app when it subscribes to the message stream
  }

  /// Get channel name based on priority
  String _getChannelName(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.high:
        return 'High Priority Notifications';
      case NotificationPriority.low:
        return 'Low Priority Notifications';
      default:
        return 'Regular Notifications';
    }
  }

  /// Get channel description based on priority
  String _getChannelDescription(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.high:
        return 'Important announcements and alerts';
      case NotificationPriority.low:
        return 'Low priority updates';
      default:
        return 'General mosque notifications';
    }
  }

  /// Subscribe to a topic (e.g., for all users to receive notifications)
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);

      if (kDebugMode) {
        print('Subscribed to topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error subscribing to topic: $e');
      }
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);

      if (kDebugMode) {
        print('Unsubscribed from topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error unsubscribing from topic: $e');
      }
    }
  }

  /// Delete FCM token (e.g., on logout)
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      _fcmToken = null;

      if (kDebugMode) {
        print('FCM token deleted');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting FCM token: $e');
      }
    }
  }

  /// Dispose resources
  void dispose() {
    _messageStreamController.close();
  }
}
