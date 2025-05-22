import 'package:flutter/material.dart';
import '../../domain/entities/plants/plant_entity.dart';

class PlantDetailScreen extends StatelessWidget {
  final PlantEntity plant;

  const PlantDetailScreen({super.key, required this.plant});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(plant.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              plant.name,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildInfoCard(
              icon: Icons.category,
              title: "식물 종 ID",
              value: plant.speciesId,
            ),
            _buildInfoCard(
              icon: Icons.water_drop,
              title: "최근 물 준 날짜",
              value: plant.lastWateredDate,
            ),
            _buildInfoCard(
              icon: Icons.vaccines,
              title: "영양제 주기",
              value: "${plant.nutrientFrequency}일",
            ),
            _buildInfoCard(
              icon: Icons.vaccines,
              title: "분갈이 주기",
              value: "${plant.repottingCycle}일",
            ),
            _buildInfoCard(
              icon: Icons.wb_sunny,
              title: "햇빛 필요 정도",
              value: plant.sunlightLevel,
            ),
            _buildInfoCard(
              icon: Icons.invert_colors,
              title: "물 주는 주기",
              value: "${plant.wateringCycle}일",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: ListTile(
        leading: Icon(icon, color: Colors.green),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value),
      ),
    );
  }
}
