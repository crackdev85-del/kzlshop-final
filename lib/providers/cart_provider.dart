
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CartItem {
  final String id;
  final String name;
  final double price;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
  });
}

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items {
    return {..._items};
  }

  int get itemCount {
    // This should return the total number of items, not just unique products.
    int count = 0;
    _items.forEach((key, cartItem) {
      count += cartItem.quantity;
    });
    return count;
  }

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

  void addItem(DocumentSnapshot product, {int quantity = 1}) {
    final productId = product.id;
    final productData = product.data() as Map<String, dynamic>;

    if (_items.containsKey(productId)) {
      // if item already in cart, update its quantity
      _items.update(
        productId,
        (existingCartItem) => CartItem(
          id: existingCartItem.id,
          name: existingCartItem.name,
          price: existingCartItem.price,
          quantity: existingCartItem.quantity + quantity, // Add the new quantity
        ),
      );
    } else {
      // if item not in cart, add it
      _items.putIfAbsent(
        productId,
        () => CartItem(
          id: product.id,
          name: productData['name'] ?? '',
          price: (productData['price'] ?? 0).toDouble(),
          quantity: quantity, // Set the initial quantity
        ),
      );
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  // New method to remove a single item from a cart item's quantity
  void removeSingleItem(String productId) {
    if (!_items.containsKey(productId)) {
      return;
    }
    if (_items[productId]!.quantity > 1) {
      _items.update(
          productId,
          (existing) => CartItem(
              id: existing.id,
              name: existing.name,
              price: existing.price,
              quantity: existing.quantity - 1));
    } else {
      _items.remove(productId);
    }
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
