import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:greon/configs/configs.dart';
import 'package:greon/presentation/widgets/transparent_button.dart';

import '../../application/bottom_navbar_cubit/bottom_navbar_cubit.dart';
import '../../core/enums/enums.dart';
import '../../core/router/app_router.dart';
import '../screens/cart.dart';
import '../screens/product/products_list.dart';

Future<void> showPoceedtoCartBottomSheet(BuildContext context) async {
  return showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xfff6f6f6),
    constraints: BoxConstraints(
        minHeight: AppDimensions.normalize(120), maxWidth: double.infinity),
    builder: (BuildContext context) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            top: AppDimensions.normalize(12),
            left: AppDimensions.normalize(8),
            right: AppDimensions.normalize(8),
            bottom: AppDimensions.normalize(5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                "계속하기",
                style: AppText.h3b,
              ),
              Space.yf(1),
              const Text("제품이 장바구니에 담겼습니다."),
              Space.yf(2),
              transparentButton(
                  context: context,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CartScreen(),
                      ),
                    );
                  },
                  buttonText: "장바구니로 가기"),
              Space.yf(1.5),
              SizedBox(
                width: double.infinity,
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
                    "쇼핑 계속하기",
                    style: AppText.h3b?.copyWith(color: Colors.black),
                  ),
                ),
              )
            ],
          ),
        ),
      );
    },
  );
}
