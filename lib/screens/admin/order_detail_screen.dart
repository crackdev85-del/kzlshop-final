
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/constants.dart';

class OrderDetailScreen extends StatelessWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection(ordersCollectionPath).doc(orderId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong.'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Order not found.'));
          }

          final data = snapshot.data!.data();
          if (data == null || data is! Map<String, dynamic>) {
            return const Center(child: Text('Order data is invalid.'));
          }
          final orderData = data;

          final items = orderData['items'] is List ? orderData['items'] as List<dynamic> : <dynamic>[];
          final createdAt = orderData['createdAt'] is Timestamp 
              ? (orderData['createdAt'] as Timestamp).toDate()
              : DateTime.now();
          final status = orderData['status'] as String? ?? 'Status Unknown';
          final total = orderData['total'] as num? ?? 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order ID: ${snapshot.data!.id}', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('Date: ${DateFormat.yMMMd().add_jms().format(createdAt)}'),
                const SizedBox(height: 8),
                Text('Status: $status'),
                const SizedBox(height: 16),
                Text('Items:', style: Theme.of(context).textTheme.titleMedium),
                const Divider(),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    if (item is! Map<String, dynamic>) {
                      return const ListTile(title: Text('Invalid item data'));
                    }
                    
                    final imageUrl = item['imageUrl'] as String?;
                    final name = item['name'] as String? ?? 'Unnamed Product';
                    final quantity = item['quantity'] as num? ?? 0;
                    final price = item['price'] as num? ?? 0.0;

                    return ListTile(
                      leading: SizedBox(
                        width: 50,
                        height: 50,
                        child: (imageUrl != null && imageUrl.isNotEmpty)
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.broken_image, size: 50);
                                },
                              )
                            : const Icon(Icons.image_not_supported, size: 50),
                      ),
                      title: Text(name),
                      subtitle: Text('Quantity: $quantity'),
                      trailing: Text('\$${price.toStringAsFixed(2)}'),
                    );
                  },
                ),
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total:', style: Theme.of(context).textTheme.titleMedium),
                    Text('\$${total.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                 const SizedBox(height: 32),
                // TODO: Implement status update functionality for admin
              ],
            ),
          );
        },
      ),
    );
  }
}
