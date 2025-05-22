import 'package:flutter/material.dart';
import 'package:greon/presentation/screens/plant_placement_survey.dart';

class PlantLocationSurveyPage extends StatefulWidget {
  final Map<String, dynamic> surveyData;

  const PlantLocationSurveyPage({Key? key, required this.surveyData}) : super(key: key);

  @override
  State<PlantLocationSurveyPage> createState() => _PlantLocationSurveyPageState();
}

class _PlantLocationSurveyPageState extends State<PlantLocationSurveyPage> {
  Set<String> _selectedLocations = Set<String>();

  void _onLocationSelected(String location) {
    setState(() {
      if (_selectedLocations.contains(location)) {
        _selectedLocations.remove(location);
      } else {
        _selectedLocations.add(location);
      }
    });
  }

  void _onNextPressed() {
    // 선택한 위치 정보를 surveyData에 추가
    widget.surveyData['plant_locations'] = _selectedLocations.toList();

    // 다음 설문 페이지로 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlantPlacementSurveyPage(surveyData: widget.surveyData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('설문 3/6')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '식물이 어디에 있나요?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              '여러 개의 옵션을 선택할 수 있습니다',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            SizedBox(height: 24),
            _buildLocationButton('실내 관엽 식물'),
            _buildLocationButton('실외 화분'),
            _buildLocationButton('정원, 땅속 식물'),
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

  Widget _buildLocationButton(String location) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        onPressed: () => _onLocationSelected(location),
        style: ElevatedButton.styleFrom(
          backgroundColor: _selectedLocations.contains(location)
              ? Colors.green
              : Colors.lightGreenAccent,
        ),
        child: Text(location),
      ),
    );
  }
}
