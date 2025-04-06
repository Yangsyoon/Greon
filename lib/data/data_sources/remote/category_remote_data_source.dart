import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/error/failures.dart';
import '../../models/category/category_model.dart';

abstract class CategoryRemoteDataSource {
  Future<List<CategoryModel>> getCategories();
}

class CategoryRemoteDataSourceImpl implements CategoryRemoteDataSource {
  final FirebaseFirestore firestore;
  CategoryRemoteDataSourceImpl({required this.firestore});
  @override
  Future<List<CategoryModel>> getCategories() async {
    try {
      final QuerySnapshot querySnapshot =
          await firestore.collection('categories').get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        print(
            'Category loaded - Name: ${data['name']}, Image URL: ${data['image']}');
        return CategoryModel(
          name: data['name'] ?? '',
          image: data['image'] ?? '',
          createdAt:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          updatedAt:
              (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          isActive: data['isActive'] ?? true,
        );
      }).toList();
    } catch (e) {
      print('Failed to load categories: $e');
      throw ServerFailure();
    }
  }
}
