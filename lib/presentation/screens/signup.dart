import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _bankController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool isChecked = false;

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _bankController.dispose();
    _accountController.dispose();
    _birthdayController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthday() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _birthdayController.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Widget buildUnderlineTextFormField(
      TextEditingController controller, String hint,
      {bool isObscure = false, TextInputType? keyboardType, VoidCallback? onTap}) {
    return TextFormField(
      controller: controller,
      obscureText: isObscure,
      keyboardType: keyboardType,
      readOnly: onTap != null,
      onTap: onTap,
      decoration: InputDecoration(
        hintText: hint,
        enabledBorder: const UnderlineInputBorder(),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.blue),
        ),
      ),
      validator: (value) => value == null || value.isEmpty ? "Required field" : null,
    );
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }
    if (!isChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must accept the terms and conditions")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      try {
        print('Firestore: 사용자 정보 저장 시작');
        // 1. FCM 토큰 가져오기
        final fcmToken = await FirebaseMessaging.instance.getToken();


        await FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user!.uid)
            .set({
          'name': _nameController.text.trim(),
          'nickname': _nicknameController.text.trim(), // 추가된 부분
          'email': _emailController.text.trim(),
          'bank': _bankController.text.trim(),           // 추가
          'account': _accountController.text.trim(),     // 추가
          'birthday': _birthdayController.text.trim(),   // 추가
          'phone': _phoneController.text.trim(),         // 추가
          'fcm_token': fcmToken,
          'createdAt': Timestamp.now(),
        });

        print('Firestore: 사용자 정보 저장 성공');
        // 2. 토큰 갱신 시 Firestore 업데이트
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(credential.user!.uid)
              .set({'fcm_token': newToken}, SetOptions(merge: true));
        });
      } catch (e, stackTrace) {
        print('Firestore: 사용자 정보 저장 실패');
        print('에러: $e');
        print('스택트레이스: $stackTrace');

        // 사용자에게도 에러 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Firestore 저장 실패: $e")),
        );
      }


      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Successfully registered")),
      );

      Navigator.of(context).pop(); // or go to login page
    } on FirebaseAuthException catch (e) {
      String message = "An error occurred";
      if (e.code == 'email-already-in-use') {
        message = "Email already in use";
      } else if (e.code == 'weak-password') {
        message = "Weak password";
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildTextFormField(TextEditingController controller, String hint,
      {bool isObscure = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isObscure,
      decoration: InputDecoration(
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      validator: (value) => value == null || value.isEmpty ? "Required field" : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("회원가입")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              buildTextFormField(_nameController, "이름"),
              const SizedBox(height: 12),
              buildTextFormField(_nicknameController, "닉네임"), // 👈 추가
              const SizedBox(height: 12),
              buildTextFormField(_emailController, "이메일"),
              const SizedBox(height: 12),
              buildTextFormField(_passwordController, "비밀번호", isObscure: true),
              const SizedBox(height: 12),
              buildTextFormField(_confirmPasswordController, "비밀번호 확인", isObscure: true),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: buildUnderlineTextFormField(_bankController, "은행명"),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: buildUnderlineTextFormField(
                      _accountController,
                      "계좌번호",
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              buildUnderlineTextFormField(_birthdayController, "생년월일", onTap: _pickBirthday),
              const SizedBox(height: 12),

              // 전화번호
              buildUnderlineTextFormField(
                _phoneController,
                "전화번호",
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Checkbox(
                    value: isChecked,
                    onChanged: (value) {
                      setState(() {
                        isChecked = value ?? false;
                      });
                    },
                  ),
                  const Expanded(
                    child: Text("개인 정보 활용에 동의합니다."),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: isLoading ? null : _signUp,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text("회원가입"),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // 로그인 화면으로 이동
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black, // 글씨 색상 검은색
                ),
                child: const Text("이미 계정이 있으신가요? 로그인"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
