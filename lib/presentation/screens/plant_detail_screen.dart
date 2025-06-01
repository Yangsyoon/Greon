import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
            _buildEditableInfoCard(
              icon: Icons.wb_sunny,
              title: "햇빛 필요 정도",
              value: plantState.sunlightLevel,
              field: 'sunlight_level',
            ),
            _buildEditableInfoCard(
              icon: Icons.invert_colors,
              title: "물 주는 주기",
              value: "${plantState.wateringCycle}일",
              field: 'watering_cycle',
              isNumeric: true,
            ),
          ],
        ),
      ),
    );
  }
}