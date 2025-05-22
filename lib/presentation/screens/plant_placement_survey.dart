import 'package:flutter/material.dart';

import 'light_exposure_survey.dart';

class PlantPlacementSurveyPage extends StatefulWidget {
  final Map<String, dynamic> surveyData;

  const PlantPlacementSurveyPage({Key? key, required this.surveyData}) : super(key: key);

  @override
  State<PlantPlacementSurveyPage> createState() => _PlantPlacementSurveyPageState();
}

class _PlantPlacementSurveyPageState extends State<PlantPlacementSurveyPage> {
  Set<String> _selectedPlacements = Set<String>();

  final List<String> indoorLocations = ['거실', '침실', '부엌', '사무실', '욕실', '홀'];
  final List<String> outdoorLocations = ['뒷마당', '앞마당', '정원', '화단', '주차장', '채소정원단'];

  void _onPlacementSelected(String location) {
    setState(() {
      if (_selectedPlacements.contains(location)) {
        _selectedPlacements.remove(location);
      } else {
        _selectedPlacements.add(location);
      }
    });
  }

  void _onNextPressed() {
    widget.surveyData['plant_placement_locations'] = _selectedPlacements.toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LightExposureSurveyPage(surveyData: widget.surveyData),
      ),
    );
  }

  Widget _buildWrapButton(String label) {
    final isSelected = _selectedPlacements.contains(label);
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: ElevatedButton(
        onPressed: () => _onPlacementSelected(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.green : Colors.grey[300],
          foregroundColor: isSelected ? Colors.white : Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          minimumSize: Size(100, 40), // 버튼 크기 조정
        ),
        child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("설문 4/6")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '식물이 어디에 놓여져 있나요?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '여러 개의 옵션을 선택할 수 있습니다',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            SizedBox(height: 20),
            Text('실내 위치', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: indoorLocations.map(_buildWrapButton).toList(),
            ),
            SizedBox(height: 16),
            Text('실외 위치', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: outdoorLocations.map(_buildWrapButton).toList(),
            ),
            Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: _onNextPressed,
                child: Text('다음'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}