import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions/v1';


admin.initializeApp();

export const scheduledNotificationSender = functions
  .region('asia-northeast3')
  .pubsub.schedule('0 8 * * *') // 매일 8시 0분에 실행
  .timeZone('Asia/Seoul')
  .onRun(async () => {
    const now = admin.firestore.Timestamp.now();

    const snapshot = await admin.firestore()
      .collection('notification_requests')
      .where('scheduled_time', '<=', now)
      .where('sent', '==', false)
      .get();

    const promises: Promise<any>[] = [];

    snapshot.forEach((doc) => {
      const data = doc.data();
      if (!data.fcm_token) return;

      const message = {
        token: data.fcm_token,
        notification: {
          title: data.title || '물 주기 알림',
          body: data.body || '식물에 물 줄 시간입니다.',
        },
        data: {
          plant_id: data.plant_id || '',
        },
      };

      const sendPromise = admin.messaging().send(message)
        .then(() => {
          console.log(`FCM 전송 성공: ${doc.id}`);
          // 알림 성공 시 문서 즉시 삭제
          return doc.ref.delete();
        })
        .catch((err) => {
          console.error(`FCM 전송 실패 (${doc.id}):`, err);
          if (err.code === 'messaging/invalid-registration-token') {
            console.log(`잘못된 토큰 문서 삭제: ${doc.id}`);
            return doc.ref.delete();
          }
          return doc.ref.update({ error: err.message });
        });

      promises.push(sendPromise);
    });

    await Promise.all(promises);
    return null;
  });
