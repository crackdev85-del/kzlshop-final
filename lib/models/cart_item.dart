import 'package:cloud_firestore/cloud_firestore.dart';

class CartItem {
  final String id;
  final String name;
  final double price;
  final int quantity;
  final DocumentSnapshot product;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.product,
  });

  CartItem copyWith({ 
    String? id,
    String? name,
    double? price,
    int? quantity,
    DocumentSnapshot? product,
  }) {
    return CartItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      product: product ?? this.product,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': product.id,
      'quantity': quantity,
      // Storing product data for convenience, but can be redundant
      'product': product.data(), 
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map, DocumentSnapshot product) {
    final productData = product.data() as Map<String, dynamic>;
    return CartItem(
      id: product.id,
      name: productData['name'] ?? '',
      price: (productData['price'] as num?)?.toDouble() ?? 0.0, 
      quantity: map['quantity'] ?? 1,
      product: product,
    );
  }
}
