import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  final String id;
  final String name;
  final String image;

  Category({required this.id, required this.name, required this.image});

  factory Category.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Category(
      id: doc.id,
      name: data['name'] ?? '',
      image: data['image'] ?? '', // Changed from imageUrl to image
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'image': image, // Changed from imageUrl to image
    };
  }
}
