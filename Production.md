Production Readiness Plan: Prayer Times App

Overview

This plan makes your Flutter prayer times app production-ready for deployment to both Google Play Store and Apple App Store. Based on comprehensive code
exploration, I've identified critical security vulnerabilities, testing gaps, and build configuration issues that must be addressed before launch.

User Requirements:

- Deploy to: Both Android and iOS
- Priority: All areas equally (security, testing, app store setup)
- Credentials: Keep existing Firebase project but secure credentials properly
- Timeline: Flexible (quality over speed)

Current Critical Issues:

- 🔴 Firebase service account private key exposed in .env file (committed to git)
- 🔴 .env file bundled as asset in pubspec.yaml (credentials in compiled app)
- 🔴 Android release builds signed with debug keys
- 🔴 iOS builds without code signing
- 🔴 0% service layer test coverage (8 critical services untested)
- 🟡 Overly permissive Firestore security rules

Implementation Phases

Phase 1: CRITICAL Security Fixes (BLOCKING - Must Complete First)

Priority: P0 | Time: 4-6 hours

1.1 Rotate Compromised Credentials

Problem: Firebase service account private key exposed in git history.

Actions:

1.  Generate new service account key in Firebase Console → Project Settings → Service Accounts
2.  Delete old service account key (ID: 8106a42ba...)
3.  Update local .env file with new credentials
4.  Check git history: git log --all --full-history -- .env

1.2 Remove .env from App Bundle

File: pubspec.yaml (line 56)

Change:

# Before

assets:

- .env
- assets/images/

# After

assets:

- assets/images/

Why: Prevents credentials from being bundled in APK/IPA where they can be extracted.

1.3 Implement Secure Secrets Management

Create: lib/utils/native_secrets.dart

Approach:

- Use String.fromEnvironment() for compile-time constants (project ID, client email)
- Use platform channels for sensitive data (private key)
- Android: BuildConfig fields from environment variables
- iOS: Xcode build configuration variables
- Development: Continue using .env file locally

Update: lib/services/fcm_notification_sender.dart

- Add fallback logic to read from both .env (dev) and environment variables (prod)

  1.4 Harden Firestore Security Rules

File: firestore.rules (lines 76-79)

Change:
// Before (TOO PERMISSIVE)
match /mosque/{document} {
allow read: if true;
allow write: if request.auth != null; // ANY authenticated user can write
}

// After
match /mosque/{document} {
allow read: if true;
allow write: if isModeratorOrAdmin(); // Only moderators/admins
}

Add input validation:

- Time format validation for iqama times
- String length limits to prevent DoS
- Type checking for all fields

  1.5 Security Validation Checklist

# Verify .env not in assets

grep -n "\.env" pubspec.yaml

# Check for hardcoded credentials

grep -r "-----BEGIN PRIVATE KEY-----" lib/ android/ ios/

# Verify all prints are debug-only

grep -r "print(" lib/ | grep -v "kDebugMode"

# Run security analyzer

flutter analyze

Critical Files:

- pubspec.yaml - Remove .env from assets
- .env - Rotate all Firebase credentials
- lib/services/fcm_notification_sender.dart - Secure credential loading
- firestore.rules - Harden permissions

---

Phase 2: Essential Testing Coverage

Priority: P1 | Time: 12-16 hours

Goal: Achieve 70%+ test coverage for critical services (currently 0%)

2.1 Priority Service Tests (CRITICAL - P0)

Create these test files:

1.  test/unit/services/firebase_service_test.dart

- Test iqama times CRUD operations
- Test notifications CRUD with filtering
- Test authentication flows
- Mock Firestore and FirebaseAuth

2.  test/unit/services/user_service_test.dart

- Test user CRUD operations
- Test role-based permissions (admin, moderator, public)
- Test critical edge cases (can't delete last admin, can't change own role)
- Test soft delete workflow

3.  test/unit/services/prayer_service_test.dart

- Test API integration with Aladhan
- Test time format validation
- Test error handling (HTTP errors, timeouts, invalid responses)
- Mock HTTP client

4.  test/unit/services/location_service_test.dart

- Test permission handling flows
- Test location fetching with fallbacks
- Mock geolocator and permission_handler

Pattern: Follow existing test structure in test/unit/services/hijri_calendar_service_test.dart

2.2 Integration Tests Enhancement

Update: test/integration/app_navigation_test.dart (currently placeholder)

Add critical user flows:

- Launch app → View prayer times → Navigate tabs
- Sign in → Create notification → Verify appears → Sign out
- Admin: Sign in → Change user role → Verify permissions updated

  2.3 CI/CD Test Integration

File: .github/workflows/flutter-ci.yml

Already configured: Test coverage upload to Codecov ✓

Add:

- Coverage threshold enforcement (70% minimum)
- Test result reporting in GitHub Actions summary

Critical Files:

- test/unit/services/firebase_service_test.dart (new)
- test/unit/services/user_service_test.dart (new)
- test/unit/services/prayer_service_test.dart (new)
- test/unit/services/location_service_test.dart (new)
- test/integration/app_navigation_test.dart (enhance)

---

