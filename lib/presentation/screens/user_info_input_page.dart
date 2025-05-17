// lib/screens/user_info_input_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:greon/domain/entities/user/app_user.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';


class UserInfoInputPage extends StatefulWidget {
  @override
  _UserInfoInputPageState createState() => _UserInfoInputPageState();
}

class _UserInfoInputPageState extends State<UserInfoInputPage> {
  @override
  void initState() {
    super.initState();
    _loadUserInfo(); // Firestore에서 기존 사용자 정보 불러오기
  }


  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _locationController = TextEditingController();
  int? _experienceLevel;  // experienceLevel을 int로 선언
  int? _plantPassion = 1;
  List<String> _preferredPlants = [];
  bool _hasPet = false;
  String? _timezone = "Asia/Seoul";

  Future<void> _loadUserInfo() async {
    final firebase.User? fbUser = firebase.FirebaseAuth.instance.currentUser;
    if (fbUser == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(fbUser.uid).get();
      if (doc.exists) {
        final data = doc.data();
        setState(() {
          // Firestore에서 'fullName' 가져오기
          String fullName = data?['fullName'] ?? 'Unknown'; // 기본값은 'Unknown'
          print("fullName: $fullName");
          _locationController.text = data?['location'] ?? '';
          // experienceLevel을 String에서 int로 변환
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

    if (fbUser == null) {
      // 로그인 안 된 경우 처리
      // 이 메시지가 뜨는지 로그 확인
      print("사용자 로그인 정보가 없음");
      return;
    }


    if (_formKey.currentState?.validate() ?? false) {
      final AppUser user = AppUser(
        id: fbUser.uid,
        fullName: fbUser.displayName ?? "",
        email: fbUser.email ?? '',
        image: fbUser.photoURL,
        createdAt: fbUser.metadata.creationTime,
        lastLogin: fbUser.metadata.lastSignInTime,
        plantPassion: _plantPassion,
        location: _locationController.text.isNotEmpty ? _locationController.text : null,
        experienceLevel: _experienceLevel != null ? _experienceLevel.toString() : null,
        preferredPlants: _preferredPlants.isNotEmpty ? _preferredPlants : null,
        hasPet: _hasPet,
        timezone: _timezone,
        language: 'ko', // 기본 언어 설정
      );

      // Firestore 저장 (기존 데이터 병합)
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.id)
            .set(user.toJson(), SetOptions(merge: true));
        print("저장 완료");
        Navigator.pop(context);
      }catch (e) {
        print("Firestore 저장 오류: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("회원 정보 추가")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              ElevatedButton(
                onPressed: _pickAndUploadImage,
                child: const Text("프로필 이미지 선택"),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: "거주지"),
                controller: _locationController,
              ),

              ListTile(
                title: Text("경험 수준"),
                subtitle: Text('1: 초보, 3: 고수'),
                trailing: DropdownButton<int>(
                  value: _experienceLevel, // 여기를 _experienceLevel로 수정
                  items: [1, 2, 3].map((int value) {
                    String label;
                    switch (value) {
                      case 1:
                        label = '초보';
                        break;
                      case 2:
                        label = '중급';
                        break;
                      case 3:
                        label = '고수';
                        break;
                      default:
                        label = '';
                    }
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text('$value: $label'),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _experienceLevel = newValue;
                    });
                  },
                ),
              ),

              ListTile(
                title: Text("식물에 대한 열정도"),
                subtitle: Text('1 ~ 3 (1: 낮음, 3: 높음)'),
                trailing: DropdownButton<int>(
                  value: _plantPassion,
                  items: [1, 2, 3].map((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text(value.toString()),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _plantPassion = newValue;
                    });
                  },
                ),
              ),
              SwitchListTile(
                title: Text("반려동물 보유 여부"),
                value: _hasPet,
                onChanged: (value) {
                  setState(() {
                    _hasPet = value;
                  });
                },
              ),
              ElevatedButton(
                onPressed: _saveUserInfo,
                child: Text("저장"),
              ),
            ],
          ),
        ),
      ),
    );
  }
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAndUploadImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final firebase.User? fbUser = firebase.FirebaseAuth.instance.currentUser;

      if (fbUser == null) {
        print("로그인된 사용자 없음");
        return;
      }

      try {
        final ref = FirebaseStorage.instance.ref().child('user_images/${fbUser.uid}.jpg');
        await ref.putFile(file);
        final downloadURL = await ref.getDownloadURL();

        setState(() {
          _selectedImage = file;
        });

        // 프로필 사진 FirebaseAuth에 설정
        await fbUser.updatePhotoURL(downloadURL);
        print("이미지 업로드 및 사용자 photoURL 설정 완료");

      } catch (e) {
        print("이미지 업로드 실패: $e");
      }
    }
  }

}
