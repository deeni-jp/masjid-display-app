# Darut Tauhid Masjid - Prayer Times App

A beautiful, modern Flutter application for displaying prayer times, managing mosque announcements, and community engagement.

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)
![Firebase](https://img.shields.io/badge/Firebase-Firestore-orange.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## ✨ Features

### For All Users

- 🕌 **Accurate Prayer Times** - Fetched from Aladhan API based on GPS location
- ⏱️ **Live Countdown** - Smooth animated countdown to next prayer
- 📢 **Announcements** - Stay updated with mosque news and events
- 🌙 **Auto Dark Mode** - Automatically switches between Maghrib and Sunrise
- 📍 **Location Detection** - GPS-based with fallback to IP geolocation
- 💾 **Offline Support** - Cached data works without internet

### For Moderators

- ✏️ **Edit Iqama Times** - Update congregation prayer times
- 📝 **Manage Announcements** - Create and edit mosque announcements

### For Admins

- 👥 **User Management** - View all users and change roles
- 🔒 **Full Access** - All moderator permissions plus user management

### Special Features

- 🔔 **60-Second Countdown Overlay** - Full-screen alert before Iqama
- 📵 **Silent Mode Screen** - 7-minute blackout during prayer time
- 👤 **User Profiles** - Edit display name and password

---

## 📱 Screenshots

| Home                          | Prayers                             | Profile                             | Admin                           |
| ----------------------------- | ----------------------------------- | ----------------------------------- | ------------------------------- |
| ![Home](screenshots/home.png) | ![Prayers](screenshots/prayers.png) | ![Profile](screenshots/profile.png) | ![Admin](screenshots/admin.png) |

---

## 🛠️ Tech Stack

- **Framework**: Flutter 3.x
- **Backend**: Firebase (Auth, Firestore)
- **APIs**: Aladhan Prayer Times API
- **State Management**: StatefulWidget
- **Local Storage**: SharedPreferences
- **Location**: Geolocator, Geocoding

---

## 📁 Project Structure

```
lib/
├── main.dart                      # App entry point with auth wrapper
├── firebase_options.dart          # Firebase configuration (auto-generated)
│
├── models/
│   ├── prayer_time.dart           # Prayer time data models
│   ├── notification_model.dart    # Notification/announcement model
│   └── user_model.dart            # User model with roles
│
├── services/
│   ├── prayer_service.dart        # Prayer times API service
│   ├── location_service.dart      # GPS & geocoding service
│   ├── firebase_service.dart      # Firestore operations
│   ├── storage_service.dart       # Local storage (SharedPreferences)
│   └── user_service.dart          # User management service
│
├── screens/
│   ├── auth_screen.dart           # Login/Signup screen
│   ├── home_page.dart             # Main container with bottom nav
│   ├── home_tab.dart              # Home tab content
│   ├── prayers_tab.dart           # Prayer schedule tab
│   ├── notifications_tab.dart     # Announcements tab
│   ├── more_tab.dart              # Settings & more tab
│   ├── profile_screen.dart        # User profile screen
│   └── users_screen.dart          # Admin user management
│
├── widgets/
│   ├── prayer_card.dart           # Prayer card widgets
│   ├── next_prayer_card.dart      # Countdown card
│   ├── countdown_overlay.dart     # Pre-iqama overlay
│   ├── blackout_overlay.dart      # Silent mode overlay
│   └── notification_card.dart     # Notification widgets
│
└── utils/
    └── constants.dart             # App constants & colors
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
   - **Firestore Database** → Create database

#### 4. Firestore Rules

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

    match /users/{userId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && request.auth.uid == userId;
      allow update: if request.auth != null && (
        (request.auth.uid == userId && !request.resource.data.diff(resource.data).affectedKeys().hasAny(['role'])) ||
        isAdmin()
      );
      allow delete: if isAdmin();
    }

    match /mosque/iqama {
      allow read: if true;
      allow write: if isModeratorOrAdmin();
    }

    match /mosque/notification {
      allow read: if true;
      allow write: if isModeratorOrAdmin();
    }

    match /mosque/{document} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

#### 5. Create First Admin

1. Run the app and create an account
2. Go to Firebase Console → Firestore → `users` collection
3. Find your user document
4. Change `role` field from `public` to `admin`

#### 6. Run the app

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

## 👥 User Roles

| Role          | Description                | Permissions                              |
| ------------- | -------------------------- | ---------------------------------------- |
| **Public**    | Default role for new users | View prayer times & announcements        |
| **Moderator** | Mosque staff/volunteers    | + Edit Iqama times, Manage announcements |
| **Admin**     | Mosque administrators      | + Manage users & roles                   |

---

## 🔧 Configuration

### App Constants

Edit `lib/utils/constants.dart` to customize:

```dart
class AppConstants {
  static const String appName = 'Your Mosque Name';
  static const String appVersion = '1.0.0';
  static const int aladhanApiMethod = 2; // Prayer calculation method
  static const Duration blackoutDuration = Duration(minutes: 7);
}
```

### Prayer Calculation Methods

| Method                                  | ID  |
| --------------------------------------- | --- |
| Shia Ithna-Ashari                       | 0   |
| University of Islamic Sciences, Karachi | 1   |
| Islamic Society of North America (ISNA) | 2   |
| Muslim World League                     | 3   |
| Umm Al-Qura University, Makkah          | 4   |
| Egyptian General Authority of Survey    | 5   |

---

## 🐛 Troubleshooting

### Common Issues

**1. Firebase permission denied**

- Check Firestore rules are correctly set
- Ensure user is authenticated
- Verify the first admin is set up correctly

**2. Location not working**

- Check app permissions in device settings
- Ensure GPS is enabled
- Add permissions to AndroidManifest.xml and Info.plist

**3. Fonts not loading**

- Check internet connection on first run
- Fonts are cached after first load

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📞 Support

For support, email dardticcjp@gmail.com

---

## 🙏 Acknowledgments

- [Aladhan API](https://aladhan.com/prayer-times-api) for prayer times
- [Flutter](https://flutter.dev) for the amazing framework
- [Firebase](https://firebase.google.com) for backend services
- The Muslim community for inspiration

---

Made with ❤️ for the Ummah
