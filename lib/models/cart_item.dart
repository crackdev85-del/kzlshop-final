import 'package:cloud_firestore/cloud_firestore.dart';

class CartItem {
  final String id;
  final String name;
  final double price;
  final int quantity;
  final String image;
  final DocumentSnapshot product;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.image,
    required this.product,
  });

  // Convert a CartItem object into a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'productId': id,
      'quantity': quantity,
    };
  }

  // Create a CartItem from a map and a product snapshot
  factory CartItem.fromMap(Map<String, dynamic> map, DocumentSnapshot product) {
    final productData = product.data() as Map<String, dynamic>;
    return CartItem(
      id: product.id,
      name: productData['name'] ?? '',
      price: (productData['price'] as num?)?.toDouble() ?? 0.0,
      image: productData['imageUrl'] ?? '',
      quantity: map['quantity'] ?? 1,
      product: product,
    );
  }

  // Method to create a copy of a CartItem with modified fields
  CartItem copyWith({
    String? id,
    String? name,
    double? price,
    int? quantity,
    String? image,
    DocumentSnapshot? product,
  }) {
    return CartItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      image: image ?? this.image,
      product: product ?? this.product,
    );
  }
}
