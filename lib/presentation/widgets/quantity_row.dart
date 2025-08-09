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
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: onDecrease,
          child: Image.asset(
            'assets/images/minus.png',
            width: 20,   // 이미지 크기 조절 가능
            height: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$quantity',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: onIncrease,
          child: Image.asset(
            'assets/images/plus.png',
            width: 20,
            height: 20,
          ),
        ),
      ],
    );

  }
}
