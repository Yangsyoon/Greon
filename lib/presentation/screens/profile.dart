import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:greon/configs/app_dimensions.dart';
import 'package:greon/configs/configs.dart';
import 'package:greon/core/constant/assets.dart';
import 'package:greon/presentation/widgets/top_row.dart';
import 'package:greon/presentation/widgets/unlogged_profile_container.dart';
import 'package:greon/presentation/widgets/user_logged_profile_container.dart';
import 'package:greon/presentation/screens/user_info_input_page.dart';


import '../../application/user_bloc/user_bloc.dart';
import '../../core/constant/colors.dart';
import '../../core/router/app_router.dart';

//TODO refactor and minimize code of this screen

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SvgPicture _arrowforward = SvgPicture.asset(
      AppAssets.LeftArrow,
      width: AppDimensions.normalize(6),
    );
    return Scaffold(
      body: Padding(
        padding: Space.hf(1.1),
        child: SafeArea(
          minimum: EdgeInsets.only(top: AppDimensions.normalize(20)),
          child: Column(
            children: [
              TopRow(isFromHome: false, context: context),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Space.y!,
                      BlocBuilder<UserBloc, UserState>(
                        builder: (context, state) {
                          if (state is UserLogged) {
                            // Firestore에서 imageUrl을 잘 받아왔는지 확인
                            return userLoggedProfileContainer(context,
                                "${state.user.fullName}", state.user.email, state.user.image,);
                          } else {
                            return unloggedProfileContainer(context);
                          }
                        },
                      ),
                      BlocBuilder<UserBloc, UserState>(
                          builder: (context, state) {
                        if (state is UserLogged) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pushNamed(AppRouter.myPlants);
                                },
                                child: Container(
                                  margin: EdgeInsets.only(bottom: AppDimensions.normalize(5)),
                                  padding: EdgeInsets.symmetric(
                                    vertical: AppDimensions.normalize(4),
                                    horizontal: AppDimensions.normalize(10),
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(AppDimensions.normalize(5)),
                                  ),
                                  child: Text(
                                    '내 식물 보기',
                                    style: TextStyle(
                                      color: AppColors.CommonCyan,
                                      fontSize: AppDimensions.normalize(8),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              // ✅ 여기에 '내 식물 추가' 버튼 추가
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pushNamed(AppRouter.registerPlant); // 라우트 이름 확인
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: AppDimensions.normalize(4),
                                    horizontal: AppDimensions.normalize(10),
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.CommonCyan,
                                    borderRadius: BorderRadius.circular(AppDimensions.normalize(5)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.add, color: Colors.white, size: AppDimensions.normalize(8)),
                                      SizedBox(width: AppDimensions.normalize(3)),
                                      Text(
                                        "내 식물 추가",
                                        style: AppText.b1?.copyWith(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              Space.yf(1.3), // 버튼과 "MY ACCOUNT" 사이 여백
                              Text(
                                "MY ACCOUNT",
                                style: AppText.h3b
                                    ?.copyWith(color: AppColors.CommonCyan),
                              ),
                              Space.yf(.9),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context)
                                      .pushNamed(AppRouter.orders);
                                },
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        SvgPicture.asset(AppAssets.Archive),
                                        Space.xf(),
                                        Text(
                                          "My Orders",
                                          style: AppText.b1b,
                                        )
                                      ],
                                    ),
                                    _arrowforward
                                  ],
                                ),
                              ),
                              Space.yf(1.1),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context)
                                      .pushNamed(AppRouter.addresses);
                                },
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        SvgPicture.asset(AppAssets.Marker),
                                        Space.xf(),
                                        Text(
                                          "Address Book",
                                          style: AppText.b1b,
                                        )
                                      ],
                                    ),
                                    _arrowforward
                                  ],
                                ),
                              ),
                              Space.yf(1.1),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      SvgPicture.asset(
                                        AppAssets.Profile,
                                        // color: AppColors.CommonCyan,
                                        colorFilter: const ColorFilter.mode(
                                            AppColors.CommonCyan,
                                            BlendMode.srcIn),
                                      ),
                                      Space.xf(),
                                      Text(
                                        "Edit Account",
                                        style: AppText.b1b,
                                      )
                                    ],
                                  ),
                                  _arrowforward
                                ],
                              ),
                              Space.yf(1.1),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      SvgPicture.asset(AppAssets.Lock),
                                      Space.xf(),
                                      Text(
                                        "Change Password",
                                        style: AppText.b1b,
                                      )
                                    ],
                                  ),
                                  _arrowforward
                                ],
                              ),
                              Space.yf(1.1),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => UserInfoInputPage()),
                                  );
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.info_outline, color: AppColors.CommonCyan),
                                        Space.xf(),
                                        Text(
                                          "회원 정보 입력",
                                          style: AppText.b1b,
                                        )
                                      ],
                                    ),
                                    _arrowforward
                                  ],
                                ),
                              ),

                            ],
                          );
                        } else {
                          return const SizedBox.shrink();
                        }
                      }),
                      Space.yf(1.9),
                      Text(
                        "SETTINGS",
                        style:
                            AppText.h3b?.copyWith(color: AppColors.CommonCyan),
                      ),
                      Space.yf(.9),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context)
                              .pushNamed(AppRouter.notifications);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                SvgPicture.asset(AppAssets.Bell),
                                Space.xf(),
                                Text(
                                  "Notifications",
                                  style: AppText.b1b,
                                )
                              ],
                            ),
                            SizedBox(
                              height: AppDimensions.normalize(10),
                              child: Switch(
                                value: true,
                                onChanged: null,
                                activeTrackColor: AppColors.CommonCyan,
                                thumbColor:
                                    MaterialStateProperty.all(Colors.white),
                              ),
                            )
                          ],
                        ),
                      ),
                      Space.yf(1.1),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SvgPicture.asset(AppAssets.Globe),
                              Space.xf(),
                              Text(
                                "Preferred Language",
                                style: AppText.b1b,
                              )
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                "English",
                                style: AppText.b2b
                                    ?.copyWith(color: AppColors.CommonCyan),
                              ),
                              Space.xf(.2),
                              _arrowforward
                            ],
                          ),
                        ],
                      ),
                      Space.yf(1.2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SvgPicture.asset(AppAssets.Money),
                              Space.xf(),
                              Text(
                                "Currency",
                                style: AppText.b1b,
                              )
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                "Dollars",
                                style: AppText.b2b
                                    ?.copyWith(color: AppColors.CommonCyan),
                              ),
                              Space.xf(.2),
                              _arrowforward
                            ],
                          ),
                        ],
                      ),
                      Space.yf(2),
                      Text(
                        "SUPPORT",
                        style:
                            AppText.h3b?.copyWith(color: AppColors.CommonCyan),
                      ),
                      Space.yf(1.2),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushNamed(AppRouter.appinfo,
                              arguments: "TERMS & CONDITIONS");
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                SvgPicture.asset(AppAssets.Document),
                                Space.xf(),
                                Text(
                                  "Terms & Conditions",
                                  style: AppText.b1b,
                                )
                              ],
                            ),
                            _arrowforward
                          ],
                        ),
                      ),
                      Space.yf(1.1),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushNamed(AppRouter.appinfo,
                              arguments: "PRIVACY POLICY");
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                SvgPicture.asset(AppAssets.Document),
                                Space.xf(),
                                Text(
                                  "Privacy Policy",
                                  style: AppText.b1b,
                                )
                              ],
                            ),
                            _arrowforward
                          ],
                        ),
                      ),
                      Space.yf(1.1),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushNamed(AppRouter.contact);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                SvgPicture.asset(AppAssets.Comments),
                                Space.xf(),
                                Text(
                                  "Contact",
                                  style: AppText.b1b,
                                )
                              ],
                            ),
                            _arrowforward
                          ],
                        ),
                      ),
                      Space.yf(2.9),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "V.1.0",
                            style: AppText.b1b,
                          )
                        ],
                      ),
                      Space.yf(.3),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            AppAssets.Whats,
                            height: AppDimensions.normalize(15),
                          ),
                          SvgPicture.asset(
                            AppAssets.Noti,
                            height: AppDimensions.normalize(15),
                          ),
                          SvgPicture.asset(
                            AppAssets.Music,
                            height: AppDimensions.normalize(15),
                          ),
                        ],
                      ),
                      Space.yf(1.3),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}


