
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/constants.dart';

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

  File? _imageFile;
  String? _imageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.productId != null) {
      _loadProductData();
    }
  }

  Future<void> _loadProductData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final doc = await FirebaseFirestore.instance
          .collection(productsCollectionPath)
          .doc(widget.productId)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        _nameController.text = data['name'] ?? '';
        _priceController.text = (data['price'] ?? 0.0).toString();
        _descriptionController.text = data['description'] ?? '';
        _imageUrl = data['imageUrl'];
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load product: $e')),
      );
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return _imageUrl;

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('product_images')
          .child('${DateTime.now().toIso8601String()}.jpg');
      await ref.putFile(_imageFile!);
      return await ref.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
      return null;
    }
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final imageUrl = await _uploadImage();
      if (imageUrl == null && _imageFile != null) {
        setState(() {
          _isLoading = false;
        });
        return; // Don't save if image upload failed
      }

      final productData = {
        'name': _nameController.text,
        'price': double.parse(_priceController.text),
        'description': _descriptionController.text,
        'imageUrl': imageUrl,
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
      }

      setState(() {
        _isLoading = false;
      });
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
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(color: Colors.white),
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
                        ),
                        child: _imageFile != null
                            ? Image.file(_imageFile!, fit: BoxFit.cover)
                            : _imageUrl != null
                                ? Image.network(_imageUrl!, fit: BoxFit.cover)
                                : const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.camera_alt, size: 50),
                                        SizedBox(height: 8),
                                        Text('Tap to select image'),
                                      ],
                                    ),
                                  ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Product Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a product name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        border: OutlineInputBorder(),
                        prefixText: '\$',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a price';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
