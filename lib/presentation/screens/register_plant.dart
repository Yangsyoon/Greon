import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:greon/presentation/screens/interest_survey.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:greon/presentation/screens/user_info_input_page.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'interest_survey.dart';

class RegisterPlant extends StatefulWidget {
  @override
  _RegisterPlantState createState() => _RegisterPlantState();
}

class _RegisterPlantState extends State<RegisterPlant> {
  String? _selectedPlantSpecies;
  List<String> _plantSpeciesList = [];
  String? _selectedSpeciesId;
  String? _lastWateredDate = DateTime.now().toIso8601String().split('T')[0];
  int _sunlightLevel = 3;

  TextEditingController _plantNameController = TextEditingController();
  int _watering = 0;
  int _repotting = 0;
  int _nutrient = 0;

  @override
  void initState() {
    super.initState();
    _fetchPlantSpecies();
  }

  Future<void> _fetchPlantSpecies() async {
    final querySnapshot =
    await FirebaseFirestore.instance.collection('plant_species').get();
    setState(() {
      _plantSpeciesList =
          querySnapshot.docs.map((doc) => doc['species_name'] as String).toList();
    });
  }

  Future<void> _fetchPlantDetails(String speciesName) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('plant_species')
        .where('species_name', isEqualTo: speciesName)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final doc = querySnapshot.docs.first;
      setState(() {
        _selectedSpeciesId = doc.id;
        _watering = doc['default_watering_cycle'];
        _repotting = doc['default_repotting_cycle'];
        _nutrient = doc['default_nutrient_cycle'];
        _plantNameController.text = speciesName; // 이름 자동 입력
      });
    }
  }

  Future<void> _showCycleDialog() async {
    int w = _watering, r = _repotting, n = _nutrient;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("주기 설정"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildNumberField("물주기", w, (v) => w = v),
            _buildNumberField("영양제", n, (v) => n = v),
            _buildNumberField("분갈이", r, (v) => r = v),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _watering = w;
                _nutrient = n;
                _repotting = r;
              });
              Navigator.pop(ctx);
            },
            child: Text("확인"),
          )
        ],
      ),
    );
  }

  Widget _buildNumberField(
      String label, int initialValue, Function(int) onChanged) {
    TextEditingController controller =
    TextEditingController(text: initialValue.toString());
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      onChanged: (val) {
        if (int.tryParse(val) != null) onChanged(int.parse(val));
      },
    );
  }

  String _getSunlightLevelLabel(int level) {
    switch (level) {
      case 1:
      case 2:
        return "적음";
      case 3:
        return "보통";
      case 4:
      case 5:
        return "많음";
      default:
        return "보통";
    }
  }

  File? _selectedImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(String plantId, String uid) async {
    if (_selectedImage == null) return null;

    final ref = FirebaseStorage.instance
        .ref()
        .child('user_plant')
        .child(uid)
        .child('$plantId.jpg');

    await ref.putFile(_selectedImage!);
    return await ref.getDownloadURL();
  }

  Future<void> _submitPlantData() async {
    if (_selectedSpeciesId == null || _plantNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("식물 종과 이름을 입력해주세요.")),
      );
      return;
    }

    final name = _plantNameController.text.trim();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    final query = await FirebaseFirestore.instance
        .collection('plant')
        .where('name', isEqualTo: name)
        .where('watering_cycle', isEqualTo: _watering)
        .where('repotting_cycle', isEqualTo: _repotting)
        .where('nutrient_frequency', isEqualTo: _nutrient)
        .where('last_watered_date', isEqualTo: _lastWateredDate)
        .where('sunlight_level', isEqualTo: _getSunlightLevelLabel(_sunlightLevel))
        .where('species_id', isEqualTo: _selectedSpeciesId)
        .get();

    if (query.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("이미 등록된 식물입니다.")),
      );
      return;
    }

    final newDoc = FirebaseFirestore.instance.collection('plant').doc();

    String? imageUrl;
    if (_selectedImage != null && uid != null) {
      imageUrl = await _uploadImage(newDoc.id, uid);
    }

    await newDoc.set({
      "name": name,
      "watering_cycle": _watering,
      "repotting_cycle": _repotting,
      "nutrient_frequency": _nutrient,
      "last_watered_date": _lastWateredDate,
      "sunlight_level": _getSunlightLevelLabel(_sunlightLevel),
      "species_id": _selectedSpeciesId,
      "user_id": uid, // ✅ 사용자 ID 추가
      if (imageUrl != null) "image_url": imageUrl,
    });

    if (uid != null) {
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      await userRef.update({
        'plants': FieldValue.arrayUnion([newDoc.id])
      });
    }

    final surveyData = {
      'plant_id': newDoc.id,
      'location': "실내 관엽 식물",
      'placement': "거실",
      'light_setting': _getSunlightLevelLabel(_sunlightLevel),
      'user_interest_level': 3,
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InterestSurveyPage(surveyData: surveyData),
      ),
    );
   }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("식물 등록")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text("식물 이미지"),
            SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: _selectedImage != null
                  ? Image.file(_selectedImage!, height: 150)
                  : Container(
                height: 150,
                width: double.infinity,
                color: Colors.grey[300],
                child: Icon(Icons.add_a_photo, size: 50, color: Colors.grey[700]),
              ),
            ),
            SizedBox(height: 16),
            // 식물 종 선택
            DropdownButton<String>(
              hint: Text("식물 종 선택"),
              value: _selectedPlantSpecies,
              onChanged: (value) {
                setState(() => _selectedPlantSpecies = value);
                if (value != null) _fetchPlantDetails(value);
              },
              items: _plantSpeciesList
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
            ),
            SizedBox(height: 16),

            // 식물 이름 입력
            TextField(
              controller: _plantNameController,
              decoration: InputDecoration(hintText: "식물 이름 입력"),
            ),
            SizedBox(height: 16),

            // 주기 설정 버튼
            ElevatedButton(
              onPressed: _showCycleDialog,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              ),
              child: Text("물주기: $_watering, 영양제: $_nutrient, 분갈이: $_repotting"),
            ),
            SizedBox(height: 16),

            // 마지막 물준날
            ListTile(
              title: Text("마지막 물 준 날"),
              subtitle: Text(_lastWateredDate ?? ''),
              onTap: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() {
                    _lastWateredDate =
                    picked.toLocal().toString().split(" ")[0];
                  });
                }
              },
            ),
            SizedBox(height: 16),

            // 일조량 선택
            Text("일조량 선택"),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(5, (i) {
                return Column(
                  children: [
                    Radio<int>(
                      value: i + 1,
                      groupValue: _sunlightLevel,
                      onChanged: (val) {
                        setState(() => _sunlightLevel = val!);
                      },
                    ),
                    Text('${i + 1}'),
                  ],
                );
              }),
            ),
            SizedBox(height: 24),

            // 하단 버튼 (Skip / 설문시작)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[400],
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: Size(120, 40),
                  ),
                  onPressed: () async {
                    await _submitPlantData(); // 식물 등록
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => UserInfoInputPage()),
                    );
                  },
                  child: Text("설문 Skip"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: Size(120, 40),
                  ),
                  onPressed: _submitPlantData,
                  child: Text("설문 시작"),
                ),
              ],
            ),

          ],
        ),
      ),
    );
  }
}
