import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:moegyi/constants.dart';
import 'package:moegyi/widgets/product_card.dart';

class ProductGrid extends StatelessWidget {
  final String? categoryId;
  const ProductGrid({super.key, this.categoryId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Query productsQuery = FirebaseFirestore.instance
        .collection(productsCollectionPath)
        .orderBy('createdAt', descending: true);

    if (categoryId != null) {
      productsQuery = productsQuery.where(
        Constants.productCategoryId,
        isEqualTo: categoryId,
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: productsQuery.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          // Print the full error to the debug console to see the details
          debugPrint("Firestore Error in ProductGrid: ${snapshot.error}");
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              // Display a more informative error message to the user
              child: Text(
                'Error loading products. Please check the debug console for details.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
              ),
            ),
          );
        }

        final productDocs = snapshot.data?.docs ?? [];

        if (productDocs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                categoryId == null
                    ? 'No products available right now.'
                    : 'No products found in this category.',
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: 0.65,
          ),
          itemCount: productDocs.length,
          itemBuilder: (context, index) {
            final productDoc = productDocs[index];
            return ProductCard(product: productDoc);
          },
        );
      },
    );
  }
}
