import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myapp/constants.dart';
import 'package:myapp/providers/cart_provider.dart';
import 'package:provider/provider.dart';

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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'product-image-${widget.productId}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return SizedBox(
                          height: 250,
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 250,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
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
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text('Quantity:', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 70,
                        child: TextFormField(
                          controller: _quantityController,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.all(12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onChanged: (value) {
                            final int? quantity = int.tryParse(value);
                            if (quantity != null && quantity > stockQuantity) {
                              _quantityController.text = stockQuantity.toString();
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Quantity cannot exceed available stock.'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            } else if (quantity != null && quantity < 1 && value.isNotEmpty) {
                               _quantityController.text = '1';
                            }
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
                    onPressed: stockQuantity == 0
                        ? null
                        : () {
                            final int quantity = int.tryParse(_quantityController.text) ?? 0;
                            if (quantity > 0 && quantity <= stockQuantity) {
                              cart.addItem(productDocument as QueryDocumentSnapshot, quantity: quantity);
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('$quantity x $name added to cart!'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter a valid quantity.'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
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
          );
        },
      ),
    );
  }
}
