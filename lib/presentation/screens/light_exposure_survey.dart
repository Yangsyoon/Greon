import 'dart:async';

import 'package:flutter/material.dart';
import 'package:greon/presentation/screens/window_distance_survey.dart';
import 'package:light/light.dart';

class LightExposureSurveyPage extends StatefulWidget {
  final Map<String, dynamic> surveyData;

  const LightExposureSurveyPage({Key? key, required this.surveyData}) : super(key: key);

  @override
  State<LightExposureSurveyPage> createState() => _LightExposureSurveyPageState();
}

class _LightExposureSurveyPageState extends State<LightExposureSurveyPage> {
  String? _selectedLightLevel;
  Light? _light;
  late StreamSubscription<int>? _lightSubscription;

  @override
  void initState() {
    super.initState();
    _light = Light();
  }

  // 가정: 스마트폰 센서로 측정할 수 있다면 해당 부분을 추가적으로 구현
  void _onLightLevelSelected(String level) {
    setState(() {
      _selectedLightLevel = level;
    });

    // 사용자가 수동 선택 시 측정 스트림 해제 (중복 측정 방지용)
    _lightSubscription?.cancel();
    _lightSubscription = null;
  }

  void _onNextPressed() {
    if (_selectedLightLevel != null) {
      widget.surveyData['light_exposure'] = _selectedLightLevel;
      // 다음 설문 페이지로 이동
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WindowDistanceSurveyPage(surveyData: widget.surveyData), // 다음 페이지로 연결
        ),
      );
    }
  }

  void _measureLightLevel() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('자동으로 빛의 세기를 측정 하였습니다.')),
    );

    try {
      _lightSubscription = _light!.lightSensorStream.listen((luxValue) {
        print("Lux value: $luxValue");

        String level;
        if (luxValue >= 10000) {
          level = '전체 일광';
        } else if (luxValue >= 1000) {
          level = '일부 일광, 일부 그늘';
        } else if (luxValue >= 100) {
          level = '그늘';
        } else {
          level = '어두움';
        }

        // 값 반영
        setState(() {
          _selectedLightLevel = level;
        });

        // 측정 한 번 후 구독 종료
        _lightSubscription?.cancel();
        _lightSubscription = null;
      });
    } catch (e) {
      print("Error measuring light: $e");
    }
  }

  @override
  void dispose() {
    _lightSubscription?.cancel();
    super.dispose();
  }

  Widget _buildLightLevelButton(String label, String description) {
    final isSelected = _selectedLightLevel == label;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ElevatedButton(
        onPressed: () => _onLightLevelSelected(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.green : Colors.grey[300],
          foregroundColor: isSelected ? Colors.white : Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          minimumSize: Size(double.infinity, 50),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              description,
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("설문 5/6")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '이 위치에서는 빛을 얼마나 받나요?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              '해당 위치의 조명 설정을 선택하세요.',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            SizedBox(height: 24),
            // 스마트폰 센서로 측정할 수 있는 경우 이 버튼을 사용
            ElevatedButton(
              onPressed: _measureLightLevel,
              child: Text('광도계를 써서 측정하세요'),
            ),
            SizedBox(height: 24),
            // 일광 선택 버튼들
            _buildLightLevelButton(
              '전체 일광',
              '적어도 8시간 동안의 직접, 걸러지지 않은 햇빛',
            ),
            _buildLightLevelButton(
              '일부 일광, 일부 그늘',
              '하루 종일 밝은 빛과 어느 정도의 직접 햇빛',
            ),
            _buildLightLevelButton(
              '그늘',
              '직접 햇빛이 거의 없거나 전혀 없는 장소',
            ),
            _buildLightLevelButton(
              '어두움',
              '햇빛이 없거나 창문이 없는 방',
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