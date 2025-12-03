import 'package:flutter/material.dart';
import 'ar_measurement_screen.dart';

class LightLevelScreen extends StatefulWidget {
  final String styleResult;

  const LightLevelScreen({super.key, required this.styleResult});

  @override
  State<LightLevelScreen> createState() => _LightLevelScreenState();
}

class _LightLevelScreenState extends State<LightLevelScreen> {
  int? _selectedLevel;

  void _onNextPressed() {
    if (_selectedLevel != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ARMeasurementScreen(
            styleResult: widget.styleResult,
            initialLightLevel: _selectedLevel!,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("밝기 레벨을 선택해주세요.")),
      );
    }
  }

  Widget _buildLevelButton(int level, String description) {
    final isSelected = _selectedLevel == level;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _selectedLevel = level;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.green : Colors.grey[200],
          foregroundColor: isSelected ? Colors.white : Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: isSelected ? 2 : 0,
          minimumSize: const Size(double.infinity, 52),
        ),

        // ★ 버튼 안의 내용을 왼쪽 정렬로 감싸기
        child: Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // 텍스트끼리도 왼쪽 정렬
            children: [
              Text(
                "레벨 $level",
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text("밝기 선택 (2/3 단계)")),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '이 위치에서는 빛을 얼마나 받나요?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              Text(
                '1은 햇빛이 거의 없는 공간, 5는 햇빛이 매우 많은 공간입니다.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),

              const SizedBox(height: 20),

              // 버튼들 (간격 줄인 버전)
              _buildLevelButton(1, "거의 햇빛이 없는 공간"),
              _buildLevelButton(2, "약간의 간접광이 있는 공간"),
              _buildLevelButton(3, "일반적인 실내 밝기"),
              _buildLevelButton(4, "밝은 간접광이 들어오는 공간"),
              _buildLevelButton(5, "햇빛이 매우 많은 공간"),

              const SizedBox(height: 16), // Spacer 대신 고정 간격

              Center(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _onNextPressed,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      '다음 (AR 측정으로 이동)',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
