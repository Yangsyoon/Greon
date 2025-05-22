import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PlantInfoPage extends StatelessWidget {
  final String plantId = '2pd5b6owV4ehz1bzMhCe'; // 하드코딩 ID -> 이후에 수정 필요

  Future<Map<String, dynamic>> fetchPlantData() async {
    final plantDoc =
    await FirebaseFirestore.instance.collection('plant').doc(plantId).get();
    final envQuery = await FirebaseFirestore.instance
        .collection('plant_environment')
        .where('plant_id', isEqualTo: plantId)
        .get();

    Map<String, dynamic> plantData = plantDoc.data() ?? {};
    Map<String, dynamic> envData = envQuery.docs.isNotEmpty
        ? envQuery.docs.first.data()
        : {};

    return {
      'plant': plantData,
      'environment': envData,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('식물 정보')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchPlantData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('데이터를 불러올 수 없습니다.'));
          }

          final plant = snapshot.data!['plant'] as Map<String, dynamic>;
          final env = snapshot.data!['environment'] as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 식물 이름 (중앙 정렬)
                Center(
                  child: Text(
                    plant['name'] ?? '이름 없음',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 식물 기본 정보 (왼쪽 정렬, 작게)
                Text(
                  '마지막 물 준 날짜: ${plant['last_watered_date'] ?? '정보 없음'}',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  '분갈이 주기: ${plant['repotting_cycle'] ?? '정보 없음'}',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  '영양제 주기: ${plant['nutrient_frequency'] ?? '정보 없음'}',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  '일조: ${plant['sunlight_level'] ?? '정보 없음'}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),

                // 환경 정보
                Text(
                  '창문과의 거리: ${env['distance_from_window'] ?? '정보 없음'}',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  '빛을 받는 정도: ${env['light_setting'] ?? '정보 없음'}',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  '위치: ${env['placement'] ?? '정보 없음'}',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  '사용자 관심도: ${env['user_interest_level'] ?? '정보 없음'}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
