// push-worker/src/index.js
//
// Sends a push notification for a masjid notice. Holds the Firebase
// service-account key server-side so it never ships inside the app.
//
// POST /notify
//   Authorization: Bearer <Firebase ID token of the signed-in user>
//   Body: { "notificationId": "<id in mosque/data/notifications>" }
//
// Only admins/moderators may send, and only for an existing, active,
// unexpired notice — the text comes from Firestore, not from the caller.
import { createRemoteJWKSet, importPKCS8, jwtVerify, SignJWT } from 'jose';

const TOPIC = 'mosque_notifications';
const SCOPES = [
  'https://www.googleapis.com/auth/datastore',
  'https://www.googleapis.com/auth/firebase.messaging',
].join(' ');

// Public keys Firebase Auth uses to sign ID tokens.
const FIREBASE_JWKS = createRemoteJWKSet(
  new URL(
    'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com',
  ),
);

// Google access token, reused across requests until shortly before expiry.
let cachedAccessToken = null; // { token, expiresAt }

export default {
  async fetch(request, env) {
    const cors = corsHeaders(request.headers.get('Origin'), env);

    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: cors });
    }
    const url = new URL(request.url);
    if (request.method !== 'POST' || url.pathname !== '/notify') {
      return json({ error: 'Not found' }, 404, cors);
    }

    try {
      const projectId = env.FIREBASE_PROJECT_ID;

      // 1. Who is calling?
      const idToken = (request.headers.get('Authorization') || '')
        .replace(/^Bearer\s+/i, '')
        .trim();
      if (!idToken) return json({ error: 'Missing token' }, 401, cors);

      let uid;
      try {
        const { payload } = await jwtVerify(idToken, FIREBASE_JWKS, {
          issuer: `https://securetoken.google.com/${projectId}`,
          audience: projectId,
        });
        uid = payload.sub;
      } catch {
        return json({ error: 'Invalid token' }, 401, cors);
      }

      // 2. Which notice?
      const body = await request.json().catch(() => ({}));
      const notificationId =
        typeof body.notificationId === 'string' ? body.notificationId : '';
      if (!/^[A-Za-z0-9_-]{1,128}$/.test(notificationId)) {
        return json({ error: 'Invalid notificationId' }, 400, cors);
      }

      const accessToken = await getAccessToken(env);

      // 3. Is the caller allowed?
      const user = await getDocument(projectId, accessToken, `users/${uid}`);
      const role = user?.fields?.role?.stringValue;
      const deleted = user?.fields?.deleted?.booleanValue === true;
      if (!user || deleted || (role !== 'admin' && role !== 'moderator')) {
        return json({ error: 'Forbidden' }, 403, cors);
      }

      // 4. Is the notice live?
      const notice = await getDocument(
        projectId,
        accessToken,
        `mosque/data/notifications/${notificationId}`,
      );
      if (!notice) return json({ error: 'Notice not found' }, 404, cors);

      const fields = notice.fields || {};
      const active = fields.active?.booleanValue === true;
      const expiresAt = Date.parse(fields.expiresAt?.timestampValue || '') || 0;
      if (!active || expiresAt <= Date.now()) {
        return json({ error: 'Notice is not active' }, 409, cors);
      }

      // 5. Send it.
      const response = await fetch(
        `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${accessToken}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(buildMessage(notificationId, fields)),
        },
      );
      if (!response.ok) {
        const detail = (await response.text()).slice(0, 500);
        console.error('FCM error', response.status, detail);
        return json({ error: 'FCM error', status: response.status }, 502, cors);
      }

      return json({ ok: true }, 200, cors);
    } catch (e) {
      console.error('Unexpected error', e);
      return json({ error: 'Server error' }, 500, cors);
    }
  },
};

/** The FCM v1 message — mirrors what the app used to send itself. */
export function buildMessage(notificationId, fields) {
  const title = fields.title?.stringValue?.trim() || 'New Mosque Notification';
  const message = fields.message?.stringValue?.trim() || '';
  const type = fields.type?.stringValue || 'announcement';
  const priority = fields.priority?.stringValue || 'regular';
  const isLow = priority === 'low';

  const channelId =
    priority === 'high'
      ? 'high_importance_channel'
      : isLow
        ? 'low_importance_channel'
        : 'regular_channel';

  return {
    message: {
      topic: TOPIC,
      notification: {
        title,
        body: message || '📷 New image notice — open the app to view',
      },
      data: {
        notificationId,
        type,
        priority,
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      android: {
        priority: isLow ? 'NORMAL' : 'HIGH',
        notification: {
          channel_id: channelId,
          ...(isLow ? {} : { sound: 'default' }),
        },
      },
      apns: {
        payload: {
          aps: { badge: 1, ...(isLow ? {} : { sound: 'default' }) },
        },
      },
    },
  };
}

/** Google OAuth access token for the service account (JWT-bearer flow). */
async function getAccessToken(env) {
  const now = Math.floor(Date.now() / 1000);
  if (cachedAccessToken && cachedAccessToken.expiresAt - 60 > now) {
    return cachedAccessToken.token;
  }

  const sa = JSON.parse(env.SERVICE_ACCOUNT_JSON);
  const key = await importPKCS8(sa.private_key, 'RS256');
  const assertion = await new SignJWT({ scope: SCOPES })
    .setProtectedHeader({ alg: 'RS256', kid: sa.private_key_id, typ: 'JWT' })
    .setIssuer(sa.client_email)
    .setAudience(sa.token_uri || 'https://oauth2.googleapis.com/token')
    .setIssuedAt(now)
    .setExpirationTime(now + 3600)
    .sign(key);

  const response = await fetch(
    sa.token_uri || 'https://oauth2.googleapis.com/token',
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        assertion,
      }),
    },
  );
  if (!response.ok) {
    throw new Error(`Token exchange failed: ${response.status}`);
  }
  const data = await response.json();
  cachedAccessToken = {
    token: data.access_token,
    expiresAt: now + (data.expires_in || 3600),
  };
  return cachedAccessToken.token;
}

/** Reads a Firestore document via REST; null if it doesn't exist. */
async function getDocument(projectId, accessToken, path) {
  const response = await fetch(
    `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/${path}`,
    { headers: { Authorization: `Bearer ${accessToken}` } },
  );
  if (response.status === 404) return null;
  if (!response.ok) {
    throw new Error(`Firestore read failed (${path}): ${response.status}`);
  }
  return response.json();
}

function corsHeaders(origin, env) {
  const allowed = (env.ALLOWED_ORIGINS || '')
    .split(',')
    .map((o) => o.trim())
    .filter(Boolean);
  const isLocalhost = /^http:\/\/localhost(:\d+)?$/.test(origin || '');
  const headers = {
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Authorization, Content-Type',
    'Access-Control-Max-Age': '86400',
    Vary: 'Origin',
  };
  if (origin && (allowed.includes(origin) || isLocalhost)) {
    headers['Access-Control-Allow-Origin'] = origin;
  }
  return headers;
}

function json(body, status, headers) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...headers, 'Content-Type': 'application/json' },
  });
}
