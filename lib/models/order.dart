import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:moegyi/models/cart_item.dart';

class Order with ChangeNotifier {
  final String id;
  final double total;
  final List<CartItem> items;
  final DateTime date;
  String status; // Allow status to be updated

  Order({
    required this.id,
    required this.total,
    required this.items,
    required this.date,
    this.status = 'Order Placed',
  });

  void updateStatus(String newStatus) {
    status = newStatus;
    notifyListeners();
  }

  Map<String, dynamic> toMap() {
    return {
      'totalAmount': total,
      'dateTime': Timestamp.fromDate(date),
      'products': items
          .map((cp) => {
                'id': cp.id,
                'name': cp.name,
                'quantity': cp.quantity,
                'price': cp.price,
                'image': cp.image,
              })
          .toList(),
      'status': status,
    };
  }

  static Future<Order> fromSnapshot(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;

    final itemFutures = (data['items'] as List).map((itemData) async {
      final productDoc = await FirebaseFirestore.instance
          .collection('products')
          .doc(itemData['productId'])
          .get();

      if (productDoc.exists) {
        final productData = productDoc.data() as Map<String, dynamic>;
        final combinedData = {
          'id': productDoc.id,
          'name': productData['name'],
          'price': productData['price'],
          'image': productData['image'],
          'quantity': itemData['quantity'],
        };
        return CartItem.fromMap(combinedData);
      } else {
        // Handle the case where the product doesn't exist anymore
        // You might want to return a placeholder or skip this item
        final placeholderData = {
          'id': itemData['productId'],
          'name': 'Product not found',
          'price': 0.0,
          'image': '',
          'quantity': itemData['quantity'],
        };
        return CartItem.fromMap(placeholderData);
      }
    }).toList();

    final items = await Future.wait(itemFutures);

    return Order(
      id: doc.id,
      total: (data['totalAmount'] as num).toDouble(),
      date: (data['dateTime'] as Timestamp).toDate(),
      items: items,
      status: data['status'] ?? 'Order Placed',
    );
  }
}
