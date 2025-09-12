import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:moegyi/models/cart_item.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants.dart';

class OrderDetailScreen extends StatelessWidget {
  final DocumentSnapshot orderSnapshot;

  const OrderDetailScreen({super.key, required this.orderSnapshot});

  @override
  Widget build(BuildContext context) {
    final orderData = orderSnapshot.data() as Map<String, dynamic>;
    final orderId = orderSnapshot.id;
    final List<dynamic> productItems = orderData['products'] ?? [];
    final List<CartItem> orderItems =
        productItems.map((item) => CartItem.fromMap(item)).toList();

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${orderId.substring(0, 8)}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserInfoCard(
              userId: orderData['userId'],
              orderId: orderId,
            ),
            const SizedBox(height: 24),
            Text(
              'Order Items',
              style: theme.textTheme.titleLarge,
            ),
            const Divider(),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: orderItems.length,
              itemBuilder: (context, index) {
                final CartItem item = orderItems[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: OrderItemImage(imageData: item.image),
                    title: Text(item.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Quantity: ${item.quantity}'),
                    trailing: Text(
                      '${item.price.toStringAsFixed(2)} Kyat',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Summary',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: 20),
                    _buildSummaryRow(
                      'Date Placed',
                      DateFormat('dd MMM yyyy, hh:mm a')
                          .format((orderData['dateTime'] as Timestamp).toDate()),
                    ),
                    _buildSummaryRow(
                      'Status',
                      orderData['status'],
                      statusColor: _getStatusColor(orderData['status']),
                    ),
                    const Divider(height: 20),
                    _buildSummaryRow(
                      'Total Amount',
                      '${orderData['totalAmount'].toStringAsFixed(2)} Kyat',
                      isTotal: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {Color? statusColor, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: isTotal ? 17 : 15)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: statusColor,
              fontSize: isTotal ? 18 : 16,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Processing':
        return Colors.orange;
      case 'Shipped':
        return Colors.blue;
      case 'Delivered':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey.shade700;
    }
  }
}

class OrderItemImage extends StatelessWidget {
  final dynamic imageData;

  const OrderItemImage({super.key, this.imageData});

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    Uint8List? imageBytes;

    if (imageData is String && imageData.isNotEmpty) {
      try {
        final String cleanBase64 =
            imageData.contains(',') ? imageData.split(',').last : imageData;
        imageBytes = base64Decode(cleanBase64);
      } catch (e) {
        imageBytes = null;
      }
    } else if (imageData is Uint8List) {
      imageBytes = imageData;
    }

    if (imageBytes != null && imageBytes.isNotEmpty) {
      imageWidget = Image.memory(
        imageBytes,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) =>
            const Icon(Icons.broken_image, size: 50),
      );
    } else {
      imageWidget = const Icon(Icons.shopping_bag, size: 30);
    }

    return SizedBox(
      width: 50,
      height: 50,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: imageWidget,
      ),
    );
  }
}

class UserInfoCard extends StatelessWidget {
  final String userId;
  final String orderId;

  const UserInfoCard({
    super.key,
    required this.userId,
    required this.orderId,
  });

  Future<void> _launchMaps(BuildContext context, String location) async {
    if (location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No location provided.')),
      );
      return;
    }
    final Uri url =
        Uri.parse('https://www.google.com/maps?q=${Uri.encodeComponent(location)}');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open map for $location')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection(usersCollectionPath)
          .doc(userId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return const Card(
            child: ListTile(
              title: Text('Unknown User'),
              subtitle: Text('Error loading user data. Check collection path.'),
            ),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final String username = userData['name'] ?? 'N/A';
        final String location = userData['address'] ?? '';

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Customer Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                _buildInfoRow(context, Icons.receipt_long, 'Order Number',
                    '#${orderId.substring(0, 8)}...'),
                _buildInfoRow(context, Icons.person, 'Username', username),
                _buildInfoRow(context, Icons.store, 'Shop Name', 'MoeGyi Shop'),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:
                      Icon(Icons.location_on, color: Theme.of(context).primaryColor),
                  title: const Text('Location'),
                  subtitle: Text(
                    location.isNotEmpty ? location : 'Not Provided',
                    style: TextStyle(
                      color: location.isNotEmpty ? Colors.blue : Colors.grey,
                      decoration: location.isNotEmpty
                          ? TextDecoration.underline
                          : TextDecoration.none,
                    ),
                  ),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _launchMaps(context, location),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(
      BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 16),
          Text('$label: ', style: const TextStyle(fontSize: 15)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
