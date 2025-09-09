import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/providers/cart_provider.dart';
import 'package:myapp/providers/order_provider.dart';

class CheckoutScreen extends StatefulWidget {
  static const routeName = '/checkout';

  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shippingAddressController = TextEditingController();
  final _phoneNumberController = TextEditingController();

  @override
  void dispose() {
    _shippingAddressController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Checkout', style: TextStyle(color: theme.colorScheme.onPrimary)),
        backgroundColor: theme.colorScheme.primary,
        iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),

      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                'Order Summary',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              ...cart.items.values.map((item) => ListTile(
                    title: Text(item.name),
                    subtitle: Text('Quantity: ${item.quantity}'),
                    trailing: Text(
                      '${(item.price * item.quantity).toStringAsFixed(2)} Kyat',
                      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                    ),
                  )),
              const Divider(),
              ListTile(
                title: Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color, fontSize: theme.textTheme.titleLarge?.fontSize),
                ),
                trailing: Text(
                  '${cart.totalAmount.toStringAsFixed(2)} Kyat',
                  style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color, fontSize: theme.textTheme.titleLarge?.fontSize),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Shipping Information',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _shippingAddressController,
                decoration: const InputDecoration(
                  labelText: 'Shipping Address',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a shipping address.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneNumberController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a phone number.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);
                    try {
                      await Provider.of<OrderProvider>(context, listen: false).addOrder(
                        cart.items.values.map((item) => item.toMap()).toList(),
                        cart.totalAmount,
                      );
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(content: Text('Order placed successfully!')),
                      );
                      navigator.pop(); // Go back to the previous screen
                    } catch (error) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(content: Text('Failed to place order: $error')),
                      );
                    }
                  }
                },
                child: const Text('Place Order'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
