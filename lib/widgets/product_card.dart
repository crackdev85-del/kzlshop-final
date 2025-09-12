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

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final theme = Theme.of(context);

    final productData = product.data() as Map<String, dynamic>;

    final imageUrl = productData[Constants.productImageUrl] as String?;
    final name = productData[Constants.productName] as String? ?? 'No Name';
    final price = (productData[Constants.productPrice] ?? 0).toDouble();

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(productId: product.id),
          ),
        );
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 4.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image, size: 40),
                            )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.shopping_bag,
                          color: Colors.grey,
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2, // Allow up to 2 lines
                    overflow: TextOverflow.ellipsis, // Add ellipsis if text overflows
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${price.toStringAsFixed(2)} Kyat',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 4.0,
                vertical: 4.0,
              ),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () {
                  // FIX: Pass the entire product object as a single positional argument.
                  cart.addItem(product);

                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$name has been added to the cart!'),
                      duration: const Duration(seconds: 2),
                      action: SnackBarAction(
                        label: 'UNDO',
                        onPressed: () {
                          cart.removeSingleItem(product.id);
                        },
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.add_shopping_cart, size: 18),
                label: const Text('Add to Cart'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
