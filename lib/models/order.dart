import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:moegyi/models/cart_item.dart';

class Order {
  final String id;
  final int orderNumber;
  final List<CartItem> items;
  final double totalAmount;
  final DateTime orderDate;
  final String status;
  final String shippingAddress;
  final String phoneNumber;

  Order({
    required this.id,
    required this.orderNumber,
    required this.items,
    required this.totalAmount,
    required this.orderDate,
    required this.status,
    required this.shippingAddress,
    required this.phoneNumber,
  });

  // Convert an Order object into a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'orderNumber': orderNumber,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'orderDate': Timestamp.fromDate(orderDate),
      'status': status,
      'shippingAddress': shippingAddress,
      'phoneNumber': phoneNumber,
    };
  }

  // Create an Order object from a DocumentSnapshot
  static Future<Order> fromSnapshot(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;

    final itemFutures = (data['items'] as List).map((itemData) async {
      final productDoc = await FirebaseFirestore.instance
          .collection('products')
          .doc(itemData['productId'])
          .get();
      return CartItem.fromMap(itemData, productDoc);
    }).toList();

    final items = await Future.wait(itemFutures);

    return Order(
      id: doc.id,
      orderNumber: data['orderNumber'] ?? 0,
      items: items,
      totalAmount: (data['totalAmount'] as num).toDouble(),
      orderDate: (data['orderDate'] as Timestamp).toDate(),
      status: data['status'] ?? 'Pending',
      shippingAddress: data['shippingAddress'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
    );
  }
}
