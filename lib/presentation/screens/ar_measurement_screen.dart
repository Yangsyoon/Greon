import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

class ARMeasurementScreen extends StatefulWidget {
  // 1. 분석 결과를 전달받을 변수 추가
  final String styleResult;

  const ARMeasurementScreen({
    Key? key,
    required this.styleResult, // 2. 생성자에 추가
  }) : super(key: key);

  @override
  State<ARMeasurementScreen> createState() => _ARMeasurementScreenState();
}


class _ARMeasurementScreenState extends State<ARMeasurementScreen> {
  late ArCoreController arCoreController;

  final List<vector.Vector3> _tappedPoints = [];
  double? _distance;
  String _instructionText = "바닥이나 벽을 인식시킨 후, 측정할 시작점을 탭하세요.";

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
            //enablePlaneDetection: true,제공x
            enableTapRecognizer: true,  // 탭 감지를 위한 파라미터
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

  void _onPlaneTap(List<ArCoreHitTestResult> hits) {
    if (hits.isEmpty) return;

    final hit = hits.first;
    final point = vector.Vector3(
      hit.pose.translation[0],
      hit.pose.translation[1],
      hit.pose.translation[2],
    );

    setState(() {
      if (_tappedPoints.length == 1) {
        _tappedPoints.add(point);
        _addSphere(hit); // 두 번째 점 추가
        _calculateDistance();
      } else {
        _resetMeasurement(); // 초기화
        _tappedPoints.add(point);
        _addSphere(hit); // 첫 번째 점 추가
        _instructionText = "측정할 끝점을 탭하세요.";
      }
    });
  }

  void _addSphere(ArCoreHitTestResult hit) {
    final material = ArCoreMaterial(color: Colors.yellow, metallic: 1.0);
    final sphere = ArCoreSphere(materials: [material], radius: 0.01);
    final node = ArCoreNode(
      shape: sphere,
      position: hit.pose.translation,
      // 한 번에 모든 노드를 지우기 위해 이름을 지정할 수 있습니다.
      // name: "point_${_tappedPoints.length}",
    );
    arCoreController.addArCoreNode(node);
  }

  void _calculateDistance() {
    if (_tappedPoints.length < 2) return;

    final distanceInMeters = _tappedPoints[0].distanceTo(_tappedPoints[1]);
    _distance = distanceInMeters;

    final distanceInCm = (distanceInMeters * 100).toStringAsFixed(1);
    _instructionText = "측정된 거리: $distanceInCm cm\n(다시 측정하려면 시작점을 탭하세요)";
  }

  void _resetMeasurement() {
    // arcore_flutter_plugin의 removeNode는 이름으로만 삭제 가능하므로,
    // 컨트롤러를 재 생성하는 것이 모든 노드를 지우는 가장 확실한 방법일 수 있으나
    // 현재 API는 모든 노드 삭제 기능이 명확하지 않아 UI만 초기화합니다.
    // 더 확실한 초기화를 위해선 화면을 나갔다 다시 들어오는 것이 좋습니다.
    arCoreController.removeNode(nodeName: 'all_nodes'); // 만약 노드에 이름을 붙였다면 사용
    setState(() {
      _tappedPoints.clear();
      _distance = null;
      _instructionText = "바닥이나 벽을 인식시킨 후, 측정할 시작점을 탭하세요.";
    });
  }

  void _showResultDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('최종 분석 결과'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 3. 전달받은 스타일 결과를 여기서 사용
            Text("스타일: ${widget.styleResult}"),
            const SizedBox(height: 16),
            const Text('측정된 공간 크기:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('너비: ...'), // 측정된 너비 표시
            Text('높이: ...'), // 측정된 높이 표시
          ],
        ),
        actions: [ /* ... */ ],
      ),
    );
  }
}