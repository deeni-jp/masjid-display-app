// push-worker/test/build-message.test.js  (run: npm test)
import assert from 'node:assert/strict';
import { test } from 'node:test';

import { buildMessage } from '../src/index.js';

const str = (v) => ({ stringValue: v });

test('uses the notice title and description', () => {
  const { message } = buildMessage('abc', {
    title: str('Eid Prayer'),
    message: str('Eid prayer at 7:30 AM'),
    type: str('event'),
    priority: str('regular'),
  });

  assert.equal(message.topic, 'mosque_notifications');
  assert.deepEqual(message.notification, {
    title: 'Eid Prayer',
    body: 'Eid prayer at 7:30 AM',
  });
  assert.deepEqual(message.data, {
    notificationId: 'abc',
    type: 'event',
    priority: 'regular',
    click_action: 'FLUTTER_NOTIFICATION_CLICK',
  });
  assert.equal(message.android.priority, 'HIGH');
  assert.equal(message.android.notification.channel_id, 'regular_channel');
  assert.equal(message.android.notification.sound, 'default');
});

test('image-only notices get the fallback body; empty title gets a default', () => {
  const { message } = buildMessage('img', {
    title: str('  '),
    message: str(''),
    priority: str('high'),
  });

  assert.equal(message.notification.title, 'New Mosque Notification');
  assert.equal(
    message.notification.body,
    '📷 New image notice — open the app to view',
  );
  assert.equal(
    message.android.notification.channel_id,
    'high_importance_channel',
  );
});

test('low priority is quiet', () => {
  const { message } = buildMessage('low', {
    title: str('FYI'),
    message: str('Parking update'),
    priority: str('low'),
  });

  assert.equal(message.android.priority, 'NORMAL');
  assert.equal(message.android.notification.channel_id, 'low_importance_channel');
  assert.equal('sound' in message.android.notification, false);
  assert.equal('sound' in message.apns.payload.aps, false);
});
