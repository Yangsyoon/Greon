import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:greon/presentation/screens/user_info_input_page.dart';

class WindowDistanceSurveyPage extends StatefulWidget {
  final Map<String, dynamic> surveyData;

  const WindowDistanceSurveyPage({Key? key, required this.surveyData}) : super(key: key);

  @override
  State<WindowDistanceSurveyPage> createState() => _WindowDistanceSurveyPageState();
}

class _WindowDistanceSurveyPageState extends State<WindowDistanceSurveyPage> {
  double _distanceFromWindow = 0.0; // 초기 거리 설정 (0 cm)

  void _onNextPressed() {
    // surveyData에 'distance_from_window' 추가
    widget.surveyData['distance_from_window'] = _distanceFromWindow;

    final data = {
      'env_id': 'e${DateTime.now().millisecondsSinceEpoch}',
      'user_interest_level': widget.surveyData['user_interest_level'],
      'location': widget.surveyData['location'],
      'placement': widget.surveyData['placement'],
      'light_setting': widget.surveyData['light_setting'],
      'distance_from_window': _distanceFromWindow,
      'plant_id': widget.surveyData['plant_id'],
      'direction': widget.surveyData['direction'],
    };

    print('Firestore 저장할 데이터:');
    data.forEach((key, value) {
      print('$key: $value');
    });

    // Firebase에 데이터 추가
    FirebaseFirestore.instance.collection('plant_environment').add(data).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('설문이 완료되었습니다.')),
      );

      // 다음 페이지로 이동
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserInfoInputPage(),
        ),
      );
    }).catchError((error) {
      print('🔥 Firestore 저장 실패: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("설문 7/7")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '창문으로부터의 거리는?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              '물 주기 정도는 식물이 창문으로부터 얼마나 떨어져 있는지에 따라 다릅니다. 슬라이더를 사용해서 거리를 지정해 주세요',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    enabled: false,
                    decoration: InputDecoration(
                      labelText: '거리',
                      suffixText: 'cm',
                      border: OutlineInputBorder(),
                    ),
                    controller: TextEditingController(text: _distanceFromWindow.toStringAsFixed(1)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            Slider(
              value: _distanceFromWindow,
              min: 0,
              max: 100,
              divisions: 100,
              label: _distanceFromWindow.toStringAsFixed(1),
              onChanged: (double value) {
                setState(() {
                  _distanceFromWindow = value;
                });
              },
            ),
            Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: _onNextPressed,
                child: Text('설문 종료'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}