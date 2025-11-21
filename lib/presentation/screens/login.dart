import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth 추가
import 'package:greon/domain/entities/user/app_user.dart';
import 'package:greon/presentation/screens/profile.dart';
import 'package:greon/presentation/screens/root.dart';
import 'package:greon/presentation/widgets/auth_error_dialog.dart'; // 로그인 오류 대화상자
import 'package:greon/presentation/widgets/successful_auth_dialog.dart'; // 로그인 성공 대화상자
import 'package:greon/presentation/widgets/custom_appbar.dart';
import 'package:greon/presentation/widgets/transparent_button.dart';
import 'package:greon/core/constant/colors.dart';
import 'package:greon/configs/app_typography.dart';
import 'package:greon/configs/space.dart';
import 'package:greon/configs/app_dimensions.dart';
import 'package:greon/presentation/widgets/custom_textfield.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:greon/application/user_bloc/user_bloc.dart'; // UserBloc import 추가
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../../application/bottom_navbar_cubit/bottom_navbar_cubit.dart';
import '../../core/enums/enums.dart';
import '../../di/di.dart' as di;
import 'home.dart';

AppUser convertFirebaseUserToAppUser(firebase_auth.User firebaseUser) {
  return AppUser(
    id: firebaseUser.uid,
    fullName: firebaseUser.displayName ?? '',
    email: firebaseUser.email ?? '',
    image: firebaseUser.photoURL,
    createdAt: DateTime.now(),
    lastLogin: DateTime.now(),
  );
}

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
    FirebaseAuth.instance.authStateChanges().listen((firebaseUser) {
      setState(() {
        if (firebaseUser != null) {
          _isLoggedIn = true;
          _loggedInEmail = firebaseUser.email; // 사용자 이메일 저장
          // FirebaseUser를 AppUser로 변환
          final appUser = convertFirebaseUserToAppUser(firebaseUser);
          // UserBloc에 로그인 상태를 전달
          context
              .read<UserBloc>()
              .add(EmitUserLogged(appUser)); // AppUser 인스턴스를 전달
        } else {
          _isLoggedIn = false;
          _loggedInEmail = null; // 로그인 안 됐을 때 초기화
          context
              .read<UserBloc>()
              .add(EmitUserUnlogged()); // UserUnlogged 이벤트 전달
        }
      });
    });
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    // 로그아웃 시 UserBloc에 상태 변경
    context
        .read<UserBloc>()
        .add(EmitUserUnlogged()); // 로그아웃 시 UserUnlogged 이벤트 전달
  }

  Future<void> _signInWithEmailPassword() async {
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      // Firebase 이메일 로그인
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        setState(() {
          _isLoggedIn = true;
          _loggedInEmail = firebaseUser.email;
        });
        // FirebaseUser를 AppUser로 변환
        final appUser = convertFirebaseUserToAppUser(firebaseUser);
        // 로그인 후 UserBloc에 상태 전달
        context
            .read<UserBloc>()
            .add(EmitUserLogged(appUser)); // AppUser 인스턴스를 전달
      }
    } on FirebaseAuthException catch (e) {
      // 로그인 오류 처리
      if (e.code == 'user-not-found') {
        showAuthErrorDialog(context, message: 'No user found for that email.');
      } else if (e.code == 'wrong-password') {
        showAuthErrorDialog(context, message: 'Incorrect password.');
      } else {
        showAuthErrorDialog(context,
            message: 'An error occurred. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (didPop) {
        if (didPop) return;

        Navigator.of(context).pushNamedAndRemoveUntil(
          '/profile', // 👈 ProfileScreen 라우트 경로 (예시)
          (Route<dynamic> route) => false,
        );
      },
      child: Scaffold(
        appBar: CustomAppBar("로그인", context, automaticallyImplyLeading: true),
        body: SingleChildScrollView(
          child: Padding(
            padding: Space.all(1, 1.3),
            child: Form(
              key: _formKey,
              child: _isLoggedIn ? _buildLoggedInUI() : _buildLoginFormUI(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoggedInUI() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RootScreen()),
      );
    });

    return const Center(child: CircularProgressIndicator());
  }

  // 로그인 폼 UI
  Widget _buildLoginFormUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "로그인",
          style: AppText.h2b?.copyWith(color: Colors.black),
        ),
        Space.y!,
        Text(
          "당신의 계정으로 로그인하세요",
          style: AppText.h3?.copyWith(color: AppColors.GreyText),
        ),
        Space.y2!,
        Text(
          "메일 주소*",
          style: AppText.b1b,
        ),
        Space.y!,
        buildTextFormField(_emailController, "Email Address"),
        Space.yf(1.5),
        Text(
          "비밀번호*",
          style: AppText.b1b,
        ),
        Space.y!,
        buildTextFormField(_passwordController, "Password", isObscure: true),
        Space.y1!,
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              "비밀번호를 잊으셨나요?",
              style: AppText.h3?.copyWith(color: Colors.black),
            )
          ],
        ),
        Space.yf(1.7),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _signInWithEmailPassword(); // 로그인 처리 함수 호출
            }
          },
          style: ButtonStyle(
            minimumSize: MaterialStatePropertyAll(
              Size(double.infinity, AppDimensions.normalize(20)),
            ),
          ),
          child: Text(
            "로그인",
            style: AppText.h3b?.copyWith(color: Colors.black),
          ),
        ),
        Space.yf(1.5),
        Center(
          child: Text(
            "계정이 없으신가요?",
            style: AppText.b1b,
          ),
        ),
        Space.y1!,
        transparentButton(
          context: context,
          onTap: () {
            Navigator.of(context).pushNamed('/signup');
          },
          buttonText: "회원가입",
        ),
      ],
    );
  }
}
