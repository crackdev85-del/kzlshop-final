import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/category_provider.dart';

class AddCategoryScreen extends StatefulWidget {
  @override
  _AddCategoryScreenState createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  Uint8List? _imageData;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageData = bytes;
      });
    }
  }

  void _saveForm() {
    if (_formKey.currentState!.validate() && _imageData != null) {
      final name = _nameController.text;
      final image = 'data:image/jpeg;base64,${base64Encode(_imageData!)}';

      Provider.of<CategoryProvider>(context, listen: false).addCategory(name, image).then((_) {
        Navigator.of(context).pop();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Category'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Category Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a category name.';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              _imageData == null
                  ? Text('No image selected.')
                  : Image.memory(_imageData!),
              ElevatedButton(onPressed: _pickImage, child: Text('Pick Image')),
              ElevatedButton(onPressed: _saveForm, child: Text('Add Category')),
            ],
          ),
        ),
      ),
    );
  }
}
