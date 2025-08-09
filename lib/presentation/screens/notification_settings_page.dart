import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../configs/app_typography.dart';
import '../../configs/space.dart';
import '../../core/constant/assets.dart';
import '../../core/constant/colors.dart';


class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});

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
            openAppSettings(); // 시스템 설정으로 이동
          },
          icon: Icon(Icons.settings, color: Colors.black),
          label: Text(
            "알림 설정 열기",
            style: AppText.b2?.copyWith(color: Colors.black),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('알림 설정')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _notificationSettingButton(context),
      ),
    );
  }
}
