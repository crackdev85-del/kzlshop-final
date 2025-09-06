
import 'package:flutter/material.dart';
import 'package:myapp/providers/cart_provider.dart';
import 'package:provider/provider.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('သင်၏ ဈေးဝယ်စာရင်း'), // "Your Cart" in Burmese
      ),
      body: Column(
        children: <Widget>[
          Card(
            margin: const EdgeInsets.all(15),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Text(
                    'စုစုပေါင်း', // "Total" in Burmese
                    style: TextStyle(fontSize: 20),
                  ),
                  const Spacer(),
                  Chip(
                    label: Text(
                      '${cart.totalAmount.toStringAsFixed(0)} ကျပ်', // "Kyat" in Burmese
                      style: TextStyle(
                        color: Theme.of(context).primaryTextTheme.titleLarge?.color,
                      ),
                    ),
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  TextButton(
                    onPressed: cart.totalAmount <= 0 ? null : () {
                      // TODO: Implement actual order logic (e.g., save to Firestore)
                       ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Order placed successfully! (simulation)'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      cart.clearCart();
                    },
                    child: const Text('မှာယူမည်'),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: cart.items.length,
              itemBuilder: (ctx, i) {
                final cartItem = cart.items.values.toList()[i];
                final productId = cart.items.keys.toList()[i];
                return Dismissible(
                  key: ValueKey(cartItem.id),
                  background: Container(
                    color: Theme.of(context).colorScheme.error,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 4,
                    ),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (direction) {
                    return showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Are you sure?'),
                        content: const Text(
                          'Do you want to remove the item from the cart?',
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
                  },
                  onDismissed: (direction) {
                    Provider.of<CartProvider>(context, listen: false)
                        .removeItem(productId);
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 4,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: FittedBox(
                              child: Text('${cartItem.price}', style: const TextStyle(color: Colors.white)),
                            ),
                          ),
                        ),
                        title: Text(cartItem.name),
                        subtitle: Text(
                            'Total: ${(cartItem.price * cartItem.quantity)} ကျပ်'),
                        trailing: Text('${cartItem.quantity} x'),
                      ),
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
