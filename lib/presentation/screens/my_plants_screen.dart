import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:greon/presentation/screens/settings_page.dart';
import '../../configs/app_typography.dart';
import '../../configs/space.dart';
import '../../core/constant/assets.dart';
import '../../domain/entities/plants/plant_entity.dart';
import 'plant_detail_screen.dart';

class MyPlantsScreen extends StatelessWidget {
  const MyPlantsScreen({super.key});

  Future<String?> getPlantImageUrl(String userId, String plantId) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('user_plant/$userId/$plantId.jpg');
      return await ref.getDownloadURL();
    } catch (e) {
      print("이미지를 가져오는 중 오류 발생: $e");
      return null;
    }
  }

  Future<DocumentSnapshot> getPlantSpeciesData(String speciesId) async {
    return FirebaseFirestore.instance
        .collection('plant_species')
        .doc(speciesId)
        .get();
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

          return SafeArea(
            child: Padding(
              padding: Space.h1!,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset(AppAssets.greonAppBar, height: 40),
                      IconButton(
                        icon: const Icon(Icons.settings, size: 28),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SettingsPage()),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      "내 식물",
                      style: AppText.h2b?.copyWith(color: Colors.black),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: plants.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 1,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 2.2,
                      ),
                      itemBuilder: (context, index) {
                        final plant = plants[index];

                        return FutureBuilder<Map<String, dynamic>>(
                          future: Future.wait([
                            getPlantImageUrl(userId, plant.id),
                            getPlantSpeciesData(plant.speciesId),
                          ]).then((results) {
                            final imageUrl = results[0] as String?;
                            final speciesSnapshot = results[1] as DocumentSnapshot;
                            String speciesName = "알 수 없음";
                            if (speciesSnapshot.exists) {
                              speciesName = speciesSnapshot['species_name'] ?? "알 수 없음";
                            }
                            return {
                              'imageUrl': imageUrl,
                              'speciesName': speciesName,
                            };
                          }),
                          builder: (context, snapshot) {
                            final imageUrl = snapshot.data?['imageUrl'];
                            final speciesName = snapshot.data?['speciesName'] ?? "알 수 없음";

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
                                    color: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 4,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: SizedBox(
                                              height: 120,
                                              width: 120,
                                              child: imageUrl != null
                                                  ? Image.network(imageUrl, fit: BoxFit.cover)
                                                  : const Icon(Icons.eco, size: 64, color: Colors.green),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  plant.name,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  "종: $speciesName",
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.grey),
                                    onPressed: () async {
                                      // ... (기존 삭제 로직은 동일)
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
                                          await FirebaseFirestore.instance
                                              .collection('plant')
                                              .doc(plant.id)
                                              .delete();
                                          final ref = FirebaseStorage.instance.ref().child('user_plant/$userId/${plant.id}.jpg');
                                          try {
                                            await ref.delete();
                                          } catch (e) {
                                            if (e is FirebaseException && e.code == 'object-not-found') {
                                              print("이미지 없음, 삭제 스킵");
                                            } else {
                                              rethrow;
                                            }
                                          }
                                          await FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(userId)
                                              .update({'plants': FieldValue.arrayRemove([plant.id])});
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
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
