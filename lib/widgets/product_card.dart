import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:moegyi/constants.dart';
import 'package:moegyi/providers/cart_provider.dart';
import 'package:moegyi/screens/user/product_detail_screen.dart';
import 'package:provider/provider.dart';

class ProductCard extends StatelessWidget {
  final QueryDocumentSnapshot product;

  const ProductCard({super.key, required this.product});

  // Helper function to get category name from categoryId
  Future<String> _getCategoryName(String categoryId) async {
    if (categoryId.isEmpty) {
      return 'Uncategorized';
    }
    try {
      final categoryDoc = await FirebaseFirestore.instance
          .collection('categories')
          .doc(categoryId)
          .get();
      if (categoryDoc.exists) {
        return categoryDoc.data()?['name'] ?? 'Uncategorized';
      }
    } catch (e) {
      print('Error fetching category: $e');
    }
    return 'Uncategorized';
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<CartProvider>(context, listen: false);
    final theme = Theme.of(context);

    final productData = product.data() as Map<String, dynamic>;

    final imageUrl = productData[Constants.productImageUrl] as String?;
    final name = productData[Constants.productName] as String? ?? 'No Name';
    final categoryId =
        productData['categoryId'] as String? ?? ''; // Changed to categoryId
    final price = (productData[Constants.productPrice] ?? 0).toDouble();

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(productId: product.id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Hero(
                  tag: 'product-image-${product.id}',
                  child: (imageUrl != null && imageUrl.isNotEmpty)
                      ? (imageUrl.startsWith('data:image'))
                            ? Image.memory(
                                base64.decode(imageUrl.split(',').last),
                                fit: BoxFit.cover,
                              )
                            : Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          value:
                                              loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                              : null,
                                        ),
                                      );
                                    },
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                      Icons.broken_image,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                              )
                      : Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.shopping_bag,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    FutureBuilder<String>(
                      future: _getCategoryName(categoryId),
                      builder: (context, snapshot) {
                        final categoryName =
                            snapshot.data ?? ' '; // Show space while loading
                        return Text(
                          categoryName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color
                                ?.withOpacity(0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${price.toStringAsFixed(0)} Kyat',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
