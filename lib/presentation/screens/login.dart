import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth 추가
import 'package:greon/presentation/widgets/auth_error_dialog.dart'; // 로그인 오류 대화상자
import 'package:greon/presentation/widgets/successful_auth_dialog.dart'; // 로그인 성공 대화상자
import 'package:greon/presentation/widgets/custom_appbar.dart';
import 'package:greon/presentation/widgets/transparent_button.dart';
import 'package:greon/core/constant/colors.dart';
import 'package:greon/configs/app_typography.dart';
import 'package:greon/configs/space.dart';
import 'package:greon/configs/app_dimensions.dart';
import 'package:greon/presentation/widgets/custom_textfield.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoggedIn = false;
  String? _loggedInEmail; // nullable로 변경

  @override
  void initState() {
    super.initState();
    // 로그인 상태가 변경될 때마다 상태 확인
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      setState(() {
        if (user != null) {
          _isLoggedIn = true;
          _loggedInEmail = user.email; // 사용자 이메일 저장
        } else {
          _isLoggedIn = false;
          _loggedInEmail = null; // 로그인 안 됐을 때 초기화
        }
      });
    });
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> _signInWithEmailPassword() async {
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      // Firebase 이메일 로그인
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        setState(() {
          _isLoggedIn = true;
          _loggedInEmail = userCredential.user?.email;
        });
      }
    } on FirebaseAuthException catch (e) {
      // 로그인 오류 처리
      if (e.code == 'user-not-found') {
        showAuthErrorDialog(context, message: 'No user found for that email.');
      } else if (e.code == 'wrong-password') {
        showAuthErrorDialog(context, message: 'Incorrect password.');
      } else {
        showAuthErrorDialog(context, message: 'An error occurred. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar("LOGIN", context, automaticallyImplyLeading: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: Space.all(1, 1.3),
          child: Form(
            key: _formKey,
            child: _isLoggedIn
                ? _buildLoggedInUI() // 로그인 됐을 때
                : _buildLoginFormUI(), // 로그인 안 됐을 때
          ),
        ),
      ),
    );
  }

  // 로그인 후 UI
  Widget _buildLoggedInUI() {
    return Column(
      children: [
        Text("Logged in as: ${_loggedInEmail ?? ''}", style: AppText.h2b), // null-safe 처리
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: _signOut,
          child: Text("Logout", style: AppText.h3b?.copyWith(color: Colors.white)),
        ),
      ],
    );
  }

  // 로그인 폼 UI
  Widget _buildLoginFormUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "LOGIN",
          style: AppText.h2b?.copyWith(color: AppColors.CommonCyan),
        ),
        Space.y!,
        Text(
          "Login Into Your Account",
          style: AppText.h3?.copyWith(color: AppColors.GreyText),
        ),
        Space.y2!,
        Text(
          "Email Address*",
          style: AppText.b1b,
        ),
        Space.y!,
        buildTextFormField(_emailController, "Email Address"),
        Space.yf(1.5),
        Text(
          "Password*",
          style: AppText.b1b,
        ),
        Space.y!,
        buildTextFormField(_passwordController, "Password", isObscure: true),
        Space.y1!,
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              "Forgot Password",
              style: AppText.h3?.copyWith(color: AppColors.CommonCyan),
            )
          ],
        ),
        Space.yf(1.7),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _signInWithEmailPassword();  // 로그인 처리 함수 호출
            }
          },
          style: ButtonStyle(
            minimumSize: MaterialStatePropertyAll(
              Size(double.infinity, AppDimensions.normalize(20)),
            ),
          ),
          child: Text(
            "Login",
            style: AppText.h3b?.copyWith(color: Colors.white),
          ),
        ),
        Space.yf(1.5),
        Center(
          child: Text(
            "Don’t have an Account?",
            style: AppText.b1b,
          ),
        ),
        Space.y1!,
        transparentButton(
          context: context,
          onTap: () {
            Navigator.of(context).pushNamed('/signup');
          },
          buttonText: "Signup",
        ),
      ],
    );
  }
}
