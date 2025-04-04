import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:greon/configs/app.dart';
import 'package:greon/configs/configs.dart';
import '../../application/filter_cubit/filter_cubit.dart';
import '../../application/products_bloc/product_bloc.dart';
import '../../configs/app_dimensions.dart';
import '../../configs/app_typography.dart';
import '../../core/constant/colors.dart';
import '../../core/error/failures.dart';
import '../../data/models/product/filter_params_model.dart';
import '../widgets/rectangular_product_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/product/product_model.dart'; // ProductModel import

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ScrollController scrollController = ScrollController();
  String value = '';

  void _scrollListener() {
    double maxScroll = scrollController.position.maxScrollExtent;
    double currentScroll = scrollController.position.pixels;
    double scrollPercentage = 0.7;
    if (currentScroll > (maxScroll * scrollPercentage)) {
      if (context.read<ProductBloc>().state is ProductLoaded) {
        context.read<ProductBloc>().add(const GetMoreProducts());
      }
    }
  }

  @override
  void initState() {
    scrollController.addListener(_scrollListener);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    App.init(context);
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size(double.infinity, AppDimensions.normalize(24)),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding:
            EdgeInsets.symmetric(horizontal: AppDimensions.normalize(5)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    context
                        .read<FilterCubit>()
                        .productsSearchController
                        .clear();
                    context.read<FilterCubit>().update(keyword: '');
                    Navigator.of(context).pop();
                  },
                  child: const Icon(Icons.arrow_back),
                ),
                Space.xf(6),
                Text(
                  "SEARCH",
                  style: AppText.b1b?.copyWith(color: AppColors.GreyText),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppDimensions.normalize(5)),
        child: Column(
          children: [
            Space.yf(1.2),
            Row(
              children: [
                Container(
                  height: AppDimensions.normalize(20),
                  width: AppDimensions.normalize(95),
                  padding: Space.h1,
                  decoration:
                  BoxDecoration(border: Border.all(color: Colors.grey)),
                  child: Center(
                    child: TextField(
                      controller:
                      context.read<FilterCubit>().productsSearchController,
                      onChanged: (val) => setState(() {}),
                      onSubmitted: (val) {
                        setState(() {
                          value = val;
                        });
                        context.read<ProductBloc>().add(
                            GetProducts(FilterProductParams(keyword: val)));
                      },
                      cursorColor: AppColors.CommonCyan,
                      decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Search Here",
                          hintStyle: AppText.b1
                              ?.copyWith(fontWeight: FontWeight.w300)),
                    ),
                  ),
                ),
                Space.x!,
                Flexible(
                  child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          value = context
                              .read<FilterCubit>()
                              .productsSearchController
                              .text
                              .toString()
                              .trim();
                        });
                        context.read<ProductBloc>().add(
                            GetProducts(FilterProductParams(keyword: value)));
                      },
                      style: ButtonStyle(
                        minimumSize: MaterialStatePropertyAll(
                          Size(
                            AppDimensions.normalize(42),
                            AppDimensions.normalize(20),
                          ),
                        ),
                      ),
                      child: Text(
                        "Search",
                        style: AppText.h3b?.copyWith(color: Colors.white),
                      )),
                ),
              ],
            ),
            Space.yf(1.5),
            context.read<FilterCubit>().productsSearchController.text.isEmpty
                ? SizedBox.shrink()
                : Row(
              children: [
                Text(
                  "Search Results for ",
                  style: AppText.h3,
                ),
                Text(
                  "' $value '",
                  style: AppText.h3b,
                ),
              ],
            ),
            Space.yf(2),
            context.read<FilterCubit>().productsSearchController.text.isEmpty
                ? const SizedBox.shrink()
                : Expanded(
              child: BlocBuilder<ProductBloc, ProductState>(
                builder: (context, state) {
                  if (state is ProductLoaded && state.products.isEmpty) {
                    return Center(
                      child: Container(
                        height: AppDimensions.normalize(50),
                        width: AppDimensions.normalize(120),
                        decoration: const BoxDecoration(
                            color: AppColors.LightGrey),
                        child: Center(
                          child: Padding(
                            padding: Space.v2!,
                            child: Column(
                              children: [
                                Text(
                                  "NO RESULT FOUND",
                                  style: AppText.h3b
                                      ?.copyWith(color: AppColors.CommonCyan),
                                ),
                                Space.yf(),
                                const Text("There is no such product"),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                  if (state is ProductError && state.products.isEmpty) {
                    if (state.failure is NetworkFailure) {
                      return const Center(
                        child: Text("Network Error"),
                      );
                    }
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (state.failure is ServerFailure)
                          const Text("Products not found!"),
                        if (state.failure is CacheFailure)
                          const Text("Products not found!"),
                        IconButton(
                            onPressed: () {
                              context.read<ProductBloc>().add(
                                  GetProducts(FilterProductParams(
                                      keyword: context
                                          .read<FilterCubit>()
                                          .productsSearchController
                                          .text)));
                            },
                            icon: const Icon(Icons.refresh)),
                        SizedBox(
                          height:
                          MediaQuery.of(context).size.height * 0.1,
                        )
                      ],
                    );
                  }
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('products')
                        .where('name', isGreaterThanOrEqualTo: value)
                        .where('name', isLessThan: value + 'z')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(child: Text('에러 발생!'));
                      }

                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      if (snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Container(
                            height: AppDimensions.normalize(50),
                            width: AppDimensions.normalize(120),
                            decoration: const BoxDecoration(
                                color: AppColors.LightGrey),
                            child: Center(
                              child: Padding(
                                padding: Space.v2!,
                                child: Column(
                                  children: [
                                    Text(
                                      "NO RESULT FOUND",
                                      style: AppText.h3b
                                          ?.copyWith(color: AppColors.CommonCyan),
                                    ),
                                    Space.yf(),
                                    const Text("There is no such product"),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      final products = snapshot.data!.docs.map((doc) {
                        try {
                          final data = doc.data() as Map<String, dynamic>;
                          data["id"] = doc.id;
                          return ProductModel.fromJson(data);
                        } catch (e) {
                          print('ProductModel 변환 오류: $e');
                          return null;
                        }
                      }).whereType<ProductModel>().toList();



                      return GridView.builder(
                        itemCount: products.length,
                        controller: scrollController,
                        gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.55,
                          crossAxisSpacing: 6,
                        ),
                        physics: const ClampingScrollPhysics(),
                        shrinkWrap: true,
                        itemBuilder: (BuildContext context, int index) {
                          return RectangularProductItem(
                            product: products[index],
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}