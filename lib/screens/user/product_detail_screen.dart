
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:myapp/providers/cart_provider.dart';
import 'package:provider/provider.dart';

class ProductDetailScreen extends StatefulWidget {
  final QueryDocumentSnapshot product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  ProductDetailScreenState createState() => ProductDetailScreenState();
}

class ProductDetailScreenState extends State<ProductDetailScreen> {
  int _selectedQuantity = 1;

  void _incrementQuantity(int availableQuantity) {
    if (_selectedQuantity < availableQuantity) {
      setState(() {
        _selectedQuantity++;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot add more than available quantity.')),
      );
    }
  }

  void _decrementQuantity() {
    if (_selectedQuantity > 1) {
      setState(() {
        _selectedQuantity--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final theme = Theme.of(context);
    final productData = widget.product.data() as Map<String, dynamic>;

    // Using the final, strict data model with 'imageUrl'
    final imageUrl = productData['imageUrl'] as String?;
    final availableQuantity = (productData['quantity'] ?? 0) as int;
    final name = productData['name'] ?? 'No Name';
    final price = productData['price'] ?? 0.0;
    final description = productData['description'] ?? 'No description available.';
    final category = productData['category'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Large Image
            if (imageUrl != null && imageUrl.isNotEmpty)
              Container(
                height: 300,
                color: Colors.grey[200],
                child: Image.memory(
                  base64Decode(imageUrl),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.error, size: 50, color: Colors.red);
                  },
                ),
              )
            else
              Container(
                height: 300,
                color: Colors.grey[200],
                child: const Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category
                  if (category != null)
                    Chip(
                      label: Text(category),
                      backgroundColor: theme.colorScheme.secondaryContainer,
                    ),
                  const SizedBox(height: 8),
                  // 2. Product Name
                  Text(
                    name,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // 3. Price
                  Text(
                    '$price Kyat',
                    style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // 5. Quantity Chip
                  Chip(
                    label: Text(availableQuantity > 0 ? 'In Stock: $availableQuantity items' : 'Out of Stock'),
                    backgroundColor: availableQuantity > 0 ? Colors.green.shade100 : Colors.red.shade100,
                    labelStyle: TextStyle(color: availableQuantity > 0 ? Colors.green.shade800 : Colors.red.shade800),
                  ),
                  const SizedBox(height: 16),

                  // 4. Full Description
                  Text(
                    'Description',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 24),

                  // 6. Quantity Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: _decrementQuantity,
                        iconSize: 32,
                      ),
                      Text(
                        '$_selectedQuantity',
                        style: theme.textTheme.headlineMedium,
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => _incrementQuantity(availableQuantity),
                        iconSize: 32,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 7. "Add to Cart" Button
                  ElevatedButton.icon(
                    onPressed: availableQuantity > 0 ? () {
                      cart.addItem(widget.product, quantity: _selectedQuantity);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added $_selectedQuantity x $name to cart.'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                      if (mounted) {
                        Navigator.of(context).pop();
                      }
                    } : null, // Disable button if out of stock
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Add to Cart'),
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: theme.textTheme.titleMedium),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
