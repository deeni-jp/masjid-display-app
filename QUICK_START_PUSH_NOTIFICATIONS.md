# Quick Start: Push Notifications

This is a quick reference guide to get push notifications working. For detailed instructions, see `PUSH_NOTIFICATIONS_SETUP.md`.

## Quick Steps

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Android Setup (3 minutes)

1. Update `android/app/build.gradle`:
   ```gradle
   minSdkVersion 21  // Make sure this is at least 21
   ```

2. Add to `android/app/src/main/AndroidManifest.xml` inside `<application>` tag:
   ```xml
   <meta-data
       android:name="com.google.firebase.messaging.default_notification_channel_id"
       android:value="high_importance_channel" />
   ```

3. Add permissions before `<application>` tag:
   ```xml
   <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
   <uses-permission android:name="android.permission.VIBRATE" />
   ```

### 3. iOS Setup (5 minutes)

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner → Signing & Capabilities
3. Click "+ Capability" → Add "Push Notifications"
4. Click "+ Capability" → Add "Background Modes"
5. Check "Remote notifications" and "Background fetch"
6. Upload APNs key to Firebase Console (Project Settings → Cloud Messaging)

### 4. Deploy Cloud Functions (2 minutes)

```bash
cd functions
npm install
firebase login
firebase use --add  # Select your project
firebase deploy --only functions
```

### 5. Test It!

1. Run the app: `flutter run`
2. Log in as a user
3. Check console for "FCM Token: ..."
4. Open another device/emulator
5. Log in as admin
6. Create a new notification
7. Check if you receive the push notification!

## That's It!

Push notifications are now working. The system will:
- ✅ Automatically request permissions on login
- ✅ Subscribe users to mosque notifications
- ✅ Send push notifications when admins create/activate announcements
- ✅ Handle notifications in foreground, background, and when app is closed
- ✅ Clean up on logout

## Common Issues

**Not receiving notifications?**
- Check FCM token is printed in console
- Verify Cloud Functions are deployed (Firebase Console → Functions)
- Make sure notification is `active: true` in Firestore
- Check notification hasn't expired

**Android: Notification not showing?**
- Grant notification permission in Settings
- Check notification channels are enabled

**iOS: Not receiving?**
- Upload APNs key to Firebase Console
- Check capabilities are added in Xcode
- Grant notification permission when prompted

## Need More Help?

See `PUSH_NOTIFICATIONS_SETUP.md` for detailed troubleshooting and advanced configuration.
