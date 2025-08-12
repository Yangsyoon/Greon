import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../domain/entities/category/category.dart';
import '../../data/models/product/filter_params_model.dart';
import '../../domain/entities/product/product.dart';

class FilterCubit extends Cubit<FilterProductParams> {
  final TextEditingController productsSearchController = TextEditingController();
  final FirebaseFirestore firestore;
  FilterCubit({required this.firestore}) : super(FilterProductParams.initial());

  bool isSelectedCategory(Category category) {
    return state.categories.contains(category);
  }

  void update({
    String? keyword,
    List<Category>? categories,
    Category? category,
  }) {
    List<Category> updatedCategories = [];
    if (category != null) {
      updatedCategories.add(category);
    } else if (categories != null) {
      updatedCategories.addAll(categories);
    } else {
      updatedCategories.addAll(state.categories);
    }
    emit(state.copyWith(
      keyword: keyword ?? state.keyword,
      categories: updatedCategories,
    ));
  }

  void updateCategory({
    required Category category,
  }) {
    List<Category> updatedCategories = [];
    updatedCategories.addAll(state.categories);
    if (updatedCategories.contains(category)) {
      updatedCategories.remove(category);
    } else {
      updatedCategories.add(category);
    }
    emit(state.copyWith(
      categories: updatedCategories,
    ));
  }

  void updateRange(double min, double max) => emit(state.copyWith(
        minPrice: min,
        maxPrice: max,
      ));

  int getFiltersCount() {
    int count = 0;
    count = (state.categories.length) + count;
    count = count + ((state.minPrice!=0 || state.maxPrice!=10000)? 1 : 0);
    return count;
  }

  void reset() => emit(const FilterProductParams());

  Future<void> applySearch(String keyword) async {
    try {
      final snapshot = await firestore.collection('products').get();

      final futures = snapshot.docs.map((doc) {
        return ProductEntity.fromMapAsync(doc.data(), docId: doc.id);
      });

      final products = await Future.wait(futures);

      if (keyword.trim().isEmpty) {
        // 검색어 없으면 전체 상품
        emit(state.copyWith(products: products));
        return;
      }

      // 검색어 있는 경우 필터링
      final filtered = products.where((product) {
        final containsKeyword = product.name.contains(keyword);
        return containsKeyword;
      }).toList();

      emit(state.copyWith(products: filtered));
    } catch (e, stackTrace) {
      debugPrint('검색 오류 발생: $e');
      debugPrint('$stackTrace');
      emit(state.copyWith(products: []));
    }
  }


}
