
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:myapp/constants.dart';
import 'package:myapp/widgets/product_card.dart';

class ProductGrid extends StatefulWidget {
  final String? categoryId;
  const ProductGrid({super.key, this.categoryId});

  @override
  _ProductGridState createState() => _ProductGridState();
}

class _ProductGridState extends State<ProductGrid> {
  late Stream<QuerySnapshot> _stream;
  List<QueryDocumentSnapshot>? _cachedData; // Cache the data

  @override
  void initState() {
    super.initState();
    _stream = _getStream();
  }

  @override
  void didUpdateWidget(ProductGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.categoryId != oldWidget.categoryId) {
      setState(() {
        _stream = _getStream();
      });
    }
  }

  Stream<QuerySnapshot> _getStream() {
    Query productsQuery = FirebaseFirestore.instance.collection(productsCollectionPath).orderBy('name');
    if (widget.categoryId != null) {
      productsQuery = productsQuery.where(Constants.productCategoryId, isEqualTo: widget.categoryId);
    }
    return productsQuery.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<QuerySnapshot>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _cachedData = snapshot.data!.docs; // Update cache
        }

        if (snapshot.hasError) {
          return Center(child: Text('Something went wrong', style: theme.textTheme.bodyMedium));
        }

        if (_cachedData == null) {
          // Only show loader if we have never had data
          return const Center(child: CircularProgressIndicator());
        }

        if (_cachedData!.isEmpty) {
          return Center(
            child: Text(
              widget.categoryId == null ? 'No products available right now.' : 'No products in this category.',
              style: theme.textTheme.bodyMedium,
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(12.0), // Reduced padding
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // Display 3 items per row
            crossAxisSpacing: 12.0, // Adjust spacing
            mainAxisSpacing: 12.0, // Adjust spacing
            childAspectRatio: 0.65, // Adjust aspect ratio for a taller look
          ),
          itemCount: _cachedData!.length,
          itemBuilder: (context, index) {
            final productDoc = _cachedData![index];
            return ProductCard(product: productDoc);
          },
        );
      },
    );
  }
}
