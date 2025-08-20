import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:greon/presentation/screens/survey/plant_location_survey.dart';

class LocationSurveyPage extends StatefulWidget {
  final Map<String, dynamic> surveyData;

  const LocationSurveyPage({Key? key, required this.surveyData})
      : super(key: key);

  @override
  State<LocationSurveyPage> createState() => _LocationSurveyPageState();
}

class _LocationSurveyPageState extends State<LocationSurveyPage> {
  bool _isLoading = false;

  Future<void> _requestLocationPermissionAndContinue() async {
    setState(() => _isLoading = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('위치 서비스가 비활성화되어 있습니다.')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('위치 권한이 필요합니다.')),
          );
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      widget.surveyData['location'] = {
        'latitude': position.latitude,
        'longitude': position.longitude,
      };

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              PlantLocationSurveyPage(surveyData: widget.surveyData),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('위치 정보를 가져오는 데 실패했습니다: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
          appBar: AppBar(title: Text('설문 2/7')),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '거주하시는 곳은 어디고 식물은 어디에 놓으시나요?',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 24),
                Text(
                  '위치정보는 다음에만 사용됩니다:',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                SizedBox(height: 8),
                _buildBullet('해당 지역에 적절한 식물 추천'),
                _buildBullet('지역 날씨를 감안하여 물 주기 일정 조정'),
                _buildBullet('서리&더위 경고 제공'),
                _buildBullet('비가 온 경우 실외 식물에 물을 준 것으로 표시'),
                Spacer(),
                Center(
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : _requestLocationPermissionAndContinue,
                    child:
                        _isLoading ? CircularProgressIndicator() : Text('계속하기'),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
