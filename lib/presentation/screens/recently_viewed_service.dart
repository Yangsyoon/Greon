import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> addRecentlyViewedProduct(String userId, String productId) async {
  final colRef = FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('recently_viewed');

  final docRef = colRef.doc(productId);

  // 1. 중복 방지 & 최신 시간 업데이트
  await docRef.set({
    'viewedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  // 2. 10개까지만 유지 (오래된 문서 삭제)
  final snapshot = await colRef.orderBy('viewedAt', descending: true).get();
  if (snapshot.docs.length > 10) {
    for (int i = 10; i < snapshot.docs.length; i++) {
      await snapshot.docs[i].reference.delete();
    }
  }
}
