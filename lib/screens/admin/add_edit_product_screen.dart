import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:moegyi/constants.dart';
import 'package:image/image.dart' as img;
import 'package:moegyi/models/category.dart';

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
  final _quantityController = TextEditingController();
  final _descriptionController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  String? _imageUrl;
  bool _isLoading = false;

  // Category related state
  String? _selectedCategoryId;
  List<Category> _categories = [];
  bool _isFetchingCategories = false;

  @override
  void initState() {
    super.initState();
    // Fetch categories first, then the product if it's an edit operation
    _fetchCategories().then((_) {
      if (widget.productId != null) {
        _fetchProduct();
      }
    });
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isFetchingCategories = true;
    });
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(categoriesCollectionPath) // Corrected the collection path
          .orderBy('name')
          .get();
      if (mounted) {
        setState(() {
          _categories = snapshot.docs
              .map((doc) => Category.fromFirestore(doc))
              .toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch categories: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingCategories = false;
        });
      }
    }
  }

  Future<void> _fetchProduct() async {
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
        _nameController.text = data[Constants.productName] ?? '';
        _priceController.text = (data[Constants.productPrice] ?? 0).toString();
        _quantityController.text =
            (data[Constants.productQuantity] ?? 0).toString();
        _descriptionController.text = data[Constants.productDescription] ?? '';
        
        final categoryId = data[Constants.productCategoryId];
        if (categoryId != null &&
            _categories.any((c) => c.id == categoryId)) {
          _selectedCategoryId = categoryId;
        } else {
          _selectedCategoryId = null;
        }

        if (data[Constants.productImageUrl] != null) {
          setState(() {
            _imageUrl = data[Constants.productImageUrl];
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Product not found. It might have been deleted.')),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch product: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile =
          await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
          _imageUrl = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<String> _uploadImage(XFile imageFile) async {
    final Uint8List imageBytes = await imageFile.readAsBytes();
    img.Image? originalImage = img.decodeImage(imageBytes);

    if (originalImage == null) {
      throw Exception("Could not decode image");
    }
    img.Image resizedImage = img.copyResize(originalImage, width: 300);
    List<int> compressedImage = img.encodeJpg(resizedImage, quality: 85);
    String base64Image = base64Encode(compressedImage);
    return 'data:image/jpeg;base64,$base64Image';
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_imageFile == null && _imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image for the product.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? finalImageUrl = _imageUrl;
      if (_imageFile != null) {
        finalImageUrl = await _uploadImage(_imageFile!);
      }

      if (finalImageUrl == null) {
        throw Exception("Image URL is null after processing.");
      }

      final productData = {
        Constants.productName: _nameController.text,
        Constants.productPrice: double.tryParse(_priceController.text) ?? 0.0,
        Constants.productQuantity: int.tryParse(_quantityController.text) ?? 0,
        Constants.productDescription: _descriptionController.text,
        Constants.productImageUrl: finalImageUrl,
        Constants.productCategoryId: _selectedCategoryId,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (widget.productId == null) {
        await FirebaseFirestore.instance
            .collection(productsCollectionPath)
            .add(productData);
      } else {
        await FirebaseFirestore.instance
            .collection(productsCollectionPath)
            .doc(widget.productId)
            .update(productData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product saved successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save product: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
              child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 3)),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveProduct,
            ),
        ],
      ),
      body: _isLoading && widget.productId != null
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
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey),
                          image: _imageUrl != null &&
                                  _imageUrl!.startsWith('data:image')
                              ? DecorationImage(
                                  image: MemoryImage(
                                      base64Decode(_imageUrl!.split(',').last)),
                                  fit: BoxFit.cover)
                              : _imageFile != null
                                  ? DecorationImage(
                                      image: FileImage(File(_imageFile!.path)),
                                      fit: BoxFit.cover)
                                  : _imageUrl != null
                                      ? DecorationImage(
                                          image: NetworkImage(_imageUrl!),
                                          fit: BoxFit.cover)
                                      : null,
                        ),
                        child: (_imageFile == null && _imageUrl == null)
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo,
                                        size: 50, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text('Tap to select image',
                                        style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              )
                            : null,
                      ),                    ),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategoryId,
                      hint: const Text('Select Category'),
                      isExpanded: true,
                      items: _categories.map((Category category) {
                        return DropdownMenuItem<String>(
                          value: category.id,
                          child: Text(category.name),
                        );
                      }).toList(),
                      onChanged: _isFetchingCategories
                          ? null
                          : (value) {
                              setState(() {
                                _selectedCategoryId = value;
                              });
                            },
                      validator: (value) =>
                          value == null ? 'Please select a category' : null,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: const OutlineInputBorder(),
                        filled: _isFetchingCategories,
                        fillColor: Colors.grey[200],
                      ),
                      disabledHint: const Text("Loading categories..."),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                          labelText: 'Product Name',
                          border: OutlineInputBorder()),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Please enter a name' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            decoration: const InputDecoration(
                                labelText: 'Price',
                                border: OutlineInputBorder(),
                                prefixText: 'Kyat '),
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter the price';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _quantityController,
                            decoration: const InputDecoration(
                                labelText: 'Quantity',
                                border: OutlineInputBorder()),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter the quantity';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Please enter a valid whole number';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                          labelText: 'Description', border: OutlineInputBorder()),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
