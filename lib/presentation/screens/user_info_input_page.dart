// lib/screens/user_info_input_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:greon/domain/entities/user/app_user.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'profile.dart';

class UserInfoInputPage extends StatefulWidget {
  @override
  _UserInfoInputPageState createState() => _UserInfoInputPageState();
}

class _UserInfoInputPageState extends State<UserInfoInputPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  int? _experienceLevel;
  int? _plantPassion = 1;
  List<String> _preferredPlants = [];
  bool _hasPet = false;
  String? _timezone = "Asia/Seoul";
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final firebase.User? fbUser = firebase.FirebaseAuth.instance.currentUser;
    if (fbUser == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(fbUser.uid).get();
      if (doc.exists) {
        final data = doc.data();
        setState(() {
          _nicknameController.text = data?['nickname'] ?? '';
          _locationController.text = data?['location'] ?? '';
          _experienceLevel = data?['experienceLevel'] != null
              ? int.tryParse(data!['experienceLevel'].toString())
              : null;
          _plantPassion = data?['plantPassion'] ?? 1;
          _hasPet = data?['hasPet'] ?? false;
          _preferredPlants = List<String>.from(data?['preferredPlants'] ?? []);
          _timezone = data?['timezone'] ?? 'Asia/Seoul';
        });
      }
    } catch (e) {
      print("Firestore에서 사용자 정보 불러오기 실패: $e");
    }
  }

  Future<void> _saveUserInfo() async {
    final firebase.User? fbUser = firebase.FirebaseAuth.instance.currentUser;
    if (fbUser == null) return;

    if (_formKey.currentState?.validate() ?? false) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(fbUser.uid)
            .set({
          'nickname': _nicknameController.text.trim(),
          'email': fbUser.email ?? '',
          'image': fbUser.photoURL,
          'createdAt': fbUser.metadata.creationTime?.toIso8601String(),
          'lastLogin': fbUser.metadata.lastSignInTime?.toIso8601String(),
          'plantPassion': _plantPassion,
          'location': _locationController.text.isNotEmpty ? _locationController.text : null,
          'experienceLevel': _experienceLevel,
          'preferredPlants': _preferredPlants.isNotEmpty ? _preferredPlants : null,
          'hasPet': _hasPet,
          'timezone': _timezone,
          'language': 'ko',
        }, SetOptions(merge: true));

        // 기존의 pop 제거하고 profile.dart로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ProfileScreen()),
        );
      } catch (e) {
        print("Firestore 저장 오류: $e");
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final firebase.User? fbUser = firebase.FirebaseAuth.instance.currentUser;

      if (fbUser == null) return;

      try {
        final ref = FirebaseStorage.instance.ref().child('user_images/${fbUser.uid}.jpg');
        await ref.putFile(file);
        final downloadURL = await ref.getDownloadURL();

        setState(() {
          _selectedImage = file;
        });

        await fbUser.updatePhotoURL(downloadURL);
      } catch (e) {
        print("이미지 업로드 실패: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(title: Text("회원 정보 추가")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              ElevatedButton.icon(
                onPressed: _pickAndUploadImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  side: BorderSide(color: Colors.grey),
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                icon: Icon(Icons.photo_camera_back_outlined),
                label: Text("프로필 이미지 선택"),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _nicknameController,
                decoration: InputDecoration(
                  labelText: "닉네임",
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '닉네임을 입력해주세요';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: "거주지",
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              SizedBox(height: 16),
              Card(
                child: ListTile(
                  title: Text("경험 수준"),
                  subtitle: Text('1: 초보, 3: 고수'),
                  trailing: DropdownButton<int>(
                    value: _experienceLevel,
                    items: [1, 2, 3].map((value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text('$value단계'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _experienceLevel = val),
                  ),
                ),
              ),
              SizedBox(height: 12),
              Card(
                child: ListTile(
                  title: Text("식물에 대한 열정도"),
                  subtitle: Text('1 ~ 3 (1: 낮음, 3: 높음)'),
                  trailing: DropdownButton<int>(
                    value: _plantPassion,
                    items: [1, 2, 3].map((val) => DropdownMenuItem(
                      value: val,
                      child: Text('$val'),
                    )).toList(),
                    onChanged: (val) => setState(() => _plantPassion = val),
                  ),
                ),
              ),
              SizedBox(height: 12),
              SwitchListTile(
                title: Text("반려동물 보유 여부"),
                value: _hasPet,
                activeColor: Theme.of(context).primaryColor,
                onChanged: (value) => setState(() => _hasPet = value),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveUserInfo,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: Text("저장", style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
