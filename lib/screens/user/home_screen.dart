import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:moegyi/constants.dart'; // Re-import constants
import 'package:moegyi/providers/cart_provider.dart';
import 'package:moegyi/screens/login_screen.dart';
import 'package:moegyi/screens/user/cart_screen.dart';
import 'package:moegyi/screens/user/my_orders_screen.dart';
import 'package:moegyi/widgets/announcement_slideshow.dart';
import 'package:moegyi/widgets/product_grid.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  final PageController pageController;
  const HomeScreen({super.key, required this.pageController});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _userRole;
  String? _selectedCategoryId;

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
            .collection(usersCollectionPath) // Use constant from constants.dart
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
    } else {
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      _navigateToLogin();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to log out: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildCategoryCarousel() {
    final theme = Theme.of(context);
    return SizedBox(
      height: 110,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('categories').snapshots(), // Keep hardcoded path for categories
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading categories'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final categories = snapshot.data!.docs;

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: categories.length + 1, // +1 for "All"
            itemBuilder: (context, index) {
              // "All" Category Button
              if (index == 0) {
                final isSelected = _selectedCategoryId == null;
                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategoryId = null;
                      });
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: isSelected ? theme.colorScheme.primary.withOpacity(0.2) : theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? theme.colorScheme.primary : Colors.grey.shade300,
                              width: 1.5,
                            ),
                          ),
                          child: Icon(Icons.apps, color: theme.colorScheme.primary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "All",
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }

              final categoryDoc = categories[index - 1];
              final categoryData = categoryDoc.data() as Map<String, dynamic>;
              final String name = categoryData['name'] ?? 'No Name';
              final String imageUrl = categoryData['image'] ?? '';
              final bool isSelected = _selectedCategoryId == categoryDoc.id;

              Widget imageWidget;
              const double imageSize = 64;

              if (imageUrl.startsWith('data:image')) {
                try {
                  final UriData? data = Uri.parse(imageUrl).data;
                  if (data != null) {
                     final imageBytes = data.contentAsBytes();
                     imageWidget = Image.memory(
                        imageBytes,
                        fit: BoxFit.cover,
                        width: imageSize,
                        height: imageSize,
                     );
                  } else {
                     imageWidget = const Icon(Icons.broken_image, size: imageSize, color: Colors.grey);
                  }
                } catch (e) {
                  imageWidget = const Icon(Icons.broken_image, size: imageSize, color: Colors.grey);
                }
              } else {
                imageWidget = const Icon(Icons.category, size: imageSize, color: Colors.grey);
              }

              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategoryId = categoryDoc.id;
                    });
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: imageSize + 4,
                        height: imageSize + 4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: imageWidget
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: imageSize,
                        child: Text(
                          name,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_userRole == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              title: Text(
                'KZL Shop',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
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
                      icon: const Icon(Icons.shopping_cart_outlined),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const CartScreen()));
                      },
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Logout',
                  icon: const Icon(Icons.logout),
                  onPressed: _logout,
                ),
              ],
              floating: true, 
              snap: true, 
              pinned: true, 
            ),
            SliverToBoxAdapter(
              child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AnnouncementSlideshow(),
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
                    child: Text(
                      "Categories",
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                         shadows: [
                          Shadow(
                            blurRadius: 10.0,
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(5.0, 5.0),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildCategoryCarousel(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                    child: Text(
                      "Products",
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                         shadows: [
                          Shadow(
                            blurRadius: 10.0,
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(5.0, 5.0),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            ),
          ];
        },
        body: ProductGrid(categoryId: _selectedCategoryId),
      ),
    );
  }
}
