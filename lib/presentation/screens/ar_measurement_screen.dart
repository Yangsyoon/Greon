import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'dart:math';

import '../../domain/entities/recommended_plant_recommender.dart';

// 측정이 진행되는 단계를 관리하기 위한 열거형(enum)
enum MeasurementState {
  initial,          // 초기 상태
  widthStarted,     // 너비 측정 시작 (첫 번째 점)
  widthDone,        // 너비 측정 완료, 높이 측정 대기
  heightStarted,    // 높이 측정 시작 (세 번째 점)
  measurementDone,  // 모든 측정 완료
}

class ARMeasurementScreen extends StatefulWidget {
  final String styleResult;
  final int initialLightLevel;
  const ARMeasurementScreen({
    Key? key,
    required this.styleResult,
    required this.initialLightLevel,
  }) : super(key: key);

  @override
  State<ARMeasurementScreen> createState() => _ARMeasurementScreenState();
}

class _ARMeasurementScreenState extends State<ARMeasurementScreen> {
  late ArCoreController arCoreController;
  final List<vector.Vector3> _tappedPoints = [];

  // 상태 및 측정값 변수 추가
  MeasurementState _currentState = MeasurementState.initial;
  double? _measuredWidth;
  double? _measuredHeight;

  String _instructionText = "바닥을 인식시킨 후, 너비 측정 시작점을 탭하세요.";

