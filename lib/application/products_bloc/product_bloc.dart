import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../domain/entities/product/pagination_meta_data.dart';
import '../../../domain/entities/product/product.dart';
import '../../../domain/usecases/product/get_product_usecase.dart';
import '../../core/enums/enums.dart';
import '../../core/error/failures.dart';
import '../../data/models/product/filter_params_model.dart';
import '../../domain/entities/product/price_tag.dart';
import '../../data/models/product/product_model.dart';

import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';

part 'product_event.dart';

part 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final GetProductUseCase _getProductUseCase;

  ProductBloc(this._getProductUseCase)
      : super(ProductInitial(
    products: const [],
    params: const FilterProductParams(),
    metaData: PaginationMetaData(
      pageSize: 20,
      limit: 0,
      total: 0,
    ),
  )) {
    on<GetProducts>(_onLoadProducts);
    on<GetMoreProducts>(_onLoadMoreProducts);
    on<SortProducts>(_onSortProducts);
  }

  void _onLoadProducts(GetProducts event, Emitter<ProductState> emit) async {
    try {
      debugPrint('🛠 GetProducts 이벤트 발생! 필터: ${event.params}');

      emit(ProductLoading(
        products: state.products,
        metaData: state.metaData,
        params: event.params,
      ));

      final result = await _getProductUseCase(event.params);
      result.fold(
            (failure) {
          debugPrint('❌ 상품 로딩 실패: $failure');
          emit(ProductError(
            products: state.products,
            metaData: state.metaData,
            failure: failure,
            params: event.params,
          ));
        },
            (productResponse) {
          debugPrint('✅ 상품 로딩 성공! 상품 개수: ${productResponse.products.length}');
          emit(ProductLoaded(
            metaData: productResponse.paginationMetaData,
            products: productResponse.products,
            params: event.params,
          ));
        },
      );
    } catch (e, stacktrace) {
      debugPrint('🔥 예외 발생: $e');
      debugPrint('📜 스택 트레이스: $stacktrace');
      emit(ProductError(
        products: state.products,
        metaData: state.metaData,
        failure: ExceptionFailure(),
        params: event.params,
      ));
    }
  }

  void _onSortProducts(SortProducts event, Emitter<ProductState> emit) {
    if (event.sortOrder != null) {
      List<ProductEntity> sortedProducts = List.from(state.products);
      sortedProducts.sort((a, b) {
        int getPrice(PriceTag priceTag) => priceTag.price.toInt();

        switch (event.sortOrder!) {
          case SortOrder.newest:
            return b.createdAt.compareTo(a.createdAt);
          case SortOrder.highToLow:
            return getPrice(b.priceTags.first).compareTo(getPrice(a.priceTags.first));
          case SortOrder.lowToHigh:
            return getPrice(a.priceTags.first).compareTo(getPrice(b.priceTags.first));
          case SortOrder.aToZ:
            return a.name.compareTo(b.name);
          case SortOrder.zToA:
            return b.name.compareTo(a.name);
        }
      });

      debugPrint('🔄 상품 정렬 완료: ${event.sortOrder}');
      emit(ProductLoaded(
        metaData: state.metaData,
        products: sortedProducts,
        params: state.params,
      ));
    }
  }

  void _onLoadMoreProducts(GetMoreProducts event, Emitter<ProductState> emit) async {
    var limit = state.metaData.limit;
    var total = state.metaData.total;
    var loadedProductsLength = state.products.length;

    if (state is ProductLoaded && (loadedProductsLength < total)) {
      try {
        debugPrint('🔽 더 많은 상품 로딩 중...');

        emit(ProductLoading(
          products: state.products,
          metaData: state.metaData,
          params: state.params,
        ));

        final result = await _getProductUseCase(state.params.copyWith(limit: limit + 10));
        result.fold(
              (failure) {
            debugPrint('❌ 추가 상품 로딩 실패: $failure');
            emit(ProductError(
              products: state.products,
              metaData: state.metaData,
              failure: failure,
              params: state.params,
            ));
          },
              (productResponse) {
            List<ProductEntity> products = List.from(state.products);
            products.addAll(productResponse.products);

            debugPrint('✅ 추가 상품 로딩 완료! 총 개수: ${products.length}');
            emit(ProductLoaded(
              metaData: state.metaData.copyWith(limit: limit + 10),
              products: products,
              params: state.params,
            ));
          },
        );
      } catch (e, stacktrace) {
        debugPrint('🔥 추가 상품 로딩 중 예외 발생: $e');
        debugPrint('📜 스택 트레이스: $stacktrace');
        emit(ProductError(
          products: state.products,
          metaData: state.metaData,
          failure: ExceptionFailure(),
          params: state.params,
        ));
      }
    }
  }
}
