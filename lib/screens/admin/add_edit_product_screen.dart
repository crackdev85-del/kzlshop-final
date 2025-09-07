
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/constants.dart';
import 'package:image/image.dart' as img;

class AddEditProductScreen extends StatefulWidget {
  final String? productId;

  const AddEditProductScreen({super.key, this.productId});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();

  File? _imageFile;
  String? _currentImageUrl; // Keep this as imageUrl
  bool _isLoading = false;

  List<String> _categories = [];
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _fetchCategoriesAndThenLoadProduct();
  }

  Future<void> _fetchCategoriesAndThenLoadProduct() async {
    setState(() => _isLoading = true);
    try {
      final categoriesSnapshot = await FirebaseFirestore.instance.collection('categories').get();
      setState(() {
        _categories = categoriesSnapshot.docs.map((doc) => doc['name'] as String).toList();
      });

      if (widget.productId != null) {
        await _loadProductData();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load initial data: $e')),
      );
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadProductData() async {
    final doc = await FirebaseFirestore.instance.collection(productsCollectionPath).doc(widget.productId).get();
    if (doc.exists) {
      final data = doc.data()!;
      _nameController.text = data['name'] ?? '';
      _priceController.text = (data['price'] ?? 0.0).toString();
      _descriptionController.text = data['description'] ?? '';
      _quantityController.text = (data['quantity'] ?? 0).toString();
      _selectedCategory = data['category'] as String?;
      _currentImageUrl = data['imageUrl'] as String?; // Changed to imageUrl

      if (_selectedCategory != null && !_categories.contains(_selectedCategory)) {
        _selectedCategory = null;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _currentImageUrl = null; 
      });
    }
  }

  Future<String?> _processAndEncodeImage() async {
    if (_imageFile == null) return _currentImageUrl;

    try {
      Uint8List imageBytes = await _imageFile!.readAsBytes();
      const oneMB = 1048576;

      if (imageBytes.length > oneMB) {
        img.Image? originalImage = img.decodeImage(imageBytes);
        if (originalImage == null) return null;

        int quality = 90;
        while (imageBytes.length > oneMB && quality > 10) {
          imageBytes = Uint8List.fromList(img.encodeJpg(originalImage, quality: quality));
          quality -= 10;
        }
      }

      if (imageBytes.length > oneMB) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image too large, even after compression.')),
        );
        return null;
      }
      return base64Encode(imageBytes);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to process image: $e')),
      );
      return null;
    }
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      if (_imageFile == null && _currentImageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an image.')),
        );
        return;
      }

      setState(() => _isLoading = true);

      final imageBase64String = await _processAndEncodeImage();
      if (imageBase64String == null) {
        setState(() => _isLoading = false);
        return;
      }

      final productData = {
        'name': _nameController.text.trim(),
        'price': double.parse(_priceController.text),
        'category': _selectedCategory,
        'quantity': int.parse(_quantityController.text),
        'imageUrl': imageBase64String, // Changed to imageUrl
        'description': _descriptionController.text.trim(),
      };

      try {
        if (widget.productId != null) {
          await FirebaseFirestore.instance
              .collection(productsCollectionPath)
              .doc(widget.productId)
              .update(productData);
        } else {
          await FirebaseFirestore.instance
              .collection(productsCollectionPath)
              .add(productData);
        }
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save product: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.productId == null ? 'Add Product' : 'Edit Product'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveProduct,
            ),
        ],
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
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                           image: _imageFile != null
                            ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                            : _currentImageUrl != null
                                ? DecorationImage(image: MemoryImage(base64Decode(_currentImageUrl!)), fit: BoxFit.cover)
                                : null,
                        ),
                        child: (_imageFile == null && _currentImageUrl == null)
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Tap to select image'),
                                ],
                              ),
                            )
                          : null,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Product Name', border: OutlineInputBorder()),
                      validator: (value) => (value == null || value.isEmpty) ? 'Please enter a name' : null,
                    ),
                    const SizedBox(height: 16),
                    if (_categories.isNotEmpty)
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                        items: _categories.map((String category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedCategory = newValue;
                          });
                        },
                        validator: (value) => (value == null) ? 'Please select a category' : null,
                      )
                    else
                       const Text('No categories found. Please add categories first.', style: TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: 'Price', border: OutlineInputBorder(), prefixText: 'MMK '),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter a price';
                        if (double.tryParse(value) == null) return 'Please enter a valid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(labelText: 'Quantity', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter the quantity';
                        if (int.tryParse(value) == null) return 'Please enter a valid whole number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
