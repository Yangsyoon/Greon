import 'package:flutter/material.dart';
import 'package:greon/presentation/screens/survey/window_distance_survey.dart';

class HomeDirectionSurveyPage extends StatefulWidget {
  final Map<String, dynamic> surveyData;

  const HomeDirectionSurveyPage({Key? key, required this.surveyData}) : super(key: key);

  @override
  State<HomeDirectionSurveyPage> createState() => _HomeDirectionSurveyPageState();
}

class _HomeDirectionSurveyPageState extends State<HomeDirectionSurveyPage> {
  String? _selectedDirection;

  void _onDirectionSelected(String direction) {
    setState(() {
      _selectedDirection = direction;
    });
  }

  void _onNextPressed() {
    if (_selectedDirection != null) {
      widget.surveyData['direction'] = _selectedDirection;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WindowDistanceSurveyPage(surveyData: widget.surveyData),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('방향을 선택해주세요.')),
      );
    }
  }

  Widget _buildDirectionButton(String label) {
    final isSelected = _selectedDirection == label;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ElevatedButton(
        onPressed: () => _onDirectionSelected(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.green : Colors.grey[300],
          foregroundColor: isSelected ? Colors.white : Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          minimumSize: Size(double.infinity, 45),
        ),
        child: Text(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("설문 6/7")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '창의 방향은 어디인가요?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              '창문이 바라보는 방향을 선택해주세요.',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            SizedBox(height: 24),
            _buildDirectionButton('동'),
            _buildDirectionButton('서'),
            _buildDirectionButton('남'),
            _buildDirectionButton('북'),
            _buildDirectionButton('남동'),
            _buildDirectionButton('북동'),
            _buildDirectionButton('남서'),
            _buildDirectionButton('북서'),
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
