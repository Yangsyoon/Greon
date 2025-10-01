import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _reauthenticateUser(String email, String password) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("No user is currently logged in.");
    }

    AuthCredential credential = EmailAuthProvider.credential(email: email, password: password);
    await user.reauthenticateWithCredential(credential);
  }

  Future<void> _deleteAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("로그인된 사용자가 없습니다.")),
        );
        return;
      }

      // 1. 재인증 (필요한 경우)
      // 보안을 위해 사용자에게 현재 비밀번호를 다시 입력받아 재인증하는 것이 강력히 권장됩니다.
      // Firebase 정책에 따라 일정 시간(약 5분) 이상 로그인 상태를 유지하면 재인증이 필요할 수 있습니다.
      try {
        await _reauthenticateUser(user.email!, _passwordController.text);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("재인증 성공.")),
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'wrong-password') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("비밀번호가 올바르지 않습니다.")),
          );
          return;
        } else if (e.code == 'invalid-email') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("유효하지 않은 이메일 형식입니다.")),
          );
          return;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("재인증 실패: ${e.message}")),
          );
          return;
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("재인증 중 알 수 없는 오류 발생: $e")),
        );
        return;
      }


      // 2. Firestore 사용자 데이터 삭제
      await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
      print('Firestore: 사용자 데이터 삭제 성공');

      // 3. Firebase Authentication 사용자 계정 삭제
      await user.delete();
      print('Firebase Auth: 사용자 계정 삭제 성공');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("회원 탈퇴가 완료되었습니다.")),
      );

      // 회원 탈퇴 후 로그인 화면으로 이동하거나, 앱의 시작 화면으로 이동
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login', // 로그인 화면 라우트 (또는 앱의 시작 화면)
            (Route<dynamic> route) => false, // 모든 이전 라우트 제거
      );
    } on FirebaseAuthException catch (e) {
      String message = "회원 탈퇴 중 오류가 발생했습니다.";
      if (e.code == 'requires-recent-login') {
        message = "보안을 위해 다시 로그인하여 재인증이 필요합니다. 비밀번호를 입력해주세요.";
      } else {
        message = "Firebase Auth 오류: ${e.message}";
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      print('Firebase Auth 에러: ${e.code} - ${e.message}');
    } catch (e, stackTrace) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("회원 탈퇴 실패: $e")),
      );
      print('회원 탈퇴 중 일반 에러: $e');
      print('스택 트레이스: $stackTrace');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("회원 탈퇴"),
        backgroundColor: Colors.redAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "회원 탈퇴를 진행하시려면, 현재 로그인된 계정의 비밀번호를 입력해주세요.",
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "비밀번호",
                  hintText: "현재 비밀번호를 입력하세요",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "비밀번호를 입력해주세요.";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: isLoading ? null : _deleteAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, // 탈퇴 버튼은 빨간색으로
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  "회원 탈퇴하기",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // 이전 화면으로 돌아가기
                },
                child: const Text(
                  "취소",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}