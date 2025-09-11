import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myapp/constants.dart';
import 'package:myapp/providers/cart_provider.dart';
import 'package:myapp/screens/user/cart_screen.dart';
import 'package:myapp/widgets/fade_page_route.dart';
import 'package:provider/provider.dart';

// A new widget to fetch and display the category name from a categoryId.
class CategoryWidget extends StatelessWidget {
  final String? categoryId;

  const CategoryWidget({super.key, this.categoryId});

  @override
  Widget build(BuildContext context) {
    if (categoryId == null || categoryId!.isEmpty) {
      return const SizedBox.shrink(); // Don't show anything if there's no category
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection(categoriesCollectionPath).doc(categoryId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          // Don't show anything if the category is not found or still loading
          return const SizedBox.shrink(); 
        }

        final categoryData = snapshot.data!.data() as Map<String, dynamic>;
        final categoryName = categoryData['name'] ?? 'Uncategorized';

        return Chip(
          label: Text(categoryName),
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
          labelStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSecondaryContainer,
            fontWeight: FontWeight.w600,
          ),
          side: BorderSide(color: Theme.of(context).colorScheme.secondaryContainer),
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
        );
      },
    );
  }
}


class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _quantityController = TextEditingController(text: '1');

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Widget _buildErrorImage(double height) {
    return Container(
      height: height,
      width: double.infinity,
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.broken_image,
          size: 50,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cart = Provider.of<CartProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection(productsCollectionPath)
            .doc(widget.productId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Product not found'));
          }

          final productDocument = snapshot.data!;
          final productData = productDocument.data() as Map<String, dynamic>;

          final String name = productData[Constants.productName] ?? 'No Name';
          final String imageUrl = productData[Constants.productImageUrl] ?? '';
          final double price = (productData[Constants.productPrice] ?? 0.0).toDouble();
          final int stockQuantity = (productData[Constants.productQuantity] ?? 0) as int;
          final String description = productData[Constants.productDescription] ?? '';
          final String? categoryId = productData[Constants.productCategoryId];

          Widget imageWidget;
          const double imageHeight = 300;
          if (imageUrl.startsWith('data:image')) {
            try {
              final UriData? data = Uri.parse(imageUrl).data;
              if (data != null) {
                final Uint8List imageBytes = data.contentAsBytes();
                imageWidget = Image.memory(
                  imageBytes,
                  height: imageHeight,
                  width: double.infinity,
                  fit: BoxFit.cover,
                );
              } else {
                imageWidget = _buildErrorImage(imageHeight);
              }
            } catch (e) {
              imageWidget = _buildErrorImage(imageHeight);
            }
          } else if (imageUrl.startsWith('http')) {
             imageWidget = Image.network(
                imageUrl,
                fit: BoxFit.cover,
                height: imageHeight,
                width: double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return SizedBox(
                    height: imageHeight,
                    child: Center(child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                    )),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return _buildErrorImage(imageHeight);
                },
              );
          }
          
          else {
              imageWidget = _buildErrorImage(imageHeight);
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  child: Hero(
                    tag: 'product-image-${widget.productId}',
                    child: imageWidget,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CategoryWidget(categoryId: categoryId),
                      const SizedBox(height: 12),
                      Text(name, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('${price.toStringAsFixed(2)} Kyat', style: textTheme.headlineMedium?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        stockQuantity > 0 ? 'Available: $stockQuantity' : 'Out of Stock',
                        style: textTheme.bodyLarge?.copyWith(
                          color: stockQuantity > 0 ? Colors.green.shade700 : Colors.red.shade700,
                          fontWeight: FontWeight.bold
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Quantity:', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 80,
                              child: TextFormField(
                                controller: _quantityController,
                                keyboardType: TextInputType.number,
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Enter a quantity';
                                  }
                                  final int? quantity = int.tryParse(value);
                                  if (quantity == null || quantity <= 0) {
                                    return 'Invalid';
                                  }
                                  if (quantity > stockQuantity) {
                                    return 'Over stock';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: stockQuantity == 0 ? null : () {
                            final int quantity = int.tryParse(_quantityController.text) ?? 1;
                            if (quantity <= 0 || quantity > stockQuantity) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter a valid quantity.'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              return;
                            }
                            cart.addItem(productDocument, quantity: quantity);

                            FirebaseAnalytics.instance.logAddToCart(
                              items: [
                                AnalyticsEventItem(
                                  itemId: widget.productId,
                                  itemName: name,
                                  price: price,
                                  quantity: quantity,
                                ),
                              ],
                              value: price * quantity,
                              currency: 'MMK',
                            );

                            Navigator.push(
                              context,
                              FadePageRoute(child: const CartScreen()),
                            );
                          },
                          icon: const Icon(Icons.add_shopping_cart),
                          label: const Text('Add to Cart'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: textTheme.titleMedium,
                            disabledBackgroundColor: Colors.grey[300],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      Text('Description', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(description, style: textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
