import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:moegyi/models/order_item.dart';

class OrderDetailsScreen extends StatelessWidget {
  final OrderItem order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${order.orderNumber}'),
        backgroundColor: theme.primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order Details',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildDetailRow(context, 'Order Number', '#${order.orderNumber}'),
                      _buildDetailRow(context, 'Order Date', DateFormat.yMMMd().format(order.dateTime)),
                      _buildDetailRow(context, 'Total Amount', '${order.totalAmount.toInt()} Kyat'),
                      _buildDetailRow(context, 'Status', order.status),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Items Ordered',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              // Builds a list of items in the order.
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: order.products.length,
                itemBuilder: (context, index) {
                  final item = order.products[index];
                  final totalPrice = item.price * item.quantity;
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text(item.name),
                      subtitle: Text('Quantity: ${item.quantity} x ${item.price.toInt()} Kyat'),
                      trailing: Text('${totalPrice.toInt()} Kyat'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.titleMedium),
          Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
