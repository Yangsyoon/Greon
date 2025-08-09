import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../configs/app_typography.dart';
import '../../configs/space.dart';
import '../../core/constant/assets.dart';
import '../../core/constant/colors.dart';
import '../../core/router/app_router.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Widget _buildSettingRow({
    required BuildContext context,
    required String title,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height:60,
    child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE0E0E0)),
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
      ),
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '내 정보',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 12),
          _buildSettingRow(
            context: context,
            title: '회원 정보 수정',
            onTap: () => Navigator.pushNamed(context, '/user_info_input'),
          ),
          const SizedBox(height: 12),
          _buildSettingRow(
            context: context,
            title: '배송지 관리',
            onTap: () => Navigator.pushNamed(context, '/addresses'),
          ),
          const SizedBox(height: 12),
          _buildSettingRow(
            context: context,
            title: '맞춤 정보',
            onTap: () => Navigator.pushNamed(context, '/custom_info'),
          ),
          const SizedBox(height: 12),
          _buildSettingRow(
            context: context,
            title: '알림 설정',
            onTap: () => Navigator.of(context).pushNamed(AppRouter.notificationSettings),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          const Text(
            '계정',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 12),
          _buildSettingRow(
            context: context,
            title: '비밀번호 변경',
            onTap: () => Navigator.pushNamed(context, '/change_password'),
          ),
          const SizedBox(height: 12),
          _buildSettingRow(
            context: context,
            title: '로그아웃',
            onTap: () {
              // 로그아웃 처리
            },
          ),
        ],
      ),
    );
  }
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
          icon: Icon(Icons.settings, color: AppColors.CommonCyan),
          label: Text(
            "알림 설정 열기",
            style: AppText.b2?.copyWith(color: AppColors.CommonCyan),
          ),
        ),
      ],
    );
  }

}

