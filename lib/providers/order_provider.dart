
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/providers/cart_provider.dart';

class OrderItem {
  final String id;
  final double amount;
  final List<CartItem> products;
  final DateTime dateTime;
  final String status;

  OrderItem({
    required this.id,
    required this.amount,
    required this.products,
    required this.dateTime,
    this.status = 'Pending',
  });
}

class OrderProvider with ChangeNotifier {
  final CollectionReference _ordersCollection = FirebaseFirestore.instance.collection('orders');

  Future<void> addOrder(List<CartItem> cartProducts, double total) async {
    final timestamp = DateTime.now();
    try {
      final newOrderRef = await _ordersCollection.add({
        'amount': total,
        'dateTime': timestamp.toIso8601String(),
        'status': 'Pending', // Initial status
        'products': cartProducts
            .map((cp) => {
                  'id': cp.product.id,
                  'name': cp.name,
                  'quantity': cp.quantity,
                  'price': cp.price,
                  // You might not need to store the full product document again
                })
            .toList(),
      });

      // Optionally, you can reduce the stock quantity from the products collection here
      for (var cartItem in cartProducts) {
          final productRef = FirebaseFirestore.instance.collection('products').doc(cartItem.product.id);
          // Use a transaction to safely update the quantity
          await FirebaseFirestore.instance.runTransaction((transaction) async {
              DocumentSnapshot freshSnap = await transaction.get(productRef);
              int currentQuantity = (freshSnap.data() as Map<String, dynamic>)['quantity'] ?? 0;
              transaction.update(productRef, {'quantity': currentQuantity - cartItem.quantity});
          });
      }

      notifyListeners();
    } catch (error) {
      // It's a good practice to handle potential errors
      print("Error placing order: $error");
      rethrow; 
    }
  }
}
