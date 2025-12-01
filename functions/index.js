// Cloud Functions for Firebase
// This file contains the Cloud Functions that send push notifications
// when new mosque notifications are created or updated

const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
admin.initializeApp();

/**
 * Cloud Function triggered when a new notification is created
 * Sends push notification to all subscribed users
 */
exports.sendNotificationOnCreate = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snap, context) => {
    try {
      const notification = snap.data();
      const notificationId = context.params.notificationId;

      // Only send push notification if the notification is active
      if (!notification.active) {
        console.log('Notification is not active, skipping push notification');
        return null;
      }

      // Check if notification is expired
      const expiresAt = notification.expiresAt?.toDate();
      if (expiresAt && expiresAt < new Date()) {
        console.log('Notification is expired, skipping push notification');
        return null;
      }

      // Prepare notification payload
      const payload = {
        notification: {
          title: notification.title || 'New Mosque Notification',
          body: notification.message || '',
        },
        data: {
          notificationId: notificationId,
          type: notification.type || 'announcement',
          priority: notification.priority || 'regular',
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
      };

      // Determine notification priority for Android
      let androidPriority = 'default';
      if (notification.priority === 'high') {
        androidPriority = 'high';
      } else if (notification.priority === 'low') {
        androidPriority = 'low';
      }

      // Add Android-specific config
      payload.android = {
        priority: androidPriority,
        notification: {
          channelId: notification.priority === 'high'
            ? 'high_importance_channel'
            : notification.priority === 'low'
            ? 'low_importance_channel'
            : 'regular_channel',
        },
      };

      // Add iOS-specific config
      payload.apns = {
        payload: {
          aps: {
            sound: notification.priority !== 'low' ? 'default' : undefined,
            badge: 1,
          },
        },
      };

      // Send to topic (all users subscribed to mosque_notifications)
      const topic = 'mosque_notifications';
      const response = await admin.messaging().sendToTopic(topic, payload);

      console.log('Successfully sent push notification:', response);
      return response;

    } catch (error) {
      console.error('Error sending push notification:', error);
      return null;
    }
  });

/**
 * Cloud Function triggered when a notification is updated
 * Sends push notification if the notification becomes active
 */
exports.sendNotificationOnUpdate = functions.firestore
  .document('notifications/{notificationId}')
  .onUpdate(async (change, context) => {
    try {
      const before = change.before.data();
      const after = change.after.data();
      const notificationId = context.params.notificationId;

      // Only send push notification if:
      // 1. The notification was just activated (inactive -> active)
      // 2. The notification is active and not expired
      const wasInactive = !before.active;
      const isNowActive = after.active;
      const justActivated = wasInactive && isNowActive;

      if (!justActivated) {
        console.log('Notification was not just activated, skipping push notification');
        return null;
      }

      // Check if notification is expired
      const expiresAt = after.expiresAt?.toDate();
      if (expiresAt && expiresAt < new Date()) {
        console.log('Notification is expired, skipping push notification');
        return null;
      }

      // Prepare notification payload
      const payload = {
        notification: {
          title: after.title || 'Updated Mosque Notification',
          body: after.message || '',
        },
        data: {
          notificationId: notificationId,
          type: after.type || 'announcement',
          priority: after.priority || 'regular',
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
      };

      // Determine notification priority for Android
      let androidPriority = 'default';
      if (after.priority === 'high') {
        androidPriority = 'high';
      } else if (after.priority === 'low') {
        androidPriority = 'low';
      }

      // Add Android-specific config
      payload.android = {
        priority: androidPriority,
        notification: {
          channelId: after.priority === 'high'
            ? 'high_importance_channel'
            : after.priority === 'low'
            ? 'low_importance_channel'
            : 'regular_channel',
        },
      };

      // Add iOS-specific config
      payload.apns = {
        payload: {
          aps: {
            sound: after.priority !== 'low' ? 'default' : undefined,
            badge: 1,
          },
        },
      };

      // Send to topic (all users subscribed to mosque_notifications)
      const topic = 'mosque_notifications';
      const response = await admin.messaging().sendToTopic(topic, payload);

      console.log('Successfully sent push notification:', response);
      return response;

    } catch (error) {
      console.error('Error sending push notification:', error);
      return null;
    }
  });

/**
 * Optional: Send targeted push notification to specific user
 * Can be called via HTTP trigger
 */
exports.sendTargetedNotification = functions.https.onCall(async (data, context) => {
  try {
    // Verify that the request is from an authenticated admin
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated to send notifications'
      );
    }

    // Get the calling user's role from Firestore
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(context.auth.token.email)
      .get();

    const userData = userDoc.data();
    const userRole = userData?.role || 'user';

    // Only allow admins and moderators to send targeted notifications
    if (userRole !== 'admin' && userRole !== 'moderator') {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Only admins and moderators can send targeted notifications'
      );
    }

    const { userId, title, message, type, priority } = data;

    if (!userId || !message) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'userId and message are required'
      );
    }

    // Get the target user's FCM token
    const targetUserDoc = await admin.firestore()
      .collection('users')
      .doc(userId)
      .get();

    const fcmToken = targetUserDoc.data()?.fcmToken;

    if (!fcmToken) {
      throw new functions.https.HttpsError(
        'not-found',
        'User does not have an FCM token'
      );
    }

    // Prepare notification payload
    const payload = {
      notification: {
        title: title || 'Mosque Notification',
        body: message,
      },
      data: {
        type: type || 'announcement',
        priority: priority || 'regular',
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      token: fcmToken,
    };

    // Send notification
    const response = await admin.messaging().send(payload);

    console.log('Successfully sent targeted notification:', response);
    return { success: true, messageId: response };

  } catch (error) {
    console.error('Error sending targeted notification:', error);
    throw error;
  }
});

/**
 * Cloud Function to delete a user (both Auth and Firestore)
 * Only callable by authenticated admin users
 */
exports.deleteUser = functions.https.onCall(async (data, context) => {
  try {
    // Verify authenticated
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated'
      );
    }

    // Get calling user's role
    const callingUserDoc = await admin.firestore()
      .collection('users')
      .doc(context.auth.uid)
      .get();

    if (callingUserDoc.data()?.role !== 'admin') {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Only admins can delete users'
      );
    }

    const { uid, email } = data;

    if (!uid || !email) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'uid and email required'
      );
    }

    // Prevent self-deletion
    if (context.auth.uid === uid) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Cannot delete your own account'
      );
    }

    // Check last admin
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(uid)
      .get();

    if (userDoc.data()?.role === 'admin') {
      const adminCount = await admin.firestore()
        .collection('users')
        .where('role', '==', 'admin')
        .get();

      if (adminCount.size <= 1) {
        throw new functions.https.HttpsError(
          'failed-precondition',
          'Cannot delete the last admin'
        );
      }
    }

    // Delete from Auth
    try {
      await admin.auth().deleteUser(uid);
      console.log(`Deleted Auth user: ${uid}`);
    } catch (authError) {
      console.error('Auth delete error:', authError);
      // Continue to Firestore deletion
    }

    // Delete from Firestore
    await admin.firestore()
      .collection('users')
      .doc(uid)
      .delete();

    console.log(`Deleted Firestore user: ${uid}`);

    return { success: true, message: `User ${email} deleted` };
  } catch (error) {
    console.error('Delete user error:', error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError(
      'internal',
      `Failed to delete: ${error.message}`
    );
  }
});
