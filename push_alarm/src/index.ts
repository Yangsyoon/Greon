import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions/v1';


admin.initializeApp();

export const scheduledNotificationSender = functions
  .region('asia-northeast3')
  .pubsub.schedule('0 9 * * *') // 매일 9시 0분에 실행
  .timeZone('Asia/Seoul')
  .onRun(async (context) => {
    const now = new Date();
    const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const todayEnd = new Date(todayStart);
    todayEnd.setDate(todayEnd.getDate() + 1);

    const todayStartTimestamp = admin.firestore.Timestamp.fromDate(todayStart);
    const todayEndTimestamp = admin.firestore.Timestamp.fromDate(todayEnd);

    const snapshot = await admin.firestore()
      .collection('notification_requests')
      .where('nextDate', '>=', todayStartTimestamp)
      .where('nextDate', '<', todayEndTimestamp)
      .get();

    const promises: Promise<any>[] = [];

    snapshot.forEach((doc) => {
      const data = doc.data();
      const fcmToken = data.fcm_token;
      const title = data.title || '물 주기 알림';
      const body = data.body || '식물에 물 줄 시간입니다.';

      const message = {
        token: fcmToken,
        notification: { title, body },
        data: { plant_id: data.plant_id || '' },
      };

      const sendPromise = admin.messaging().send(message)
        .then(() => {
          console.log(`FCM 전송 성공: ${doc.id}`);

          // 다음 해 같은 날짜로 업데이트
          const nextDate = new Date(data.nextDate.toDate());
          nextDate.setFullYear(nextDate.getFullYear() + 1);

          return doc.ref.update({
            nextDate: admin.firestore.Timestamp.fromDate(nextDate),
            lastSent: admin.firestore.Timestamp.now()
          });
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
