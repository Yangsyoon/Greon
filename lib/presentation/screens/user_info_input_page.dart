import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
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

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _bankController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();


  int? _experienceLevel;
  int? _plantPassion = 1;
  bool _hasPet = false;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

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
          _emailController.text = fbUser.email ?? '';
          _nameController.text = data?['name'] ?? '';
          _nicknameController.text = data?['nickname'] ?? '';
          _phoneController.text = data?['phone'] ?? '';
          _birthdayController.text = data?['birthday'] ?? '';
          _accountController.text = data?['account'] ?? '';
          _bankController.text = data?['bank'] ?? '';
          _experienceLevel = data?['experienceLevel'] != null
              ? int.tryParse(data!['experienceLevel'].toString())
              : null;
          _plantPassion = data?['plantPassion'] ?? 1;
          _hasPet = data?['hasPet'] ?? false;
        });
      }
    } catch (e) {
      print("Firestore에서 사용자 정보 불러오기 실패: $e");
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() {
      _selectedImage = File(pickedFile.path);
    });

    await _uploadImage();
  }

  Future<void> _uploadImage() async {
    final firebase.User? fbUser = firebase.FirebaseAuth.instance.currentUser;
    if (fbUser == null || _selectedImage == null) return;

    if (mounted) setState(() => _isUploading = true);

    try {
      // Storage 업로드
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images/${fbUser.uid}.jpg');
      await ref.putFile(_selectedImage!);
      final downloadUrl = await ref.getDownloadURL();

      // Firestore에 저장
      await FirebaseFirestore.instance.collection('users').doc(fbUser.uid).set({
        'image': downloadUrl,
      }, SetOptions(merge: true));

      // FirebaseAuth 프로필에도 반영
      await fbUser.updatePhotoURL(downloadUrl);
      await fbUser.reload();

      if (mounted) {
        setState(() {
          _selectedImage = null; // 선택 이미지 초기화
        });
      }

      print("이미지 업로드 완료: $downloadUrl");
    } catch (e) {
      print("이미지 업로드 실패: $e");
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }


  Future<void> _saveUserInfo() async {
    final firebase.User? fbUser = firebase.FirebaseAuth.instance.currentUser;
    if (fbUser == null) return;

    if (_formKey.currentState?.validate() ?? false) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(fbUser.uid).set({
          'email': fbUser.email ?? '',
          'name': _nameController.text.trim(),
          'nickname': _nicknameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'birthday': _birthdayController.text.trim(),
          'bank': _bankController.text.trim(),
          'account': _accountController.text.trim(),
          'experienceLevel': _experienceLevel,
          'plantPassion': _plantPassion,
          'hasPet': _hasPet,
        }, SetOptions(merge: true));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ProfileScreen()),
        );
      } catch (e) {
        print("Firestore 저장 오류: $e");
      }
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _birthdayController.text =
        "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = firebase.FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text("회원정보 수정")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // 프로필 사진 + 사진 수정 버튼
              Center(
                child: Column(
                  children: [
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey[200],
                            child: CircularProgressIndicator(),
                          );
                        }
                        final data = snapshot.data!.data() as Map<String, dynamic>?;
                        final imageUrl = data?['image'] as String?;

                        return CircleAvatar(
                          radius: 50,
                          backgroundImage: _selectedImage != null
                              ? FileImage(_selectedImage!)
                              : (imageUrl != null && imageUrl.isNotEmpty
                              ? NetworkImage(imageUrl)
                              : AssetImage('assets/images/default_avatar.png') as ImageProvider),
                          backgroundColor: Colors.grey[200],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _pickImage,
                      child: Text("사진 수정"),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 이메일 (수정 불가)
              TextFormField(
                controller: _emailController,
                readOnly: true,
                style: TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  labelText: "이메일",
                  labelStyle: TextStyle(fontSize: 14),
                  filled: true,
                  fillColor: Colors.grey[300],
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // 이름
              TextFormField(
                controller: _nameController,
                style: TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  labelText: "이름",
                  labelStyle: TextStyle(fontSize: 14),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  border: UnderlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // 닉네임
              TextFormField(
                controller: _nicknameController,
                style: TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  labelText: "닉네임",
                  labelStyle: TextStyle(fontSize: 14),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  border: UnderlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // 휴대폰번호
              TextFormField(
                controller: _phoneController,
                style: TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  labelText: "휴대폰번호",
                  labelStyle: TextStyle(fontSize: 14),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  border: UnderlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // 생년월일 (DatePicker 적용)
              TextFormField(
                controller: _birthdayController,
                readOnly: true,
                onTap: _pickDate,
                style: TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  labelText: "생년월일",
                  labelStyle: TextStyle(fontSize: 14),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  border: UnderlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // 계좌
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _bankController, // controller 연결
                      decoration: InputDecoration(
                        labelText: '은행명',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        border: UnderlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _accountController, // controller 연결
                      decoration: InputDecoration(
                        labelText: '계좌번호',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        border: UnderlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 경험 수준
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("경험 수준", style: TextStyle(fontSize: 14)),
                  DropdownButton<int>(
                    value: _experienceLevel,
                    isExpanded: true,
                    items: [1, 2, 3].map((value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text('$value단계', style: TextStyle(fontSize: 16)),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _experienceLevel = val),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 식물 열정도
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("식물에 대한 열정도", style: TextStyle(fontSize: 14)),
                  DropdownButton<int>(
                    value: _plantPassion,
                    isExpanded: true,
                    items: [1, 2, 3].map((val) => DropdownMenuItem(
                      value: val,
                      child: Text('$val', style: TextStyle(fontSize: 16)),
                    )).toList(),
                    onChanged: (val) => setState(() => _plantPassion = val),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 반려동물 여부
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //   children: [
              //     Text("반려동물 보유 여부", style: TextStyle(fontSize: 14)),
              //     Switch(
              //       value: _hasPet,
              //       onChanged: (value) {
              //         setState(() {
              //           _hasPet = value;
              //         });
              //       },
              //       activeColor: Colors.black, // 켜졌을 때 색상
              //       inactiveThumbColor: Colors.black, // 꺼졌을 때 동그라미 색상
              //       inactiveTrackColor: Colors.grey[300], // 꺼졌을 때 트랙 색상
              //     )
              //   ],
              // ),
              // const SizedBox(height: 24),

              SizedBox(
                child: ElevatedButton(
                  onPressed: _saveUserInfo,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                  child: Text(
                    "저장",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
