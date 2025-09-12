import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:moegyi/constants.dart';
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher

class AdminOrdersScreen extends StatelessWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Orders'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(ordersCollectionPath)
            .orderBy('orderDate', descending: true)
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
      ),
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
            onPressed: () {
              Navigator.of(ctx).pop();
            },
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

  @override
  Widget build(BuildContext context) {
    final orderData = widget.orderSnapshot.data() as Map<String, dynamic>;
    final orderId = widget.orderSnapshot.id;
    final int orderNumber = orderData['orderNumber'] ?? 0;
    final List<dynamic> products = orderData['products'] ?? [];
    final String currentStatus = orderData['status'] ?? 'Order Placed';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: currentStatus == 'Received'
            ? const BorderSide(color: Colors.green, width: 2)
            : BorderSide.none,
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(
              'Order #$orderNumber',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: UserInfoWidget(userId: orderData['userId']),
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
                  Text(
                      'Order Date: ${DateFormat('dd/MM/yy hh:mm a').format((orderData['orderDate'] as Timestamp).toDate())}'),
                  const SizedBox(height: 8),
                  Text('Total: ${orderData['totalAmount'].toStringAsFixed(2)} Kyat',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Products:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  ...products.map((prod) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                              child: Text('${prod['name']} (x${prod['quantity']})')),
                          Text('${(prod['price']).toStringAsFixed(2)} Kyat'),
                        ],
                      ),
                    );
                  }),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.check_circle_outline,
                            color: Colors.green),
                        label: const Text('Receive',
                            style: TextStyle(color: Colors.green)),
                        onPressed: () {
                          _showConfirmationDialog(
                            context: context,
                            title: 'Receive Order',
                            content:
                                'Are you sure you want to mark this order as received?',
                            onConfirm: () {
                              FirebaseFirestore.instance
                                  .collection(ordersCollectionPath)
                                  .doc(orderId)
                                  .update({'status': 'Received'});
                            },
                          );
                        },
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                        label: const Text('Edit', style: TextStyle(color: Colors.blue)),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Edit functionality is not yet implemented.')),
                          );
                        },
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        label:
                            const Text('Delete', style: TextStyle(color: Colors.red)),
                        onPressed: () {
                          _showConfirmationDialog(
                            context: context,
                            title: 'Delete Order',
                            content:
                                'Are you sure you want to delete this order? This action cannot be undone.',
                            onConfirm: () {
                              FirebaseFirestore.instance
                                  .collection(ordersCollectionPath)
                                  .doc(orderId)
                                  .delete();
                            },
                          );
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

class UserInfoWidget extends StatelessWidget {
  final String userId;

  const UserInfoWidget({super.key, required this.userId});

  // Function to launch Google Maps
  Future<void> _launchMaps(double lat, double lon, BuildContext context) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lon');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open Google Maps.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection(usersCollectionPath).doc(userId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('Loading user info...');
        }
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return const Text('Unknown User',
              style: TextStyle(color: Colors.red, fontStyle: FontStyle.italic));
        }
        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final username = userData['username'] ?? 'N/A';
        final shopName = userData['shopName'] ?? 'N/A';
        final address = userData['address'] ?? 'No address provided';
        final GeoPoint? geoPoint = userData['location'];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User: $username', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text('Shop: $shopName', style: const TextStyle(fontStyle: FontStyle.italic)),
            const SizedBox(height: 4),
            if (geoPoint != null)
              InkWell(
                onTap: () => _launchMaps(geoPoint.latitude, geoPoint.longitude, context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on, color: Colors.blue.shade700, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        address, // Display the readable address
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          decoration: TextDecoration.underline,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )
            else
              Text('Location: $address', style: TextStyle(color: Colors.grey[600])),
          ],
        );
      },
    );
  }
}
