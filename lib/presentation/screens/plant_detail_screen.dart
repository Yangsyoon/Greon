  import 'dart:io';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:firebase_messaging/firebase_messaging.dart';
  import 'package:firebase_storage/firebase_storage.dart';
  import 'package:flutter/material.dart';
  import 'package:image_picker/image_picker.dart';
  import '../../domain/entities/plants/plant_entity.dart';

  class PlantDetailScreen extends StatefulWidget {
    final PlantEntity plant;

    const PlantDetailScreen({super.key, required this.plant});

    @override
    State<PlantDetailScreen> createState() => _PlantDetailScreenState();
  }

  class _PlantDetailScreenState extends State<PlantDetailScreen> {
    late PlantEntity plantState;
    String? imageUrl;

    @override
    void initState() {
      super.initState();
      plantState = widget.plant;
      _loadImage();
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
      await FirebaseFirestore.instance
          .collection('plant')
          .doc(widget.plant.id)
          .update({field: value});

      setState(() {
        switch (field) {
          case 'name':
            plantState = plantState.copyWith(name: value);
            break;
          case 'nutrient_frequency':
            plantState = plantState.copyWith(nutrientFrequency: value);
            break;
          case 'repotting_cycle':
            plantState = plantState.copyWith(repottingCycle: value);
            break;
          case 'watering_cycle':
            plantState = plantState.copyWith(wateringCycle: value);
            break;
          case 'sunlight_level':
            plantState = plantState.copyWith(sunlightLevel: value);
            break;
          case 'last_watered_date':
            plantState = plantState.copyWith(lastWateredDate: value.toDate().toString().split(" ").first);
            break;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("변경사항이 저장되었습니다.")),
      );
    }

    Future<void> _waterPlantAndSchedule(BuildContext context, PlantEntity plantState) async {
      try {
        // 1. 사용자 ID 가져오기 (가장 먼저)
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId == null) return;

        // 2. 현재 시간 및 계산
        final now = DateTime.now();
        final nextWateringDate = now.add(Duration(days: plantState.wateringCycle));

        // 3. 문서 참조 생성 (userId 사용)
        final plantDocRef = FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('plants')
            .doc(plantState.id); // plantId -> plantState.id

        // 4. 문서 존재 여부 확인 및 처리
        final docSnapshot = await plantDocRef.get();
        if (docSnapshot.exists) {
          await plantDocRef.update({'last_watered_date': Timestamp.fromDate(now)});
        } else {
          await plantDocRef.set({
            'last_watered_date': Timestamp.fromDate(now),
            'name': plantState.name,
            'watering_cycle': plantState.wateringCycle,
          });
        }
        // 모든 Firestore 저장 시 UTC 변환
        final nextWateringDateUtc = nextWateringDate.toUtc(); // 공통 변수로 추출

        // 5. 스케줄 등록 (기존 코드 유지)
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

        // 6. FCM 토큰 처리 (기존 코드 유지)
        final fcmToken = await FirebaseMessaging.instance.getToken();
        print('FCM 토큰: $fcmToken');
        if (fcmToken == null) {
          throw Exception('FCM 토큰을 가져올 수 없습니다');
        }

        // 7. 알림 예약 (기존 코드 유지)
        final scheduledTime = DateTime(
          nextWateringDateUtc.year,
          nextWateringDateUtc.month,
          nextWateringDateUtc.day,
          8,
          0,
          0,
        ).toUtc();

        await FirebaseFirestore.instance
            .collection('notification_requests')
            .add({
          'user_id': userId,
          'fcm_token': fcmToken,
          'title': '${plantState.name} 물 줄 시간이에요 💧',
          'body': '오늘은 ${plantState.name}에게 물을 줄 날입니다!',
          'scheduled_time': Timestamp.fromDate(scheduledTime),
          'sent': false,
          'plant_id': plantState.id,
          'created_at': Timestamp.now(),
        });

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("물주기 완료! 다음 일정이 자동 등록되고, 푸시 알림이 예약되었습니다.")),
        );
      } catch (e, stack) {
        print('알림 설정 실패: $e');
        print(stack);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("알림 설정 실패: ${e.toString()}")),
        );
        rethrow;
      }
    }



    void _showEditDialog(String title, String currentValue, String field, {bool isNumeric = false}) {
      final initialValue = isNumeric ? RegExp(r'\d+').stringMatch(currentValue) ?? '' : currentValue;
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("숫자를 입력해주세요.")),
                      );
                      return;
                    }
                    await _updatePlantField(field, number);
                  } else {
                    await _updatePlantField(field, trimmed);
                  }
                  Navigator.of(context).pop();
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
        await _updatePlantField(field, selected.toIso8601String().split("T").first);
      }
    }

    Future<void> _pickAndUploadImage() async {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      final ref = FirebaseStorage.instance.ref().child('user_plant/$userId/${widget.plant.id}.jpg');

      // 기존 이미지 삭제
      try {
        await ref.delete();
      } catch (_) {}

      // 새 이미지 업로드
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
              const Text("필요 일조량 선택", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),
              ...options.map((option) => ListTile(
                title: Text(option),
                onTap: () async {
                  Navigator.of(context).pop(); // 바텀시트 닫기
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
      return Scaffold(
        appBar: AppBar(title: Text(plantState.name)),
        body: SingleChildScrollView(
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
                    child: const Icon(Icons.eco, size: 64, color: Colors.green),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildEditableInfoCard(
                icon: Icons.label,
                title: "이름",
                value: plantState.name,
                field: 'name',
              ),
              _buildEditableInfoCard(
                icon: Icons.water_drop,
                title: "최근 물 준 날짜",
                value: plantState.lastWateredDate,
                field: 'last_watered_date',
                isDate: true,
              ),
              _buildEditableInfoCard(
                icon: Icons.vaccines,
                title: "영양제 주기",
                value: "${plantState.nutrientFrequency}일",
                field: 'nutrient_frequency',
                isNumeric: true,
              ),
              _buildEditableInfoCard(
                icon: Icons.local_florist,
                title: "분갈이 주기",
                value: "${plantState.repottingCycle}일",
                field: 'repotting_cycle',
                isNumeric: true,
              ),
              Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 3,
                child: ListTile(
                  leading: const Icon(Icons.wb_sunny, color: Colors.green),
                  title: const Text("필요 일조량", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(plantState.sunlightLevel),
                  trailing: const Icon(Icons.edit, size: 18),
                  onTap: _showSunlightLevelPicker,
                ),
              ),
              _buildEditableInfoCard(
                icon: Icons.invert_colors,
                title: "물 주는 주기",
                value: "${plantState.wateringCycle}일",
                field: 'watering_cycle',
                isNumeric: true,
              ),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await _waterPlantAndSchedule(context, plantState);
                  },
                  icon: const Icon(Icons.water_drop),
                  label: const Text("물 주기"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
      );
    }
  }
