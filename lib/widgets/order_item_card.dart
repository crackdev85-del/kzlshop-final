import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:moegyi/models/order_item.dart';
import 'package:moegyi/screens/user/order_details_screen.dart';

class OrderItemCard extends StatelessWidget {
  final OrderItem order;

  const OrderItemCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDate = DateFormat('dd-MM-yyyy').format(order.dateTime);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => OrderDetailsScreen(order: order),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order.orderNumber}',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Chip(
                    label: Text(order.status),
                    backgroundColor: _getStatusColor(order.status, theme),
                    labelStyle: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Divider(height: 24),
              _buildDetailRow(theme, Icons.calendar_today, 'Order Date', formattedDate),
              const SizedBox(height: 8),
              _buildDetailRow(theme, Icons.monetization_on, 'Total Amount', '${order.totalAmount.toStringAsFixed(2)} Kyat'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(ThemeData theme, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.secondary),
        const SizedBox(width: 12),
        Text('$label: ', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
        Expanded(
          child: Text(value, style: theme.textTheme.bodyMedium, textAlign: TextAlign.end),
        ),
      ],
    );
  }

  Color _getStatusColor(String status, ThemeData theme) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange.shade600;
      case 'processing':
        return Colors.blue.shade600;
      case 'shipped':
        return Colors.cyan.shade600;
      case 'delivered':
        return Colors.green.shade600;
      case 'cancelled':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade500;
    }
  }
}
