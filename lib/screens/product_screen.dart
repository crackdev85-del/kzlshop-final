import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moegyi/constants.dart';
import 'package:moegyi/screens/user/product_detail_screen.dart';

// A custom widget to display images from either a network URL or a base64 string.
class DisplayImage extends StatelessWidget {
  final String imageUrl;
  final double height;

  const DisplayImage({super.key, required this.imageUrl, required this.height});

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (imageUrl.startsWith('data:image')) {
      // Handle base64 image
      try {
        final UriData? data = Uri.parse(imageUrl).data;
        if (data != null) {
          final Uint8List imageBytes = data.contentAsBytes();
          imageWidget = Image.memory(
            imageBytes,
            fit: BoxFit.cover,
            height: height,
            width: double.infinity,
          );
        } else {
          imageWidget = _buildErrorWidget();
        }
      } catch (e) {
        imageWidget = _buildErrorWidget();
      }
    } else if (imageUrl.startsWith('http')) {
      // Handle network image
      imageWidget = Image.network(
        imageUrl,
        fit: BoxFit.cover,
        height: height,
        width: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return SizedBox(
            height: height,
            child: const Center(child: CircularProgressIndicator()),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorWidget();
        },
      );
    } else {
      // Placeholder for empty or invalid URL
      imageWidget = _buildErrorWidget();
    }

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(15.0),
        topRight: Radius.circular(15.0),
      ),
      child: imageWidget,
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      height: height,
      width: double.infinity,
      color: Colors.grey[200],
      child: const Center(child: Icon(Icons.broken_image, size: 40, color: Colors.grey)),
    );
  }
}

class ProductScreen extends StatelessWidget {
  const ProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(productsCollectionPath).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        return GridView.builder(
          padding: const EdgeInsets.all(10.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10.0,
            mainAxisSpacing: 10.0,
            childAspectRatio: 0.7,
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot product = snapshot.data!.docs[index];
            final productData = product.data() as Map<String, dynamic>?;

            final String imageUrl = productData != null && productData.containsKey(Constants.productImageUrl)
                ? productData[Constants.productImageUrl]
                : '';

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailScreen(productId: product.id),
                  ),
                );
              },
              child: Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Hero(
                        tag: 'product-image-${product.id}',
                        child: DisplayImage(imageUrl: imageUrl, height: 180),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        productData != null && productData.containsKey(Constants.productName)
                            ? productData[Constants.productName]
                            : 'No Name',
                        style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        productData != null && productData.containsKey(Constants.productPrice)
                            ? '${productData[Constants.productPrice].toStringAsFixed(2)} Kyat'
                            : '0.00 Kyat',
                        style: GoogleFonts.lato(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
