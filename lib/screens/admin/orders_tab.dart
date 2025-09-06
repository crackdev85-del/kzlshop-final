
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:myapp/constants.dart';

class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _updateOrderStatus(String orderId, String newStatus, Map<String, dynamic> orderData) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final orderRef = _firestore.collection(ordersCollectionPath).doc(orderId);
        final productRef = _firestore.collection(productsCollectionPath).doc(orderData['productId']);

        final productSnapshot = await transaction.get(productRef);
        if (!productSnapshot.exists) {
          throw Exception("Product not found!");
        }

        final currentQuantity = productSnapshot.data()!['quantity'] ?? 0;
        final orderQuantity = orderData['quantity'];

        if (newStatus == 'Order Received' && orderData['status'] != 'Order Received') {
          if (currentQuantity < orderQuantity) {
            throw Exception('Insufficient stock!');
          }
          transaction.update(productRef, {'quantity': currentQuantity - orderQuantity});
        } else if (newStatus != 'Order Received' && orderData['status'] == 'Order Received') {
          transaction.update(productRef, {'quantity': currentQuantity + orderQuantity});
        }

        transaction.update(orderRef, {'status': newStatus});
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to update order status: $e")));
    }
  }

  Future<void> _editOrderQuantity(String orderId, int newQuantity, Map<String, dynamic> orderData) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final orderRef = _firestore.collection(ordersCollectionPath).doc(orderId);
        final productRef = _firestore.collection(productsCollectionPath).doc(orderData['productId']);

        final productSnapshot = await transaction.get(productRef);
        if (!productSnapshot.exists) {
          throw Exception("Product not found!");
        }

        final currentQuantity = productSnapshot.data()!['quantity'] ?? 0;
        final oldQuantity = orderData['quantity'];
        final quantityDifference = newQuantity - oldQuantity;

        if (orderData['status'] == 'Order Received') {
            if (currentQuantity < quantityDifference) {
              throw Exception('Insufficient stock!');
            }
            transaction.update(productRef, {'quantity': currentQuantity - quantityDifference});
        }

        transaction.update(orderRef, {'quantity': newQuantity});
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to edit order quantity: $e")));
    }
  }

  Future<void> _deleteOrder(String orderId, Map<String, dynamic> orderData) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final orderRef = _firestore.collection(ordersCollectionPath).doc(orderId);

        if (orderData['status'] == 'Order Received') {
          final productRef = _firestore.collection(productsCollectionPath).doc(orderData['productId']);
           final productSnapshot = await transaction.get(productRef);
           if(productSnapshot.exists){
             final currentQuantity = productSnapshot.data()!['quantity'] ?? 0;
             final orderQuantity = orderData['quantity'];
             transaction.update(productRef, {'quantity': currentQuantity + orderQuantity});
           }
        }
        transaction.delete(orderRef);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to delete order: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection(ordersCollectionPath).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No orders found.'));
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              final orderData = doc.data() as Map<String, dynamic>;
              final total = (orderData['price'] ?? 0) * (orderData['quantity'] ?? 0);

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('User: ${orderData['userName'] ?? 'N/A'}', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text('Product: ${orderData['productName'] ?? 'N/A'}'),
                      const SizedBox(height: 4),
                      Text('Quantity: ${orderData['quantity'] ?? 0}'),
                      const SizedBox(height: 4),
                      Text('Total: \$${total.toStringAsFixed(2)}'),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          DropdownButton<String>(
                            value: orderData['status'],
                            onChanged: (String? newStatus) {
                              if (newStatus != null) {
                                _updateOrderStatus(doc.id, newStatus, orderData);
                              }
                            },
                            items: <String>[
                              'Order Placed',
                              'Order Received',
                              'Processing',
                              'Shipping',
                              'Delivered',
                              'Cancelled'
                            ].map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  _showEditQuantityDialog(doc.id, orderData);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  final confirm = await showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Are you sure?'),
                                      content: const Text('Do you want to delete this order?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('No')),
                                        TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Yes')),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    _deleteOrder(doc.id, orderData);
                                  }
                                },
                              ),
                            ],
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  void _showEditQuantityDialog(String orderId, Map<String, dynamic> orderData) {
    final TextEditingController qtyController = TextEditingController(text: orderData['quantity'].toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Quantity'),
        content: TextField(
          controller: qtyController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'New Quantity'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final newQuantity = int.tryParse(qtyController.text);
              if (newQuantity != null && newQuantity > 0) {
                _editOrderQuantity(orderId, newQuantity, orderData);
                Navigator.of(context).pop();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid quantity')));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
