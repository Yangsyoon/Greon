import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

import '../../application/cart_bloc/cart_bloc.dart';
import '../../configs/configs.dart';
import '../../core/constant/assets.dart';
import '../../core/constant/colors.dart';
import '../../domain/entities/cart/cart_item.dart';

class QuantityRow extends StatelessWidget {
  final int quantity;
  final double padding;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  const QuantityRow({
    super.key,
    required this.quantity,
    required this.padding,
    required this.onIncrease,
    required this.onDecrease,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onDecrease,
          child: Container(
            width: AppDimensions.normalize(15), // 기존보다 작게
            height: AppDimensions.normalize(15),
            decoration: BoxDecoration(
              color: AppColors.CommonCyan,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: SvgPicture.asset(
                AppAssets.Minus,
                color: Colors.white,
                height: 10,
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: Text(
            "$quantity",
            style: AppText.h3b,
          ),
        ),
        GestureDetector(
          onTap: onIncrease,
          child: Container(
            width: AppDimensions.normalize(15),
            height: AppDimensions.normalize(15),
            decoration: BoxDecoration(
              color: AppColors.CommonCyan,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: SvgPicture.asset(
                AppAssets.Plus,
                color: Colors.white,
                height: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
