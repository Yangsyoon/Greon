import 'package:cloud_firestore/cloud_firestore.dart';

class PlantEntity {
  final String id;
  final String name;
  final String speciesId;
  final String userId;
  final String lastWateredDate;
  final int nutrientFrequency;
  final int repottingCycle;
  final String sunlightLevel;
  final int wateringCycle;

  PlantEntity({
    required this.id,
    required this.name,
    required this.speciesId,
    required this.userId,
    required this.lastWateredDate,
    required this.nutrientFrequency,
    required this.repottingCycle,
    required this.sunlightLevel,
    required this.wateringCycle,
  });

  factory PlantEntity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PlantEntity(
      id: doc.id,
      name: data['name'],
      speciesId: data['species_id'],
      userId: data['user_id'],
      lastWateredDate: data['last_watered_date'],
      nutrientFrequency: data['nutrient_frequency'],
      repottingCycle: data['repotting_cycle'],
      sunlightLevel: data['sunlight_level'],
      wateringCycle: data['watering_cycle'],
    );
  }
}
