
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CartItem {
  final String id; // Product ID
  final String name;
  final int quantity;
  final double price;
  final QueryDocumentSnapshot product; // Changed from 'dynamic'

  CartItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    required this.product,
  });

  CartItem copyWith({
    int? quantity,
  }) {
    return CartItem(
      id: id,
      name: name,
      quantity: quantity ?? this.quantity,
      price: price,
      product: product,
    );
  }
}

class CartProvider with ChangeNotifier {
  Map<String, CartItem> _items = {};

  Map<String, CartItem> get items {
    return {..._items};
  }

  int get itemCount {
    return _items.length;
  }

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

  void addItem(QueryDocumentSnapshot product, {int quantity = 1}) {
    final productId = product.id;
    final productData = product.data() as Map<String, dynamic>;

    if (_items.containsKey(productId)) {
      // Change quantity...
      _items.update(
        productId,
        (existingCartItem) => existingCartItem.copyWith(
          quantity: existingCartItem.quantity + quantity,
        ),
      );
    } else {
      // Add a new item...
      _items.putIfAbsent(
        productId,
        () => CartItem(
          id: productId,
          name: productData['name'] ?? 'No Name',
          price: (productData['price'] ?? 0.0).toDouble(),
          quantity: quantity,
          product: product, // Pass the full product snapshot
        ),
      );
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void removeSingleItem(String productId) {
    if (!_items.containsKey(productId)) {
      return;
    }
    if (_items[productId]!.quantity > 1) {
      _items.update(
          productId,
          (existingCartItem) => existingCartItem.copyWith(
                quantity: existingCartItem.quantity - 1,
              ));
    } else {
      _items.remove(productId);
    }
    notifyListeners();
  }

  void clearCart() {
    _items = {};
    notifyListeners();
  }
}
