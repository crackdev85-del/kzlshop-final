import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:moegyi/constants.dart';
import 'package:moegyi/models/order_item.dart';
import 'package:moegyi/widgets/order_item_card.dart';

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});
  static const routeName = '/my-orders';

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Orders',
          style: theme.textTheme.titleLarge
              ?.copyWith(color: theme.colorScheme.onPrimary),
        ),
        backgroundColor: theme.colorScheme.primary,
        iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(ordersCollectionPath) // Ensure this collection path is correct
            .where('userId', isEqualTo: currentUser?.uid)
            .orderBy('dateTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('You have no orders yet.'));
          }

          final orders = snapshot.data!.docs.map((doc) => OrderItem.fromFirestore(doc)).toList();

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return OrderItemCard(order: order);
            },
          );
        },
      ),
    );
  }
}
