
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:moegyi/constants.dart';

class EditOrderProductsScreen extends StatefulWidget {
  final String orderId;
  final List<dynamic> initialProducts;

  const EditOrderProductsScreen({
    super.key,
    required this.orderId,
    required this.initialProducts,
  });

  @override
  State<EditOrderProductsScreen> createState() =>
      _EditOrderProductsScreenState();
}

class _EditOrderProductsScreenState extends State<EditOrderProductsScreen> {
  late List<Map<String, dynamic>> _products;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Make a deep copy of the initial products list to allow modifications.
    _products = List<Map<String, dynamic>>.from(
      widget.initialProducts.map((item) => Map<String, dynamic>.from(item)),
    );
  }

  void _updateQuantity(int index, int change) {
    setState(() {
      final newQuantity = _products[index]['quantity'] + change;
      if (newQuantity > 0) {
        _products[index]['quantity'] = newQuantity;
      }
    });
  }

  void _removeProduct(int index) {
    setState(() {
      _products.removeAt(index);
    });
  }

  Future<void> _saveChanges() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    // Recalculate the total amount
    double newTotalAmount = 0.0;
    for (var product in _products) {
      newTotalAmount += (product['price'] as num) * (product['quantity'] as num);
    }

    try {
      // Update Firestore document
      await FirebaseFirestore.instance
          .collection(ordersCollectionPath)
          .doc(widget.orderId)
          .update({
        'products': _products,
        'totalAmount': newTotalAmount,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order updated successfully!')),
      );

      Navigator.of(context).pop();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update order: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Products'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(child: CircularProgressIndicator(color: Colors.white)),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Save Changes',
              onPressed: _saveChanges,
            ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          final productName = product['name'] ?? 'Unknown Product';
          final productQuantity = product['quantity'] ?? 0;
          final productPrice = (product['price'] as num?)?.toDouble() ?? 0.0;

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('Price: ${productPrice.toStringAsFixed(2)} Ks'),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => _updateQuantity(index, -1),
                      ),
                      Text(productQuantity.toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => _updateQuantity(index, 1),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_forever, color: Colors.red),
                        tooltip: 'Remove Product',
                        onPressed: () => _removeProduct(index),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
