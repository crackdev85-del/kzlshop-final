import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/providers/order_provider.dart' as ord;
import 'package:provider/provider.dart';

class OrderItemCard extends StatefulWidget {
  final ord.OrderItem order;

  const OrderItemCard({super.key, required this.order});

  @override
  State<OrderItemCard> createState() => _OrderItemCardState();
}

class _OrderItemCardState extends State<OrderItemCard> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      child: Column(
        children: <Widget>[
          ListTile(
            title: Text(
              'Order ID: ${widget.order.id}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              'Total: ${widget.order.totalAmount.toStringAsFixed(2)} Kyat\nPlaced on: ${DateFormat('dd/MM/yyyy hh:mm a').format(widget.order.dateTime)}',
            ),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Chip(
                  label: Text(
                    widget.order.status,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: _getStatusColor(widget.order.status),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                ),
                const SizedBox(width: 8),
                if (widget.order.status == 'Order Placed')
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      final confirmed = await showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Are you sure?'),
                          content: const Text(
                            'Do you want to delete this order?',
                          ),
                          actions: <Widget>[
                            TextButton(
                              child: const Text('No'),
                              onPressed: () {
                                Navigator.of(ctx).pop(false);
                              },
                            ),
                            TextButton(
                              child: const Text('Yes'),
                              onPressed: () {
                                Navigator.of(ctx).pop(true);
                              },
                            ),
                          ],
                        ),
                      );
                      if (confirmed) {
                        try {
                          await Provider.of<ord.OrderProvider>(context, listen: false)
                              .deleteOrder(widget.order.id);
                        } catch (error) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Deleting failed!',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }
                      }
                    },
                  ),
                IconButton(
                  icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () {
                    setState(() {
                      _expanded = !_expanded;
                    });
                  },
                ),
              ],
            ),
          ),
          if (_expanded)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              // Use a Column for better control over the layout
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                  const Text(
                    'Products',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  ...widget.order.products.map((prod) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            prod.name,
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            '${prod.quantity} x ${prod.price.toStringAsFixed(2)} Kyat',
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          )
                        ],
                      ),
                    )),
                 ]
              ),
            )
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'order placed':
        return Colors.blue.shade600;
      case 'processing':
        return Colors.orange.shade600;
      case 'shipped':
        return Colors.purple.shade600;
      case 'delivered':
        return Colors.green.shade600;
      case 'cancelled':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }
}
