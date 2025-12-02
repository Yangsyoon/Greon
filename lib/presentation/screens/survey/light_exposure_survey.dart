import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:greon/presentation/screens/survey/home_direction_survey.dart';

class LightExposureSurveyPage extends StatefulWidget {
  final Map<String, dynamic> surveyData;

  const LightExposureSurveyPage({Key? key, required this.surveyData})
      : super(key: key);

  @override
  State<LightExposureSurveyPage> createState() =>
      _LightExposureSurveyPageState();
}

class _LightExposureSurveyPageState extends State<LightExposureSurveyPage> {
  String? _selectedLightLevel;
  late StreamSubscription? _lightSubscription;

  @override
  void initState() {
    super.initState();
  }

  /// 수동 선택
  void _onLightLevelSelected(String level) {
    setState(() {
      _selectedLightLevel = level;
    });

    _lightSubscription?.cancel();
    _lightSubscription = null;
  }

  /// 다음 페이지 이동
  void _onNextPressed() {
    if (_selectedLightLevel != null) {
      widget.surveyData['light_exposure'] = _selectedLightLevel;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeDirectionSurveyPage(
            surveyData: widget.surveyData,
          ),
        ),
      );
    }
  }

  /// 🔥 오류 없이 동작하는 "더미 자동 측정" 함수
  void _measureLightLevel() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('자동으로 빛의 세기를 측정하였습니다.')),
    );

    // 실제 센서가 없으므로 임의 값(0~2000 lux) 샘플 생성
    final luxValue = Random().nextInt(2000);

    String level;
    if (luxValue >= 1000) {
      level = '전체 일광';
    } else if (luxValue >= 500) {
      level = '일부 일광, 일부 그늘';
    } else if (luxValue >= 200) {
      level = '그늘';
    } else {
      level = '어두움';
    }

    setState(() {
      _selectedLightLevel = level;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: WillPopScope(
        onWillPop: () async {
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("설문 종료"),
              content: const Text("정말 설문을 스킵하시겠습니까?"),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("취소")),
                TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text("확인")),
              ],
            ),
          );
          return shouldExit ?? false;
        },
        child: Scaffold(
          appBar: AppBar(title: const Text("설문 5/7")),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '이 위치에서는 빛을 얼마나 받나요?',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  '해당 위치의 조명 설정을 선택하세요.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 24),

                /// 자동 측정 버튼
                ElevatedButton(
                  onPressed: _measureLightLevel,
                  child: const Text('광도계를 써서 측정하세요'),
                ),
                const SizedBox(height: 24),

                /// 선택 버튼들
                _buildLightLevelButton(
                    '전체 일광', '적어도 8시간 동안의 직접, 걸러지지 않은 햇빛'),
                _buildLightLevelButton(
                    '일부 일광, 일부 그늘', '하루 종일 밝은 빛과 어느 정도의 직접 햇빛'),
                _buildLightLevelButton(
                    '그늘', '직접 햇빛이 거의 없거나 전혀 없는 장소'),
                _buildLightLevelButton(
                    '어두움', '햇빛이 없거나 창문이 없는 방'),

                const Spacer(),

                Center(
                  child: ElevatedButton(
                    onPressed: _onNextPressed,
                    child: const Text('다음'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
          minimumSize: const Size(double.infinity, 50),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(description, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
