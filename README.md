# Darut Tauhid Masjid - Prayer Times App

A beautiful, modern Flutter application for displaying prayer times, managing mosque announcements, and community engagement with advanced notification system and role-based access control.

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)
![Firebase](https://img.shields.io/badge/Firebase-Firestore-orange.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

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

- 🔔 **60-Second Countdown Overlay** - Full-screen alert before Iqama with progress bar
- 🔵 **Silent Mode Screen** - 7-minute blackout during prayer time with elegant design
- 🎯 **High Priority Notifications** - Rotating cards for important announcements on home screen
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

---

## 📂 Project Structure

```
lib/
├── main.dart                      # App entry point with auth wrapper
├── firebase_options.dart          # Firebase configuration (auto-generated)
│
├── models/
│   ├── prayer_time.dart           # Prayer time data models
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
│   ├── home_tab.dart              # Home tab with countdown & high priority notifications
│   ├── prayers_tab.dart           # Prayer schedule with edit capabilities
│   ├── notifications_tab.dart     # Full notifications list with filters & CRUD
│   ├── more_tab.dart              # Settings, user info, and app info
│   ├── profile_screen.dart        # User profile editing
│   └── users_screen.dart          # Admin user management screen
│
├── widgets/
│   ├── prayer_card.dart           # Prayer card widgets (full & compact)
│   ├── next_prayer_card.dart      # Countdown card with sun times
│   ├── countdown_overlay.dart     # Pre-iqama full-screen overlay
│   ├── blackout_overlay.dart      # Silent mode full-screen overlay
│   ├── notification_card.dart     # Notification cards with detail sheet
│   └── news_ticker.dart           # Bottom ticker for announcements
│
└── utils/
    └── constants.dart             # App constants, colors, & enums
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

#### 3. Firebase Setup

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

#### 4. Firestore Structure

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

#### 5. Firestore Rules

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

#### 6. Firestore Indexes

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

#### 7. Create First Admin

1. Run the app and create an account
2. Go to Firebase Console → Firestore → `users` collection
3. Find your user document
4. Change `role` field from `public` to `admin`

#### 8. Run the app

```bash
flutter run
```

---

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Firebase
  firebase_core: ^2.24.2
  cloud_firestore: ^4.14.0
  firebase_auth: ^4.16.0

  # Location
  geolocator: ^10.1.0
  geocoding: ^2.1.1

  # Storage & Utils
  shared_preferences: ^2.2.2
  http: ^1.1.0
  intl: ^0.18.1

  # UI
  google_fonts: ^6.1.0
```

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
  static const Duration countdownWarningTime = Duration(seconds: 60);
  static const Duration blackoutDuration = Duration(minutes: 7);

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

Edit `AppColors` class in `constants.dart`:

```dart
static const Color primaryGreen = Color(0xFF2D5F3F);
static const Color priorityHigh = Color(0xFFE53935);
static const Color priorityRegular = Color(0xFF1E88E5);
```

---

## 🖼️ UI Features

### Dark Mode

- **Auto-switching**: Between Maghrib and Sunrise
- **Manual override**: Toggle in settings
- **Proper contrast**: All screens optimized for both themes
- **Notification detail**: Fixed contrast issue in meta information section

### Responsive Design

- **Mobile-first**: Optimized for phones
- **Tablet support**: Larger screens supported
- **Adaptive layouts**: Content adjusts to screen size
- **Smooth animations**: Fade transitions for countdown and notifications

### Overlays

- **Countdown Overlay**: Shows 60 seconds before iqama
- **Blackout Overlay**: Silent mode during prayer (7 minutes)
- **Gradient designs**: Beautiful visual effects

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

---

## 🚀 Deployment

### Android

```bash
flutter build apk --release
# or for app bundle
flutter build appbundle --release
```

### iOS

```bash
flutter build ios --release
```

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

## 🔐 Security Best Practices

1. **Never commit** `firebase_options.dart` to public repos
2. **Use environment variables** for sensitive data
3. **Regular updates** - Keep dependencies updated
4. **Role verification** - Always verify user roles on server-side
5. **Input validation** - Validate all user inputs
6. **Rate limiting** - Consider rate limiting for write operations

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

### Version 1.0.0 (Current)

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
