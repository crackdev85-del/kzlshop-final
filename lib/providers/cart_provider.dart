import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:moegyi/models/cart_item.dart';

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};

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

  void addItem(DocumentSnapshot product, {int quantity = 1}) {
    final productData = product.data() as Map<String, dynamic>;

    if (_items.containsKey(product.id)) {
      // Change quantity...
      _items.update(
        product.id,
        (existingCartItem) => CartItem(
          id: existingCartItem.id,
          name: existingCartItem.name,
          price: existingCartItem.price,
          quantity: existingCartItem.quantity + quantity,
          image: existingCartItem.image,
        ),
      );
    } else {
      // Add a new item...
      _items.putIfAbsent(
        product.id,
        () => CartItem(
          id: product.id,
          name: productData['name'],
          price: (productData['price'] as num).toDouble(),
          quantity: quantity,
          image: productData['image'] ?? '', // Ensure image is handled
        ),
      );
    }
    notifyListeners();
  }

  void addSingleItem(String productId) {
    if (!_items.containsKey(productId)) {
      return;
    }
    _items.update(
      productId,
      (existingCartItem) => CartItem(
        id: existingCartItem.id,
        name: existingCartItem.name,
        price: existingCartItem.price,
        quantity: existingCartItem.quantity + 1,
        image: existingCartItem.image,
      ),
    );
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
        (existingCartItem) => CartItem(
          id: existingCartItem.id,
          name: existingCartItem.name,
          price: existingCartItem.price,
          quantity: existingCartItem.quantity - 1,
          image: existingCartItem.image,
        ),
      );
    } else {
      _items.remove(productId);
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
