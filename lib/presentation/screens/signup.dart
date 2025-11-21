import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:greon/presentation/screens/terms_viewer_screen.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; // <<< 이 부분을 추가합니다.

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

  String? _selectedBank;

  final List<String> bankList = [
    "NH농협", "카카오뱅크", "KB국민", "토스뱅크", "신한", "우리", "IBK기업",
    "하나", "새마을", "부산", "iM뱅크", "케이뱅크", "신협", "우체국",
    "SC제일", "경남", "광주", "수협", "정북", "저축은행", "제주",
    "씨티", "KDB산업", "산림조합", "SBI저축은행", "BOA", "중국",
    "HSBC", "중국공상", "도이치", "JP모건", "BNP파리바", "중국건설"
  ];

  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool _agreedToTerms = false; // 서비스 이용 약관 동의
  bool _agreedToPrivacy = false;    // 개인정보 처리방침 동의

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
      {bool isObscure = false, TextInputType? keyboardType, VoidCallback? onTap, String? Function(String?)? validator}) {
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
      validator: validator ?? (value) => value == null || value.isEmpty ? "필수 입력 항목입니다." : null,
    );
  }

  Widget buildTextFormField(TextEditingController controller, String hint,
      {bool isObscure = false, String? Function(String?)? validator, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      obscureText: isObscure,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      validator: validator ?? (value) => value == null || value.isEmpty ? "필수 입력 항목입니다." : null,
    );
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("비밀번호가 일치하지 않습니다.")),
      );
      return;
    }
    if (!_agreedToTerms || !_agreedToPrivacy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("서비스 이용 약관과 개인정보 처리방침에 동의해야 합니다.")),
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
        final fcmToken = await FirebaseMessaging.instance.getToken();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user!.uid)
            .set({
          'name': _nameController.text.trim(),
          'nickname': _nicknameController.text.trim(),
          'email': _emailController.text.trim(),
          'bank': _bankController.text.trim(),
          'account': _accountController.text.trim(),
          'birthday': _birthdayController.text.trim(),
          'phone': _phoneController.text.trim(),
          'fcm_token': fcmToken,
          'createdAt': Timestamp.now(),
        });

        print('Firestore: 사용자 정보 저장 성공');
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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("사용자 정보 저장 실패: $e")),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("회원가입이 완료되었습니다.")),
      );

      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      String message = "회원가입 중 오류가 발생했습니다.";
      if (e.code == 'email-already-in-use') {
        message = "이미 사용 중인 이메일입니다.";
      } else if (e.code == 'weak-password') {
        message = "비밀번호가 너무 약합니다.";
      } else if (e.code == 'invalid-email') {
        message = "유효하지 않은 이메일 형식입니다.";
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // // <<< _launchUrl 함수를 여기에 추가합니다.
  // Future<void> _launchUrl(String url) async {
  //   final Uri uri = Uri.parse(url);
  //   if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
  //     // launchUrl 실패 시 예외 처리
  //     if (mounted) { // 위젯이 마운트된 상태인지 확인 (비동기 함수에서 context 사용 시 권장)
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('URL을 열 수 없습니다: $url')),
  //       );
  //     }
  //     throw Exception('Could not launch $uri');
  //   }
  // }

  void _showTerms(BuildContext context, String title, String url) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TermsViewerScreen(
          title: title,
          markdownUrl: url,
        ),
      ),
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              buildTextFormField(_nameController, "이름",
                  validator: (value) => value == null || value.isEmpty ? "이름을 입력해주세요." : null),
              const SizedBox(height: 12),
              buildTextFormField(_nicknameController, "닉네임",
                  validator: (value) => value == null || value.isEmpty ? "닉네임을 입력해주세요." : null),
              const SizedBox(height: 12),
              buildTextFormField(_emailController, "이메일",
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return "이메일을 입력해주세요.";
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return "유효한 이메일 형식이 아닙니다.";
                    return null;
                  }),
              const SizedBox(height: 12),
              buildTextFormField(_passwordController, "비밀번호 (6자 이상)", isObscure: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) return "비밀번호를 입력해주세요.";
                    if (value.length < 6) return "비밀번호는 6자 이상이어야 합니다.";
                    return null;
                  }),
              const SizedBox(height: 12),
              buildTextFormField(_confirmPasswordController, "비밀번호 확인", isObscure: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) return "비밀번호를 다시 입력해주세요.";
                    if (value != _passwordController.text) return "비밀번호가 일치하지 않습니다.";
                    return null;
                  }),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _selectedBank,
                      hint: const Text("은행명"), // 힌트 텍스트
                      isExpanded: true,
                      items: bankList.map((String bank) {
                        return DropdownMenuItem<String>(
                          value: bank,
                          child: Text(bank),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedBank = newValue;
                        });
                      },
                      validator: (value) => value == null || value.isEmpty ? "은행명을 선택해주세요." : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: buildUnderlineTextFormField(
                      _accountController,
                      "계좌번호",
                      keyboardType: TextInputType.number,
                      validator: (value) => value == null || value.isEmpty ? "계좌번호를 입력해주세요." : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              buildUnderlineTextFormField(_birthdayController, "생년월일", onTap: _pickBirthday,
                  validator: (value) => value == null || value.isEmpty ? "생년월일을 선택해주세요." : null),
              const SizedBox(height: 12),

              buildUnderlineTextFormField(
                  _phoneController,
                  "전화번호 ('-' 없이 입력)",
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) return "전화번호를 입력해주세요.";
                    if (!RegExp(r'^[0-9]+$').hasMatch(value)) return "숫자만 입력해주세요.";
                    return null;
                  }
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Checkbox(
                    value: _agreedToTerms,
                    onChanged: (value) {
                      setState(() {
                        _agreedToTerms = value ?? false;
                      });
                    },
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        // Raw URL을 사용해야 합니다.
                        const termsUrl = 'https://raw.githubusercontent.com/Yangsyoon/greon-terms/main/terms.md';
                        _showTerms(context, '서비스 이용 약관', termsUrl);
                      },
                      child: RichText(
                        text: const TextSpan( // const 추가
                          children: [
                            TextSpan(
                              text: "서비스 이용 약관",
                              style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                                fontSize: 15,
                              ),
                            ),
                            TextSpan(
                              text: "에 동의합니다.",
                              style: TextStyle(color: Colors.black, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Checkbox(
                    value: _agreedToPrivacy,
                    onChanged: (value) {
                      setState(() {
                        _agreedToPrivacy = value ?? false;
                      });
                    },
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        // Raw URL을 사용해야 합니다.
                        const privacyUrl = 'https://raw.githubusercontent.com/Yangsyoon/greon-terms/main/privacy.md';
                        _showTerms(context, '개인정보 처리방침', privacyUrl);
                      },
                      child: RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: "개인정보 처리방침",
                              style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                                fontSize: 15,
                              ),
                            ),
                            TextSpan(
                              text: "에 동의합니다.",
                              style: TextStyle(color: Colors.black, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              ElevatedButton(
                onPressed: isLoading ? null : _signUp,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  "회원가입",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black,
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