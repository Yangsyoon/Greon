import 'package:equatable/equatable.dart';

import '../category/category.dart';

import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductEntity extends Equatable {
  final String id;
  final String name;
  final String description;
  final int price;
  final List<Category> categories;
  final List<String> images;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  const ProductEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.categories,
    required this.images,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
  });

  @override
  List<Object?> get props => [id];
}