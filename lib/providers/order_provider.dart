import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/constants.dart';
import 'package:myapp/models/order_item.dart';

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
          OrderItem.fromMap(doc.id, orderData),
        );
      }
      _orders = loadedOrders;
      notifyListeners();
    } catch (error) {
      debugPrint('Error fetching orders: $error');
    }
  }

  Future<void> addOrder(List<Map<String, dynamic>> cartProducts, double total) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final timestamp = DateTime.now();
    try {
      final orderRef = _firestore.collection(ordersCollectionPath);
      final lastOrderQuery = await orderRef.orderBy('orderNumber', descending: true).limit(1).get();
      int newOrderNumber = 1;
      if (lastOrderQuery.docs.isNotEmpty) {
        newOrderNumber = (lastOrderQuery.docs.first.data()['orderNumber'] as int) + 1;
      }

      final newOrderRef = await orderRef.add({
        'userId': user.uid,
        'totalAmount': total,
        'dateTime': Timestamp.fromDate(timestamp),
        'status': 'Order Placed',
        'products': cartProducts,
        'orderNumber': newOrderNumber,
      });

      _orders.insert(
        0,
        OrderItem(
          id: newOrderRef.id,
          totalAmount: total,
          products: cartProducts.map((item) => OrderProduct.fromMap(item)).toList(),
          dateTime: timestamp,
          orderNumber: newOrderNumber,
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
