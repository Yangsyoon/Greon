import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:greon/core/router/app_router.dart';
import 'package:greon/presentation/widgets/transparent_button.dart';

class AddressesScreen extends StatelessWidget {
  AddressesScreen({Key? key}) : super(key: key);

  final String userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    final addressesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('addresses');

    return Scaffold(
      appBar: AppBar(title: const Text('배송지 관리'),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.grey[700],
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pushNamed(AppRouter.addEditAddress);
            },
            child: const Text(
              '배송지 추가',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: addressesRef.snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(child: Text("등록된 주소가 없습니다."));
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;

                      final isDefault = data['isDefault'] == true;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDefault ? Colors.blue : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    data['recipient'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (isDefault)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: const BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.rectangle,
                                      borderRadius:
                                      BorderRadius.all(Radius.circular(12)),
                                    ),
                                    child: const Text(
                                      '기본 배송지',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(data['address'] ?? '', style: const TextStyle(fontSize: 16)),
                            Text(data['detail'] ?? '', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                            Text(data['phone'] ?? '', style: const TextStyle(fontSize: 14)),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                // 기본 배송지 설정 버튼
                                if (!isDefault)
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.blue,
                                      side: const BorderSide(
                                          color: Colors.blue, width: 1),
                                    ),
                                    onPressed: () async {
                                      // 다른 주소들은 false 처리
                                      final batch = FirebaseFirestore.instance
                                          .batch();
                                      for (var d in docs) {
                                        batch.update(d.reference, {
                                          'isDefault': d.id == doc.id,
                                        });
                                      }
                                      await batch.commit();
                                    },
                                    child: const Text('기본 배송지 설정'),
                                  ),
                                const SizedBox(width: 8),
                                // 삭제 버튼
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.black, // 글씨 색
                                    backgroundColor: Colors.white, // 배경 색
                                    side: const BorderSide(color: Colors.grey, width: 1), // 테두리
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                  onPressed: () async {
                                    await addressesRef.doc(doc.id).delete();
                                  },
                                  child: const Text('삭제'),
                                ),
                                const SizedBox(width: 8), // 버튼 간 간격
                                // 수정 버튼
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.black,
                                    backgroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.grey, width: 1),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pushNamed(
                                      AppRouter.addEditAddress,
                                      arguments: doc.id,
                                    );
                                  },
                                  child: const Text('수정'),
                                ),
                              ],
                            )
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
