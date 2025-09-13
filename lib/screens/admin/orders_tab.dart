
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:moegyi/constants.dart';
import 'package:moegyi/screens/admin/admin_orders_screen.dart';

// Main widget to display a list of orders in a tab
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
          return Center(child: Text('An error occurred: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No orders found.'));
        }

        final orderDocs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: orderDocs.length,
          itemBuilder: (context, index) {
            return OrderListCard(orderSnapshot: orderDocs[index]);
          },
        );
      },
    );
  }
}

// A simplified card widget for the order list
class OrderListCard extends StatelessWidget {
  final DocumentSnapshot orderSnapshot;

  const OrderListCard({super.key, required this.orderSnapshot});

  @override
  Widget build(BuildContext context) {
    final orderData = orderSnapshot.data() as Map<String, dynamic>?;

    if (orderData == null) {
      return const Card(child: ListTile(title: Text('Invalid order data')));
    }

    final String userId = orderData['userId'] ?? '';
    final double totalAmount = (orderData['totalAmount'] ?? 0.0).toDouble();
    final Timestamp? dateTime = orderData['dateTime'] as Timestamp?;
    final String status = orderData['status'] ?? 'N/A';
    final int orderNumber = orderData['orderNumber'] ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      child: ListTile(
        title: Text('Order #$orderNumber', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserInfoWidget(userId: userId),
            const SizedBox(height: 4),
            Text('Total: ${totalAmount.toStringAsFixed(2)} Ks'),
            Text('Status: $status'),
            if (dateTime != null)
               Text('Time: ${DateFormat('dd/MM/yy hh:mm a').format(dateTime.toDate())}'),
          ],
        ),
        isThreeLine: true,
        trailing: TextButton.icon(
            icon: const Icon(Icons.visibility_outlined),
            label: const Text('View'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AdminOrdersScreen(
                    orderId: orderSnapshot.id, // Pass only the ID
                  ),
                ),
              );
            },
          ),
      ),
    );
  }
}

// Widget to fetch and display user information based on userId
class UserInfoWidget extends StatelessWidget {
  final String? userId;

  const UserInfoWidget({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    if (userId == null || userId!.isEmpty) {
      return const Text('Unknown User', style: TextStyle(color: Colors.red));
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection(usersCollectionPath).doc(userId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('Loading User...');
        }
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return Text('Unknown User (ID: $userId)', style: const TextStyle(color: Colors.red, fontStyle: FontStyle.italic));
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        final shopName = userData?['shopName'] ?? 'N/A';

        return Text(shopName, style: const TextStyle(fontWeight: FontWeight.w500));
      },
    );
  }
}
