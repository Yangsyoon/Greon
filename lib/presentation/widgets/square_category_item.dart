import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:greon/configs/app.dart';
import 'package:greon/configs/app_dimensions.dart';
import 'package:greon/configs/configs.dart';
import 'package:greon/presentation/widgets/loading_shimmer.dart';
import 'package:shimmer/shimmer.dart';

import '../../application/bottom_navbar_cubit/bottom_navbar_cubit.dart';
import '../../application/filter_cubit/filter_cubit.dart';
import '../../application/products_bloc/product_bloc.dart';
import '../../core/constant/colors.dart';
import '../../core/enums/enums.dart';
import '../../data/models/category/category_model.dart';
import '../../domain/entities/category/category.dart';

class SquareCategoryItem extends StatelessWidget {
  const SquareCategoryItem({super.key, this.category});

  final CategoryModel? category; // Category를 CategoryModel로 수정

  @override
  Widget build(BuildContext context) {
    App.init(context);
    return category != null
        ? GestureDetector(
      onTap: () {
        context
            .read<NavigationCubit>()
            .updateTab(NavigationTab.productsTap);
        context.read<FilterCubit>().update(category: category);
        context
            .read<ProductBloc>()
            .add(GetProducts(context.read<FilterCubit>().state));
      },
      child: Padding(
        padding: EdgeInsets.only(right: AppDimensions.normalize(5)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration:
              BoxDecoration(border: Border.all(color: Colors.grey)),
              child: CachedNetworkImage(
                height: AppDimensions.normalize(70),
                width: AppDimensions.normalize(70),
                imageUrl: category!.image, // Image URL 수정
                fit: BoxFit.cover,
                placeholder: (context, url) => placeholderShimmer(),
                errorWidget: (context, url, error) =>
                const Center(child: Icon(Icons.error)),
              ),
            ),
            Space.y1!,
            Text(
              category!.name.toUpperCase(), // CategoryModel의 name 사용
              style: AppText.h2b?.copyWith(color: AppColors.GreyText),
            )
          ],
        ),
      ),
    )
        : LoadingShimmer(isSquare: true);
  }
}

