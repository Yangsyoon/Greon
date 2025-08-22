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
          type: 'watering',
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


export const sendCommentNotification = functions
  .region('asia-northeast3')
  .firestore
  .document("posts/{postId}/comments/{commentId}")
  .onCreate(async (snap, context) => {
    const comment = snap.data();
    console.log('댓글 데이터:', comment);

    if (!comment?.targetUid) {
        console.log('targetUid 없음, 알림 안보냄');
        return;
    }

    // 알림 받을 유저
    const targetUserDoc = await admin.firestore().collection("users").doc(comment.targetUid).get();
    if (!targetUserDoc.exists) {
        console.log('유저 문서 없음:', comment.targetUid);
        return;
    }

    const fcmToken = targetUserDoc.data()?.fcm_token; // Firestore에 저장된 토큰
    if (!fcmToken) {
        console.log("fcm token 없어");
        return;
    }

    // 댓글 작성자 닉네임 가져오기
    const writerDoc = await admin.firestore().collection("users").doc(comment.uid).get();
    const writerNickname = writerDoc.exists ? writerDoc.data()?.nickname : "누군가";

    try {
      await admin.messaging().send({
        token: fcmToken,
        notification: {
          title: `${writerNickname}님이 댓글을 남겼습니다`,
          body: comment.content,
        },
        data: {
          postId: context.params.postId,
          commentId: context.params.commentId,
          type: "comment",
        },
      });
      console.log(`댓글 알림 전송 성공: ${comment.targetUid}`);
    } catch (err) {
      console.error(`댓글 알림 전송 실패:`, err);
    }
  });



// 3) 답글 추가 시 - 댓글 작성자에게 알림
export const sendReplyNotification = functions
  .region('asia-northeast3')
  .firestore
  .document("posts/{postId}/comments/{commentId}/replies/{replyId}")
  .onCreate(async (snap, context) => {
    const reply = snap.data();
    console.log('답글 데이터:', reply);

    if (!reply?.targetUid) {
        console.log('targetUid 없음, 알림 안보냄');
        return;
    }

    // 알림 받을 댓글 작성자
    const targetUserDoc = await admin.firestore().collection("users").doc(reply.targetUid).get();
    if (!targetUserDoc.exists) {
        console.log('유저 문서 없음:', reply.targetUid);
        return;
    }

    const fcmToken = targetUserDoc.data()?.fcm_token; // Firestore에 저장된 토큰
    if (!fcmToken) {
        console.log("fcm token 없어");
        return;
    }
    console.log('fcmToken 확인:', fcmToken);

    // 답글 작성자 닉네임 가져오기
    const writerDoc = await admin.firestore().collection("users").doc(reply.uid).get();
    const writerNickname = writerDoc.exists ? writerDoc.data()?.nickname : "누군가";

    try {
      await admin.messaging().send({
        token: fcmToken,
        notification: {
          title: `${writerNickname}님이 내 댓글에 답글을 남겼습니다`,
          body: reply.content,
        },
        data: {
          postId: context.params.postId,
          commentId: context.params.commentId,
          replyId: context.params.replyId,
          type: "reply",
        },
      });
      console.log(`답글 알림 전송 성공: ${reply.targetUid}`);
    } catch (err) {
      console.error(`답글 알림 전송 실패:`, err);
    }
  });
