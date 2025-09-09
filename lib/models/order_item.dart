import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String id;
  final double totalAmount;
  final List<OrderProduct> products;
  final DateTime dateTime;
  String status;
  final int orderNumber; 

  OrderItem({
    required this.id,
    required this.totalAmount,
    required this.products,
    required this.dateTime,
    this.status = 'Order Placed',
    required this.orderNumber,
  });

  factory OrderItem.fromMap(String id, Map<String, dynamic> data) {
    return OrderItem(
      id: id,
      totalAmount: data['totalAmount'] ?? 0.0,
      products: (data['products'] as List<dynamic>? ?? [])
          .map((item) => OrderProduct.fromMap(item))
          .toList(),
      dateTime: (data['dateTime'] as Timestamp? ?? Timestamp.now()).toDate(),
      status: data['status'] ?? 'Order Placed',
      orderNumber: data['orderNumber'] ?? 0,
    );
  }

  factory OrderItem.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return OrderItem(
      id: doc.id,
      totalAmount: data['totalAmount']?.toDouble() ?? 0.0,
      products: (data['products'] as List<dynamic>? ?? [])
          .map((item) => OrderProduct.fromMap(item as Map<String, dynamic>))
          .toList(),
      dateTime: (data['dateTime'] as Timestamp? ?? Timestamp.now()).toDate(),
      status: data['status'] ?? 'Order Placed',
      orderNumber: data['orderNumber'] ?? 0,
    );
  }
}

class OrderProduct {
  final String id;
  final String name;
  final int quantity;
  final double price;

  OrderProduct({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
  });

  factory OrderProduct.fromMap(Map<String, dynamic> data) {
    return OrderProduct(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      quantity: data['quantity'] ?? 0,
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
