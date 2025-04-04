import '../../../domain/entities/category/category.dart';

class FilterProductParams {
  final String? keyword;
  final List<Category> categories;
  final double minPrice;
  final double maxPrice;
  final int? limit;
  final int? pageSize;

  const FilterProductParams({
    this.keyword = '',
    this.categories = const [],
    this.minPrice = 0,
    this.maxPrice = 10000,
    this.limit = 0,
    this.pageSize = 10,
  });

  FilterProductParams copyWith({
    String? keyword,
    List<Category>? categories,
    double? minPrice,
    double? maxPrice,
    int? limit,
    int? pageSize,
  }) {
    return FilterProductParams(
      keyword: keyword ?? this.keyword,
      categories: categories ?? this.categories,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      limit: limit ?? this.limit, // ✅ 여기서 limit을 그대로 유지
      pageSize: pageSize ?? this.pageSize,
    );
  }

  @override
  String toString() {
    return 'FilterProductParams(keyword: $keyword, categories: $categories, minPrice: $minPrice, maxPrice: $maxPrice, limit: $limit, pageSize: $pageSize)';
  }
}

