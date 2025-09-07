
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  late TextEditingController _quantityController;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: _selectedQuantity.toString());
    
    _quantityController.addListener(() {
      final text = _quantityController.text;
      if (text.isNotEmpty) {
        try {
          int newQuantity = int.parse(text);
          final availableQuantity = (widget.product.data() as Map<String, dynamic>)['quantity'] ?? 0;
          
          if (newQuantity > availableQuantity) {
            newQuantity = availableQuantity;
            _quantityController.text = newQuantity.toString();
            _quantityController.selection = TextSelection.fromPosition(TextPosition(offset: _quantityController.text.length));
             if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cannot add more than available quantity.')),
                );
            }
          }
          
          if (newQuantity < 1 && availableQuantity > 0) {
             newQuantity = 1;
          }

          if (_selectedQuantity != newQuantity) {
            setState(() {
              _selectedQuantity = newQuantity;
            });
          }
        } catch (e) {
          // Handle parsing error, maybe reset to a default
          setState(() {
            _selectedQuantity = 1;
          });
          _quantityController.text = _selectedQuantity.toString();
        }
      }
    });
  }


  void _incrementQuantity(int availableQuantity) {
    if (_selectedQuantity < availableQuantity) {
      setState(() {
        _selectedQuantity++;
        _quantityController.text = _selectedQuantity.toString();
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
        _quantityController.text = _selectedQuantity.toString();
      });
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final theme = Theme.of(context);
    final productData = widget.product.data() as Map<String, dynamic>;

    final imageUrl = productData['imageUrl'] as String?;
    final availableQuantity = (productData['quantity'] ?? 0) as int;
    final name = productData['name'] ?? 'No Name';
    final price = productData['price'] ?? 0.0;
    final description = productData['description'] ?? 'No description available.';
    final categoryId = productData['categoryId'] as String?;

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
            if (imageUrl != null && imageUrl.isNotEmpty)
              Container(
                height: 300,
                color: Colors.grey[200],
                child: Image.memory(
                  base64Decode(imageUrl.split(',').last),
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
                  if (categoryId != null)
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('categories').doc(categoryId).get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                          final categoryData = snapshot.data!.data() as Map<String, dynamic>;
                          return Chip(
                            label: Text(categoryData['name'] ?? 'Uncategorized'),
                            backgroundColor: theme.colorScheme.secondaryContainer,
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$price Kyat',
                    style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Chip(
                    label: Text(availableQuantity > 0 ? 'In Stock: $availableQuantity items' : 'Out of Stock'),
                    backgroundColor: availableQuantity > 0 ? Colors.green.shade100 : Colors.red.shade100,
                    labelStyle: TextStyle(color: availableQuantity > 0 ? Colors.green.shade800 : Colors.red.shade800),
                  ),
                  const SizedBox(height: 16),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: availableQuantity > 0 ? _decrementQuantity : null,
                        iconSize: 32,
                      ),
                      SizedBox(
                        width: 80, // Set a fixed width for the text field
                        child: TextField(
                          controller: _quantityController,
                          textAlign: TextAlign.center,
                          enabled: availableQuantity > 0,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.all(8),
                          ),
                          style: theme.textTheme.headlineMedium,
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: availableQuantity > 0 ? () => _incrementQuantity(availableQuantity) : null,
                        iconSize: 32,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: availableQuantity > 0 && _selectedQuantity > 0 ? () {
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
                    } : null, // Disable button if out of stock or quantity is 0
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