Phase 3: Production Build Configuration (BLOCKING for Deployment)

Priority: P0 | Time: 8-10 hours

3.1 Android Release Signing

Current Issue: android/app/build.gradle.kts line 38 uses debug keys for release builds

Step 1: Generate Release Keystore

cd android/app
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

Save password securely in password manager.

Step 2: Create android/key.properties (gitignored)

storePassword=YOUR_PASSWORD
keyPassword=YOUR_PASSWORD
keyAlias=upload
storeFile=upload-keystore.jks

Step 3: Update android/app/build.gradle.kts

Replace lines 34-40 with proper signing configuration:

- Load key.properties file
- Create release signing config
- Enable minification and shrink resources
- Add ProGuard rules

Step 4: Create android/app/proguard-rules.pro

Add Flutter and Firebase keep rules to prevent issues with R8 optimization.

3.2 iOS Code Signing

Current Issue: Builds with --no-codesign flag in CI/CD (line 130)

Step 1: Update Bundle Identifier

Open ios/Runner.xcworkspace in Xcode:

- Change from com.example.prayerTimesApp to com.daruttauhidmasjid.prayerapp
- Must match Android package name for consistency

Step 2: Configure Signing in Xcode

- Runner → Signing & Capabilities
- Select Apple Developer Team
- Enable "Automatically manage signing" (recommended)
- Add Push Notifications capability

Step 3: Register App in App Store Connect

- Create new app at https://appstoreconnect.apple.com
- Bundle ID must match Xcode configuration
- App Name: "Prayer Times - Darut Tauhid"

Step 4: Update ios/Runner/Info.plist

Add location usage descriptions (required for App Store approval):
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to show accurate prayer times for your area.</string>

3.3 Update Package Names (Recommended)

Change from: com.example.prayer_app (generic, may conflict)
Change to: com.daruttauhidmasjid.prayerapp (production-ready)

Files to update:

- android/app/build.gradle.kts (line 25): applicationId
- android/app/src/main/AndroidManifest.xml: package attribute
- android/app/src/main/kotlin/.../MainActivity.kt: package and folder structure
- Update Firebase project configuration (download new google-services.json)

  3.4 Version Management

File: pubspec.yaml (line 4)

Current: version: 1.0.0+1 ✓ (correct for initial release)

For future releases, use:
flutter pub global activate cider
cider bump patch # 1.0.0 → 1.0.1
cider bump minor # 1.0.1 → 1.1.0

Critical Files:

- android/app/build.gradle.kts - Release signing configuration
- android/key.properties (new, gitignored) - Keystore credentials
- android/app/proguard-rules.pro (new) - R8 optimization rules
- android/app/upload-keystore.jks (new, gitignored) - Release keystore
- ios/Runner.xcodeproj/project.pbxproj - Bundle ID and signing
- ios/Runner/Info.plist - Usage descriptions

---

Phase 4: CI/CD Enhancement & Secrets Management

Priority: P1 | Time: 6-8 hours

4.1 Configure GitHub Secrets

Add these secrets in GitHub repo → Settings → Secrets and variables → Actions:

Android:

- ANDROID_KEYSTORE_BASE64 - Base64 encoded upload-keystore.jks
- KEYSTORE_PASSWORD - Keystore password
- KEY_PASSWORD - Key password
- KEY_ALIAS - "upload"

Firebase:

- FCM_PROJECT_ID - Firebase project ID
- FCM_CLIENT_EMAIL - Service account email
- FCM_PRIVATE_KEY - Service account private key
- FCM_PRIVATE_KEY_ID - Private key ID

Other:

- CODECOV_TOKEN - For coverage reporting (from codecov.io)

To encode keystore:

# Linux/Mac

base64 -i android/app/upload-keystore.jks -o keystore.b64

# Windows

certutil -encode android/app/upload-keystore.jks keystore.b64

4.2 Update CI/CD Workflow

File: .github/workflows/flutter-ci.yml

Changes needed:

1.  Add FCM environment variables to build (lines 67-80)

- Use --dart-define for compile-time constants
- Pass secrets from GitHub Actions

2.  Fix iOS build (line 130)

- Remove --no-codesign flag
- Add certificate and provisioning profile installation steps
- Install from base64-encoded secrets

3.  Add deployment jobs (new)

- Deploy to Google Play internal track on version tags
- Deploy to TestFlight on version tags
- Require manual approval for production

4.3 Environment-Specific Configuration

Create environment files (all gitignored):

- .env.dev - Development Firebase project
- .env.staging - Staging Firebase project
- .env.production - Production Firebase project

Update: lib/utils/env_config.dart

- Support loading different .env files based on environment
- Read environment from --dart-define=ENVIRONMENT=production

Build commands:

# Development

flutter build apk --dart-define=ENVIRONMENT=dev

# Production

flutter build apk --release --dart-define=ENVIRONMENT=production --obfuscate --split-debug-info=build/debug-info

Critical Files:

- .github/workflows/flutter-ci.yml - Enhanced with secrets and deployment
- lib/utils/env_config.dart - Environment-aware initialization
- lib/main.dart - Read environment from compile-time constant

