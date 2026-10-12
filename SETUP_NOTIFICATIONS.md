# Setup Automatic Prayer Time Notifications

This guide will help you complete the setup for automatic waqt-time notifications that work even when the app is closed.

## What You've Done So Far ✓

- ✓ Created local notification scheduler (flutter_local_notifications)
- ✓ Added Android permissions for exact alarm scheduling
- ✓ Created Firebase Cloud Functions for server-side notifications
- ✓ Updated Firestore security rules
- ✓ Deployed Firestore rules to Firebase

## What's Left to Do

### Step 0: Upgrade to Firebase Blaze Plan (Required)

**⚠️ IMPORTANT:** Cloud Functions require the Firebase Blaze (pay-as-you-go) plan. However, **your cost will still be $0** because you'll be well within the free tier.

**To upgrade:**

1. Go to [Firebase Console → Billing](https://console.firebase.google.com/project/dticc-app/usage/details)
2. Click "Upgrade project" or "Modify plan"
3. Select the "Blaze (pay-as-you-go)" plan
4. Add a payment method (credit card required, but won't be charged)
5. Set a budget alert (optional, recommended: $5/month)

**Free tier includes:**
- Cloud Functions: 2 million invocations/month
- Cloud Messaging: Unlimited notifications
- Firestore: 50,000 reads/day, 20,000 writes/day

**Your expected usage:**
- Cloud Functions: ~180 invocations/month (0.009% of free tier)
- Cloud Messaging: ~150 notifications/month (free)
- Firestore: ~10 reads/day (0.02% of free tier)

**Monthly cost: $0** (far below free tier limits)

**Why it's required:**
- Cloud Build API (needed for deploying functions) requires Blaze plan
- Scheduled functions (cron jobs) require Blaze plan
- The Spark (free) plan doesn't support outbound network requests from functions

### Step 1: Create Mosque Settings Document in Firestore

The cloud functions need to know your mosque's location to fetch accurate prayer times. You need to create a document in Firestore with your mosque's coordinates.

**To create the document:**

1. Go to [Firebase Console](https://console.firebase.google.com/project/dticc-app/firestore)

2. Click "Start collection" (or if you already have collections, click the + icon)

3. **Collection ID:** `mosque`

4. Click "Next"

5. **Document ID:** `settings`

6. Add the following fields:

   | Field Name  | Type   | Value                                      |
   |------------|--------|---------------------------------------------|
   | `latitude` | number | Your mosque's latitude (e.g., `40.7128`)   |
   | `longitude`| number | Your mosque's longitude (e.g., `-74.0060`) |
   | `method`   | number | `3` (Muslim World League)                  |
   | `school`   | number | `1` (Hanafi) or `0` (Shafi)                |
   | `timezone` | string | `America/New_York` (or your timezone)      |

7. Click "Save"

**To find your mosque's coordinates:**

1. Go to [Google Maps](https://www.google.com/maps)
2. Search for "Darut Tauhid Masjid" (or your mosque's name)
3. Right-click on the mosque location marker
4. Select "What's here?"
5. Copy the latitude and longitude values that appear at the bottom

Example: `40.7128, -74.0060` means:
- Latitude: `40.7128`
- Longitude: `-74.0060`

**Calculation Methods:**
- `1` - University of Islamic Sciences, Karachi
- `2` - Islamic Society of North America (ISNA)
- `3` - Muslim World League (MWL) ← **Default, recommended**
- `4` - Umm Al-Qura University, Makkah
- `5` - Egyptian General Authority of Survey

**School of Jurisprudence:**
- `0` - Shafi (Asr when shadow = object length)
- `1` - Hanafi (Asr when shadow = 2x object length)

### Step 2: Deploy Cloud Functions

Once you've created the mosque/settings document, deploy the cloud functions:

```bash
npx firebase deploy --only functions
```

This will deploy 7 cloud functions:
- `scheduleDailyPrayerNotifications` - Runs at midnight to fetch prayer times
- `sendFajrNotification` - Sends Fajr notification (currently at 5:30 AM)
- `sendDhuhrNotification` - Sends Dhuhr notification (currently at 12:30 PM)
- `sendAsrNotification` - Sends Asr notification (currently at 4:00 PM)
- `sendMaghribNotification` - Sends Maghrib notification (currently at 7:00 PM)
- `sendIshaNotification` - Sends Isha notification (currently at 8:30 PM)
- `sendPrayerTimeNotification` - HTTP function for manual testing

**Note:** The fixed times (5:30 AM, etc.) are approximate. You should update these in `functions/index.js` to match your mosque's typical prayer times.

### Step 3: Update Timezone in Cloud Functions

The cloud functions are currently set to `America/New_York` timezone. If your mosque is in a different timezone, update the following files:

**File: `functions/index.js`**

Find these lines (appears multiple times):

```javascript
.timeZone('America/New_York')  // <-- Change this to your timezone
```

Replace `'America/New_York'` with your timezone. Examples:
- `'America/Los_Angeles'` - Pacific Time
- `'America/Chicago'` - Central Time
- `'America/Denver'` - Mountain Time
- `'America/Toronto'` - Eastern Canada
- `'Europe/London'` - UK
- [Full list of timezones](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)

### Step 4: Test the Functions

**Option A: Test via Firebase Console**

1. Go to [Firebase Console → Functions](https://console.firebase.google.com/project/dticc-app/functions)
2. Find `scheduleDailyPrayerNotifications`
3. Click the three dots (⋮) → "Test function"
4. Click "Run test"
5. Check the logs to verify it fetched prayer times successfully

**Option B: Test via Command Line**

```bash
npx firebase functions:shell

# In the shell:
scheduleDailyPrayerNotifications()

# View logs:
npx firebase functions:log --only scheduleDailyPrayerNotifications
```

**Option C: Test Manual Notification**

Send a test notification to verify FCM is working:

```bash
npx firebase functions:call sendPrayerTimeNotification --data '{"prayerName":"Fajr"}'
```

### Step 5: Verify Scheduled Jobs

After deploying, verify that Cloud Scheduler jobs were created:

1. Go to [Cloud Scheduler](https://console.cloud.google.com/cloudscheduler?project=dticc-app)
2. You should see 6 scheduled jobs:
   - `firebase-schedule-scheduleDailyPrayerNotifications-...` (runs at midnight)
   - `firebase-schedule-sendFajrNotification-...` (runs at 5:30 AM)
   - `firebase-schedule-sendDhuhrNotification-...` (runs at 12:30 PM)
   - etc.

### Step 6: Monitor Execution

**View Function Logs:**

```bash
npx firebase functions:log
```

**Check Specific Function:**

```bash
npx firebase functions:log --only sendFajrNotification
```

**View in Console:**

Go to [Functions → Logs](https://console.firebase.google.com/project/dticc-app/functions/logs)

## How the System Works

### Two-Tier Notification System

Your app now has **two independent notification systems** for maximum reliability:

#### Tier 1: Cloud Functions (Primary)
- Runs on Firebase servers, completely automatic
- Fetches prayer times daily at midnight
- Sends notifications at exact waqt times
- Works even if user never opens the app
- No battery drain on user's device

#### Tier 2: Local Notifications (Fallback)
- Scheduled by the app when opened
- Uses exact alarm scheduling on Android
- Provides redundancy if cloud functions fail
- Requires app to be opened at least once per day

### Daily Workflow

**Midnight (12:00 AM):**
1. `scheduleDailyPrayerNotifications` cloud function runs
2. Fetches mosque location from Firestore
3. Calls Aladhan API to get today's prayer times
4. Logs the prayer times

**At Each Prayer Time:**
1. Corresponding cloud function runs (e.g., `sendFajrNotification` at 5:30 AM)
2. Sends FCM notification to topic `mosque_notifications`
3. All subscribed users receive: "{Prayer Name} prayer time has begun"

**When User Opens App:**
1. App fetches current prayer times
2. Schedules local notifications for remaining prayers today
3. Provides fallback if cloud functions fail

## Troubleshooting

### Notifications Not Received

**Check 1: Mosque Settings**
- Verify `mosque/settings` document exists in Firestore
- Verify latitude and longitude are correct
- Test: `https://api.aladhan.com/v1/timings?latitude=YOUR_LAT&longitude=YOUR_LON&method=3`

**Check 2: Topic Subscription**
- Verify app subscribes to `mosque_notifications` topic
- Check in `lib/main.dart` for `FirebaseMessaging.instance.subscribeToTopic('mosque_notifications')`

**Check 3: Function Logs**
```bash
npx firebase functions:log --only sendFajrNotification
```
Look for errors or "Permission denied" messages

**Check 4: Billing**
- Scheduled functions require Firebase Blaze (pay-as-you-go) plan
- Check at [Firebase Console → Billing](https://console.firebase.google.com/project/dticc-app/settings/billing)

### Prayer Times Incorrect

**Fix 1: Update Coordinates**
- Go to Firestore → `mosque/settings`
- Verify latitude and longitude match your mosque's location
- Use Google Maps to get exact coordinates

**Fix 2: Change Calculation Method**
- Update `method` field in `mosque/settings`
- Try different values (1-5) to match your mosque's times
- Redeploy functions after changing

**Fix 3: Adjust School**
- Update `school` field in `mosque/settings`
- `0` = Shafi, `1` = Hanafi (affects Asr time)

### Functions Not Running

**Check 1: Deployment**
```bash
npx firebase functions:list
```
Should show all 7 functions

**Check 2: Billing**
- Scheduled functions require Blaze plan
- Free tier includes 2M invocations/month (you'll use ~180/month)

**Check 3: Cloud Scheduler**
```bash
gcloud scheduler jobs list
```
Should show 6 scheduled jobs

## Costs

- **Cloud Functions:** First 2M invocations/month FREE
  - Your usage: ~180 invocations/month
  - **Cost: $0**

- **Cloud Messaging:** Unlimited notifications FREE

- **Firestore:** First 50k reads/day FREE
  - Your usage: ~10 reads/day
  - **Cost: $0**

**Total monthly cost: $0** (well within free tier)

## Next Steps

After completing setup:

1. ✓ Create `mosque/settings` in Firestore
2. ✓ Deploy cloud functions
3. ✓ Update timezone if needed
4. ✓ Test the functions
5. ✓ Monitor for one day to verify notifications arrive
6. ✓ Adjust scheduled times if needed

## Support

For detailed information, see:
- `functions/README.md` - Complete cloud functions documentation
- [Firebase Functions Docs](https://firebase.google.com/docs/functions)
- [Aladhan API Docs](https://aladhan.com/prayer-times-api)

---

**Ready to deploy?** Run this command:

```bash
npx firebase deploy --only functions
```

Then test by running `scheduleDailyPrayerNotifications` in the Firebase Console!
