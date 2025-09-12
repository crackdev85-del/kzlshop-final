
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:moegyi/constants.dart';
import 'package:moegyi/providers/order_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'order_detail_screen.dart';

// Main widget to display a list of orders
class OrdersTab extends StatelessWidget {
  const OrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // Stream data from the orders collection, ordering by the most recent
      stream: FirebaseFirestore.instance
          .collection(ordersCollectionPath)
          .orderBy('dateTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        // Show a loading indicator while waiting for data
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        // Show an error message if something goes wrong
        if (snapshot.hasError) {
          return Center(
            child: Text('An error occurred: ${snapshot.error}'),
          );
        }
        // Show a message if there are no orders
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No orders found.'));
        }

        final orderDocs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: orderDocs.length,
          itemBuilder: (context, index) {
            // Use a separate widget for each order card
            return AdminOrderCard(orderSnapshot: orderDocs[index]);
          },
        );
      },
    );
  }
}

// A card widget to display individual order information
class AdminOrderCard extends StatefulWidget {
  final DocumentSnapshot orderSnapshot;

  const AdminOrderCard({super.key, required this.orderSnapshot});

  @override
  State<AdminOrderCard> createState() => _AdminOrderCardState();
}

class _AdminOrderCardState extends State<AdminOrderCard> {
  bool _expanded = false;

  // Function to show a generic confirmation dialog
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

  @override
  Widget build(BuildContext context) {
    final orderData = widget.orderSnapshot.data() as Map<String, dynamic>?;

    // Handle cases where order data might be null
    if (orderData == null) {
      return const Card(
        child: ListTile(
          title: Text('Invalid order data'),
        ),
      );
    }

    final orderId = widget.orderSnapshot.id;
    final String userId = orderData['userId'] ?? '';
    final List<dynamic> products = orderData['products'] ?? [];
    final double totalAmount = (orderData['totalAmount'] ?? 0.0).toDouble();
    final Timestamp? dateTime = orderData['dateTime'] as Timestamp?;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 3,
      child: Column(
        children: [
          ListTile(
            // Use a dedicated widget to fetch and display user info
            title: UserInfoWidget(userId: userId),
            subtitle: Text(
              'Total: ${totalAmount.toStringAsFixed(2)} Ks\n'
              'Time: ${dateTime != null ? DateFormat('dd/MM/yy hh:mm a').format(dateTime.toDate()) : 'N/A'}',
            ),
            isThreeLine: true,
            onTap: () => setState(() => _expanded = !_expanded),
            trailing: IconButton(
              icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () => setState(() => _expanded = !_expanded),
            ),
          ),
          // Expanded section with more details and actions
          if (_expanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Items:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  // Display list of products in the order
                  ...products.map((prod) {
                    final String name = prod['name'] ?? 'Unknown Product';
                    final int quantity = (prod['quantity'] ?? 0).toInt();
                    final double price = (prod['price'] ?? 0.0).toDouble();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text('$name (x$quantity)')),
                          Text('${price.toStringAsFixed(2)} Ks'),
                        ],
                      ),
                    );
                  }),
                  const Divider(height: 24),
                  // Action buttons for the order
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Accept Order
                      TextButton.icon(
                        icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                        label: const Text('Accept', style: TextStyle(color: Colors.green)),
                        onPressed: () {
                          _showConfirmationDialog(
                            context: context,
                            title: 'Accept Order',
                            content: 'Do you want to accept this order?',
                            onConfirm: () {
                              Provider.of<OrderProvider>(context, listen: false)
                                  .updateOrderStatus(orderId, 'Processing');
                            },
                          );
                        },
                      ),
                      // Edit Order
                      TextButton.icon(
                        icon: Icon(Icons.edit_outlined, color: Theme.of(context).primaryColor),
                        label: Text('Edit', style: TextStyle(color: Theme.of(context).primaryColor)),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => OrderDetailScreen(
                                orderSnapshot: widget.orderSnapshot,
                              ),
                            ),
                          );
                        },
                      ),
                      // Delete Order
                      TextButton.icon(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        label: const Text('Delete', style: TextStyle(color: Colors.red)),
                        onPressed: () {
                          _showConfirmationDialog(
                            context: context,
                            title: 'Delete Order',
                            content: 'This action cannot be undone. Are you sure?',
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

// Widget to fetch and display user information based on userId
class UserInfoWidget extends StatelessWidget {
  final String userId;

  const UserInfoWidget({super.key, required this.userId});

  // Function to launch a URL (for Google Maps)
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Handle case where userId is empty
    if (userId.isEmpty) {
      return const Text('Unknown User (No ID)', style: TextStyle(color: Colors.red));
    }

    return FutureBuilder<DocumentSnapshot>(
      // Fetch user data from the users collection
      future: FirebaseFirestore.instance.collection(usersCollectionPath).doc(userId).get(),
      builder: (context, snapshot) {
        // Show loading text while fetching data
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('Loading User...');
        }
        // Show an error if the user is not found or an error occurs
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return Text(
            'Unknown User (ID: $userId)',
            style: const TextStyle(color: Colors.red, fontStyle: FontStyle.italic),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>?;

        if (userData == null) {
          return const Text('User data is empty', style: TextStyle(color: Colors.red));
        }

        // Extract user details with fallback values
        final shopName = (userData['shopName'] ?? 'Unknown Shop').toString();
        final phoneNumber = (userData['phoneNumber'] ?? 'No Phone Number').toString();
        
        // Handle both GeoPoint and String for location
        final dynamic locationValue = userData['location'];
        String locationDisplay = 'No location provided';
        String locationUrl = '';

        if (locationValue is GeoPoint) {
            locationDisplay = '${locationValue.latitude}, ${locationValue.longitude}';
            locationUrl = 'https://www.google.com/maps/search/?api=1&query=${locationValue.latitude},${locationValue.longitude}';
        } else if (locationValue is String && locationValue.isNotEmpty) {
            locationDisplay = locationValue;
            locationUrl = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(locationValue)}';
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(shopName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              'ID: $userId',
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(phoneNumber),
            const SizedBox(height: 4),
            if (locationUrl.isNotEmpty)
              InkWell(
                onTap: () => _launchURL(locationUrl),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: Theme.of(context).primaryColor, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        locationDisplay,
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Text(locationDisplay), // Shows 'No location provided'
          ],
        );
      },
    );
  }
}
