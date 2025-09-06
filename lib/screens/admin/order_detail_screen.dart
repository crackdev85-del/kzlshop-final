
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/constants.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  DocumentSnapshot? _order;
  bool _isLoading = true;
  String? _selectedStatus;

  final List<String> _orderStatuses = [
    'Order Placed',
    'Processing',
    'Shipped',
    'Completed',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
  }

  Future<void> _fetchOrderDetails() async {
    try {
      final doc = await FirebaseFirestore.instance.collection(ORDERS_COLLECTION_PATH).doc(widget.orderId).get();
      if (mounted) {
        setState(() {
          _order = doc;
          _selectedStatus = (doc.data() as Map<String, dynamic>)['status'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching order details: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateStatus() async {
    if (_selectedStatus == null) return;

    try {
      await FirebaseFirestore.instance.collection(ORDERS_COLLECTION_PATH).doc(widget.orderId).update({
        'status': _selectedStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order status updated successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_order == null || !_order!.exists) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Details')),
        body: const Center(child: Text('Order not found!')),
      );
    }

    final orderData = _order!.data() as Map<String, dynamic>;
    final Timestamp timestamp = orderData['createdAt'] ?? Timestamp.now();
    final String formattedDate = DateFormat('dd MMM, yyyy, hh:mm a').format(timestamp.toDate());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order ID: ${widget.orderId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Text('Placed on: $formattedDate'),
            const Divider(height: 30),

            // Shipping Details Section
            const Text('Shipping Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text('User: ${orderData['userName'] ?? 'N/A'}'),
            Text('Address: ${orderData['address'] ?? 'N/A'}'),
            Text('Township: ${orderData['township'] ?? 'N/A'}'),
            Text('Phone: ${orderData['phoneNumber'] ?? 'N/A'}'),
            const Divider(height: 30),

            const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            if (orderData.containsKey('items') && orderData['items'] is List) ...[
              ...List.generate(orderData['items'].length, (index) {
                  final item = orderData['items'][index] as Map<String, dynamic>;
                  return ListTile(
                    title: Text(item['productName'] ?? 'Unknown Product'),
                    subtitle: Text('Quantity: ${item['quantity']}'),
                    trailing: Text('MMK ${item['price']}'),
                  );
              })
            ],
            const Divider(height: 30),

            Align(
              alignment: Alignment.centerRight,
              child: Text('Total Amount: MMK ${orderData['totalAmount'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            const SizedBox(height: 30),

            const Text('Update Status:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: _orderStatuses.map((status) {
                return DropdownMenuItem<String>(
                  value: status,
                  child: Text(status),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateStatus,
              child: const Text('Save Status'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            ),
          ],
        ),
      ),
    );
  }
}
