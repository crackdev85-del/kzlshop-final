import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:moegyi/constants.dart';
import 'package:moegyi/models/cart_item.dart';

class CartProvider with ChangeNotifier {
  Map<String, CartItem> _items = {};
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
        (existingCartItem) => existingCartItem.copyWith(
          quantity: quantity,
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
          image: productData['imageUrl'] ?? '', // Fixed: Added image
          product: product,
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
        ),
      );
    } else {
      _items.remove(productId);
    }
    notifyListeners();
  }

  Future<void> addOrder(String shippingAddress, String phoneNumber) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("User not logged in");
    }
    // Fixed: Using the correct collection path from constants.dart
    final orderRef = _firestore.collection(ordersCollectionPath); 
    
    // Note: This order number logic might not be safe in a multi-user environment.
    // A more robust solution like a Cloud Function with a transaction is recommended for production.
    final lastOrderQuery = await orderRef.orderBy('orderDate', descending: true).limit(1).get();
    int newOrderNumber = 1;
    if (lastOrderQuery.docs.isNotEmpty) {
      final lastOrderData = lastOrderQuery.docs.first.data();
      if (lastOrderData.containsKey('orderNumber')) {
        newOrderNumber = (lastOrderData['orderNumber'] as int) + 1;
      } 
    }

    final newOrder = {
      'userId': user.uid,
      'orderNumber': newOrderNumber,
      'items': _items.values.map((cartItem) => {
        'productId': cartItem.id,
        'name': cartItem.name,
        'quantity': cartItem.quantity,
        'price': cartItem.price,
        'image': cartItem.image, // Fixed: Added image to order data
      }).toList(),
      'totalAmount': totalAmount,
      'orderDate': Timestamp.now(),
      'status': 'Processing', // Changed from 'Pending' to match your order detail screen
      'shippingAddress': shippingAddress,
      'phoneNumber': phoneNumber,
    };

    await orderRef.add(newOrder);
    clearCart();
  }

  void clearCart() {
    _items = {};
    notifyListeners();
  }
}
