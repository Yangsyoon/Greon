import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/plants/plant_entity.dart';

class PlantDetailScreen extends StatefulWidget {
  final PlantEntity plant;

  const PlantDetailScreen({super.key, required this.plant});

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  // `plantState` 변수를 제거합니다. 모든 UI는 StreamBuilder에서 오는 데이터에 의존합니다.
  String? imageUrl;

  @override
  void initState() {
    super.initState();
    // initState에서 위젯의 초기 plant 데이터를 사용하여 이미지를 로드합니다.
    _loadImage();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadImage() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('user_plant/$userId/${widget.plant.id}.jpg');
      final url = await ref.getDownloadURL();
      setState(() {
        imageUrl = url;
      });
    } catch (e) {
      print("이미지를 가져오는 중 오류 발생: $e");
    }
  }

  Future<void> _updatePlantField(String field, dynamic value) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      if (field == 'last_watered_date' && value is String) {
        final date = DateTime.parse(value);
        await FirebaseFirestore.instance
            .collection('plant')
            .doc(widget.plant.id)
            .update({field: Timestamp.fromDate(date)});
      } else {
        await FirebaseFirestore.instance
            .collection('plant')
            .doc(widget.plant.id)
            .update({field: value});
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("변경사항이 저장되었습니다.")),
      );
    } catch (e) {
      print("Firestore 업데이트 오류: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("변경사항 저장 실패: ${e.toString()}")),
      );
    }
  }

  Future<void>  _waterPlantAndSchedule(
      BuildContext context, PlantEntity plantState) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final now = DateTime.now();
      final nextWateringDate = now.add(Duration(days: plantState.wateringCycle));

      await _updatePlantField('last_watered_date', DateFormat('yyyy-MM-dd').format(now));

      final nextWateringDateUtc = nextWateringDate.toUtc();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('schedules')
          .add({
        'plant_id': plantState.id,
        'plant_name': plantState.name,
        'date': Timestamp.fromDate(nextWateringDateUtc),
        'type': '물주기',
        'memo': '자동 등록됨',
        'auto_generated': true,
      });

      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) {
        throw Exception('FCM 토큰을 가져올 수 없습니다');
      }
      final scheduledTime = DateTime(
        nextWateringDateUtc.year,
        nextWateringDateUtc.month,
        nextWateringDateUtc.day,
        8,
        0,
        0,
      ).toUtc();

      await FirebaseFirestore.instance.collection('notification_requests').add({
        'user_id': userId,
        'fcm_token': fcmToken,
        'title': '${plantState.name} 물 줄 시간이에요 💧',
        'body': '오늘은 ${plantState.name}에게 물을 줄 날입니다!',
        'scheduled_time': Timestamp.fromDate(scheduledTime),
        'sent': false,
        'plant_id': plantState.id,
        'created_at': Timestamp.now(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("물주기 완료! 다음 일정이 자동 등록되고, 푸시 알림이 예약되었습니다.")),
      );
    } catch (e, stack) {
      print('알림 설정 실패: $e');
      print(stack);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("알림 설정 실패: ${e.toString()}")),
      );
      rethrow;
    }
  }

  void _showEditDialog(String title, String currentValue, String field,
      {bool isNumeric = false}) {
    final initialValue = isNumeric
        ? RegExp(r'\d+').stringMatch(currentValue) ?? ''
        : currentValue;
    final controller = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("$title 수정"),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("취소"),
            ),
            ElevatedButton(
              onPressed: () async {
                final trimmed = controller.text.trim();
                if (isNumeric) {
                  final number = int.tryParse(trimmed);
                  if (number == null) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("숫자를 입력해주세요.")),
                      );
                    }
                    return;
                  }
                  await _updatePlantField(field, number);
                } else {
                  await _updatePlantField(field, trimmed);
                }
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text("저장"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDatePickerDialog(String field, String currentDate) async {
    DateTime initialDate = DateTime.tryParse(currentDate) ?? DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected != null) {
      final formattedDate = DateFormat('yyyy-MM-dd').format(selected);
      await _updatePlantField(field, formattedDate);
    }
  }

  Future<void> _pickAndUploadImage() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final ref = FirebaseStorage.instance
        .ref()
        .child('user_plant/$userId/${widget.plant.id}.jpg');
    try {
      await ref.delete();
    } catch (_) {}
    await ref.putFile(File(picked.path));
    final url = await ref.getDownloadURL();
    setState(() {
      imageUrl = url;
    });
  }

  void _showSunlightLevelPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final options = ['적음', '보통', '많음'];
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const Text("필요 일조량 선택",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            ...options.map((option) => ListTile(
              title: Text(option),
              onTap: () async {
                if (mounted) {
                  Navigator.of(context).pop();
                }
                await _updatePlantField('sunlight_level', option);
              },
            )),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildEditableInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required String field,
    bool isNumeric = false,
    bool isDate = false,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: ListTile(
        leading: Icon(icon, color: Colors.green),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value),
        trailing: const Icon(Icons.edit, size: 18),
        onTap: () {
          if (isDate) {
            _showDatePickerDialog(field, value);
          } else {
            _showEditDialog(title, value, field, isNumeric: isNumeric);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text("로그인이 필요합니다")),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      // ✅ Stream을 'plant' 컬렉션으로 통일
      stream: FirebaseFirestore.instance
          .collection('plant')
          .doc(widget.plant.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};

        String lastWateredDate;
        final rawDate = data['last_watered_date'];

        if (rawDate is Timestamp) {
          lastWateredDate = DateFormat('yyyy-MM-dd').format(rawDate.toDate());
        } else if (rawDate is String) {
          // 문자열일 경우 그대로 사용
          lastWateredDate = rawDate;
        } else {
          // 데이터가 없거나 다른 타입일 경우 기본값 사용
          lastWateredDate = widget.plant.lastWateredDate;
        }

        final updatedPlantState = widget.plant.copyWith(
          name: data['name'] ?? widget.plant.name,
          lastWateredDate: lastWateredDate, // 안전하게 변환된 값 사용
          nutrientFrequency:
          data['nutrient_frequency'] ?? widget.plant.nutrientFrequency,
          repottingCycle: data['repotting_cycle'] ?? widget.plant.repottingCycle,
          sunlightLevel: data['sunlight_level'] ?? widget.plant.sunlightLevel,
          wateringCycle: data['watering_cycle'] ?? widget.plant.wateringCycle,
        );

        return Scaffold(
          appBar: AppBar(title: Text(updatedPlantState.name)),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: _pickAndUploadImage,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: imageUrl != null
                          ? Image.network(
                        imageUrl!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      )
                          : Container(
                        width: double.infinity,
                        height: 200,
                        color: Colors.green[100],
                        child: const Icon(Icons.eco,
                            size: 64, color: Colors.green),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildEditableInfoCard(
                    icon: Icons.label,
                    title: "이름",
                    value: updatedPlantState.name,
                    field: 'name',
                  ),
                  _buildEditableInfoCard(
                    icon: Icons.water_drop,
                    title: "최근 물 준 날짜",
                    value: updatedPlantState.lastWateredDate,
                    field: 'last_watered_date',
                    isDate: true,
                  ),
                  _buildEditableInfoCard(
                    icon: Icons.vaccines,
                    title: "영양제 주기",
                    value: "${updatedPlantState.nutrientFrequency}일",
                    field: 'nutrient_frequency',
                    isNumeric: true,
                  ),
                  _buildEditableInfoCard(
                    icon: Icons.local_florist,
                    title: "분갈이 주기",
                    value: "${updatedPlantState.repottingCycle}일",
                    field: 'repotting_cycle',
                    isNumeric: true,
                  ),
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                    child: ListTile(
                      leading: const Icon(Icons.wb_sunny, color: Colors.green),
                      title: const Text("필요 일조량",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(updatedPlantState.sunlightLevel),
                      trailing: const Icon(Icons.edit, size: 18),
                      onTap: _showSunlightLevelPicker,
                    ),
                  ),
                  _buildEditableInfoCard(
                    icon: Icons.invert_colors,
                    title: "물 주는 주기",
                    value: "${updatedPlantState.wateringCycle}일",
                    field: 'watering_cycle',
                    isNumeric: true,
                  ),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await _waterPlantAndSchedule(
                            context, updatedPlantState);
                      },
                      icon: const Icon(Icons.water_drop),
                      label: const Text("물 주기"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}