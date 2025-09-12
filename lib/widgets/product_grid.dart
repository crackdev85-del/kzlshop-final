import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:moegyi/constants.dart';
import 'package:moegyi/widgets/product_card.dart';

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
        _cachedData = null; // Clear cache when category changes
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
        if (snapshot.connectionState == ConnectionState.waiting && _cachedData == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Something went wrong', style: theme.textTheme.bodyMedium));
        }

        if (snapshot.hasData) {
          _cachedData = snapshot.data!.docs; 
        }

        if (_cachedData == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_cachedData!.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                widget.categoryId == null ? 'No products available right now.' : 'No products in this category.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(12.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, 
            crossAxisSpacing: 10.0, 
            mainAxisSpacing: 10.0, 
            childAspectRatio: 0.6, 
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
