import 'package:flutter/material.dart';
import 'package:moegyi/providers/cart_provider.dart';
import 'package:moegyi/providers/order_provider.dart';
import 'package:moegyi/widgets/cart_item_card.dart';
import 'package:provider/provider.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  void _showRemoveConfirmationDialog(
      BuildContext context, String productId, CartProvider cart) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Are you sure?'),
        content: const Text('Do you want to remove the item from the cart?'),
        actions: <Widget>[
          TextButton(
            child: const Text('No'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: const Text('Yes'),
            onPressed: () {
              cart.removeItem(productId);
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: cart.items.isEmpty
                ? const Center(
                    child: Text(
                      'Your cart is empty.',
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                : ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (ctx, i) {
                      final cartItem = cart.items.values.toList()[i];
                      final productId = cart.items.keys.toList()[i];
                      return CartItemCard(
                        cartItem: cartItem,
                        onRemove: () =>
                            _showRemoveConfirmationDialog(context, productId, cart),
                        onQuantityChanged: (newQuantity) {
                          final currentItem = cart.items[productId];
                          if (currentItem != null) {
                            if (newQuantity > currentItem.quantity) {
                                cart.addSingleItem(productId);
                            } else if (newQuantity < currentItem.quantity) {
                                cart.removeSingleItem(productId);
                            }
                          }
                        },
                      );
                    },
                  ),
          ),
          if (cart.items.isNotEmpty) CheckoutCard(cart: cart),
        ],
      ),
    );
  }
}

class CheckoutCard extends StatefulWidget {
  final CartProvider cart;

  const CheckoutCard({super.key, required this.cart});

  @override
  State<CheckoutCard> createState() => _CheckoutCardState();
}

class _CheckoutCardState extends State<CheckoutCard> {
  var _isLoading = false;

  void _placeOrder() async {
    if (widget.cart.items.isEmpty || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
       await Provider.of<OrderProvider>(context, listen: false).addOrder(
        widget.cart.items.values.map((cartItem) => {
              'id': cartItem.id,
              'name': cartItem.name,
              'quantity': cartItem.quantity,
              'price': cartItem.price,
              'image': cartItem.image,
            }).toList(),
        widget.cart.totalAmount,
        '', // address
        '', // phone
      );
      widget.cart.clear();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order placed successfully!'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ordering failed! Please try again later.'),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.all(15),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const Text('Total', style: TextStyle(fontSize: 20)),
            const Spacer(),
            Chip(
              label: Text(
                '${widget.cart.totalAmount.toStringAsFixed(2)} Kyat',
                style: TextStyle(
                  color: theme.primaryTextTheme.titleLarge?.color,
                ),
              ),
              backgroundColor: theme.primaryColor,
            ),
            TextButton(
              onPressed: (widget.cart.totalAmount <= 0 || _isLoading) ? null : _placeOrder,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : Text(
                      'ORDER NOW',
                      style: TextStyle(color: theme.primaryColor),
                    ),
            )
          ],
        ),
      ),
    );
  }
}
