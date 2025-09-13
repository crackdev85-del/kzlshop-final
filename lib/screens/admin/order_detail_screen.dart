import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:moegyi/models/cart_item.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants.dart';

class OrderDetailScreen extends StatefulWidget {
  final DocumentSnapshot orderSnapshot;

  const OrderDetailScreen({super.key, required this.orderSnapshot});

  @override
  _OrderDetailScreenState createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late Map<String, dynamic> orderData;
  late String orderId;
  late List<CartItem> orderItems;
  late double totalAmount;

  @override
  void initState() {
    super.initState();
    orderData = widget.orderSnapshot.data() as Map<String, dynamic>;
    orderId = widget.orderSnapshot.id;
    final List<dynamic> productItems = orderData['products'] ?? [];
    orderItems =
        productItems.map((item) => CartItem.fromMap(item)).toList();
    totalAmount = orderData['totalAmount'];
  }

  void _showEditQuantityDialog(BuildContext context, CartItem item, int index) {
    final TextEditingController _quantityController = TextEditingController(text: item.quantity.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Quantity'),
        content: TextField(
          controller: _quantityController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'Quantity'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newQuantity = int.tryParse(_quantityController.text);
              if (newQuantity != null && newQuantity > 0) {
                _updateOrderQuantity(index, newQuantity);
                Navigator.of(context).pop();
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateOrderQuantity(int itemIndex, int newQuantity) async {
    final updatedItems = List<CartItem>.from(orderItems);
    final itemToUpdate = updatedItems[itemIndex];
    final newPrice = itemToUpdate.price;
    final oldQuantity = itemToUpdate.quantity;
    updatedItems[itemIndex] = itemToUpdate.copyWith(quantity: newQuantity);

    final newTotalAmount =
        totalAmount - (itemToUpdate.price * oldQuantity) + (newPrice * newQuantity);

    final productsAsMaps = updatedItems.map((item) => item.toMap()).toList();

    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({'products': productsAsMaps, 'totalAmount': newTotalAmount});

      setState(() {
        orderItems = updatedItems;
        totalAmount = newTotalAmount;
        orderData['totalAmount'] = newTotalAmount; // Update local data as well
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update order: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${orderData['orderNumber'] ?? orderId.substring(0, 8)}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserInfoCard(
              userId: orderData['userId'],
              orderId: orderId,
              orderData: orderData,
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
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${item.price.toStringAsFixed(0)} Kyat',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showEditQuantityDialog(context, item, index),
                        ),
                      ],
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
                      '${totalAmount.toStringAsFixed(0)} Kyat',
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
  final Map<String, dynamic> orderData;

  const UserInfoCard({
    super.key,
    required this.userId,
    required this.orderId,
    required this.orderData,
  });

  Future<void> _launchMaps(BuildContext context, GeoPoint? location) async {
    if (location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No location provided.')),
      );
      return;
    }
    final Uri url =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open map')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users') 
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
              subtitle: Text('Error loading user data.'),
            ),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final String username = userData['username'] ?? 'N/A';
        final String shopName = userData['shopName'] ?? 'N/A';
        final GeoPoint? location = userData['geopoint'];
        final String phoneNumber = userData['phone'] ?? 'N/A';

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
                    orderData['orderNumber'] ?? 'N/A'),
                _buildInfoRow(context, Icons.confirmation_number, 'Order ID', orderId),
                _buildInfoRow(context, Icons.person, 'User ID', userId),
                _buildInfoRow(context, Icons.person_outline, 'Username', username),
                _buildInfoRow(context, Icons.phone, 'Phone Number', phoneNumber),
                _buildInfoRow(context, Icons.store, 'Shop Name', shopName),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:
                      Icon(Icons.location_on, color: Theme.of(context).primaryColor),
                  title: const Text('Location'),
                  subtitle: Text(
                    location != null ? "View on Map" : 'Not Provided',
                    style: TextStyle(
                      color: location != null ? Colors.blue : Colors.grey,
                      decoration: location != null
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
