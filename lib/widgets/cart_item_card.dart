import 'package:flutter/material.dart';
import 'package:moegyi/models/cart_item.dart';

class CartItemCard extends StatelessWidget {
  final CartItem cartItem;
  final Function()? onRemove;
  final Function(int)? onQuantityChanged;

  const CartItemCard({super.key, 
    required this.cartItem,
    this.onRemove,
    this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productData = cartItem.product.data() as Map<String, dynamic>;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                productData['imageUrl'] ?? '',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => 
                  Container(width: 80, height: 80, color: Colors.grey[200], child: const Icon(Icons.image, color: Colors.grey)),
              ),
            ),
            const SizedBox(width: 16),
            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productData['name'] ?? 'No Name',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${productData['price']?.toStringAsFixed(2) ?? '0.00'} Kyat',
                    style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            // Quantity and Remove Button
            if (onQuantityChanged != null && onRemove != null) // Only show controls if callbacks are provided
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 22),
                    onPressed: () => onQuantityChanged!(cartItem.quantity - 1),
                  ),
                  Text('${cartItem.quantity}', style: theme.textTheme.titleMedium),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 22),
                    onPressed: () => onQuantityChanged!(cartItem.quantity + 1),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 24),
                    onPressed: onRemove,
                    tooltip: 'Remove',
                  ),
                ],  
              ) 
            else // Display quantity for order details
                Text('Qty: ${cartItem.quantity}', style: theme.textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
