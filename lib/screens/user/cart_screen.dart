
import 'package:flutter/material.dart';
import 'package:myapp/providers/cart_provider.dart';
import 'package:myapp/providers/order_provider.dart';
import 'package:myapp/screens/user/product_detail_screen.dart';
import 'package:provider/provider.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final theme = Theme.of(context);

    void showRemoveConfirmationDialog(String productId) {
      showDialog(
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
                Navigator.of(ctx).pop();
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                Provider.of<CartProvider>(context, listen: false).removeItem(productId);
                Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
      );
    }

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
                    'Total',
                    style: TextStyle(fontSize: 20),
                  ),
                  const Spacer(),
                  Chip(
                    label: Text(
                      '${cart.totalAmount.toStringAsFixed(2)} Kyat',
                      style: TextStyle(
                        color: theme.primaryTextTheme.titleLarge?.color,
                      ),
                    ),
                    backgroundColor: theme.primaryColor,
                  ),
                  OrderButton(cart: cart), // Extracted to a new widget
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: cart.items.length,
              itemBuilder: (ctx, i) {
                String productId = cart.items.keys.toList()[i];
                CartItem cartItem = cart.items.values.toList()[i];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 4,
                  ),
                  child: ListTile(
                    onTap: () {
                       // Navigate to Product Detail Screen
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => ProductDetailScreen(productId: productId),
                        ));
                    },
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: FittedBox(
                          child: Text(cartItem.price.toStringAsFixed(0)),
                        ),
                      ),
                    ),
                    title: Text(cartItem.name),
                    subtitle: Text('Total: ${(cartItem.price * cartItem.quantity).toStringAsFixed(2)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${cartItem.quantity} x'),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => showRemoveConfirmationDialog(productId),
                        ),
                      ],
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

// New StatefulWidget for the Order Button to manage its own loading state
class OrderButton extends StatefulWidget {
  const OrderButton({super.key, required this.cart});

  final CartProvider cart;

  @override
  State<OrderButton> createState() => _OrderButtonState();
}

class _OrderButtonState extends State<OrderButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: (widget.cart.totalAmount <= 0 || _isLoading)
          ? null
          : () async {
              setState(() {
                _isLoading = true;
              });
              try {
                await Provider.of<OrderProvider>(context, listen: false).addOrder(
                  widget.cart.items.values.toList(),
                  widget.cart.totalAmount,
                );
                widget.cart.clearCart();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('သင် မှာယူပြီးပါပြီ ကျွန်တော်တို့လက်ခံပေးပါမယ် ခေတ္တစောင့်ဆိုင်းပေးပါနော်'),
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
              }
              setState(() {
                _isLoading = false;
              });
            },
      child: _isLoading ? const CircularProgressIndicator() : const Text('ORDER NOW'),
    );
  }
}
