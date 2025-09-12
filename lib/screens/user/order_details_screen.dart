import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:moegyi/models/order_item.dart';

class OrderDetailsScreen extends StatelessWidget {
  final OrderItem order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDate = DateFormat('dd-MM-yyyy, hh:mm a').format(order.dateTime);

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${order.orderNumber}', style: TextStyle(color: theme.colorScheme.onPrimary)),
        backgroundColor: theme.colorScheme.primary,
        iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order Details', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(theme, Icons.receipt, 'Order Number', order.orderNumber.toString()),
                    const Divider(height: 24),
                    _buildDetailRow(theme, Icons.calendar_today, 'Date', formattedDate),
                    const SizedBox(height: 8),
                    _buildDetailRow(theme, Icons.info_outline, 'Status', order.status),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Items', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: order.products.length,
              itemBuilder: (context, index) {
                final item = order.products[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  child: ListTile(
                    title: Text(item.name, style: theme.textTheme.titleMedium),
                    subtitle: Text('Quantity: ${item.quantity}'),
                    trailing: Text('${item.price.toStringAsFixed(2)} Kyat', style: theme.textTheme.bodyLarge),
                  ),
                );
              },
            ),
            const Divider(height: 32),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Total: ${order.totalAmount.toStringAsFixed(2)} Kyat',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(ThemeData theme, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.secondary),
        const SizedBox(width: 12),
        Text('$label: ', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.end,
            softWrap: true,
          ),
        ),
      ],
    );
  }
}
