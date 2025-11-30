# FCM HTTP v1 API Setup Guide (Updated)

The Legacy FCM API is deprecated. This guide shows you how to use the **modern FCM HTTP v1 API** for push notifications without Cloud Functions.

## 🎯 Quick Setup (10 minutes)

### Step 1: Get Service Account Credentials

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **dticc-app**
3. Click ⚙️ gear icon → **Project settings**
4. Go to the **Service accounts** tab
5. Click **Generate new private key**
6. Click **Generate key** (a JSON file will download)
7. **IMPORTANT**: Keep this file secure! Don't share it or commit it to Git

The downloaded file will look like this:
```json
{
  "type": "service_account",
  "project_id": "dticc-app",
  "private_key_id": "abc123...",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIE...\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-xxxxx@dticc-app.iam.gserviceaccount.com",
  "client_id": "123456789",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/..."
}
```

### Step 2: Add Service Account to Your App

Open `lib/services/fcm_notification_sender.dart` and find line 21:

```dart
static const String _serviceAccountJson = '''
{
  "type": "service_account",
  "project_id": "YOUR_PROJECT_ID",
  ...
}
''';
```

Replace the entire JSON with your downloaded service account credentials. Make sure to keep the triple quotes (`'''`) around it.

**Example:**
```dart
static const String _serviceAccountJson = '''
{
  "type": "service_account",
  "project_id": "dticc-app",
  "private_key_id": "abc123def456...",
  "private_key": "-----BEGIN PRIVATE KEY-----\\nMIIEvQIBADANBgkq...\\n-----END PRIVATE KEY-----\\n",
  "client_email": "firebase-adminsdk-xxxxx@dticc-app.iam.gserviceaccount.com",
  "client_id": "123456789012345678901",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-xxxxx%40dticc-app.iam.gserviceaccount.com"
}
''';
```

**IMPORTANT:** Make sure newlines in the private_key are properly escaped with `\\n` (double backslash + n).

### Step 3: Enable Firebase Cloud Messaging API

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select project: **dticc-app**
3. Go to **APIs & Services** → **Library**
4. Search for "Firebase Cloud Messaging API"
5. Click on it and click **Enable**

### Step 4: Rebuild and Test

```bash
flutter clean
flutter build apk --release
```

Install the APK and test:
1. Log in as a user on your phone
2. Create a notification from the web as admin
3. You should receive a push notification! 🎉

---

## 🔒 Security Best Practices

### Option 1: Using Environment Variables (RECOMMENDED for Production)

**Step 1:** Add service account to `.env` file:

Create/edit `.env` file:
```env
FCM_SERVICE_ACCOUNT={"type":"service_account","project_id":"dticc-app",...}
```

**Step 2:** Update `fcm_notification_sender.dart`:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FCMNotificationSender {
  static final String _serviceAccountJson =
    dotenv.env['FCM_SERVICE_ACCOUNT'] ?? '{}';

  // Rest of the code...
}
```

**Step 3:** Make sure `.env` is in `.gitignore`:
```
.env
```

### Option 2: Store in Firestore (Most Secure)

Store credentials server-side and fetch them when needed (requires admin authentication).

---

## 🆚 Why FCM HTTP v1 API?

| Feature | Legacy API | HTTP v1 API |
|---------|-----------|-------------|
| **Status** | ❌ Deprecated (June 2024) | ✅ Current |
| **Authentication** | Server Key | OAuth 2.0 |
| **Security** | Lower | ✅ Higher |
| **Features** | Limited | Full featured |
| **Token Format** | Simple string | Structured JSON |

---

## 🔧 How It Works

### Flow:

```
Admin Creates Notification
        ↓
App gets OAuth2 access token (using service account)
        ↓
App sends FCM HTTP v1 request
        ↓
FCM validates token and sends to topic
        ↓
All subscribed users receive push notification
```

### Authentication Process:

1. **Service Account Credentials** → Used to authenticate with Google
2. **OAuth2 Access Token** → Temporary token (expires in 1 hour)
3. **FCM Request** → Sent with Bearer token
4. **Push Notification** → Delivered to users

---

## 🐛 Troubleshooting

### Error: "Service account not configured"

**Solution:** Make sure you've replaced the placeholder JSON with your actual service account credentials.

### Error: "Invalid credentials"

**Possible causes:**
1. Private key not properly escaped (check `\\n` in private_key)
2. Missing or incorrect quotes around JSON
3. Copied credentials incorrectly

**Solution:** Re-download the service account JSON and paste it carefully.

### Error: "Permission denied" or "403 Forbidden"

**Solution:**
1. Enable Firebase Cloud Messaging API in Google Cloud Console
2. Make sure service account has correct permissions

### Error: "Invalid argument" or "400 Bad Request"

**Solution:**
1. Check that your notification is active and not expired
2. Verify topic name is correct (`mosque_notifications`)
3. Check FCM token is valid

### Notifications not received

1. **Check service account is configured**: Look for `⚠️` warnings in debug console
2. **Check FCM API is enabled**: Google Cloud Console → APIs & Services
3. **Check user has FCM token**: Firestore → users collection → check `fcmToken` field
4. **Check user subscribed to topic**: Users should auto-subscribe on login
5. **Check notification is active**: Only active, non-expired notifications send push

---

## ⚡ Better Alternative: Cloud Functions

While the direct approach works, **Cloud Functions** is the recommended solution for production:

### Benefits:
- ✅ More secure (credentials stay on server)
- ✅ Automatic (no manual trigger needed)
- ✅ Reliable
- ✅ Scales better
- ✅ Lower latency

### Cost:
- **Free tier**: 2 million invocations/month
- **Blaze plan**: Pay only for what you use (still mostly free)
- **For your app**: Probably FREE (unless sending 1000s of notifications daily)

### How to Upgrade:

1. Go to [Firebase Console → Usage](https://console.firebase.google.com/project/dticc-app/usage/details)
2. Click **Modify plan** → Select **Blaze**
3. Add billing (you can set spending limits)
4. Deploy Cloud Functions (we already created them):
   ```bash
   cd functions
   firebase deploy --only functions
   ```

That's it! Cloud Functions will automatically send push notifications when you create notifications in Firestore.

---

## 📊 Cost Comparison

### Current Setup (Direct FCM):
- ✅ **Cost**: $0/month
- ⚠️ **Security**: Medium (credentials in app)
- ✅ **Reliability**: Good

### With Cloud Functions (Recommended):
- ✅ **Cost**: ~$0-5/month (depending on usage)
- ✅ **Security**: High (credentials on server)
- ✅ **Reliability**: Excellent
- ✅ **Automatic**: No manual trigger

---

## 🎯 Summary

You now have **modern FCM HTTP v1 API** working without Cloud Functions!

**What's done:**
- ✅ Updated to FCM HTTP v1 API
- ✅ OAuth2 authentication implemented
- ✅ Service account integration ready
- ✅ Auto-send on notification create

**Next steps:**
1. Download service account JSON from Firebase Console
2. Add it to `fcm_notification_sender.dart`
3. Enable Firebase Cloud Messaging API
4. Rebuild app and test

**When ready for production:**
- Consider upgrading to Blaze plan for Cloud Functions
- Or use environment variables for better security

---

## 📚 Resources

- [FCM HTTP v1 API Documentation](https://firebase.google.com/docs/cloud-messaging/http-server-ref)
- [Service Account Authentication](https://firebase.google.com/docs/admin/setup#initialize-sdk)
- [Firebase Pricing](https://firebase.google.com/pricing)
- [Migration from Legacy FCM](https://firebase.google.com/docs/cloud-messaging/migrate-v1)
