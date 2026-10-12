# iOS Configuration for App Store Release

**Status:** Location permissions added ✅ | Code signing requires manual configuration ⚠️

---

## What's Been Configured ✅

### 1. Location Usage Descriptions (Required for App Store)

**File:** `ios/Runner/Info.plist`

Added required location permission descriptions:
- `NSLocationWhenInUseUsageDescription` - For fetching prayer times based on location
- `NSLocationAlwaysAndWhenInUseUsageDescription` - For prayer notifications

These descriptions will be shown to users when the app requests location access.

---

## Manual Configuration Required ⚠️

The following steps **must be completed in Xcode** before submitting to App Store:

### Step 1: Open Project in Xcode

```bash
cd ios
open Runner.xcworkspace
```

**Important:** Always open `Runner.xcworkspace`, NOT `Runner.xcodeproj`

### Step 2: Update Bundle Identifier (Recommended)

**Current:** `com.example.prayerApp`
**Recommended:** `com.daruttauhidmasjid.prayerapp` (or your organization's domain)

**Steps:**
1. In Xcode, select `Runner` in the project navigator
2. Select the `Runner` target
3. Go to "Signing & Capabilities" tab
4. Update "Bundle Identifier" field

**Note:** If you change the bundle identifier, you must:
- Update Firebase iOS configuration (download new `GoogleService-Info.plist`)
- Register new bundle ID in Apple Developer Portal
- Create new App ID in App Store Connect

### Step 3: Configure Code Signing

**Option A: Automatic Signing (Recommended for beginners)**

1. In Xcode → Runner target → "Signing & Capabilities"
2. Check "Automatically manage signing"
3. Select your "Team" from dropdown (requires Apple Developer account)
4. Xcode will automatically:
   - Generate provisioning profiles
   - Create certificates
   - Handle signing complexity

**Option B: Manual Signing (Advanced users)**

1. Uncheck "Automatically manage signing"
2. Create certificates in Apple Developer Portal:
   - Development certificate for testing
   - Distribution certificate for App Store
3. Create provisioning profiles:
   - Development profile for testing
   - App Store profile for release
4. Select profiles in Xcode for Debug and Release configurations

**Apple Developer Account Required:**
- Individual: $99/year
- Organization: $99/year
- Sign up at: https://developer.apple.com/programs/

### Step 4: Add Push Notifications Capability

1. In Xcode → Runner target → "Signing & Capabilities"
2. Click "+ Capability"
3. Add "Push Notifications"
4. This is required for FCM (Firebase Cloud Messaging)

### Step 5: Register App in App Store Connect

1. Go to https://appstoreconnect.apple.com
2. Click "My Apps" → "+" → "New App"
3. Fill in details:
   - **Platform:** iOS
   - **Name:** Prayer Times - Darut Tauhid (or your app name)
   - **Primary Language:** English
   - **Bundle ID:** Select the bundle ID you configured (must match Xcode)
   - **SKU:** Unique identifier (e.g., `darut-tauhid-prayer-app-001`)
4. Click "Create"

---

## Current iOS Project Status

### Build Configuration

**Debug Configuration:**
- Bundle ID: `com.example.prayerApp`
- Signing: Debug signing (works for local testing)
- Code signing: ⚠️ **Not configured for release**

**Release Configuration:**
- Bundle ID: `com.example.prayerApp`
- Signing: ⚠️ **Requires manual configuration in Xcode**
- Code signing: ⚠️ **Not configured**

### Files Configured

✅ `ios/Runner/Info.plist` - Location permissions added
⚠️ `ios/Runner.xcodeproj/project.pbxproj` - Bundle ID needs update
⚠️ `ios/Runner.xcodeproj/project.pbxproj` - Code signing needs configuration

---

## Build Commands

### Development Build (Simulator)

```bash
flutter build ios --debug --simulator
```

### Release Build (Physical Device - Requires Code Signing)

```bash
# After configuring code signing in Xcode
flutter build ios --release
```

### Create Archive for App Store Submission

```bash
# After configuring code signing in Xcode
flutter build ipa
```

The IPA file will be created at: `build/ios/ipa/prayer_app.ipa`

---

## Verification Checklist

Before submitting to App Store, verify:

- [ ] Bundle identifier is production-ready (not `com.example.*`)
- [ ] Code signing is configured with valid distribution certificate
- [ ] Push Notifications capability is added
- [ ] Location permission descriptions are clear and accurate
- [ ] App builds successfully with `flutter build ipa`
- [ ] App is registered in App Store Connect
- [ ] Firebase iOS configuration matches bundle identifier
- [ ] Version number is correct (currently `1.0.0+1`)

---

## CI/CD Configuration

**Current:** `.github/workflows/flutter-ci.yml` builds with `--no-codesign` flag

**For Production:** Update workflow to:
1. Install signing certificates from GitHub Secrets
2. Install provisioning profiles from GitHub Secrets
3. Remove `--no-codesign` flag
4. Build with proper code signing

**Required GitHub Secrets:**
- `IOS_CERTIFICATE_BASE64` - Distribution certificate (base64 encoded .p12)
- `IOS_CERTIFICATE_PASSWORD` - Certificate password
- `IOS_PROVISION_PROFILE_BASE64` - Provisioning profile (base64 encoded)
- `KEYCHAIN_PASSWORD` - Temporary keychain password for CI

---

## Common Issues & Solutions

### Issue: "Xcode requires a provisioning profile"

**Solution:**
1. Go to Signing & Capabilities in Xcode
2. Select your Team
3. Let Xcode automatically manage signing

### Issue: "No accounts with App Store Connect access"

**Solution:**
1. You need an active Apple Developer Program membership ($99/year)
2. Add your Apple ID in Xcode → Settings → Accounts

### Issue: "Failed to register bundle identifier"

**Solution:**
1. Bundle ID must be unique across all iOS apps
2. Choose a bundle ID based on your domain (e.g., `com.yourorg.appname`)
3. Register it in Apple Developer Portal first

### Issue: "Build fails with code signing error"

**Solution:**
1. Delete derived data: `rm -rf ~/Library/Developer/Xcode/DerivedData`
2. Clean build folder in Xcode: Product → Clean Build Folder
3. Verify certificates are valid in Apple Developer Portal
4. Try "Revoke and Request" in Xcode if certificate is invalid

---

## Next Steps After iOS Configuration

Once iOS code signing is configured:

1. ✅ Phase 3.0: Compass UI Fix - **COMPLETE**
2. ✅ Phase 3.1: Android Release Signing - **COMPLETE**
3. ⚠️ Phase 3.2: iOS Code Signing - **Requires manual Xcode configuration**
4. Phase 3.3: Update Package Names (Optional)
5. Phase 3.4: Version Management
6. Phase 4: CI/CD Enhancement
7. Phase 5: Additional Testing & Production Optimizations

---

## Support Resources

- **Apple Developer Documentation:** https://developer.apple.com/documentation/
- **App Store Connect Help:** https://developer.apple.com/help/app-store-connect/
- **Flutter iOS Deployment:** https://docs.flutter.dev/deployment/ios
- **Firebase iOS Setup:** https://firebase.google.com/docs/ios/setup

---

**Last Updated:** December 10, 2025
**Phase:** 3.2 - iOS Code Signing Configuration
