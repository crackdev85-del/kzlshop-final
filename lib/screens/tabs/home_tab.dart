
import 'package:flutter/material.dart';
import 'package:myapp/widgets/product_carousel.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Welcome to KZL Shop',
              style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const ProductCarousel(category: 'all'),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Featured Products',
              style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const ProductCarousel(category: 'electronics'),
        ],
      ),
    );
  }
}

