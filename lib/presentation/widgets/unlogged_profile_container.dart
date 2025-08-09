import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import 'package:greon/configs/configs.dart';
import 'package:greon/presentation/widgets/transparent_button.dart';

import '../../core/constant/assets.dart';
import '../../core/constant/colors.dart';
import '../../core/router/app_router.dart';

Widget unloggedProfileContainer(BuildContext context) {
  return Container(
    padding: Space.all(1.3, .7),
    width: double.infinity,
    decoration: BoxDecoration(
      image: DecorationImage(
        image: const AssetImage(AppAssets.Profile_bg_png),
        fit: BoxFit.fill,
        colorFilter:
            ColorFilter.mode(Colors.grey.shade700, BlendMode.colorBurn),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Space.y1!,
        SvgPicture.asset(
          AppAssets.Profile,
          colorFilter:
              const ColorFilter.mode(Colors.black, BlendMode.srcIn),
          height: AppDimensions.normalize(19),
        ),
        Space.y1!,
        Text(
          "로그인/회원가입",
          style: AppText.h2b,
        ),
        Space.yf(.9),
        Text(
          "Join The Hub!",
          style: AppText.b1,
        ),
        Space.yf(1.2),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushNamed(AppRouter.login);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              side: const BorderSide(color: Colors.black),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              minimumSize: const Size.fromHeight(50),
            ),
            child: Text(
              "로그인",
              style: AppText.h3b?.copyWith(color: Colors.black),
            ),
          ),
        ),
        Space.yf(1.1),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushNamed(AppRouter.signup);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white, // 흰 배경
              side: const BorderSide(color: Colors.black), // 검은 테두리
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              minimumSize: const Size.fromHeight(50),
            ),
            child: Text(
              "회원가입",
              style: AppText.h3b?.copyWith(color: Colors.black),
            ),
          ),
        ),

        Space.yf(.6)
      ],
    ),
  );
}
