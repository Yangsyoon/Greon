import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'dart:math';

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

  const ARMeasurementScreen({
    Key? key,
    required this.styleResult,
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
  void dispose() {
    arCoreController.dispose();
    super.dispose();
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

    // 1. 안정적인 평면 hit를 담을 수 있는 nullable 변수를 선언합니다.
    ArCoreHitTestResult? planeHit;

    // 2. for 반복문으로 모든 hit를 순회합니다.
    for (final hit in hits) {
      final vector.Vector4 rotation = hit.pose.rotation;
      final double magnitudeXZ = sqrt(pow(rotation.x, 2) + pow(rotation.z, 2));

      // 3. 안정적인 평면을 찾으면 변수에 할당하고 반복을 중단합니다.
      if (magnitudeXZ < 0.1) {
        planeHit = hit;
        break;
      }
    }

    // 4. 안정적인 평면(planeHit)을 찾았다면 그것을 사용하고,
    //    못 찾았다면 기존처럼 리스트의 첫 번째 hit를 사용합니다.
    final ArCoreHitTestResult hit = planeHit ?? hits.first;

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
  void _showResultDialog() {
    // 측정값이 없으면 다이얼로그를 보여주지 않음
    if (_measuredWidth == null || _measuredHeight == null) return;

    // 미터(m) 단위를 센티미터(cm)로 변환
    final widthInCm = _measuredWidth! * 100;
    final heightInCm = _measuredHeight! * 100;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('최종 분석 결과'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("분석된 스타일: ${widget.styleResult}"),
            const SizedBox(height: 16),
            const Text('측정된 공간 크기:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('너비: ${widthInCm.toStringAsFixed(1)} cm'),
            Text('높이: ${heightInCm.toStringAsFixed(1)} cm'),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('확인'),
            onPressed: () => Navigator.of(dialogContext).pop(),
          )
        ],
      ),
    );
  }
}