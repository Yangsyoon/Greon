import '../../../domain/entities/category/category.dart';
import '../../../domain/entities/product/product.dart';

class FilterProductParams {
  final String? keyword;
  final List<Category> categories;
  final double minPrice;
  final double maxPrice;
  final int? limit;
  final int? pageSize;
  final List<ProductEntity> products; // 🔍 검색 결과

  const FilterProductParams({
    this.keyword = '',
    this.categories = const [],
    this.minPrice = 0,
    this.maxPrice = 10000,
    this.limit = 0,
    this.pageSize = 10,
    this.products = const [], // 🔍 기본 빈 리스트
  });

  FilterProductParams copyWith({
    String? keyword,
    List<Category>? categories,
    double? minPrice,
    double? maxPrice,
    int? limit,
    int? pageSize,
    List<ProductEntity>? products, // ✅ 추가됨
  }) {
    return FilterProductParams(
      keyword: keyword ?? this.keyword,
      categories: categories ?? this.categories,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      limit: limit ?? this.limit,
      pageSize: pageSize ?? this.pageSize,
      products: products ?? this.products, // ✅ 포함
    );
  }

  factory FilterProductParams.initial() {
    return const FilterProductParams(
      keyword: '',
      categories: [],
      minPrice: 0,
      maxPrice: 10000,
      limit: 0,
      pageSize: 10,
      products: [],
    );
  }

  @override
  String toString() {
    return 'FilterProductParams(keyword: $keyword, categories: $categories, minPrice: $minPrice, maxPrice: $maxPrice, limit: $limit, pageSize: $pageSize, products: $products)';
  }
}
