# Firebase Cloud Functions - Prayer Time Notifications

This directory contains Firebase Cloud Functions that automatically send push notifications to all users when prayer waqt times are reached.

## Features

- **Automatic Daily Scheduling**: Runs every day at midnight to fetch prayer times for the day
- **Waqt-Time Notifications**: Sends notifications at the exact moment each prayer time begins
- **Zero User Action Required**: Works even if users never open the app
- **Accurate Prayer Times**: Fetches from Aladhan API using mosque's exact coordinates

## Setup Instructions

### 1. Create Mosque Settings Document

The cloud functions need a `mosque/settings` document in Firestore with your mosque's location and calculation preferences.

**Option A: Using Firebase Console (Easiest)**

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to Firestore Database
4. Click "Start collection"
5. Collection ID: `mosque`
6. Document ID: `settings`
7. Add these fields:
   - `latitude` (number): Your mosque's latitude (e.g., `40.7128`)
   - `longitude` (number): Your mosque's longitude (e.g., `-74.0060`)
   - `method` (number): Calculation method (default: `3` for Muslim World League)
   - `school` (number): School of jurisprudence (default: `1` for Hanafi)

**To find your mosque's coordinates:**
1. Go to [Google Maps](https://www.google.com/maps)
2. Search for your mosque name (e.g., "Darut Tauhid Masjid")
3. Right-click on the location marker
4. Select "What's here?"
5. Copy the latitude and longitude values

**Option B: Using the Initialization Script**

If you have Firebase Admin SDK credentials:

```bash
cd functions
node init-mosque-settings.js
```

Follow the prompts to enter your mosque's coordinates and preferences.

### 2. Deploy Firestore Rules

The security rules have been updated to allow the cloud functions to read `mosque/settings`:

```bash
firebase deploy --only firestore:rules
```

### 3. Deploy Cloud Functions

Deploy all the cloud functions to Firebase:

```bash
firebase deploy --only functions
```

This will deploy:
- `scheduleDailyPrayerNotifications` - Runs daily at midnight
- `sendFajrNotification` - Sends Fajr notification at 5:30 AM
- `sendDhuhrNotification` - Sends Dhuhr notification at 12:30 PM
- `sendAsrNotification` - Sends Asr notification at 4:00 PM
- `sendMaghribNotification` - Sends Maghrib notification at 7:00 PM
- `sendIshaNotification` - Sends Isha notification at 8:30 PM
- `sendPrayerTimeNotification` - HTTP callable function for manual testing

**Note:** The fixed times (5:30 AM, 12:30 PM, etc.) are approximate and should be adjusted to match your mosque's typical prayer times. Edit `functions/index.js` to change these schedules.

### 4. Update Timezone

The cloud functions are currently configured for `America/New_York` timezone. Update this in `functions/index.js` if your mosque is in a different timezone:

```javascript
// Find these lines and change the timezone
exports.scheduleDailyPrayerNotifications = functions.pubsub
  .schedule('0 0 * * *')
  .timeZone('America/New_York')  // <-- Change this
  .onRun(async (context) => {
```

Valid timezone values: [List of tz database time zones](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)

### 5. Test the Functions

**Test via Firebase Console:**

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select Functions → `scheduleDailyPrayerNotifications`
3. Click "Test function"
4. Check the logs to verify prayer times were fetched
5. Verify that Cloud Scheduler jobs were created

**Test via Command Line:**

```bash
# Test the daily scheduler
firebase functions:shell
scheduleDailyPrayerNotifications()

# View logs
firebase functions:log
```

**Manual Test Notification:**

You can call the HTTP function to test sending a notification:

```bash
firebase functions:call sendPrayerTimeNotification --data='{"prayerName":"Fajr"}'
```

## How It Works

### Daily Scheduling Flow

1. **Midnight (12:00 AM)**: `scheduleDailyPrayerNotifications` runs
   - Fetches mosque location from Firestore (`mosque/settings`)
   - Calls Aladhan API to get today's prayer times
   - Logs the prayer times for the day

2. **Fixed Times**: Individual prayer functions run at approximate times
   - `sendFajrNotification` runs at 5:30 AM
   - `sendDhuhrNotification` runs at 12:30 PM
   - etc.

3. **Each Prayer Time**: Notification sent to all users
   - Uses FCM topic `mosque_notifications`
   - Title: "{Prayer Name} Prayer Time"
   - Body: "{Prayer name} prayer time has begun"
   - High priority for reliable delivery

### Fallback: Local Notifications

The app also schedules local notifications using `flutter_local_notifications`:
- Scheduled when app is opened and prayer times are fetched
- Uses exact alarm scheduling (Android 12+)
- Provides redundancy if cloud functions fail

## Calculation Methods

The `method` field in `mosque/settings` determines which calculation method is used:

- `1` - University of Islamic Sciences, Karachi
- `2` - Islamic Society of North America (ISNA)
- `3` - Muslim World League (Default, used by most mosques worldwide)
- `4` - Umm Al-Qura University, Makkah
- `5` - Egyptian General Authority of Survey

## School of Jurisprudence

The `school` field determines Asr calculation:

- `0` - Shafi (Default, Asr when shadow = object length)
- `1` - Hanafi (Asr when shadow = 2x object length)

## Monitoring

**View Function Logs:**

```bash
firebase functions:log --only scheduleDailyPrayerNotifications
```

**View Scheduled Jobs:**

```bash
gcloud scheduler jobs list
```

**Check Function Execution:**

Go to Firebase Console → Functions → Click on any function → View logs

## Costs

Firebase Cloud Functions pricing:
- First 2 million invocations per month: **Free**
- Each notification function runs once daily = 5 functions/day
- Daily scheduler runs once daily = 1 function/day
- Total: ~6 invocations/day × 30 days = ~180 invocations/month
- **Cost: $0** (well within free tier)

Firebase Cloud Messaging:
- Unlimited notifications: **Free**

## Troubleshooting

**Notifications not received:**
1. Check that `mosque/settings` document exists and has valid coordinates
2. Verify users are subscribed to `mosque_notifications` topic
3. Check function logs for errors: `firebase functions:log`
4. Ensure app has FCM token and topic subscription working

**Prayer times incorrect:**
1. Verify latitude/longitude in `mosque/settings` are correct
2. Check that `method` and `school` values match your mosque's preferences
3. Test Aladhan API directly: `https://api.aladhan.com/v1/timings?latitude=40.7128&longitude=-74.0060&method=3`

**Functions not running:**
1. Verify functions are deployed: `firebase functions:list`
2. Check Cloud Scheduler jobs: `gcloud scheduler jobs list`
3. Ensure Firebase project has billing enabled (required for scheduled functions)

## Development

**Local Testing:**

```bash
# Start emulators
firebase emulators:start --only functions,firestore

# In another terminal
cd functions
npm run shell
```

**Update Dependencies:**

```bash
cd functions
npm install
```

**Lint Code:**

```bash
npm run lint
```

## Security

- Firestore rules allow anyone to read `mosque/settings` (needed for app and functions)
- Only admins can write to `mosque/settings`
- Cloud functions run with admin privileges
- All notification data is validated before sending

## Support

For issues or questions:
1. Check function logs: `firebase functions:log`
2. Review [Firebase documentation](https://firebase.google.com/docs/functions)
3. Open an issue in the project repository
