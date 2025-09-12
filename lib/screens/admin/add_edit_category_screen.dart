import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/category.dart';
import '../../providers/category_provider.dart';

class AddEditCategoryScreen extends StatefulWidget {
  final Category? category;

  const AddEditCategoryScreen({super.key, this.category});

  @override
  _AddEditCategoryScreenState createState() => _AddEditCategoryScreenState();
}

class _AddEditCategoryScreenState extends State<AddEditCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  Uint8List? _imageData;
  bool _isEditMode = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.category != null;
    _nameController = TextEditingController(text: _isEditMode ? widget.category!.name : '');
    if (_isEditMode && widget.category!.image.startsWith('data:image')) {
      try {
        _imageData = base64Decode(widget.category!.image.split(',').last);
      } catch (e) {
        print("Error decoding image: $e");
        _imageData = null;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_isLoading) return;
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 800);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageData = bytes;
      });
    }
  }

  void _saveForm() {
    if (_isLoading) return;

    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      return;
    }
    if (_imageData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please pick an image.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    _formKey.currentState!.save();
    final name = _nameController.text;
    final image = 'data:image/jpeg;base64,${base64Encode(_imageData!)}';
    final provider = Provider.of<CategoryProvider>(context, listen: false);

    final future = _isEditMode
        ? provider.updateCategory(widget.category!.id, name, image)
        : provider.addCategory(name, image);

    future.then((_) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Category ${(_isEditMode ? 'updated' : 'added')} successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }).catchError((error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save category: $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }).whenComplete(() {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  void _deleteCategory() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing while deleting
      builder: (ctx) {
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Confirm Deletion'),
              content: Text('Are you sure you want to delete "${widget.category!.name}"? This action cannot be undone.'),
              actions: <Widget>[
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  onPressed: isDeleting ? null : () {
                    setDialogState(() => isDeleting = true);
                    Provider.of<CategoryProvider>(context, listen: false)
                        .deleteCategory(widget.category!.id)
                        .then((_) {
                          if (!mounted) return;
                          Navigator.of(ctx).pop();
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Category deleted successfully!'),
                                backgroundColor: Colors.green,
                              ),
                          );
                    }).catchError((error) {
                        if (!mounted) return;
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                           SnackBar(
                            content: Text('Failed to delete category: $error'),
                            backgroundColor: Theme.of(context).colorScheme.error,
                          ),
                        );
                    });
                  },
                  child: isDeleting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Delete'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Category' : 'Add New Category'),
        elevation: 4,
        actions: [
          if (_isEditMode)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _isLoading ? null : _deleteCategory,
              tooltip: 'Delete Category',
            ),
        ],
      ),
      body: IgnorePointer(
        ignoring: _isLoading,
        child: Opacity(
          opacity: _isLoading ? 0.5 : 1.0,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 2,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Category Name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            prefixIcon: const Icon(Icons.category),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a category name.';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      elevation: 2,
                      clipBehavior: Clip.antiAlias,
                       shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                height: 180,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8.0),
                                  border: Border.all(
                                    color: isDark ? Colors.grey[700]! : Colors.grey[400]!,
                                    width: 1.5,
                                  ),
                                ),
                                child: _imageData != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8.0),
                                        child: Image.memory(
                                          _imageData!,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_a_photo_outlined,
                                            size: 50,
                                            color: theme.colorScheme.secondary,
                                          ),
                                          const SizedBox(height: 8),
                                          const Text(
                                            'Tap to select an image',
                                            style: TextStyle(fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: _pickImage,
                              icon: const Icon(Icons.image_search),
                              label: const Text('Choose from Gallery'),
                               style: OutlinedButton.styleFrom(
                                 padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                 shape: RoundedRectangleBorder(
                                   borderRadius: BorderRadius.circular(8.0),
                                 ),
                               ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _saveForm,
                      icon: _isLoading
                          ? Container(
                              width: 24,
                              height: 24,
                              padding: const EdgeInsets.all(2.0),
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Icon(Icons.save_alt_outlined),
                      label: Text(_isLoading
                          ? 'Saving...'
                          : (_isEditMode ? 'Update Category' : 'Save Category')),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
