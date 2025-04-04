import '../../../domain/entities/product/pagination_meta_data.dart';

class PaginationMetaDataModel extends PaginationMetaData {
  PaginationMetaDataModel({
    required int page,
    required int pageSize,
    required int total,
  }) : super(
    limit: page,
    pageSize: pageSize,
    total: total,
  );

  /// **🔹 `PaginationMetaData` → `PaginationMetaDataModel` 변환**
  factory PaginationMetaDataModel.fromEntity(PaginationMetaData entity) {
    return PaginationMetaDataModel(
      page: entity.limit, // limit을 page로 매핑
      pageSize: entity.pageSize,
      total: entity.total,
    );
  }

  factory PaginationMetaDataModel.fromJson(Map<String, dynamic> json) => PaginationMetaDataModel(
    page: json["page"],
    pageSize: json["pageSize"],
    total: json["total"],
  );

  Map<String, dynamic> toJson() => {
    "page": limit, // page를 limit에서 변환
    "pageSize": pageSize,
    "total": total,
  };
}