  @override
  void initState() {
    super.initState();
    // AR 시작 시 안전 경고 표시
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showSafetyDialog();
    });
  }

  @override
  void dispose() {
    arCoreController.dispose();
    super.dispose();
  }
  void _showSafetyDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ AR 안전 주의사항'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• AR 사용 시 주변 환경에 항상 주의하세요.'),
            Text('• 걷거나 이동 중에는 화면에만 집중하지 마세요.'),
            Text('• 어린이는 보호자 감독하에만 사용해야 합니다.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AR 공간 측정'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetMeasurement,
          )
        ],
      ),
      body: Stack(
        children: [
          ArCoreView(
            onArCoreViewCreated: _onArCoreViewCreated,
            enablePlaneRenderer: true,
            enableTapRecognizer: true,
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: const EdgeInsets.all(20.0),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _instructionText,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onArCoreViewCreated(ArCoreController controller) {
    arCoreController = controller;
    arCoreController.onPlaneTap = _onPlaneTap;
  }

  // 👇 핵심 로직: 상태에 따라 탭 이벤트를 다르게 처리
  void _onPlaneTap(List<ArCoreHitTestResult> hits) {
    if (hits.isEmpty) return;
    final hit = hits.first;
    final point = vector.Vector3(
      hit.pose.translation[0],
      hit.pose.translation[1],
      hit.pose.translation[2],
    );

    // 모든 측정 단계에서 노란 구를 추가
    _addSphere(hit);

    setState(() {
      switch (_currentState) {
        case MeasurementState.initial:
          _tappedPoints.add(point);
          _currentState = MeasurementState.widthStarted;
          _instructionText = "너비 측정 끝점을 탭하세요.";
          break;

        case MeasurementState.widthStarted:
          _tappedPoints.add(point);
          _measuredWidth = _tappedPoints[0].distanceTo(_tappedPoints[1]);
          _tappedPoints.clear(); // 너비 측정이 끝났으므로 포인트 초기화
          _currentState = MeasurementState.widthDone;
          _instructionText = "높이 측정 시작점을 탭하세요. (바닥)";
          break;

        case MeasurementState.widthDone:
          _tappedPoints.add(point);
          _currentState = MeasurementState.heightStarted;
          _instructionText = "높이 측정 끝점을 탭하세요. (천장 또는 벽)";
          break;

        case MeasurementState.heightStarted:
          _tappedPoints.add(point);
          // 높이는 y축 좌표의 차이로 계산합니다.
          _measuredHeight = (_tappedPoints[0].y - _tappedPoints[1].y).abs();
          _currentState = MeasurementState.measurementDone;
          _instructionText = "측정 완료! (결과를 확인하거나 초기화 버튼으로 재시작)";
          _showResultDialog();
          break;

        case MeasurementState.measurementDone:
        // 모든 측정이 끝나면 더 이상 탭에 반응하지 않음
          break;
      }
    });
  }

  void _addSphere(ArCoreHitTestResult hit) {
    final material = ArCoreMaterial(color: Colors.yellow, metallic: 1.0);
    final sphere = ArCoreSphere(materials: [material], radius: 0.015);
    final node = ArCoreNode(
      shape: sphere,
      position: hit.pose.translation,
      name: "measurement_node", // 모든 노드를 한번에 지우기 위해 같은 이름 부여
    );
    arCoreController.addArCoreNode(node);
  }

  // 👇 초기화 함수 업데이트
  void _resetMeasurement() {
    arCoreController.removeNode(nodeName: "measurement_node");
    setState(() {
      _tappedPoints.clear();
      _measuredWidth = null;
      _measuredHeight = null;
      _currentState = MeasurementState.initial;
      _instructionText = "바닥을 인식시킨 후, 너비 측정 시작점을 탭하세요.";
    });
  }

  // 👇 결과 다이얼로그 업데이트
  void _showResultDialog() async {
    // 측정값이 없으면 다이얼로그를 보여주지 않음
    if (_measuredWidth == null || _measuredHeight == null) return;

    final widthInCm = _measuredWidth! * 100;
    final heightInCm = _measuredHeight! * 100;

    // --- [측정 결과 설정 및 추천 로직에 전달할 데이터] ---
    // ⚠️ actualLightLevel과 mockMoodScores는 실제 앱의 분석 로직에 맞게 구현해야 합니다.
    final int actualLightLevel = widget.initialLightLevel;
    final primaryMood = widget.styleResult; // AR 화면 진입 시 받은 주 무드

    // 무드 스코어 (주 무드 외에는 임시로 값 설정)
    final mockMoodScores = {
      primaryMood: 0.6,
      'modern': 0.3,
      'basic': 0.1,
    };

    final result = MeasurementResult(
      measuredWidthCm: widthInCm,
      measuredHeightCm: heightInCm,
      moodScores: mockMoodScores,
      lightLevel: actualLightLevel,
    );

    // 추천 알고리즘 실행 (RecommendedPlant 타입 사용)
    List<RecommendedPlant> recommendedPlants = await recommendPlants(result: result);


    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('✨ 공간 분석 및 식물 추천'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 측정된 공간 크기 표시 (사용자에게 노출) ---
            const Text('측정된 공간 크기:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('너비: ${widthInCm.toStringAsFixed(1)} cm'),
            Text('높이: ${heightInCm.toStringAsFixed(1)} cm'),
            const SizedBox(height: 16),

            // --- 추천 식물 목록 표시 ---
            const Text('🌱 당신에게 맞는 식물:', style: TextStyle(fontWeight: FontWeight.bold)),

            if (recommendedPlants.isEmpty)
              const Text('현재 조건에 맞는 식물을 찾을 수 없습니다.', style: TextStyle(color: Colors.red))
            else
            // 추천된 식물들을 순서대로 표시 (RecommendedPlant 객체 사용)
              ...recommendedPlants.map((recommendedPlant) =>
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    // 사진 URL이 있으면 네트워크 이미지 표시
                    leading: recommendedPlant.imageUrl.isNotEmpty
                        ? Image.network(recommendedPlant.imageUrl, width: 50, height: 50, fit: BoxFit.cover)
                        : const Icon(Icons.nature, size: 50),
                    title: Text(recommendedPlant.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    // 사용자에게 무드 정보는 간결하게, 광도는 레벨로 표시
                    subtitle: Text('무드: ${recommendedPlant.mood}, 광도: ${recommendedPlant.light} 레벨'),
                  )
              ).toList(),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('닫기'),
            onPressed: () => Navigator.of(dialogContext).pop(),
          )
        ],
      ),
    );
  }
}
