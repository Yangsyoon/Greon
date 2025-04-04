class PaginationMetaData {
  final int limit;
  final int pageSize;
  final int total;

  PaginationMetaData({
    required this.limit,
    required this.pageSize,
    required this.total,
  });

  PaginationMetaData copyWith({
    int? pageSize,
    int? limit,
    int? total,
  }) {
    return PaginationMetaData(
      pageSize: pageSize ?? this.pageSize,
      limit: limit ?? this.limit,
      total: total ?? this.total,
    );
  }
}