import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:myapp/constants.dart';
import 'package:myapp/providers/order_provider.dart';
import 'package:provider/provider.dart';

class OrdersTab extends StatelessWidget {
  const OrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(ordersCollectionPath)
          .orderBy('dateTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Something went wrong: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No orders found.'));
        }

        final orderDocs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: orderDocs.length,
          itemBuilder: (context, index) {
            return AdminOrderCard(orderSnapshot: orderDocs[index]);
          },
        );
      },
    );
  }
}

class AdminOrderCard extends StatefulWidget {
  final DocumentSnapshot orderSnapshot;

  const AdminOrderCard({super.key, required this.orderSnapshot});

  @override
  State<AdminOrderCard> createState() => _AdminOrderCardState();
}

class _AdminOrderCardState extends State<AdminOrderCard> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final orderData = widget.orderSnapshot.data() as Map<String, dynamic>;
    final orderId = widget.orderSnapshot.id;
    final String currentStatus = orderData['status'] ?? 'Order Placed';
    final List<dynamic> products = orderData['products'] ?? [];

    final List<String> statusOptions = [
      'Order Placed',
      'Processing',
      'Shipped',
      'Delivered',
      'Cancelled'
    ];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 3,
      child: Column(
        children: [
          ListTile(
            title: UserEmailWidget(userId: orderData['userId']),
            subtitle: Text(
                'Total: ${orderData['totalAmount'].toStringAsFixed(2)} Kyat\nPlaced on: ${DateFormat('dd/MM/yy hh:mm a').format((orderData['dateTime'] as Timestamp).toDate())}'),
            isThreeLine: true,
            trailing: IconButton(
              icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () {
                setState(() {
                  _expanded = !_expanded;
                });
              },
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Products:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  ...products.map((prod) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${prod['name']} (x${prod['quantity']})'),
                          Text('${(prod['price']).toStringAsFixed(2)} Kyat'),
                        ],
                      ),
                    );
                  }),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Update Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                      DropdownButton<String>(
                        value: currentStatus,
                        items: statusOptions.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newStatus) {
                          if (newStatus != null && newStatus != currentStatus) {
                             Provider.of<OrderProvider>(context, listen: false)
                                .updateOrderStatus(orderId, newStatus);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class UserEmailWidget extends StatelessWidget {
  final String userId;

  const UserEmailWidget({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection(usersCollectionPath).doc(userId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('Loading user...');
        }
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return const Text('Unknown User', style: TextStyle(color: Colors.red, fontStyle: FontStyle.italic));
        }
        final userData = snapshot.data!.data() as Map<String, dynamic>;
        return Text(
          '${userData['email'] ?? 'No email available'}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        );
      },
    );
  }
}
