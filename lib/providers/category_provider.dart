import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:moegyi/constants.dart';
import '../models/category.dart';

class CategoryProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = categoriesCollectionPath; // Collection path is defined directly here

  Stream<List<Category>> getCategories() {
    return _firestore.collection(_collectionPath).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList();
    });
  }

  Future<void> addCategory(String name, String image) async {
    try {
      await _firestore.collection(_collectionPath).add({
        'name': name,
        'image': image,
      });
      notifyListeners();
    } catch (e) {
      print(e.toString());
      rethrow; // Rethrow the error to be caught by the UI
    }
  }

  Future<void> updateCategory(String id, String name, String image) async {
    try {
      await _firestore.collection(_collectionPath).doc(id).update({
        'name': name,
        'image': image,
      });
      notifyListeners();
    } catch (e) {
      print(e.toString());
      rethrow; // Rethrow the error to be caught by the UI
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await _firestore.collection(_collectionPath).doc(id).delete();
      notifyListeners();
    } catch (e) {
      print(e.toString());
      rethrow; // Rethrow the error to be caught by the UI
    }
  }
}
