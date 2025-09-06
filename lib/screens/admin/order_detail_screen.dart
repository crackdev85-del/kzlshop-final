
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/constants.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  _OrderDetailScreenState createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  String? _currentStatus;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection(ordersCollectionPath)
            .doc(widget.orderId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Order not found.'));
          }

          final orderData = snapshot.data!.data() as Map<String, dynamic>;
          _currentStatus ??= orderData['status'] ?? 'pending';
          final List<dynamic> items = orderData['items'] ?? [];
          final Timestamp timestamp = orderData['createdAt'];
          final String formattedDate =
              DateFormat('dd-MM-yyyy, hh:mm a').format(timestamp.toDate());

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection(usersCollectionPath).doc(orderData['userId']).get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (userSnapshot.hasError || !userSnapshot.data!.exists) {
                 return _buildOrderDetails(context, orderData, 'N/A', items, formattedDate);
              }

              final userData = userSnapshot.data!.data() as Map<String, dynamic>;
              final customerName = userData['username'] ?? 'Unknown User';

              return _buildOrderDetails(context, orderData, customerName, items, formattedDate);
            }
          );
        },
      ),
    );
  }

  Widget _buildOrderDetails(BuildContext context, Map<String, dynamic> orderData, String customerName, List<dynamic> items, String formattedDate) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order ID: ${widget.orderId}', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          _buildDetailRow('Customer:', customerName),
          _buildDetailRow('Order Date:', formattedDate),
          _buildDetailRow('Total Amount:', 'MMK ${orderData['totalAmount'].toStringAsFixed(2)}'),
          _buildDetailRow('Shipping Address:', (orderData['shippingAddress']?['addressLine'] ?? "N/A") + ", " + (orderData['shippingAddress']?['township'] ?? "N/A")),
          const SizedBox(height: 24),
          _buildStatusSection(context, orderData),
          const SizedBox(height: 24),
          Text('Items Ordered', style: theme.textTheme.titleMedium),
          const Divider(),
          ...items.map((item) => _buildItemTile(item)).toList(),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildStatusSection(BuildContext context, Map<String, dynamic> orderData) {
    final List<String> statuses = ['pending', 'processing', 'shipped', 'delivered', 'cancelled'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Order Status', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _currentStatus,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
                items: statuses.map((String status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status.replaceFirst(status[0], status[0].toUpperCase())),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _currentStatus = newValue;
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: _currentStatus == orderData['status'] ? null : () {
                _updateOrderStatus();
              },
              child: const Text('Update'),
            )
          ],
        ),
      ],
    );
  }

  void _updateOrderStatus() {
    if (_currentStatus != null) {
      FirebaseFirestore.instance
          .collection(ordersCollectionPath)
          .doc(widget.orderId)
          .update({'status': _currentStatus}).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order status updated successfully!')),
        );
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $error')),
        );
      });
    }
  }

  Widget _buildItemTile(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: item['imageUrl'] != null
            ? Image.network(item['imageUrl'], width: 50, height: 50, fit: BoxFit.cover)
            : const Icon(Icons.shopping_cart),
        title: Text(item['name'] ?? 'N/A'),
        subtitle: Text('Quantity: ${item['quantity']}'),
        trailing: Text('MMK ${(item['price'] * item['quantity']).toStringAsFixed(2)}'),
      ),
    );
  }
}
