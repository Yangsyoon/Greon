import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/bottom_navbar_cubit/bottom_navbar_cubit.dart';
import '../../configs/configs.dart';
import '../../core/constant/colors.dart';
import '../../core/enums/enums.dart';
import '../screens/product/products_list.dart';

Widget emptyCartContainer(BuildContext context) {
  return Container(
    color: AppColors.LightGrey,
    margin: EdgeInsets.only(top: AppDimensions.normalize(60)),
    //  height: AppDimensions.normalize(45),
    padding: Space.all(1, 2.5),
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "카트에 아이템이 없습니다",
            style: AppText.h3b?.copyWith(color: Colors.black),
          ),
          Space.yf(),
          Text(
            "구매하고자 하는 상품을",
            style: AppText.b1,
          ),
          Space.yf(),
          Text(
            "카트에서 찾지 못했습니다.",
            style: AppText.b1,
          ),
          Space.yf(1.5),
          SizedBox(
            width: AppDimensions.normalize(100),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProductsListScreen(),
                  ),
                );
              },

              child: Text(
                "아이템 추가하러 가기",
                style: AppText.h3b?.copyWith(color: Colors.black),
              ),
            ),
          )
        ],
      ),
    ),
  );
}
