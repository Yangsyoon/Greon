import 'package:flutter/material.dart';
import '../../../data/models/product/product_model.dart';

class RectangularProductItem extends StatelessWidget {
  final ProductModel product;
  final bool isFromWishlist;

  const RectangularProductItem({
    Key? key,
    required this.product,
    this.isFromWishlist = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Expanded(
            child: Image.network(
              product.images.isNotEmpty
                  ? product.images.first
                  : 'https://via.placeholder.com/150',
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              product.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
// TODO Implement this library.