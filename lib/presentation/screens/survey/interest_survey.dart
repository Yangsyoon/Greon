import 'package:flutter/material.dart';

import 'location_survey.dart';

class InterestSurveyPage extends StatefulWidget {
  final Map<String, dynamic> surveyData;

  const InterestSurveyPage({Key? key, required this.surveyData})
      : super(key: key);

  @override
  _InterestSurveyPageState createState() => _InterestSurveyPageState();
}

class _InterestSurveyPageState extends State<InterestSurveyPage> {
  String? _selectedInterestLevel;

  final List<Map<String, String>> _interestOptions = [
    {"level": "낮음", "desc": "식물들이 살아있게 하고 싶습니다"},
    {"level": "중간", "desc": "식물 돌보기를 좋아하고 식물과 함께 시간 보내는게 괜찮습니다"},
    {"level": "높음", "desc": "식물을 위해 삽니다. 깨어있는 모든 시간을 사용하고 싶습니다"},
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: WillPopScope(
        onWillPop: () async {
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text("설문 종료"),
              content: Text("정말 설문을 스킵하시겠습니까?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false), // 아니오
                  child: Text("취소"),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true), // 예
                  child: Text("확인"),
                ),
              ],
            ),
          );
          return shouldExit ?? false; // true면 pop 허용, false면 차단
        },
        child: Scaffold(
          appBar: AppBar(title: Text("설문 1/7")),
          body: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "식물 돌보기에 얼마나 관심이 많으세요?",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 24),
                ..._interestOptions.map((option) {
                  return RadioListTile<String>(
                    title: Text(
                      option["level"]!,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(option["desc"]!),
                    value: option["level"]!,
                    groupValue: _selectedInterestLevel,
                    onChanged: (value) {
                      setState(() => _selectedInterestLevel = value);
                    },
                  );
                }).toList(),
                Spacer(),
                Center(
                  child: ElevatedButton(
                    onPressed: _selectedInterestLevel == null
                        ? null
                        : () {
                            final updatedSurvey =
                                Map<String, dynamic>.from(widget.surveyData);
                            updatedSurvey['interest_level'] =
                                _selectedInterestLevel;

                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LocationSurveyPage(
                                    surveyData: updatedSurvey),
                              ),
                            );
                          },
                    child: Text("다음"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
