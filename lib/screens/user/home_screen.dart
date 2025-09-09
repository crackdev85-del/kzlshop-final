import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myapp/constants.dart';
import 'package:myapp/providers/cart_provider.dart';
import 'package:myapp/screens/admin/admin_home_screen.dart';
import 'package:myapp/screens/user/cart_screen.dart';
import 'package:myapp/screens/user/my_orders_screen.dart'; 
import 'package:myapp/widgets/product_card.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  final PageController pageController;
  const HomeScreen({super.key, required this.pageController});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _getUserRole();
  }

  Future<void> _getUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection(usersCollectionPath)
            .doc(user.uid)
            .get();
        if (doc.exists && mounted) {
          setState(() {
            _userRole = doc.data()!['role'];
          });
        }
      } catch (e) {
        debugPrint('Error getting user role: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _userRole == 'admin' ? 'Admin Panel' : 'KZL Shop',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onPrimary,
          ),
        ),
        actions: [
          if (_userRole == 'admin')
            IconButton(
              tooltip: 'Admin Dashboard',
              icon: const Icon(Icons.dashboard),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminHomeScreen(),
                  ),
                );
              },
            ),
          // My Orders Button
          IconButton(
            tooltip: 'My Orders',
            icon: const Icon(Icons.receipt_long),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyOrdersScreen()),
              );
            },
          ),
          Consumer<CartProvider>(
            builder: (context, cart, child) => Badge(
              label: Text(cart.itemCount.toString()),
              isLabelVisible: cart.itemCount > 0,
              child: IconButton(
                tooltip: 'My Cart',
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                   Navigator.push(context, MaterialPageRoute(builder: (context) => const CartScreen()));
                },
              ),
            ),
          ),
          IconButton(
            tooltip: 'My Profile',
            icon: const Icon(Icons.person),
            onPressed: () {
              widget.pageController.animateToPage(3, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(productsCollectionPath)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Something went wrong',
                style: theme.textTheme.bodyMedium,
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No products available right now.',
                style: theme.textTheme.bodyMedium,
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 0.75,
            ),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final productDoc = snapshot.data!.docs[index];
              return ProductCard(product: productDoc);
            },
          );
        },
      ),
    );
  }
}
