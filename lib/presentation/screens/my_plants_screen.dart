import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/plants/plant_entity.dart';
import 'plant_detail_screen.dart';

class MyPlantsScreen extends StatelessWidget {
  const MyPlantsScreen({super.key});

  Future<String?> getPlantImageUrl(String userId, String plantId) async {
    try {
      final ref = FirebaseStorage.instance.ref().child('user_plant/$userId/$plantId.jpg');
      return await ref.getDownloadURL();
    } catch (e) {
      print("이미지를 가져오는 중 오류 발생: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text("로그인이 필요합니다.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("🌿 나의 식물들")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('plant')
            .where('user_id', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('에러가 발생했습니다.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final plants = snapshot.data!.docs
              .map((doc) => PlantEntity.fromFirestore(doc))
              .toList();

          if (plants.isEmpty) {
            return const Center(child: Text("등록된 식물이 없습니다."));
          }

          return Padding(
            padding: const EdgeInsets.all(12),
            child: GridView.builder(
              itemCount: plants.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2 / 3,
              ),
                itemBuilder: (context, index) {
                  final plant = plants[index];
                  return FutureBuilder<String?>(
                    future: getPlantImageUrl(userId, plant.id),
                    builder: (context, imageSnapshot) {
                      final imageUrl = imageSnapshot.data;

                      // 종 이름을 가져오기 위한 FutureBuilder
                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('plant_species')
                            .doc(plant.speciesId)
                            .get(),
                        builder: (context, speciesSnapshot) {
                          String speciesName = "알 수 없음";
                          if (speciesSnapshot.hasData && speciesSnapshot.data!.exists) {
                            speciesName = speciesSnapshot.data!['species_name'] ?? "알 수 없음";
                          }

                          return Stack(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PlantDetailScreen(plant: plant),
                                    ),
                                  );
                                },
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 4,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Container(
                                            height: 140,
                                            width: double.infinity,
                                            color: Colors.grey[200],
                                            child: imageUrl != null
                                                ? Image.network(imageUrl, fit: BoxFit.cover)
                                                : const Icon(Icons.eco, size: 64, color: Colors.green),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          plant.name,
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "종: $speciesName",
                                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              // 삭제 버튼
                              Positioned(
                                top: 4,
                                right: 4,
                                child: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.grey),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text("식물 삭제"),
                                        content: Text("정말 '${plant.name}' 식물을 삭제하시겠습니까?"),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, false),
                                            child: const Text("취소"),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, true),
                                            child: const Text("삭제"),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      try {
                                        // plant 문서 삭제
                                        await FirebaseFirestore.instance
                                            .collection('plant')
                                            .doc(plant.id)
                                            .delete();

                                        // 스토리지 파일 삭제 (없어도 무시)
                                        final ref = FirebaseStorage.instance
                                            .ref()
                                            .child('user_plant/$userId/${plant.id}.jpg');

                                        try {
                                          await ref.delete();
                                        } catch (e) {
                                          if (e is FirebaseException && e.code == 'object-not-found') {
                                            print("이미지 없음, 삭제 스킵");
                                          } else {
                                            rethrow; // 다른 에러는 그대로 던짐
                                          }
                                        }

                                        // users 문서에서 plant.id 제거
                                        await FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(userId)
                                            .update({
                                          'plants': FieldValue.arrayRemove([plant.id])
                                        });

                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text("'${plant.name}' 삭제 완료")),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text("삭제 실패: $e")),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                }
            ),
          );
        },
      ),
    );
  }
}