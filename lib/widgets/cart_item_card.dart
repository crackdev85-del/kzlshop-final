import 'package:flutter/material.dart';
import 'package:moegyi/models/cart_item.dart';

class CartItemCard extends StatelessWidget {
  final CartItem cartItem;
  final Function()? onRemove;
  final Function(int)? onQuantityChanged;

  const CartItemCard({
    super.key,
    required this.cartItem,
    this.onRemove,
    this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          children: [
            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cartItem.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${cartItem.price.toStringAsFixed(2)} Kyat',
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Quantity and Remove
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onQuantityChanged != null)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 22),
                    onPressed: () {
                      if (cartItem.quantity > 1) {
                        onQuantityChanged!(cartItem.quantity - 1);
                      } else {
                        // If quantity is 1, a common behavior is to ask for removal.
                        // Or simply do nothing. Here we call onRemove if available.
                        if (onRemove != null) {
                           onRemove!();
                        }
                      }
                    },
                  ),
                Text(
                  cartItem.quantity.toString(),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                if (onQuantityChanged != null)
                  IconButton(
                    icon: Icon(Icons.add_circle_outline, size: 22, color: theme.primaryColor),
                    onPressed: () => onQuantityChanged!(cartItem.quantity + 1),
                  ),
                if (onRemove != null && onQuantityChanged == null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: onRemove,
                  )
              ],
            ),
          ],
        ),
      ),
    );
  }
}