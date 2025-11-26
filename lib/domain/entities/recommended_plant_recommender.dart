import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

// --- A. 식물 데이터 모델 ---
class RecommendedPlant { // 클래스명 변경됨
  final String name;
  final String imageUrl;
  final String mood;
  final int light;
  final int heightMin;
  final int heightMax;
  final int widthMin;
  final int widthMax;
  double score = 0.0; // 추천 점수 (정렬에 사용)

  RecommendedPlant({ // 생성자명 변경됨
    required this.name,
    required this.imageUrl,
    required this.mood,
    required this.light,
    required this.heightMin,
    required this.heightMax,
    required this.widthMin,
    required this.widthMax,
  });

  factory RecommendedPlant.fromFirestore(Map<String, dynamic> data) { // 팩토리명 변경됨
    return RecommendedPlant(
      name: data['name'] ?? '이름 없음',
      imageUrl: data['imageUrl'] ?? '',
      mood: data['mood'] ?? 'basic',
      light: (data['light'] as num?)?.toInt() ?? 2,
      heightMin: (data['height_min'] as num?)?.toInt() ?? 0,
      heightMax: (data['height_max'] as num?)?.toInt() ?? 1000,
      widthMin: (data['width_min'] as num?)?.toInt() ?? 0,
      widthMax: (data['width_max'] as num?)?.toInt() ?? 1000,
    );
  }
}

// --- B. 측정 결과 데이터 모델 (변화 없음) ---
class MeasurementResult {
  final double measuredWidthCm;
  final double measuredHeightCm;
  final Map<String, double> moodScores; // 예: {"vintage": 0.5, "modern": 0.3, ...}
  final int lightLevel; // 측정된 광도 레벨 (예: 1, 2, 3)

  MeasurementResult({
    required this.measuredWidthCm,
    required this.measuredHeightCm,
    required this.moodScores,
    required this.lightLevel,
  });
}

// --- C. 식물 추천 알고리즘 함수 ---

Future<List<RecommendedPlant>> recommendPlants({ // 반환 타입 변경됨
  required MeasurementResult result,
}) async {
  final firestore = FirebaseFirestore.instance;
  final snapshot = await firestore.collection('plants').get();

  // 1. 모든 식물 데이터를 RecommendedPlant 모델로 변환
  List<RecommendedPlant> allPlants = snapshot.docs.map((doc) => RecommendedPlant.fromFirestore(doc.data())).toList(); // 모델명 변경됨

  // 2. 무드 스코어를 내림차순으로 정렬하여 추천 순위를 정합니다.
  final sortedMoods = result.moodScores.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  List<RecommendedPlant> finalRecommendations = []; // 리스트 타입 변경됨

  // 3. 무드 순위에 따라 최대 2단계까지 반복
  for (int moodRank = 0; moodRank < min(2, sortedMoods.length); moodRank++) {
    String currentMood = sortedMoods[moodRank].key;

    if (finalRecommendations.length >= 3) break;

    // 4. 공간 및 무드 필터링
    List<RecommendedPlant> moodFiltered = allPlants.where((plant) { // 리스트 타입 변경됨
      // 4-1. 공간 필터링: height_min 또는 width_min 보다 작으면 제외
      bool failsSpaceCheck = (result.measuredHeightCm < plant.heightMin) ||
          (result.measuredWidthCm < plant.widthMin);

      // 4-2. 무드 필터링
      bool passesMoodCheck = plant.mood == currentMood &&
          !finalRecommendations.any((p) => p.name == plant.name);

      return !failsSpaceCheck && passesMoodCheck;
    }).toList();

    // 5. 광도 점수 부여
    for (var plant in moodFiltered) {
      int lightDifference = (result.lightLevel - plant.light).abs();
      plant.score = 5.0 - lightDifference;
    }

    // 6. 점수 기준으로 정렬
    moodFiltered.sort((a, b) => b.score.compareTo(a.score));

    // 7. 최종 추천 리스트에 추가
    int needed = 3 - finalRecommendations.length;
    finalRecommendations.addAll(moodFiltered.sublist(0, min(needed, moodFiltered.length)));
  }

  return finalRecommendations;
}