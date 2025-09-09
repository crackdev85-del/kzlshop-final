import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/constants.dart';
import 'package:myapp/providers/cart_provider.dart';

class OrderItem {
  final String id;
  final double totalAmount;
  final List<CartItem> products;
  final DateTime dateTime;
  String status;

  OrderItem({
    required this.id,
    required this.totalAmount,
    required this.products,
    required this.dateTime,
    this.status = 'Order Placed',
  });
}

class OrderProvider with ChangeNotifier {
  List<OrderItem> _orders = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<OrderItem> get orders {
    return [..._orders];
  }

  Future<void> fetchAndSetOrders() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final querySnapshot = await _firestore
          .collection(ordersCollectionPath)
          .where('userId', isEqualTo: user.uid)
          .orderBy('dateTime', descending: true)
          .get();

      final List<OrderItem> loadedOrders = [];
      for (var doc in querySnapshot.docs) {
        final orderData = doc.data();
        loadedOrders.add(
          OrderItem(
            id: doc.id,
            totalAmount: orderData['totalAmount'],
            dateTime: (orderData['dateTime'] as Timestamp).toDate(),
            status: orderData['status'] ?? 'Order Placed',
            products: (orderData['products'] as List<dynamic>)
                .map((item) => CartItem(
                      id: item['id'],
                      name: item['name'],
                      quantity: item['quantity'],
                      price: item['price'],
                      product: null,
                    ))
                .toList(),
          ),
        );
      }
      _orders = loadedOrders;
      notifyListeners();
    } catch (error) {
      debugPrint('Error fetching orders: $error');
    }
  }

  Future<void> addOrder(List<CartItem> cartProducts, double total) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final timestamp = DateTime.now();
    try {
      final newOrderRef = await _firestore.collection(ordersCollectionPath).add({
        'userId': user.uid,
        'totalAmount': total,
        'dateTime': Timestamp.fromDate(timestamp),
        'status': 'Order Placed',
        'products': cartProducts
            .map((cp) => {
                  'id': cp.id,
                  'name': cp.name,
                  'quantity': cp.quantity,
                  'price': cp.price,
                })
            .toList(),
      });

      _orders.insert(
        0,
        OrderItem(
          id: newOrderRef.id,
          totalAmount: total,
          products: cartProducts,
          dateTime: timestamp,
        ),
      );
      notifyListeners();
    } catch (error) {
      debugPrint('Error adding order: $error');
      rethrow;
    }
  }

  Future<void> deleteOrder(String orderId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection(ordersCollectionPath).doc(orderId).delete();
      _orders.removeWhere((order) => order.id == orderId);
      notifyListeners();
    } catch (error) {
      debugPrint('Error deleting order: $error');
      rethrow;
    }
  }

  // New function to update order status
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _firestore
          .collection(ordersCollectionPath)
          .doc(orderId)
          .update({'status': newStatus});
      // No need to call notifyListeners() here because the Admin screen is using a StreamBuilder
      // which will automatically reflect the changes from Firestore.
    } catch (error) {
      debugPrint('Error updating order status: $error');
      // Optionally, re-throw the error to show a message in the UI
      rethrow;
    }
  }
}
