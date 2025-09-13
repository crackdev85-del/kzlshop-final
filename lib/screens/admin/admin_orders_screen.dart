
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:moegyi/constants.dart';
import 'package:moegyi/providers/order_provider.dart';
import 'package:moegyi/screens/admin/edit_order_products_screen.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

// This screen now uses a StreamBuilder to show real-time details of a SINGLE order.
class AdminOrdersScreen extends StatefulWidget {
  final String orderId;

  const AdminOrdersScreen({super.key, required this.orderId});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {

  void _showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: const Text('Confirm'),
            onPressed: () {
              onConfirm();
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  void _updateStatus(String newStatus) {
    Provider.of<OrderProvider>(context, listen: false)
        .updateOrderStatus(widget.orderId, newStatus)
        .then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order status updated to $newStatus')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $error')),
      );
    });
  }

  void _deleteOrder() {
    Provider.of<OrderProvider>(context, listen: false)
        .deleteOrder(widget.orderId)
        .then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order successfully deleted')),
      );
      // Pop the screen to go back to the orders list tab
      Navigator.of(context).pop();
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete order: $error')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection(ordersCollectionPath)
            .doc(widget.orderId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
                appBar: AppBar(),
                body: const Center(child: CircularProgressIndicator()));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            // This can happen if the order was deleted.
            // The pop in _deleteOrder should handle this, but it is good practice.
            return Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: const Center(child: Text('Order not found. It may have been deleted.')));
          }

          final orderData = snapshot.data!.data() as Map<String, dynamic>;
          final int orderNumber = orderData['orderNumber'] ?? 0;
          final List<dynamic> products = orderData['products'] ?? [];
          final double totalAmount = (orderData['totalAmount'] ?? 0.0).toDouble();
          final Timestamp? dateTime = orderData['dateTime'] as Timestamp?;
          final String currentStatus = orderData['status'] as String? ?? 'Order Placed';

          return Scaffold(
            appBar: AppBar(
              title: Text('Order #$orderNumber'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete Order',
                  onPressed: () {
                    _showConfirmationDialog(
                      context: context,
                      title: 'Delete Order',
                      content: 'This action cannot be undone. Are you sure?',
                      onConfirm: _deleteOrder,
                    );
                  },
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Information Card
                  UserInfoWidget(userId: orderData['userId'] as String?),
                  const SizedBox(height: 16),

                  // Order Details Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Order Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                tooltip: 'Edit Products',
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => EditOrderProductsScreen(
                                        orderId: widget.orderId,
                                        initialProducts: products,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          _buildSummaryRow('Order Number', '#$orderNumber'),
                          _buildSummaryRow(
                              'Date Placed',
                              dateTime != null
                                  ? DateFormat('dd MMM yyyy, hh:mm a')
                                      .format(dateTime.toDate())
                                  : 'N/A'),
                          const Divider(height: 20),
                          const Text('Products', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          ...products.map((prod) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text('${prod['name']} (x${prod['quantity']})')),
                                  Text('${(prod['price']).toStringAsFixed(2)} Ks'),
                                ],
                              ),
                            );
                          }),
                          const Divider(height: 20),
                          _buildSummaryRow('Total Amount',
                              '${totalAmount.toStringAsFixed(2)} Ks',
                              isTotal: true),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Status Update Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Update Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: currentStatus,
                            decoration: const InputDecoration(
                              labelText: 'Order Status',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              'Order Placed',
                              'Processing',
                              'Shipped',
                              'Delivered',
                              'Cancelled'
                            ]
                                .map((status) => DropdownMenuItem(
                                      value: status,
                                      child: Text(status),
                                    ))
                                .toList(),
                            onChanged: (newValue) {
                              if (newValue != null &&
                                  newValue != currentStatus) {
                                _updateStatus(newValue);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: isTotal ? 16 : 14)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isTotal ? 17 : 15,
            ),
          ),
        ],
      ),
    );
  }
}

class UserInfoWidget extends StatelessWidget {
  final String? userId;

  const UserInfoWidget({super.key, required this.userId});

  Future<void> _launchURL(String url, BuildContext context) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open map: $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null || userId!.isEmpty) {
      return const Card(
          elevation: 2,
          child: ListTile(
              title: Text('Unknown User'),
              subtitle: Text('User ID is missing.')));
    }

    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection(usersCollectionPath).doc(userId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return Card(
              elevation: 2,
              child: ListTile(
                  title: const Text('Unknown User'),
                  subtitle: Text('Error loading data for ID: $userId')));
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final username = userData['username'] ?? 'N/A';
        final shopName = userData['shopName'] ?? 'N/A';
        final phoneNumber = userData['phoneNumber'] ?? 'N/A';
        final dynamic locationValue = userData['location'];
        String locationDisplay = 'Not Provided';
        String? locationUrl;

        if (locationValue is GeoPoint) {
          locationDisplay = 'View on Map (${locationValue.latitude.toStringAsFixed(2)}, ${locationValue.longitude.toStringAsFixed(2)})';
          locationUrl = 'https://www.google.com/maps/search/?api=1&query=${locationValue.latitude},${locationValue.longitude}';
        } else if (locationValue is String && locationValue.isNotEmpty) {
          locationDisplay = locationValue;
          locationUrl = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(locationValue)}';
        }

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Customer Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Divider(),
                ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Username'),
                    subtitle: Text(username)),
                ListTile(
                    leading: const Icon(Icons.store),
                    title: const Text('Shop Name'),
                    subtitle: Text(shopName)),
                ListTile(
                    leading: const Icon(Icons.phone),
                    title: const Text('Phone Number'),
                    subtitle: Text(phoneNumber)),
                if (locationUrl != null)
                  ListTile(
                    leading: const Icon(Icons.location_on),
                    title: const Text('Location'),
                    subtitle: Text(locationDisplay,
                        style: const TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline)),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () => _launchURL(locationUrl!, context),
                  )
                else
                  ListTile(
                      leading: const Icon(Icons.location_off),
                      title: const Text('Location'),
                      subtitle: Text(locationDisplay)),
              ],
            ),
          ),
        );
      },
    );
  }
}
