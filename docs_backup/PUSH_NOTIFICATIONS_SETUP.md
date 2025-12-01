# Push Notifications Setup Guide

This guide will help you configure push notifications for the Prayer Times App using Firebase Cloud Messaging (FCM).

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Install Dependencies](#install-dependencies)
3. [Android Configuration](#android-configuration)
4. [iOS Configuration](#ios-configuration)
5. [Cloud Functions Setup](#cloud-functions-setup)
6. [Testing Push Notifications](#testing-push-notifications)
7. [Troubleshooting](#troubleshooting)

---

## Prerequisites

- Firebase project already set up (you should have `firebase_options.dart` and `google-services.json`)
- Flutter SDK installed
- Firebase CLI installed (`npm install -g firebase-tools`)
- Node.js installed (for Cloud Functions)

---

## Install Dependencies

The dependencies have already been added to `pubspec.yaml`. Run:

```bash
flutter pub get
```

This will install:
- `firebase_messaging: ^15.1.5` - Firebase Cloud Messaging
- `flutter_local_notifications: ^18.0.1` - Local notifications for foreground messages

---

## Android Configuration

### 1. Update `android/app/build.gradle`

Make sure your `minSdkVersion` is at least 21:

```gradle
android {
    defaultConfig {
        minSdkVersion 21  // Changed from 19 if needed
        targetSdkVersion flutter.targetSdkVersion
    }
}
```

### 2. Update `android/app/src/main/AndroidManifest.xml`

Add the following permissions and intent filter:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Add these permissions -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.VIBRATE" />
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>

    <application
        android:label="Prayer App"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">

        <activity
            android:name=".MainActivity"
            <!-- ... existing config ... -->

            <!-- Add this intent filter inside the MainActivity -->
            <intent-filter>
                <action android:name="FLUTTER_NOTIFICATION_CLICK" />
                <category android:name="android.intent.category.DEFAULT" />
            </intent-filter>
        </activity>

        <!-- Add FCM default channel -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_channel_id"
            android:value="high_importance_channel" />

        <!-- Don't delete the meta-data below. This is used by the Flutter tool -->
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
```

### 3. Verify `google-services.json`

Ensure `google-services.json` is in `android/app/` directory and contains your Firebase configuration.

---

## iOS Configuration

### 1. Enable Push Notifications Capability

1. Open your iOS project in Xcode (`ios/Runner.xcworkspace`)
2. Select the `Runner` project in the navigator
3. Go to **Signing & Capabilities** tab
4. Click **+ Capability**
5. Add **Push Notifications**
6. Add **Background Modes** and check:
   - Remote notifications
   - Background fetch

### 2. Update `ios/Runner/Info.plist`

Add notification permissions:

```xml
<dict>
    <!-- Add these keys -->
    <key>UIBackgroundModes</key>
    <array>
        <string>fetch</string>
        <string>remote-notification</string>
    </array>

    <!-- Existing keys... -->
</dict>
```

### 3. APNs Certificate

1. Go to [Apple Developer Portal](https://developer.apple.com/account/)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Create an APNs authentication key or certificate
4. Upload the key/certificate to your Firebase Project:
   - Go to Firebase Console → Project Settings → Cloud Messaging
   - Upload APNs Authentication Key or APNs Certificate

### 4. Request Notification Permissions

The app will automatically request notification permissions when the user logs in. The permissions are requested in the `PushNotificationService` class.

---

## Cloud Functions Setup

Cloud Functions automatically send push notifications when admins create or activate notifications.

### 1. Initialize Firebase Functions

```bash
cd functions
npm install
```

### 2. Login to Firebase

```bash
firebase login
```

### 3. Set Firebase Project

```bash
firebase use --add
```

Select your Firebase project from the list.

### 4. Deploy Cloud Functions

```bash
firebase deploy --only functions
```

This will deploy three functions:
- `sendNotificationOnCreate` - Sends push notification when a notification is created
- `sendNotificationOnUpdate` - Sends push notification when a notification is activated
- `sendTargetedNotification` - Allows admins to send targeted notifications to specific users

### 5. Verify Deployment

Check the Firebase Console → Functions to verify the functions are deployed successfully.

---

## Testing Push Notifications

### Test 1: Foreground Notification

1. Launch the app and log in as a user
2. Keep the app in the foreground
3. As an admin, create a new notification from the Notifications tab
4. You should see a local notification appear at the top of the screen

### Test 2: Background Notification

1. Launch the app and log in
2. Minimize the app (press home button)
3. As an admin, create a new notification
4. You should see a system notification appear in the notification tray

### Test 3: Terminated State

1. Force close the app completely
2. As an admin, create a new notification
3. You should see a system notification
4. Tap the notification - the app should open

### Test 4: Send Test from Firebase Console

1. Go to Firebase Console → Cloud Messaging → Send test message
2. Add your FCM token (printed in debug console on app launch)
3. Set title and body
4. Send the test message
5. Verify you receive it

### Manual Testing with Firebase Console

To manually send a test notification:

1. Go to Firebase Console → Messaging → New Campaign
2. Select **Firebase Notification Message**
3. Enter notification title and text
4. Click **Send test message**
5. Enter your FCM token (found in app logs on startup)
6. Send the test

---

## How It Works

### Flow Diagram

```
Admin Creates Notification
        ↓
Firestore Document Created
        ↓
Cloud Function Triggered (onCreate)
        ↓
Cloud Function Sends FCM Message to Topic
        ↓
FCM Delivers to All Subscribed Devices
        ↓
App Receives Message
        ↓
PushNotificationService Handles Message
        ↓
User Sees Notification
```

### Notification States

1. **Foreground**: App is open and active
   - Message handled by `FirebaseMessaging.onMessage`
   - Local notification shown via `flutter_local_notifications`
   - Message added to stream for app to handle

2. **Background**: App is minimized
   - Message handled by `firebaseMessagingBackgroundHandler`
   - System shows notification automatically
   - Tapping notification opens app and triggers `onMessageOpenedApp`

3. **Terminated**: App is completely closed
   - Message handled by Firebase automatically
   - System shows notification
   - Tapping notification launches app with `getInitialMessage`

### Token Management

- FCM tokens are automatically generated when the user logs in
- Tokens are stored in Firestore under `users/{email}/fcmToken`
- Tokens are refreshed automatically and updated in Firestore
- Tokens are deleted when the user logs out

### Topic Subscription

- All users are automatically subscribed to `mosque_notifications` topic on login
- Admins send notifications to this topic, reaching all subscribed users
- Users are unsubscribed from the topic on logout

---

## Troubleshooting

### Notifications Not Received

1. **Check FCM Token**
   - Look for "FCM Token: ..." in debug logs
   - Verify token is saved in Firestore (`users/{email}/fcmToken`)

2. **Check Permissions**
   - Android: Ensure POST_NOTIFICATIONS permission is granted
   - iOS: Ensure notification permissions are granted in Settings

3. **Check Cloud Functions**
   - Go to Firebase Console → Functions → Logs
   - Look for errors in function execution
   - Verify functions are deployed and active

4. **Check Firestore Rules**
   - Ensure Cloud Functions have permission to read notifications
   - Ensure app has permission to write FCM tokens

### Android-Specific Issues

1. **Notification not showing in foreground**
   - Check that notification channels are created
   - Verify `flutter_local_notifications` is initialized

2. **Notification not making sound**
   - Check notification channel importance
   - Verify channel settings in Android Settings → Apps → Prayer App → Notifications

### iOS-Specific Issues

1. **Notifications not received**
   - Verify APNs certificate is uploaded to Firebase
   - Check that capabilities are added in Xcode
   - Ensure app is registered for remote notifications

2. **Notifications not showing in foreground**
   - Verify `UNUserNotificationCenter` delegate is set
   - Check notification presentation options

### Cloud Functions Issues

1. **Function not triggering**
   - Check function logs in Firebase Console
   - Verify Firestore trigger path matches: `notifications/{notificationId}`
   - Check that notification document has `active: true`

2. **Permission errors**
   - Ensure Cloud Functions service account has necessary permissions
   - Check Firestore security rules

---

## Advanced Configuration

### Custom Notification Icons (Android)

1. Create notification icons in various sizes:
   - `android/app/src/main/res/drawable-mdpi/ic_notification.png` (24x24)
   - `android/app/src/main/res/drawable-hdpi/ic_notification.png` (36x36)
   - `android/app/src/main/res/drawable-xhdpi/ic_notification.png` (48x48)
   - `android/app/src/main/res/drawable-xxhdpi/ic_notification.png` (72x72)
   - `android/app/src/main/res/drawable-xxxhdpi/ic_notification.png` (96x96)

2. Update notification icon in `push_notification_service.dart`:
   ```dart
   icon: '@drawable/ic_notification',  // Changed from '@mipmap/ic_launcher'
   ```

### Custom Notification Sounds

1. Add sound files to platform-specific directories:
   - Android: `android/app/src/main/res/raw/notification_sound.mp3`
   - iOS: Add to Xcode project in `Runner/Resources/`

2. Update notification configuration in service to use custom sound

### Notification Actions

Add action buttons to notifications for quick responses (e.g., "View", "Dismiss")

---

## Next Steps

1. Run `flutter pub get` to install dependencies
2. Configure Android and iOS as described above
3. Deploy Cloud Functions
4. Test notifications in all three states (foreground, background, terminated)
5. Monitor Cloud Function logs for any issues

---

## Support

For issues or questions:
- Check Firebase Cloud Messaging documentation: https://firebase.google.com/docs/cloud-messaging
- Check Flutter Fire documentation: https://firebase.flutter.dev/docs/messaging/overview/

---

## Summary

You now have a complete push notification system that:
- ✅ Requests notification permissions from users
- ✅ Registers FCM tokens and stores them in Firestore
- ✅ Subscribes users to a mosque-wide notification topic
- ✅ Handles notifications in foreground, background, and terminated states
- ✅ Automatically sends push notifications when admins create/activate announcements
- ✅ Shows notifications with appropriate priority and channels
- ✅ Cleans up tokens on logout

The push notification service is fully integrated with your existing notification system and requires minimal additional configuration!
