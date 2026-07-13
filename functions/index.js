const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

initializeApp();

/**
 * Sends FCM push to the recipient when a notification doc is created.
 * Path: users/{userId}/notifications/{notificationId}
 */
exports.deliverUserNotification = onDocumentCreated(
  'users/{userId}/notifications/{notificationId}',
  async (event) => {
    const userId = event.params.userId;
    const data = event.data?.data();
    if (!data) return null;

    const db = getFirestore();
    const userSnap = await db.collection('users').doc(userId).get();
    const token = userSnap.data()?.fcmToken;
    if (!token) return null;

    const title = data.title || 'Civic Citizen';
    const body = data.body || '';

    const payload = {
      token,
      notification: { title, body },
      data: {
        type: String(data.type || ''),
        title,
        body,
        contractId: String(data.contractId || ''),
        postId: String(data.postId || ''),
        targetUserId: String(data.targetUserId || ''),
        routeName: String(data.routeName || ''),
      },
      android: {
        priority: 'high',
        notification: { channelId: 'civic_citizen_alerts' },
      },
      apns: {
        payload: { aps: { sound: 'default' } },
      },
    };

    try {
      await getMessaging().send(payload);
    } catch (err) {
      console.error('FCM send failed', userId, err);
    }
    return null;
  },
);
