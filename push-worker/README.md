# Push worker (Cloudflare Worker)

Sends push notifications for masjid notices. It holds the Firebase
service-account key as an encrypted Cloudflare secret, so the key is **never
bundled into the app** (anything in the app — including `.env` — can be read
by users).

How it works: when a moderator/admin saves a notice, the app calls
`POST <worker>/notify` with the user's Firebase ID token and the notice id.
The worker:

1. verifies the ID token (Firebase Auth, your project `FIREBASE_PROJECT_ID`);
2. checks `users/{uid}` in Firestore has role `admin` or `moderator`;
3. reads the notice from `mosque/data/notifications/{id}` (must be active and
   not expired) — the text comes from Firestore, not from the caller;
4. sends it to the FCM topic `mosque_notifications`.

Runs on Cloudflare's free plan (100,000 requests/day).

## First-time setup

Requires Node.js 18+.

```sh
cd push-worker
npm install
npx wrangler login          # opens a browser to authorise your Cloudflare account
```

In `wrangler.toml`, set `FIREBASE_PROJECT_ID` to your Firebase project ID
(and optionally rename the worker with `name`).

### 1. Create a new service-account key

Firebase Console → ⚙ Project settings → **Service accounts** →
**Generate new private key**. This downloads a JSON file. Treat it like a
password: don't email it, don't commit it, delete the download once step 2 is
done.

### 2. Store it in the worker and deploy

```sh
npx wrangler secret put SERVICE_ACCOUNT_JSON   # paste the WHOLE JSON file, then Enter
npx wrangler deploy
```

`wrangler deploy` prints the worker URL, e.g.
`https://masjid-push.<your-account>.workers.dev`.

### 3. Point the app at it

Set `PUSH_WORKER_URL=<that URL>` in the app's `.env` (and in the `.env` CI
uses, see `docs/ci-cd.md`). It's a public URL — not a secret.

### 4. Delete keys you don't use

Google Cloud Console → IAM & Admin → **Service accounts** →
`firebase-adminsdk-…@<your-project>.iam.gserviceaccount.com` → **Keys**.
Delete every key except the one the worker uses (check the key IDs).

## Changing the code

```sh
npm test               # unit tests for the message format
npx wrangler dev       # run locally on http://localhost:8787
npx wrangler deploy    # publish
```

Allowed browser origins are in `wrangler.toml` (`ALLOWED_ORIGINS`). If
moderators send notices from the web app, add its
address (e.g. `http://192.168.1.20:8080`) there and `npx wrangler deploy`.
`http://localhost:*` is always allowed. The Android/iOS apps don't need this.

## Responses

| Status | Meaning |
|---|---|
| 200 | Push sent |
| 400 | Missing/invalid `notificationId` |
| 401 | Missing or invalid Firebase ID token |
| 403 | Signed-in user is not a moderator/admin |
| 404 | Notice doesn't exist |
| 409 | Notice is inactive or expired |
| 502 | FCM rejected the message (see `npx wrangler tail`) |