---

Phase 5: Production Optimizations & App Store Preparation

Priority: P2 (Nice-to-Have for Launch) | Time: 10-12 hours

5.1 Performance Optimizations

Enable obfuscation:
flutter build apk --release --obfuscate --split-debug-info=build/debug-info

Add Firebase Performance Monitoring:

- Add firebase_performance package
- Track app startup, API response times, screen renders

Add Firebase Crashlytics:

- Add firebase_crashlytics package
- Configure fatal error handlers in main.dart

Optimize images:

- Compress assets/images/mosque.png with ImageOptim or TinyPNG
- Target: 50% file size reduction

  5.2 App Store Assets

Screenshots needed:

Google Play (1080x1920 or similar):

- Home screen with prayer times and countdown
- Prayer times list with iqama times
- Notifications tab with announcements
- Qibla compass
- Dark mode variation

iOS (1290x2796 for 6.7" iPhone):

- Same content as Android, different dimensions

Feature Graphic (Android only): 1024x500

App Descriptions:

Short (80 chars):
"Accurate prayer times, iqama alerts, and mosque announcements for Darut Tauhid"

Full description: Include features, benefits, about the mosque, contact info

5.3 Privacy Policy & Terms

Required by both app stores:

1.  Create privacy policy (host on GitHub Pages or mosque website)

- What data collected: location, email, FCM token
- How used: prayer times, notifications
- Third-party services: Firebase, Aladhan API
- User rights: deletion, access, opt-out

2.  Add privacy policy URL to both app stores
3.  Complete content rating questionnaires (both stores)

5.4 Beta Testing

Google Play Internal Testing:

- Add 10-20 test users (mosque staff, board members)
- Duration: 1-2 weeks
- Collect feedback via Google Forms

TestFlight (iOS):

- Upload build to TestFlight
- Add internal testers
- Duration: 1-2 weeks
- Collect feedback via TestFlight

Beta feedback questions:

- App installs and launches correctly?
- Prayer times accurate?
- Notifications arrive on time?
- UI easy to navigate?
- Any bugs or crashes?
- Overall rating (1-5 stars)

  5.5 Final Pre-Launch Checklist

Security:

- .env removed from pubspec.yaml assets
- Firebase credentials rotated
- Firestore rules hardened
- No debug logging in release
- Security analyzer passes

Build:

- Android signed with production keystore
- iOS signed with distribution certificate
- ProGuard/R8 enabled
- Code obfuscation enabled

Testing:

- 70%+ test coverage
- All tests passing in CI/CD
- Beta testing completed with positive feedback

Functional:

- App installs on physical devices (both platforms)
- Prayer times accurate
- Notifications work in release builds
- Location permissions work
- Qibla compass accurate
- Dark mode switches correctly
- Admin panel works
- Offline mode works

App Store:

- Screenshots created (all sizes)
- Descriptions written
- Privacy policy published and linked
- Content rating completed
- Contact information accurate

Critical Files:

- pubspec.yaml - Add firebase_crashlytics, firebase_performance
- lib/main.dart - Crashlytics error handlers

---

Execution Timeline

Recommended approach (with flexibility):

Week 1: Security & Foundation

- Phase 1: Critical Security Fixes (2 days)
- Phase 3: Android Build Setup (3 days)

Week 2: Testing & iOS

- Phase 2: Priority Service Tests (3 days)
- Phase 3: iOS Build Setup (2 days)

Week 3: CI/CD & Complete Testing

- Phase 4: CI/CD Enhancement (2 days)
- Phase 2: Complete Test Coverage (3 days)

Week 4: Polish & Launch

- Phase 5: Performance Optimizations (2 days)
- Phase 5: App Store Assets & Submission (3 days)

Total: 4 weeks (can be compressed with multiple developers or extended for quality)

Critical Files Summary

Must Edit:

1.  pubspec.yaml - Remove .env, add dependencies
2.  .env - Rotate credentials (then secure)
3.  lib/services/fcm_notification_sender.dart - Secure credential loading
4.  android/app/build.gradle.kts - Release signing, ProGuard
5.  firestore.rules - Harden security
6.  .github/workflows/flutter-ci.yml - Secrets, deployment
7.  lib/main.dart - Crashlytics, environment-aware init
8.  ios/Runner.xcodeproj/project.pbxproj - Bundle ID, signing
9.  ios/Runner/Info.plist - Usage descriptions

Must Create: 10. android/key.properties - Keystore credentials (gitignored) 11. android/app/proguard-rules.pro - R8 rules 12. android/app/upload-keystore.jks - Release keystore (gitignored) 13. lib/utils/native_secrets.dart - Platform channel for secrets 14. test/unit/services/firebase_service_test.dart - Firebase tests 15. test/unit/services/user_service_test.dart - User tests 16. test/unit/services/prayer_service_test.dart - Prayer tests 17. test/unit/services/location_service_test.dart - Location tests

Next Steps

Once you approve this plan, we'll start with Phase 1 (Critical Security Fixes) and work through each phase systematically. Each phase can be validated and tested  
 before moving to the next, ensuring production-quality at every step.
