# Push notifications

When a moderator or admin saves a notice, phones get a push notification
(Android and iOS; the web app shows notices in-app only).

## How it works

```
App (moderator saves notice)
  └─ POST <PUSH_WORKER_URL>/notify  (Firebase ID token + notice id)
       └─ push worker (Cloudflare, free plan)
            ├─ verifies the token and the user's role in Firestore
            ├─ reads the notice from Firestore (must be active, not expired)
            └─ sends it with FCM HTTP v1 to the topic "mosque_notifications"
```

- App side: `lib/services/fcm_notification_sender.dart` (sending) and
  `lib/services/push_notification_service.dart` (receiving, topic subscription).
- The Firebase **service-account key lives only in the worker** as a Cloudflare
  secret – never in `.env` or the app.
- Costs: Firebase Spark + Cloudflare Workers free plan + FCM are all free.

## Setup

1. **Deploy the worker** – follow [push-worker/README.md](../push-worker/README.md)
   (`wrangler login`, store the service-account key, `wrangler deploy`).
2. Put the worker URL in `.env` as `PUSH_WORKER_URL` (the `.env` CI uses
   too, see [ci-cd.md](ci-cd.md)), then rebuild.
3. Enable the **Firebase Cloud Messaging API**: Google Cloud Console → APIs &
   Services → Library (otherwise FCM returns 403).

**Android** is already configured (notification permission and default
channel in `AndroidManifest.xml`).

**iOS** still needs, on a Mac:

1. Xcode → `ios/Runner.xcworkspace` → Runner → Signing & Capabilities →
   add **Push Notifications** and **Background Modes** (Remote notifications,
   Background fetch).
2. Create an APNs authentication key in the Apple Developer portal and upload
   it in Firebase Console → Project settings → Cloud Messaging.

## Testing

1. Sign in on a phone and allow notifications.
2. As a moderator/admin, save a notice on another device.
3. The phone shows a notification within a few seconds – test with the app in
   the foreground, in the background and closed.
4. Watch the worker live with `npx wrangler tail` (in `push-worker/`).

Test on a real iPhone; the iOS simulator's push support is limited.

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| App logs "PUSH_WORKER_URL is not set" | Set it in `.env` and rebuild |
| Worker returns **401** | Sign-in token invalid/expired – sign in again |
| Worker returns **403** | The user isn't a moderator/admin in Firestore |
| Worker returns **409** | The notice is inactive or expired |
| Worker returns **502** | FCM rejected the message – check `wrangler tail`, FCM API enabled, service-account secret correct |
| Nothing on Android | Notification permission off, or battery optimisation is blocking the app |
| Nothing on iOS | APNs key not uploaded, capabilities missing, or permission denied |
