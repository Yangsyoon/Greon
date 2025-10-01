import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth 추가

import '../../configs/app_typography.dart'; // 필요시 경로 확인
import '../../configs/space.dart'; // 필요시 경로 확인
import '../../core/constant/assets.dart'; // 필요시 경로 확인
import '../../core/constant/colors.dart'; // 필요시 경로 확인
import '../../core/router/app_router.dart'; // 필요시 경로 확인

// 회원 탈퇴 화면 import (경로에 맞게 수정해주세요)
import '../screens/delete_account_screen.dart';


class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  // 설정 항목을 위한 재사용 가능한 위젯
  Widget _buildSettingRow({
    required BuildContext context,
    required String title,
    VoidCallback? onTap,
  }) {
    return Padding( // 여기에 패딩을 적용하여 각 항목 간의 여백을 만듭니다.
      padding: const EdgeInsets.only(bottom: 12.0), // 각 설정 항목 아래에 12px 여백
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 60, // 높이를 고정하여 일관성 유지
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE0E0E0)),
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16), // Container 내부 패딩
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.black, fontSize: 16),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black, // AppBar 타이틀 색상
        elevation: 1, // AppBar 아래 그림자
      ),
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.all(16), // ListView 전체 패딩
        children: [
          const Text(
            '내 정보',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 12), // 텍스트와 첫 번째 설정 항목 사이 여백
          _buildSettingRow(
            context: context,
            title: '회원 정보 수정',
            onTap: () => Navigator.pushNamed(context, '/user_info_input'),
          ),
          // _buildSettingRow 내부에 padding이 있으므로 여기서는 SizedBox를 제거하거나 조절
          _buildSettingRow(
            context: context,
            title: '배송지 관리',
            onTap: () => Navigator.pushNamed(context, '/addresses'),
          ),
          _buildSettingRow(
            context: context,
            title: '맞춤 정보',
            onTap: () => Navigator.pushNamed(context, '/custom_info'),
          ),
          _buildSettingRow(
            context: context,
            title: '알림 설정',
            onTap: () => Navigator.of(context).pushNamed(AppRouter.notificationSettings),
          ),
          const SizedBox(height: 12), // 알림 설정과 구분선 사이 여백
          const Divider(),
          const SizedBox(height: 24), // 구분선과 다음 섹션 텍스트 사이 여백
          const Text(
            '계정',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 12), // 텍스트와 첫 번째 계정 항목 사이 여백
          _buildSettingRow(
            context: context,
            title: '비밀번호 변경',
            onTap: () => Navigator.pushNamed(context, '/change_password'),
          ),
          _buildSettingRow(
            context: context,
            title: '로그아웃',
            onTap: () async {
              // Firebase 로그아웃 처리
              await FirebaseAuth.instance.signOut();
              // 로그인 화면으로 이동 및 이전 모든 화면 스택 제거
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login', // main.dart에 정의된 로그인 라우트 (경로를 확인하세요)
                    (Route<dynamic> route) => false,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("로그아웃 되었습니다.")),
              );
            },
          ),
          _buildSettingRow(
            context: context,
            title: '회원 탈퇴',
            onTap: () async {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DeleteAccountScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // 이 함수는 ListView 밖에 있기 때문에 그대로 둡니다. (만약 UI에 사용된다면)
  Widget _notificationSettingButton(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            SvgPicture.asset(AppAssets.Bell),
            Space.xf(),
            Text("알림", style: AppText.b1b),
          ],
        ),
        TextButton.icon(
          onPressed: () {
            Navigator.of(context).pushNamed(AppRouter.notificationSettings);
          },
          icon: const Icon(Icons.settings, color: Colors.black),
          label: Text(
            "알림 설정 열기",
            style: AppText.b2?.copyWith(color: Colors.black),
          ),
        ),
      ],
    );
  }
}