import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;


import '../../../application/products_bloc/product_bloc.dart';
import '../../../core/constant/api.dart';
import '../../../core/error/exceptions.dart';
import '../../../core/error/failures.dart';
import '../../../di/di.dart';
import '../../../domain/entities/product/pagination_meta_data.dart';
import '../../../domain/repositories/product_repository.dart';
import '../../../domain/usecases/product/get_product_usecase.dart';
import '../../models/product/filter_params_model.dart';
import '../../models/product/product_model.dart';
import '../../models/product/product_response_model.dart';


import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../repositories/product_repository_impl.dart';
import '../local/product_local_data_source.dart';

abstract class ProductRemoteDataSource {
  Future<ProductResponseModel> getProducts(FilterProductParams params);
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final FirebaseFirestore firestore;
  final http.Client client;

  ProductRemoteDataSourceImpl({required this.firestore, required this.client});

  @override
  Future<ProductResponseModel> getProducts(FilterProductParams params) async {
    try {
      return await _getProductsFromFirestore(params);
    } catch (e, stackTrace) {
      print("❌ getProducts() 실패: $e");
      print("📌 StackTrace: $stackTrace");
      throw ServerFailure(message: e.toString());
    }
  }

  Future<ProductResponseModel> _getProductsFromFirestore(FilterProductParams params) async {
    try {
      Query query = firestore.collection("products");

      if (params.keyword != null && params.keyword!.isNotEmpty) {
        query = query.where("name", isGreaterThanOrEqualTo: params.keyword);
      }

      List<QuerySnapshot> snapshots = [];
      if (params.categories != null && params.categories.isNotEmpty) {
        List<List<String>> categoryChunks = [];
        for (var i = 0; i < params.categories.length; i += 10) {
          categoryChunks.add(params.categories.skip(i).take(10).map((e) => e.name).toList());
        }

        snapshots = await Future.wait(categoryChunks.map((chunk) {
          return firestore.collection("products")
              .where("category", whereIn: chunk)
              .limit(params.pageSize ?? 10)
              .get();
        }));
      } else {
        snapshots.add(await query.limit(params.pageSize ?? 10).get());
      }

      final docs = snapshots.expand((snapshot) => snapshot.docs).toList();
      return _processDocuments(docs, params.pageSize);
    } catch (e, stackTrace) {
      print("❌ Firestore에서 제품 로드 실패: $e");
      print("📌 StackTrace: $stackTrace");
      throw ServerFailure(message: e.toString());
    }
  }

  Future<ProductResponseModel> _processDocuments(List<QueryDocumentSnapshot> docs, int? pageSize) async {
    final products = await Future.wait(docs.map((doc) async {
      try {
        return await ProductModel.fromDocumentAsync(doc);
      } catch (e) {
        print("❌ Firestore 데이터 변환 실패: ${doc.id}, 오류: $e");
        return ProductModel.errorModel(doc.id);
      }
    }));

    return ProductResponseModel(
      meta: PaginationMetaData(
        pageSize: pageSize ?? 10,
        limit: products.length,
        total: docs.length,
      ),
      data: products,
    );
  }
}
