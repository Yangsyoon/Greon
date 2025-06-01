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

  PlantEntity copyWith({
    String? id,
    String? name,
    String? speciesId,
    String? userId,
    String? lastWateredDate,
    int? nutrientFrequency,
    int? repottingCycle,
    int? wateringCycle,
    String? sunlightLevel,
  }) {
    return PlantEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      speciesId: speciesId ?? this.speciesId,
      userId: userId ?? this.userId,
      lastWateredDate: lastWateredDate ?? this.lastWateredDate,
      nutrientFrequency: nutrientFrequency ?? this.nutrientFrequency,
      repottingCycle: repottingCycle ?? this.repottingCycle,
      wateringCycle: wateringCycle ?? this.wateringCycle,
      sunlightLevel: sunlightLevel ?? this.sunlightLevel,
    );
  }
}
