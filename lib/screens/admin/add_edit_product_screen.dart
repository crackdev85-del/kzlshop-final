
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/constants.dart';

class AddEditProductScreen extends StatefulWidget {
  final String? documentId;

  const AddEditProductScreen({super.key, this.documentId});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  String? _selectedCategory;
  String? _selectedTownship;
  String? _imageUrl;
  File? _imageFile;
  bool _isLoading = false;

  List<String> _categories = [];
  List<String> _townships = [];

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    await _fetchCategories();
    await _fetchTownships();
    if (widget.documentId != null) {
      _loadProductData();
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection(categoriesCollectionPath).get();
      setState(() {
        _categories = snapshot.docs.map((doc) => doc['name'] as String).toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to fetch categories: $e')));
    }
  }

  Future<void> _fetchTownships() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection(townshipsCollectionPath).get();
      setState(() {
        _townships = snapshot.docs.map((doc) => doc['name'] as String).toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to fetch townships: $e')));
    }
  }

  Future<void> _loadProductData() async {
    try {
      final doc = await FirebaseFirestore.instance.collection(productsCollectionPath).doc(widget.documentId).get();
      if (doc.exists) {
        final data = doc.data()!;
        _nameController.text = data['name'] ?? '';
        _priceController.text = (data['price'] ?? 0).toString();
        _quantityController.text = (data['quantity'] ?? 0).toString();
        _imageUrl = data['imageUrl'];
        _selectedCategory = data['category'];
        _selectedTownship = data['township'];
        setState(() {});
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load product data: $e')));
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('product_images')
          .child('${DateTime.now().toIso8601String()}.jpg');
      await ref.putFile(image);
      return await ref.getDownloadURL();
    } catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
      return null;
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    String? newImageUrl = _imageUrl;
    if (_imageFile != null) {
      newImageUrl = await _uploadImage(_imageFile!);
      if (newImageUrl == null) {
        setState(() {
          _isLoading = false;
        });
        return; // Stop if image upload failed
      }
    }

    final productData = {
      'name': _nameController.text,
      'price': double.tryParse(_priceController.text) ?? 0.0,
      'quantity': int.tryParse(_quantityController.text) ?? 0,
      'category': _selectedCategory,
      'township': _selectedTownship,
      'imageUrl': newImageUrl,
    };

    try {
      if (widget.documentId != null) {
        await FirebaseFirestore.instance.collection(productsCollectionPath).doc(widget.documentId).update(productData);
      } else {
        await FirebaseFirestore.instance.collection(productsCollectionPath).add(productData);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save product: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.documentId == null ? 'Add Product' : 'Edit Product'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Product Name'),
                      validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: 'Price'),
                      keyboardType: TextInputType.number,
                      validator: (value) => value!.isEmpty ? 'Please enter a price' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      keyboardType: TextInputType.number,
                      validator: (value) => value!.isEmpty ? 'Please enter quantity' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      hint: const Text('Select Category'),
                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (value) => setState(() => _selectedCategory = value),
                      validator: (value) => value == null ? 'Please select a category' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedTownship,
                      hint: const Text('Select Township'),
                      items: _townships.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (value) => setState(() => _selectedTownship = value),
                      validator: (value) => value == null ? 'Please select a township' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _imageFile != null
                            ? Image.file(_imageFile!, width: 100, height: 100, fit: BoxFit.cover)
                            : (_imageUrl != null
                                ? Image.network(_imageUrl!, width: 100, height: 100, fit: BoxFit.cover)
                                : const Icon(Icons.image, size: 100)),
                        const SizedBox(width: 16),
                        ElevatedButton(onPressed: _pickImage, child: const Text('Pick Image')),
                      ],
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _saveProduct,
                      child: const Text('Save Product'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
