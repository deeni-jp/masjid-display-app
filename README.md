# Darut Tauhid Masjid - Prayer Times App

A beautiful, modern Flutter application for displaying prayer times, managing mosque announcements, and community engagement with advanced notification system and role-based access control.

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)
![Firebase](https://img.shields.io/badge/Firebase-Firestore-orange.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## Table of Contents

### Getting Started
- [Features](#features)
- [Screenshots](#screenshots)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Installation](#getting-started)
- [Quick Reference](#quick-reference) ⭐

### Setup & Configuration
- [Dependencies](#dependencies)
- [Push Notifications Setup](#push-notifications-setup) ⭐
  - [Quick Start (5 min)](#quick-start-push-notifications)
  - [Detailed Setup](#detailed-push-notifications-setup)
  - [Android](#android-configuration-push)
  - [iOS](#ios-configuration-push)
  - [FCM HTTP v1 API](#fcm-http-v1-api-setup)
  - [Testing](#testing-push-notifications)
  - [Troubleshooting](#troubleshooting-push-notifications)
- [CI/CD Pipeline Setup](#cicd-pipeline-setup) ⭐
- [Firebase Setup](#firebase-setup)
- [Environment Variables](#environment-variables)

### Development
- [User Roles & Permissions](#user-roles--permissions)
- [Notification System](#notification-system)
- [Configuration](#configuration)
- [UI Features](#ui-features)
- [Masjid Display Mode](#masjid-display-mode)

### Deployment & Operations
- [Troubleshooting](#troubleshooting)
- [Deployment](#deployment)
- [CI/CD Automation](#cicd-pipeline-setup)
- [Security](#security)

### Reference
- [License](#license)
- [Contributing](#contributing)
- [Support](#support)
- [Changelog](#changelog)

---

## ✨ Features

### For All Users

- 🕌 **Accurate Prayer Times** - Fetched from Aladhan API based on GPS location
- ⏱️ **Live Countdown** - Smooth animated countdown to next prayer with fade transitions
- 📢 **Multi-Notification System** - Support for unlimited announcements with types (Announcement, Event, Alert) and priorities (High, Regular, Low)
- 📰 **News Ticker** - Continuous scrolling notification ticker for non-high priority announcements
- 🌙 **Auto Dark Mode** - Automatically switches between Maghrib and Sunrise with manual override
- 📍 **Location Detection** - GPS-based with fallback to IP geolocation
- 💾 **Offline Support** - Cached data works without internet connection
- 🎨 **Theme-Aware UI** - Proper contrast and colors in both light and dark modes

### For Moderators & Admins

- ✏️ **Edit Iqama Times** - Update congregation prayer times (Moderators and Admins)
- 📝 **Manage Announcements** - Create, edit, and delete mosque notifications
  - Set notification type (Announcement, Event, Alert)
  - Set priority level (High, Regular, Low)
  - Set expiration dates
  - Schedule event times
  - Toggle active/inactive status
- 🔄 **Auto-Cleanup** - Expired notifications automatically removed

### For Admins Only

- 👥 **User Management** - View all users and change roles
- 🔐 **Role Assignment** - Promote users to Moderator or Admin
- 📊 **User Statistics** - View user counts by role

### Special Features

- 🖥️ **Masjid Display Mode** - Full-screen TV/tablet layout with large prayer table, clock, Hijri date, notices and donation QR code (see [Masjid Display Mode](#masjid-display-mode))
- 🔔 **Iqamah Sequence** - 60-second iqamah countdown → 30-second "Time for prayer" screen → 10-minute "Prayer in progress" silent screen → back to home, on both display and phones
- 🕌 **Jummah Times** - Jummah shown in the prayer tables (in place of Dhuhr on Fridays)
- 🌐 **Bilingual UI** - English with Arabic labels throughout; Japanese on the "Prayer in progress" screen
- 🎯 **Rotating Notices** - Notices cycle on the home screen, high priority first
- 💬 **Notification Detail View** - Full-screen bottom sheet with complete information
- 🔄 **Real-time Updates** - Live sync with Firestore for iqama times and notifications
- 👤 **User Profiles** - Edit display name, change password, and view account info
- 🌐 **Multi-Language Support** - Ready for localization

---

## 📱 Screenshots

| Home                          | Prayers                             | Notifications                                   | Admin                           |
| ----------------------------- | ----------------------------------- | ----------------------------------------------- | ------------------------------- |
| ![Home](screenshots/home.png) | ![Prayers](screenshots/prayers.png) | ![Notifications](screenshots/notifications.png) | ![Admin](screenshots/admin.png) |

---

## 🛠️ Tech Stack

- **Framework**: Flutter 3.x
- **Backend**: Firebase (Auth, Firestore)
- **APIs**: Aladhan Prayer Times API
- **State Management**: StatefulWidget with Stream listeners
- **Local Storage**: SharedPreferences
- **Location**: Geolocator, Geocoding
- **UI**: Material Design 3, Google Fonts
- **Configuration**: flutter_dotenv for environment variables
- **CI/CD**: GitHub Actions

---

## 📂 Project Structure

```
lib/
├── main.dart                      # App entry point with auth wrapper
├── firebase_options.dart          # Firebase configuration (auto-generated)
│
├── models/
│   ├── prayer_time.dart           # Prayer time data models
│   ├── prayer_windows.dart        # Iqamah sequence timing (countdown → started → in progress)
│   ├── notification_model.dart    # Enhanced notification model with types & priorities
│   └── user_model.dart            # User model with roles (Public, Moderator, Admin)
│
├── services/
│   ├── prayer_service.dart        # Prayer times API service
│   ├── location_service.dart      # GPS & geocoding service
│   ├── firebase_service.dart      # Firestore operations with notification collection
│   ├── storage_service.dart       # Local storage with notification list caching
│   └── user_service.dart          # User management & authentication service
│
├── screens/
│   ├── auth_screen.dart           # Login/Signup screen with validation
│   ├── home_page.dart             # Main container with bottom nav & overlays
│   ├── home_tab.dart              # Home tab: mobile layout, or display layout on wide screens
│   ├── display_home.dart          # Masjid display (TV/tablet) home layout
│   ├── prayers_tab.dart           # Prayer schedule with edit capabilities
│   ├── notifications_tab.dart     # Full notifications list with filters & CRUD
│   ├── more_tab.dart              # Settings, user info, and app info
│   ├── profile_screen.dart        # User profile editing
│   └── users_screen.dart          # Admin user management screen
│
├── widgets/
│   ├── prayer_card.dart           # Prayer card widgets (full & compact)
│   ├── next_prayer_card.dart      # Countdown card with sun times
│   ├── countdown_overlay.dart     # Iqamah countdown (final 60 seconds)
│   ├── prayer_started_overlay.dart # "Time for prayer" screen (30 seconds after iqamah)
│   ├── blackout_overlay.dart      # "Prayer in progress" silent screen
│   ├── prohibited_time_overlay.dart # Prohibited-time alert (currently disabled)
│   ├── notification_card.dart     # Notification cards with detail sheet
│   └── news_ticker.dart           # Bottom ticker for announcements
│
└── utils/
    ├── constants.dart             # App constants, colors, & enums
    ├── design.dart                # Design tokens: palette (light/dark), fonts, Arabic labels, masjid info
    └── env_config.dart            # Environment configuration manager
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.x or higher
- Firebase account
- Android Studio / VS Code
- Git

### Installation

#### 1. Clone the repository

```bash
git clone https://github.com/yourusername/darut-tauhid-masjid.git
cd darut-tauhid-masjid
```

#### 2. Install dependencies

```bash
flutter pub get
```

#### 3. Environment Configuration

Create a `.env` file in the project root:

```bash
cp .env.example .env
```

The `.env` file contains configuration variables:

```env
# API Configuration
# Aladhan API calculation method (default: 3 for Muslim World League)
ALADHAN_API_METHOD=3
```

**Important**: The `.env` file is gitignored and should never be committed. Use `.env.example` as a template.

#### 4. Firebase Setup

1. Create a new project in [Firebase Console](https://console.firebase.google.com/)

2. Install Firebase CLI and FlutterFire CLI:

```bash
npm install -g firebase-tools
dart pub global activate flutterfire_cli
```

3. Login and configure:

```bash
firebase login
flutterfire configure
```

4. Enable Firebase services:
   - **Authentication** → Enable Email/Password
   - **Firestore Database** → Create database (Start in production mode)

#### 5. Firestore Structure

The app uses the following Firestore structure:

```
mosque/
├── iqama/                         # Document for iqama times
│   ├── Fajr: "5:30 AM"
│   ├── Dhuhr: "1:15 PM"
│   └── ... (other prayers)
│
└── data/
    └── notifications/             # Collection for announcements
        ├── {notificationId1}
        │   ├── title: "Jumah Khutbah"
        │   ├── message: "..."
        │   ├── type: "announcement"
        │   ├── priority: "high"
        │   ├── active: true
        │   ├── createdAt: Timestamp
        │   ├── expiresAt: Timestamp
        │   ├── eventTime: Timestamp (optional)
        │   ├── postedBy: "user@email.com"
        │   └── postedByRole: "Admin"
        │
        └── {notificationId2}
            └── ...

users/
└── {userId}/
    ├── email: "user@example.com"
    ├── displayName: "John Doe"
    ├── role: "public" | "moderator" | "admin"
    ├── createdAt: Timestamp
    └── lastLogin: Timestamp
```

#### 6. Firestore Rules

Go to Firestore → Rules and paste:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function getUserRole() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role;
    }

    function isAdmin() {
      return request.auth != null && getUserRole() == 'admin';
    }

    function isModeratorOrAdmin() {
      return request.auth != null && (getUserRole() == 'admin' || getUserRole() == 'moderator');
    }

    // User documents
    match /users/{userId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && request.auth.uid == userId;
      allow update: if request.auth != null && (
        (request.auth.uid == userId && !request.resource.data.diff(resource.data).affectedKeys().hasAny(['role'])) ||
        isAdmin()
      );
      allow delete: if isAdmin();
    }

    // Iqama times
    match /mosque/iqama {
      allow read: if true;
      allow write: if isModeratorOrAdmin();
    }

    // Notifications collection
    match /mosque/data/notifications/{notificationId} {
      allow read: if true;
      allow create, update, delete: if isModeratorOrAdmin();
    }

    // Legacy notification document (for migration)
    match /mosque/notification {
      allow read: if true;
      allow write: if isModeratorOrAdmin();
    }

    // Default mosque collection
    match /mosque/{document} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

#### 7. Firestore Indexes

Create composite indexes for efficient queries:

**Index 1: Active notifications sorted by expiry**

- Collection: `mosque/data/notifications`
- Fields:
  - `active` (Ascending)
  - `expiresAt` (Ascending)

**Index 2: Notifications by type**

- Collection: `mosque/data/notifications`
- Fields:
  - `active` (Ascending)
  - `type` (Ascending)

**Index 3: Notifications by priority**

- Collection: `mosque/data/notifications`
- Fields:
  - `active` (Ascending)
  - `priority` (Ascending)

You can create these in Firebase Console → Firestore → Indexes or wait for the error messages when running queries, which will provide direct links to create the indexes.

#### 8. Create First Admin

1. Run the app and create an account
2. Go to Firebase Console → Firestore → `users` collection
3. Find your user document
4. Change `role` field from `public` to `admin`

#### 9. Run the app

```bash
flutter run
```

---

## Quick Reference
[↑ Back to Top](#table-of-contents)

### I want to...
- **Get started quickly** → [Installation](#getting-started)
- **Set up push notifications** → [Quick Start (5 min)](#quick-start-push-notifications)
- **Configure CI/CD** → [CI/CD Pipeline Setup](#cicd-pipeline-setup)
- **Deploy the app** → [Deployment](#deployment)
- **Fix an issue** → [Troubleshooting](#troubleshooting)
- **Configure prayer times** → [Configuration](#configuration)
- **Manage users** → [User Roles](#user-roles--permissions)

### Platform-Specific Guides
- **Android Setup** → [Android Configuration](#android-configuration-push)
- **iOS Setup** → [iOS Configuration](#ios-configuration-push)

### Advanced Topics
- **FCM HTTP v1 API** → [FCM Setup](#fcm-http-v1-api-setup)
- **Cloud Functions** → [Push Notifications](#push-notifications-setup)
- **Environment Variables** → [Environment Variables](#environment-variables)
- **Security Best Practices** → [Security](#security)

---

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Firebase
  firebase_core: ^4.0.0
  cloud_firestore: ^6.0.0
  firebase_auth: ^6.0.1

  # Location
  geolocator: ^14.0.2
  geocoding: ^4.0.0
  permission_handler: ^11.0.0

  # Storage & Utils
  shared_preferences: ^2.5.3
  http: ^1.5.0
  intl: ^0.20.2

  # Configuration
  flutter_dotenv: ^5.2.1

  # UI
  google_fonts: ^5.0.0
  win32: ^5.15.0
```

---
---

## Push Notifications Setup
[↑ Back to Top](#table-of-contents)

> **Quick Links:** [Quick Start (5 min)](#quick-start-push-notifications) | [Android](#android-configuration-push) | [iOS](#ios-configuration-push) | [FCM Setup](#fcm-http-v1-api-setup) | [Testing](#testing-push-notifications) | [Troubleshooting](#troubleshooting-push-notifications)

This app uses **Firebase Cloud Messaging (FCM) HTTP v1 API** to send push notifications to users when admins create or activate announcements.

### Overview

**What it does:**
- 📱 Sends push notifications when admins create/activate notifications
- 🔔 Works in foreground, background, and when app is terminated
- 🎯 Subscribes users to topic-based notifications
- ✅ Automatic permission requests on login
- 🧹 Cleans up on logout

**Why FCM HTTP v1 API?**

| Feature | Legacy API | HTTP v1 API ✅ |
|---------|-----------|----------------|
| **Status** | ❌ Deprecated (June 2024) | ✅ Current |
| **Authentication** | Server Key | OAuth 2.0 |
| **Security** | Lower | Higher |
| **Features** | Limited | Full featured |

---

### Quick Start (5 Minutes)
**For users who want to get started quickly**

> 💡 For detailed explanations and troubleshooting, see [Detailed Setup](#detailed-push-notifications-setup) below

#### 1. Install Dependencies

```bash
flutter pub get
```

#### 2. Android Setup (3 minutes)

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

#### 3. iOS Setup (5 minutes)

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner → Signing & Capabilities
3. Click "+ Capability" → Add "Push Notifications"
4. Click "+ Capability" → Add "Background Modes"
5. Check "Remote notifications" and "Background fetch"
6. Upload APNs key to Firebase Console (Project Settings → Cloud Messaging)

#### 4. FCM HTTP v1 API Setup (10 minutes)

See [FCM HTTP v1 API Setup](#fcm-http-v1-api-setup) below for complete instructions.

Quick version:
1. Generate service account credentials from Firebase Console
2. Add credentials to `.env` file (see section below)
3. Enable Firebase Cloud Messaging API in Google Cloud Console

#### 5. Deploy Cloud Functions (2 minutes)

```bash
cd functions
npm install
firebase login
firebase use --add  # Select your project
firebase deploy --only functions
```

#### 6. Test It!

1. Run the app: `flutter run`
2. Log in as a user
3. Check console for "FCM Token: ..."
4. Create a notification as admin
5. Check if you receive the push notification! 🎉

---

### Detailed Push Notifications Setup

#### 1. Install Dependencies

The dependencies have already been added to `pubspec.yaml`. Run:

```bash
flutter pub get
```

This will install:
- `firebase_messaging: ^15.1.5` - Firebase Cloud Messaging
- `flutter_local_notifications: ^18.0.1` - Local notifications for foreground messages

---

#### 2. Android Configuration (DETAILED)
<a id="android-configuration-push"></a>

##### Update `android/app/build.gradle`

Make sure your `minSdkVersion` is at least 21:

```gradle
android {
    defaultConfig {
        minSdkVersion 21  // Changed from 19 if needed
        targetSdkVersion flutter.targetSdkVersion
    }
}
```

##### Update `android/app/src/main/AndroidManifest.xml`

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

##### Verify `google-services.json`

Ensure `google-services.json` is in `android/app/` directory and contains your Firebase configuration.

---

#### 3. iOS Configuration (DETAILED)
<a id="ios-configuration-push"></a>

##### Enable Push Notifications Capability

1. Open your iOS project in Xcode (`ios/Runner.xcworkspace`)
2. Select the `Runner` project in the navigator
3. Go to **Signing & Capabilities** tab
4. Click **+ Capability**
5. Add **Push Notifications**
6. Add **Background Modes** and check:
   - Remote notifications
   - Background fetch

##### Update `ios/Runner/Info.plist`

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

##### APNs Certificate

1. Go to [Apple Developer Portal](https://developer.apple.com/account/)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Create an APNs authentication key or certificate
4. Upload the key/certificate to your Firebase Project:
   - Go to Firebase Console → Project Settings → Cloud Messaging
   - Upload APNs Authentication Key or APNs Certificate

The app will automatically request notification permissions when the user logs in.

---

#### 4. FCM HTTP v1 API Setup
<a id="fcm-http-v1-api-setup"></a>

The app uses the modern **FCM HTTP v1 API** with OAuth2 authentication for enhanced security.

##### Step 1: Get Service Account Credentials

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click ⚙️ gear icon → **Project settings**
4. Go to the **Service accounts** tab
5. Click **Generate new private key**
6. Click **Generate key** (a JSON file will download)
7. **IMPORTANT**: Keep this file secure! Don't commit it to Git

The downloaded file will look like this:
```json
{
  "type": "service_account",
  "project_id": "your-project-id",
  "private_key_id": "abc123...",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIE...\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com",
  ...
}
```

##### Step 2: Add Credentials to .env File

The app uses environment variables for FCM credentials (managed by `lib/services/fcm_notification_sender.dart`). Add the service account details to your `.env` file:

```env
# FCM Service Account Credentials
FCM_PROJECT_ID=your-project-id
FCM_PRIVATE_KEY_ID=your-private-key-id
FCM_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYOUR_PRIVATE_KEY_HERE\n-----END PRIVATE KEY-----\n"
FCM_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com
FCM_CLIENT_ID=your-client-id
FCM_AUTH_URI=https://accounts.google.com/o/oauth2/auth
FCM_TOKEN_URI=https://oauth2.googleapis.com/token
FCM_AUTH_PROVIDER_CERT_URL=https://www.googleapis.com/oauth2/v1/certs
FCM_CLIENT_CERT_URL=https://www.googleapis.com/robot/v1/metadata/x509/...
FCM_UNIVERSE_DOMAIN=googleapis.com
```

**IMPORTANT Notes:**
- Make sure `.env` is in `.gitignore` (it already is)
- The `fcm_notification_sender.dart` service reads from these environment variables
- Keep newlines in the private key properly escaped with `\n`
- Copy values exactly from the downloaded JSON file

##### Step 3: Enable Firebase Cloud Messaging API

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project
3. Go to **APIs & Services** → **Library**
4. Search for "Firebase Cloud Messaging API"
5. Click on it and click **Enable**

**This step is required** - the app will return a 403 error if this API is not enabled.

---

#### 5. Cloud Functions Setup

Cloud Functions automatically send push notifications when admins create or activate notifications.

##### Initialize and Deploy

```bash
cd functions
npm install
firebase login
firebase use --add  # Select your project
firebase deploy --only functions
```

This deploys three functions:
- `sendNotificationOnCreate` - Sends push notification when a notification is created
- `sendNotificationOnUpdate` - Sends push notification when a notification is activated
- `sendTargetedNotification` - Allows admins to send targeted notifications to specific users

##### Verify Deployment

Check the Firebase Console → Functions to verify the functions are deployed successfully.

**Note:** Cloud Functions require a Blaze (pay-as-you-go) plan, but costs are minimal (~$0.40 per million invocations).

---

### Testing Push Notifications
<a id="testing-push-notifications"></a>

#### Test 1: Foreground Notification

1. Launch the app and log in as a user
2. Keep the app in the foreground
3. As an admin, create a new notification from the Notifications tab
4. You should see a local notification appear at the top of the screen

#### Test 2: Background Notification

1. Launch the app and log in as a user
2. Press home button to send app to background
3. As an admin, create a new notification
4. You should receive a system notification

#### Test 3: Terminated App Notification

1. Log in as a user
2. Force-quit the app completely
3. As an admin, create a new notification
4. You should receive a system notification
5. Tap the notification to open the app

#### Test 4: Firebase Console Test

1. Go to Firebase Console → Cloud Messaging
2. Click "Send your first message"
3. Enter title and text
4. Click "Send test message"
5. Enter your FCM token (from app console logs)
6. Click "Test"

#### Expected Behavior

**When notification is received:**
- ✅ System notification appears with title and message
- ✅ App badge updates (iOS)
- ✅ Sound plays (based on priority)
- ✅ Notification stored in Firestore
- ✅ Console logs show: "✅ Push notification sent successfully"

**Success Indicators:**
- FCM token is printed in console on login: "FCM Token: ..."
- Firestore `users` collection has `fcmToken` field populated
- Console shows "Push notifications initialized successfully"
- Notifications appear on device within 1-2 seconds
- Cloud Functions logs show successful execution (Firebase Console → Functions → Logs)

---

### Troubleshooting Push Notifications
<a id="troubleshooting-push-notifications"></a>

#### Common Error Codes

| Error Code | Issue | Solution |
|------------|-------|----------|
| **403 Permission Denied** | FCM API not enabled | Enable Firebase Cloud Messaging API in Google Cloud Console → APIs & Services → Library |
| **401 Unauthorized** | Invalid service account credentials | Verify FCM credentials in `.env` file match the downloaded JSON exactly. Check for extra spaces or newline issues in `FCM_PRIVATE_KEY` |
| **404 Not Found** | Wrong project ID or endpoint | Check `FCM_PROJECT_ID` in `.env` matches your Firebase project. Verify you're using v1 API endpoint |
| **Missing credentials** | Service account not configured | Ensure all `FCM_*` variables are set in `.env` file. Run `flutter clean` and rebuild |

#### General Issues

**Not receiving notifications?**
1. Check FCM token is printed in console on login
2. Verify Cloud Functions are deployed (Firebase Console → Functions)
3. Make sure notification is `active: true` in Firestore
4. Check notification hasn't expired (`expiryDate` field)
5. Verify user's `fcmToken` field exists in Firestore `users` collection
6. Check Firebase Console → Functions → Logs for errors

**Console shows "⚠️ FCM credentials not configured"?**
1. Make sure `.env` file exists in project root directory
2. Verify all `FCM_*` variables are set with correct values
3. Check private key format: must include `\n` for newlines
4. Run `flutter clean` and rebuild the app
5. Restart your IDE/editor to reload environment variables

**Notifications working inconsistently?**
- Check device battery optimization settings (Android)
- Verify app is not in "Do Not Disturb" mode
- Check notification permission is granted in device Settings
- Ensure stable internet connection

#### Android-Specific Issues

**Notification not showing?**
- Grant notification permission: Settings → Apps → Prayer App → Permissions → Notifications
- Check notification channels are enabled
- Verify `minSdkVersion 21` or higher in `build.gradle`
- Check `google-services.json` is in `android/app/` directory
- Clear app data and re-login to re-request permissions

**Android Priority Error (Fixed)?**
- The latest version uses `_getAndroidPriority()` which returns "HIGH" or "NORMAL"
- These values comply with FCM v1 API requirements
- If you see "max" or "default" in logs, update to the latest code

**Web warnings in console?**
- These are expected when running on Android/iOS
- The app gracefully handles platform-specific initialization
- Safe to ignore warnings about web configuration

#### iOS-Specific Issues

**Not receiving notifications?**
- Upload APNs key to Firebase Console: Project Settings → Cloud Messaging → iOS app → APNs Authentication Key
- Check Push Notifications capability is added in Xcode (Runner → Signing & Capabilities)
- Verify Background Modes are enabled with "Remote notifications" and "Background fetch" checked
- Grant notification permission when prompted on first login
- Check `Info.plist` has `UIBackgroundModes` array with correct values

**Notifications work in simulator but not on device?**
- Simulator has limited push notification support
- Always test on a physical iOS device for accurate results
- Ensure device has internet connection
- Check device is not in Low Power Mode (can delay notifications)

**APNs certificate/key issues?**
- Use APNs Authentication Key (recommended) instead of certificate
- Ensure the key is uploaded for the correct bundle identifier
- Verify the key hasn't expired
- Check the key has the correct permissions in Apple Developer Portal

#### Cloud Functions Issues

**Functions not deploying?**
- Run `firebase login` and ensure you're logged in with correct account
- Check you've selected the correct project: `firebase use --add`
- Verify you're on a Blaze (pay-as-you-go) plan (required for Cloud Functions)
- Check for syntax errors in `functions/index.js`
- Try deploying individual functions: `firebase deploy --only functions:sendNotificationOnCreate`

**Functions deployed but notifications not sending?**
- Check Firebase Console → Functions → Logs for errors
- Verify the function is triggered when creating notifications (check logs timestamp)
- Ensure FCM credentials are configured in `.env`
- Check Firestore rules allow Cloud Functions to read user tokens
- Verify notification document has required fields: `title`, `message`, `active: true`

**Cloud Functions timeout errors?**
- Increase timeout in `functions/index.js`: `{ timeoutSeconds: 60 }`
- Check if too many users are being notified at once
- Consider batching notifications for large user bases

---

### Security Best Practices

#### Environment Variables (Current Approach) ✅

The app uses environment variables for FCM credentials, managed by `lib/services/fcm_notification_sender.dart`.

**Advantages:**
- ✅ Credentials not in source code
- ✅ `.env` is gitignored automatically
- ✅ Easy to manage different credentials per environment
- ✅ No risk of accidentally committing secrets
- ✅ Simple OAuth2 token management with automatic refresh

**Security Checklist:**
- [ ] `.env` file is in `.gitignore`
- [ ] FCM credentials are in `.env` file (not in source code)
- [ ] `.env.example` documents required variables without actual values
- [ ] Production `.env` is never committed to Git
- [ ] Team members have their own `.env` files
- [ ] Service account JSON file is stored securely (not in project directory)
- [ ] Access to Firebase Console is restricted to authorized personnel

#### Alternative: Firestore Storage

For maximum security in production environments, you can store credentials server-side:

**Approach:**
1. Store service account JSON in Firestore with admin-only access rules
2. Fetch credentials on app startup (requires admin authentication)
3. Cache credentials securely in memory
4. Refresh OAuth2 tokens as needed

**Trade-offs:**
- ✅ More secure (credentials server-side only)
- ✅ Centralized credential management
- ❌ More complex setup and maintenance
- ❌ Requires admin login before sending notifications
- ❌ Additional Firestore reads

**When to use:**
- Production apps with high security requirements
- Apps with multiple admins needing credential rotation
- Environments where client-side credentials are prohibited

#### Cost Comparison

**Using FCM Direct (Current Approach):**
- ✅ Free tier: Unlimited notifications
- ✅ No Cloud Functions required for sending (can send from app)
- ✅ OAuth2 authentication from app
- ✅ Minimal infrastructure costs

**Using Cloud Functions Only:**
- Cloud Functions required (Blaze plan)
- Small cost per function invocation (~$0.40 per million invocations)
- Better for complex notification logic and server-side validation
- Separates notification logic from client app

**Hybrid Approach (Recommended - Current Implementation):**
- Direct FCM for immediate, user-triggered notifications (free)
- Cloud Functions for automatic triggers on Firestore changes (minimal cost)
- Best balance of cost, security, and functionality

**Estimated Monthly Costs:**
- Up to 1,000 users: ~$0 (within free tier)
- 1,000-10,000 users: ~$1-5/month
- 10,000+ users: ~$5-20/month

---

## 👥 User Roles & Permissions

| Role          | Description                | Permissions                                                                                                                                                        |
| ------------- | -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Public**    | Default role for new users | • View prayer times<br>• View active announcements<br>• Change own password & display name                                                                         |
| **Moderator** | Mosque staff/volunteers    | **All Public permissions, plus:**<br>• Edit Iqama times<br>• Create, edit, delete announcements<br>• Set notification types & priorities<br>• Schedule event times |
| **Admin**     | Mosque administrators      | **All Moderator permissions, plus:**<br>• Manage users (view all users)<br>• Change user roles<br>• Full access to all features                                    |

---

## 📋 Notification System

### Notification Types

- **Announcement** (Blue) - General mosque announcements
- **Event** (Green) - Scheduled events with event time
- **Alert** (Orange/Red) - Urgent notifications

### Priority Levels

- **High** (Red for Alerts, Orange otherwise) - Displayed prominently on home screen
- **Regular** (Blue) - Standard priority
- **Low** (Gray) - Lower visibility

### Features

- **Expiration System** - Auto-delete after expiry date
- **Active/Inactive Toggle** - Hide notifications without deleting
- **Rotation Display** - High priority notifications rotate on home screen
- **News Ticker** - Non-high priority notifications scroll at bottom
- **Filtering** - Filter by type (All, Announcements, Events, Alerts)
- **Auto-Cleanup** - Background cleanup every 15 minutes

---

## 🔧 Configuration

### App Constants

Edit `lib/utils/constants.dart` to customize:

```dart
class AppConstants {
  static const String appName = 'Your Mosque Name';
  static const String appVersion = '1.0.0';

  // Prayer calculation method
  static const int aladhanApiMethod = 2; // ISNA

  // Timing
  static const Duration countdownWarningTime = Duration(seconds: 60); // iqamah countdown
  static const Duration blackoutDuration = Duration(minutes: 10);     // "Prayer in progress"

  // Notification settings
  static const Duration notificationRotationInterval = Duration(seconds: 5);
  static const Duration tickerRotationInterval = Duration(seconds: 4);
  static const int maxActiveNotifications = 50;

  // Default expiration durations
  static const Duration defaultAnnouncementExpiry = Duration(days: 7);
  static const Duration defaultEventExpiry = Duration(days: 1);
  static const Duration defaultAlertExpiry = Duration(hours: 24);
}
```

### Prayer Calculation Methods

| Method                                  | ID  | Region               |
| --------------------------------------- | --- | -------------------- |
| Shia Ithna-Ashari                       | 0   | Shia communities     |
| University of Islamic Sciences, Karachi | 1   | Pakistan, Bangladesh |
| Islamic Society of North America (ISNA) | 2   | North America        |
| Muslim World League                     | 3   | Europe, Americas     |
| Umm Al-Qura University, Makkah          | 4   | Saudi Arabia         |
| Egyptian General Authority of Survey    | 5   | Egypt, Middle East   |

### Colors & Theme

The home screens, display mode and full-screen overlays use the design tokens in `lib/utils/design.dart`:

- `DesignColors` - the palette from the mockups in `design/screens` (greens, gold accents, red for alerts)
- `DesignPalette.light` / `DesignPalette.dark` - colour sets for the home screens; dark is used when the app is in dark mode
- `DesignText` - fonts: Manrope (English), Noto Sans Arabic, Noto Sans JP (loaded via `google_fonts`)

Other screens still use the `AppColors` class in `constants.dart`:

```dart
static const Color primaryGreen = Color(0xFF2D5F3F);
static const Color priorityHigh = Color(0xFFE53935);
static const Color priorityRegular = Color(0xFF1E88E5);
```

### Masjid Name & Donation QR Code

Set in `MasjidInfo` (`lib/utils/design.dart`):

```dart
class MasjidInfo {
  static const String name = AppConstants.appName;
  static const String donationQrAsset = 'assets/images/qr code for donations.png';
}
```

To change the QR code, replace `assets/images/qr code for donations.png` (keep the same name, or update both `donationQrAsset` and the `assets:` entry in `pubspec.yaml`).

### Iqamah Sequence Timing

Set in `lib/models/prayer_windows.dart`:

| Screen | Duration | Constant |
| --- | --- | --- |
| Iqamah countdown | 60 seconds before iqamah | `kIqamahCountdownDuration` (= `AppConstants.countdownWarningTime`) |
| Time for prayer | 30 seconds from iqamah | `kPrayerStartedDuration` |
| Prayer in progress | 10 minutes | `kPrayerInProgressDuration` (= `AppConstants.blackoutDuration`) |

### Environment Variables

Configure in `.env` file (see `.env.example` for template):

```env
# Aladhan API calculation method
# 0 = Shia Ithna-Ashari
# 1 = University of Islamic Sciences, Karachi
# 2 = Islamic Society of North America (ISNA)
# 3 = Muslim World League (default)
# 4 = Umm Al-Qura University, Makkah
# 5 = Egyptian General Authority of Survey
ALADHAN_API_METHOD=3
```

Access in code via `EnvConfig`:

```dart
import 'package:prayer_app/utils/env_config.dart';

// Get API method (defaults to 3 if not set)
final method = EnvConfig.aladhanApiMethod;
```

---

## 🖼️ UI Features

### Dark Mode

- **Auto-switching**: Between Maghrib and Sunrise
- **Manual override**: Toggle in settings
- **Proper contrast**: All screens optimized for both themes
- **Home screens**: The mobile home and the masjid display both have light and dark versions
- **Notification detail**: Fixed contrast issue in meta information section

### Responsive Design

- **Phones**: Mobile home with next-prayer card, prayer list and rotating notices
- **Wide screens (≥ 900px)**: Masjid display layout (see below)
- **Full-screen overlays**: Landscape layouts for the display, portrait layouts for phones
- **Smooth animations**: Fade transitions for countdown and notifications

### Mobile Home

- Masjid name with a bell button that opens Notices
- Next prayer card: name (English & Arabic), countdown, iqamah time
- Prayer list with Begins and Iqamah times; the next prayer is highlighted
- Notice card that rotates every 5 seconds through active notices (high priority first), with dots (or a "3 / 20" counter above 10 notices)
- Bottom navigation with English and Arabic labels: Times, Prayers, Qibla (not on web), Notices, Settings

### Prayer Times Rules

- **Sunrise** is not a prayer: it is not counted as the next prayer, has no iqamah, and is not listed in the Prayers tab (it is still used for the automatic dark mode)
- **Jummah** replaces Dhuhr on Fridays; on other days it is shown as an extra row at the bottom of the prayer tables

### Overlays (Iqamah Sequence)

Shown on both the display and phones:

1. **Iqamah countdown** - final 60 seconds before iqamah, large MM:SS timer
2. **Time for prayer** - 30 seconds from iqamah: prayer name, iqamah time and etiquette reminders (straighten the rows, fill the gaps, silence your phone, repeat after the iqamah)
3. **Prayer in progress** - 10-minute black silent screen in English and Japanese
4. Back to the home screen

The sequence is calculated from the iqamah time, so the correct screen is shown even if the app restarts part way through.

A **prohibited-time alert** (sunrise, zenith, sunset) is implemented in `prohibited_time_overlay.dart` and `prayer_windows.dart` but is currently **disabled**.

---

## 🖥️ Masjid Display Mode

When the app window is at least **900px wide** (TV, monitor or landscape tablet), the Home tab switches to a full-screen display layout based on `design/screens/1 · Home display`. The bottom navigation is hidden; the ⚙️ button opens Settings.

| Area | Content |
| --- | --- |
| Header | Masjid icon, masjid name, settings button |
| Clock | Live time, Gregorian date, Hijri date (English & Arabic) |
| Left (main) | Large prayer table: Fajr, Dhuhr/Jummah, Asr, Maghrib, Isha (+ Jummah on non-Fridays) with Begins and Iqamah times; next prayer highlighted |
| Right | Small next-prayer countdown (when notices are shown), rotating notices carousel, "Support the Masjid" donation QR code |
| Bottom | Notice ticker (when there are notices) |

When there are no active notices, the notices area shows the next prayer with a countdown instead.

The display follows the app's dark mode setting, including the automatic switch after Maghrib.

---

## 🛡️ Troubleshooting

### Common Issues

**1. Firebase permission denied**

- Check Firestore rules are correctly set
- Ensure user is authenticated
- Verify the first admin is set up correctly
- Check user role in Firestore console

**2. Location not working**

- Check app permissions in device settings
- Ensure GPS is enabled
- Add permissions to `AndroidManifest.xml`:
  ```xml
  <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
  <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
  ```
- Add to `Info.plist` (iOS):
  ```xml
  <key>NSLocationWhenInUseUsageDescription</key>
  <string>This app needs location to show accurate prayer times</string>
  ```

**3. Notifications not showing**

- Check if notifications are active (`active: true`)
- Verify expiration date is in the future
- Check Firestore indexes are created
- Clear app cache and restart

**4. Fonts not loading**

- Check internet connection on first run
- Fonts are cached after first load
- Verify `google_fonts` dependency version

**5. Dark mode contrast issues**

- Update to latest version (v1.0.0+)
- Clear app cache
- The notification detail meta info section is now theme-aware

**6. Iqama times not syncing**

- Check internet connection
- Verify Firestore rules allow write access for moderators/admins
- Check user role permissions

**7. Environment file error on startup**

- Ensure `.env` file exists in project root
- Copy `.env.example` to `.env`
- Verify `.env` is listed in `pubspec.yaml` assets
- Check environment variables are correctly formatted

**8. CI/CD build failures**

- Review [CI/CD Pipeline Setup](#cicd-pipeline-setup) for detailed troubleshooting
- Ensure all GitHub Secrets are configured
- Verify `.env` file is created in CI workflow
- Check `firebase_options.dart` is committed to repository

---

## 🚀 Deployment

For detailed CI/CD setup and deployment instructions, see [CI/CD Pipeline Setup](#cicd-pipeline-setup).

### Manual Builds

#### Android

```bash
# Ensure .env file exists
cp .env.example .env

# Build release
flutter build apk --release
# or for app bundle
flutter build appbundle --release
```

#### iOS

```bash
# Ensure .env file exists
cp .env.example .env

# Build release
flutter build ios --release
```

### Automated Deployment (GitHub Actions)

The project includes CI/CD pipeline that automatically:
- Runs tests and code analysis
- Builds Android APK and App Bundle
- Builds iOS app
- Deploys Firestore rules to Firebase
- Creates GitHub releases on version tags

See [CI/CD Pipeline Setup](#cicd-pipeline-setup) for:
- Setting up GitHub Secrets
- Configuring Firebase deployment
- Troubleshooting build issues

### Raspberry Pi (Kiosk Mode)

The app is designed to run as a kiosk display on Raspberry Pi:

1. **Install Flutter-Pi**:

```bash
# See flutter-pi documentation
```

2. **Auto-rotate feature** (coming soon):

- Cycles through tabs every 30 seconds
- Keyboard navigation support
- Systemd service for auto-start

---
---

## CI/CD Pipeline Setup
[↑ Back to Top](#table-of-contents)

This project uses GitHub Actions for continuous integration and continuous deployment, automating builds, tests, and deployments.

### Overview

The CI/CD pipeline automatically:
- ✅ Runs code analysis and tests
- ✅ Builds Android APK and App Bundle
- ✅ Builds iOS app
- ✅ Deploys Firestore rules and Cloud Functions
- ✅ Creates GitHub releases on version tags

### Fixes Applied

#### 1. Environment File Issue ✅
**Problem**: The `.env` file is required as an asset but gitignored, causing CI builds to fail.

**Solution**: CI now automatically creates a `.env` file during builds with default values.

#### 2. Firebase Configuration ✅
**Problem**: `firebase_options.dart` was gitignored, making it unavailable in CI.

**Solution**: Removed `firebase_options.dart` from `.gitignore`. This is safe because:
- Firebase client API keys are meant to be public
- Firebase Security Rules protect your backend
- This is the recommended approach by Google/Firebase

---

### Required GitHub Secrets

Set these secrets in your GitHub repository: **Settings** → **Secrets and variables** → **Actions**

#### Android Build Secrets

| Secret Name | Description | How to Get |
|-------------|-------------|------------|
| `ANDROID_KEYSTORE_BASE64` | Base64-encoded keystore file | See instructions below |
| `KEYSTORE_PASSWORD` | Keystore password | Created when generating keystore |
| `KEY_PASSWORD` | Key password | Created when generating keystore |
| `KEY_ALIAS` | Key alias | Created when generating keystore |

#### Firebase Deployment Secret

| Secret Name | Description | How to Get |
|-------------|-------------|------------|
| `FIREBASE_TOKEN` | Firebase CLI token for deployments | Run `firebase login:ci` |

---

### Generating Required Secrets

#### 1. Android Keystore

**Create Keystore** (if you don't have one):
```bash
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

Follow the prompts to set:
- Keystore password
- Key password
- Your name and organization details

**Convert to Base64**:
```bash
# On Linux/Mac
base64 upload-keystore.jks | tr -d '\n'

# On Windows (PowerShell)
[Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks"))
```

Copy the output and add it as `ANDROID_KEYSTORE_BASE64` secret in GitHub.

**⚠️ Important**: Store the keystore file securely - you'll need it for all future app updates!

#### 2. Firebase Token

```bash
# Login to Firebase CLI
firebase login:ci
```

This will:
1. Open your browser for authentication
2. Generate a token
3. Print the token in your terminal

Copy the token and add it as `FIREBASE_TOKEN` secret in GitHub.

---

### Workflow Jobs

#### 1. Analyze Job
**Triggers**: Every push and pull request

**Steps**:
- Creates `.env` file with default values
- Installs Flutter dependencies
- Verifies code formatting
- Runs static analysis (`flutter analyze`)
- Executes tests with coverage

**Purpose**: Ensure code quality before building

#### 2. Build Android Job
**Triggers**: After analyze succeeds on `main` or `develop` branches

**Steps**:
- Creates `.env` file
- Decodes keystore from base64
- Configures signing properties
- Builds release APK: `flutter build apk --release`
- Builds App Bundle: `flutter build appbundle --release`
- Uploads build artifacts
- Cleans up sensitive files (keystore, signing configs)

**Outputs**:
- `app-release.apk`
- `app-release.aab`

#### 3. Build iOS Job
**Triggers**: After analyze succeeds on `main` or `develop` branches

**Steps**:
- Creates `.env` file
- Installs CocoaPods dependencies
- Builds iOS without code signing: `flutter build ios --release --no-codesign`
- Uploads build artifacts

**Note**: Code signing for iOS typically requires a macOS runner and Apple Developer certificates.

#### 4. Deploy Firebase Job
**Triggers**: After successful Android build on `main` branch only

**Steps**:
- Installs Firebase CLI
- Authenticates using `FIREBASE_TOKEN`
- Deploys Firestore security rules: `firebase deploy --only firestore:rules`
- Deploys Firestore indexes: `firebase deploy --only firestore:indexes`

**Purpose**: Keep Firestore configuration in sync with production

#### 5. Release Job (Optional)
**Triggers**: When you push a version tag (e.g., `v1.0.0`, `v1.1.0`)

**Steps**:
- Creates GitHub release
- Attaches APK and App Bundle to release
- Generates release notes from tag

**Usage**:
```bash
git tag v1.0.0
git push origin v1.0.0
```

---

### Local Development Setup

#### Initial Setup

1. **Copy environment template**:
   ```bash
   cp .env.example .env
   ```

2. **Generate Firebase configuration** (if not already done):
   ```bash
   flutterfire configure
   ```
   This creates/updates `firebase_options.dart`

3. **Install dependencies**:
   ```bash
   flutter pub get
   ```

#### Environment Files

**`.env` file** (gitignored):
- Contains environment-specific configuration
- Never commit this file
- Required for local development and CI builds
- Example variables: `ALADHAN_API_METHOD`, `ALADHAN_SCHOOL`, `FCM_*` credentials

**`firebase_options.dart`** (committed):
- Contains Firebase project configuration
- Public API keys (safe to commit)
- Generated by FlutterFire CLI
- Protected by Firebase Security Rules

---

### Troubleshooting

#### Build Fails with "No file found for asset: .env"

**Solution**: The CI workflow creates this file automatically. Locally:
```bash
cp .env.example .env
```

#### Firebase Initialization Fails

**Solutions**:
1. Ensure `firebase_options.dart` is committed to repository
2. Run `flutterfire configure` to regenerate
3. Verify Firebase project ID matches

#### Android Build Fails in CI

**Common issues**:
1. **Keystore secret malformed**: Ensure base64 encoding has no line breaks
2. **Wrong password**: Double-check `KEYSTORE_PASSWORD` and `KEY_PASSWORD`
3. **Missing secret**: Verify all 4 Android secrets are set

**Debug steps**:
```bash
# Verify your keystore locally
keytool -list -v -keystore upload-keystore.jks
```

#### Firebase Deployment Fails

**Common issues**:
1. **Invalid token**: Run `firebase login:ci` again to get a new token
2. **Wrong project**: Check Firebase project ID in `.firebaserc`
3. **Insufficient permissions**: Ensure Firebase account has deployment permissions

**Debug steps**:
```bash
# Test deployment locally
firebase deploy --only firestore:rules --token YOUR_TOKEN
```

#### iOS Build Fails

**Common issues**:
1. **CocoaPods errors**: The workflow handles pod installation automatically
2. **Code signing**: iOS builds in CI use `--no-codesign` flag
3. **Platform version**: Ensure `ios/Podfile` has correct platform version

---

### Environment Variables in CI

The workflow automatically creates a `.env` file with these variables:

```env
# API Configuration
ALADHAN_API_METHOD=3
ALADHAN_SCHOOL=1

# FCM credentials would go here (if needed for CI builds)
# For security, consider using GitHub Secrets for sensitive values
```

To add more environment variables to CI:
1. Add them to the workflow file's "Create .env file" step
2. Or, add them as GitHub Secrets and reference them in the workflow

---

### Workflow Customization

The workflow file is located at: `.github/workflows/flutter_ci.yml`

**Common customizations**:

#### Change Trigger Branches
```yaml
on:
  push:
    branches: [ main, develop, staging ]  # Add more branches
```

#### Add Slack/Discord Notifications
```yaml
- name: Notify on success
  if: success()
  run: |
    curl -X POST -H 'Content-type: application/json' \
    --data '{"text":"Build succeeded!"}' \
    ${{ secrets.SLACK_WEBHOOK }}
```

#### Deploy Cloud Functions
Add to the deploy job:
```yaml
- name: Deploy Cloud Functions
  run: firebase deploy --only functions --token ${{ secrets.FIREBASE_TOKEN }}
```

---

### Best Practices

#### Security
- ✅ Never commit `.env` file
- ✅ Store all secrets in GitHub Secrets
- ✅ Rotate Firebase tokens periodically
- ✅ Keep keystore file backed up securely
- ✅ Use different keystores for debug/release builds

#### Performance
- ✅ Cache Flutter dependencies to speed up builds
- ✅ Run jobs in parallel when possible
- ✅ Only deploy on `main` branch to avoid unnecessary deployments

#### Maintenance
- ✅ Keep GitHub Actions versions updated
- ✅ Monitor build times and optimize slow steps
- ✅ Review workflow logs for warnings
- ✅ Test workflow changes on a separate branch first

---

### CI/CD Pipeline Flow

```
Push to GitHub
    ↓
[Analyze Job]
    ├── Create .env
    ├── Install dependencies
    ├── Run flutter analyze
    └── Run tests
    ↓
┌───────────────────┐
│ On main/develop   │
└───────────────────┘
    ↓
[Build Android]          [Build iOS]
    ├── Decode keystore      ├── Create .env
    ├── Build APK            ├── Pod install
    ├── Build AAB            └── Build iOS
    └── Upload artifacts         ↓
    ↓                         Upload artifacts
[Deploy Firebase]
(main branch only)
    ├── Deploy rules
    └── Deploy indexes
    ↓
[Create Release]
(on version tag)
    ├── Create GitHub release
    └── Attach build artifacts
```

---

### Monitoring Builds

**View build status**:
- Go to your GitHub repository
- Click "Actions" tab
- See all workflow runs and their status

**Build badges** (add to README):
```markdown
![CI](https://github.com/YOUR_USERNAME/YOUR_REPO/workflows/Flutter%20CI/badge.svg)
```

**Email notifications**:
- GitHub sends emails on build failures by default
- Configure in: GitHub Settings → Notifications

---


## 📊 Analytics & Monitoring

### Firebase Analytics (Optional)

Add Firebase Analytics to track:

- Active users
- Most viewed screens
- Notification engagement
- Prayer time views

### Crashlytics (Optional)

Add Crashlytics for error tracking and stability monitoring.

---

## 🔐 Security

### Security Measures Implemented

This application implements multiple layers of security:

#### 1. **No Hardcoded Credentials**
- All hardcoded credentials have been removed from the codebase
- Authentication is exclusively handled through Firebase
- No local admin backdoors or testing credentials

#### 2. **Environment Configuration**
- Sensitive configuration stored in `.env` file (gitignored)
- Environment variables managed through `flutter_dotenv`
- `.env.example` provided as a template without real credentials
- Configuration loaded at app initialization

#### 3. **Input Validation**
All user inputs are validated before processing:

**Prayer Service Validation:**
- Coordinates: Latitude (-90 to 90), Longitude (-180 to 180)
- Calculation method: 0-23 (Aladhan API methods)
- City/Country: Non-empty, max 100 characters
- Prayer times: HH:MM or HH:MM AM/PM format validation
- Iqama times: Format and completeness validation before saving

**User Input Validation:**
- Email format validation
- Password strength requirements
- Display name length limits
- Role changes restricted to admins

#### 4. **Firebase Security**
- **Authentication**: Email/password with Firebase Auth
- **Firestore Rules**: Role-based access control (RBAC)
- **Security Rules**: Server-side validation of all operations
- **API Keys**: Client API keys are public (as designed by Firebase)
- **Backend Protection**: Firestore Security Rules protect data access

#### 5. **CI/CD Security**
- Secrets managed through GitHub Secrets
- Keystore files never committed to repository
- Automatic cleanup of sensitive files after builds
- Environment files created dynamically in CI pipeline
- Firebase deployment tokens secured

### Security Best Practices

1. **Never commit** the `.env` file to version control
2. **Rotate credentials** regularly if compromised
3. **Keep dependencies updated** - Run `flutter pub upgrade` periodically
4. **Role verification** - Always verify user roles server-side through Firestore rules
5. **Input validation** - All inputs are validated both client and server-side
6. **Rate limiting** - Consider implementing rate limiting for write operations
7. **Monitor Firebase** - Regularly check Firebase Console for suspicious activity
8. **Audit logs** - Review Firestore operations in Firebase Console
9. **Use strong passwords** - Enforce password policies for user accounts
10. **Review security rules** - Periodically audit Firestore security rules

### What's Protected

✅ **Protected:**
- User credentials (Firebase Authentication)
- Role-based permissions (Firestore Rules)
- Prayer time modifications (Moderator/Admin only)
- User management (Admin only)
- Notification management (Moderator/Admin only)

✅ **Public (By Design):**
- Firebase client API keys (protected by Security Rules)
- Prayer times (read-only for public)
- Active notifications (read-only for public)

### Incident Response

If you suspect a security issue:
1. Immediately rotate affected credentials
2. Review Firebase Console audit logs
3. Check Firestore Security Rules are properly configured
4. Update the app if necessary
5. Report the issue to: dardticcjp@gmail.com

### Security Audits

Regular security audits should include:
- Firestore Security Rules review
- Dependency vulnerability scanning (`flutter pub outdated`)
- User access patterns monitoring
- Authentication logs review

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Contribution Guidelines

- Follow Flutter/Dart style guide
- Write meaningful commit messages
- Add comments for complex logic
- Test on both Android and iOS
- Update documentation as needed
- Ensure dark mode compatibility

---

## 📞 Support

For support and questions:

- **Email**: dardticcjp@gmail.com

---

## 🙏 Acknowledgments

- [Aladhan API](https://aladhan.com/prayer-times-api) for accurate prayer times
- [Flutter](https://flutter.dev) for the amazing cross-platform framework
- [Firebase](https://firebase.google.com) for reliable backend services
- [Google Fonts](https://fonts.google.com) for beautiful typography
- The Muslim Ummah for inspiration and feedback

---

## 📝 Changelog

### Unreleased (13 October 2026) - UI Redesign & Masjid Display

#### New Features

- 🖥️ **Masjid display mode** for screens ≥ 900px wide: large prayer table, clock with Gregorian & Hijri dates, rotating notices, next-prayer countdown, donation QR code, notice ticker
- 🔔 **New iqamah sequence**: 60s countdown → 30s "Time for prayer" → 10-minute "Prayer in progress" → home (display and phones)
- 🕌 **"Time for prayer" screen** with etiquette reminders, in landscape (display) and portrait (phone) layouts
- 🕋 **Jummah** shown in the prayer tables, in place of Dhuhr on Fridays
- 💳 **Donation QR code** on the display (`assets/images/qr code for donations.png`)
- 🌙 **Dark mode** for the redesigned mobile home and the display
- 🌐 **Arabic labels** across the home screens and overlays; **Japanese** on the "Prayer in progress" screen

#### Changes

- 🎨 Redesigned mobile home, iqamah countdown and "Prayer in progress" screens to match `design/screens`
- 🧭 Bottom navigation restyled with English & Arabic labels (Times, Prayers, Qibla, Notices, Settings)
- 🔄 Mobile home notice card now rotates through all active notices (high priority first)
- ⏱️ "Prayer in progress" duration changed from 7 to 10 minutes
- 🌅 Sunrise removed from the Prayers tab and no longer counted as the next prayer
- 🕌 New sunset icon for Maghrib
- 🚫 Prohibited-time alert implemented but disabled for now

#### Bug Fixes

- Fixed bottom navigation overflow error when the browser window is very small
- Notice dots switch to a "3 / 20" counter above 10 notices so they don't overflow

#### Tests

- Added `test/unit/models/prayer_windows_test.dart` (iqamah sequence, Jummah/Friday rule, prohibited windows)
- Added a test that Sunrise is skipped when finding the next prayer

### Version 1.1.0

#### Security Enhancements 🔐

- ✅ **Removed all hardcoded credentials** - No local admin backdoors
- ✅ **Environment configuration** - Added `flutter_dotenv` for secure config management
- ✅ **Comprehensive input validation** - All prayer times, coordinates, and user inputs validated
- ✅ **Firebase-only authentication** - Exclusively using Firebase Auth (no local auth)
- ✅ **CI/CD security improvements** - Dynamic `.env` creation, secure secret management
- ✅ **Gitignore updates** - Proper exclusion of sensitive files
- ✅ **Security documentation** - Comprehensive security practices documented

#### Bug Fixes

- Fixed CI/CD dependency installation failures
- Fixed environment configuration loading
- Fixed input validation edge cases

#### Documentation

- Added detailed security section in README
- Created CI_CD_SETUP.md for deployment guide
- Updated installation instructions with environment setup
- Added troubleshooting for environment issues

### Version 1.0.0

#### New Features

- ✨ Multi-notification system with unlimited announcements
- 🎨 Notification types: Announcement, Event, Alert
- 🎯 Priority levels: High, Regular, Low
- 📰 News ticker for non-high priority notifications
- 🔄 Rotating high priority cards on home screen
- 📱 Notification detail bottom sheet
- 🗂️ Notification filtering by type
- ⚡ Real-time Firestore sync
- 🧹 Auto-cleanup of expired notifications
- 👥 Enhanced user management for admins
- ✏️ Moderators can now edit iqama times
- 🌙 Improved dark mode with proper contrast
- 💾 Enhanced caching system

#### Bug Fixes

- Fixed dark mode contrast in notification detail sheet
- Fixed LateInitializationError on smaller screens
- Fixed notification overflow issues
- Improved error handling for network failures
- Fixed ticker display on various screen sizes

#### Performance

- Optimized Firestore queries with indexes
- Improved local caching
- Reduced unnecessary rebuilds
- Better memory management

---

Made with ❤️ for the Ummah by the Darut Tauhid Masjid Development Team
