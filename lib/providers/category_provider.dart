import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category.dart';
import '../constants.dart';

class CategoryProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Category>> getCategories() {
    return _firestore.collection(categoriesCollectionPath).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList();
    });
  }

  Future<void> addCategory(String name, String imageUrl) async {
    try {
      await _firestore.collection(categoriesCollectionPath).add({
        'name': name,
        'imageUrl': imageUrl,
      });
      notifyListeners();
    } catch (e) {
      print(e.toString());
    }
  }
}
