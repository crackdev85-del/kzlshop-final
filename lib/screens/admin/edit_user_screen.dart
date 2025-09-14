import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:moegyi/constants.dart';

class EditUserScreen extends StatefulWidget {
  final DocumentSnapshot userDoc;

  const EditUserScreen({super.key, required this.userDoc});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _shopNameController;
  late TextEditingController _addressController;
  late TextEditingController _townshipController;
  late TextEditingController _locationController;
  late TextEditingController _roleController;

  @override
  void initState() {
    super.initState();
    final data = widget.userDoc.data();
    Map<String, dynamic> userData = {};

    if (data is Map<String, dynamic>) {
      userData = data;
    }

    _usernameController = TextEditingController(text: userData['username']?.toString() ?? '');
    _phoneNumberController = TextEditingController(text: userData['phoneNumber']?.toString() ?? '');
    _shopNameController = TextEditingController(text: userData['shopName']?.toString() ?? '');
    _addressController = TextEditingController(text: userData['address']?.toString() ?? '');
    _townshipController = TextEditingController(text: userData['township']?.toString() ?? '');
    _locationController = TextEditingController(text: userData['location']?.toString() ?? '');
    _roleController = TextEditingController(text: userData['role']?.toString() ?? 'user');
  }

  Future<void> _updateUser() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance.collection(usersCollectionPath).doc(widget.userDoc.id).update({
          'username': _usernameController.text,
          'phoneNumber': _phoneNumberController.text,
          'shopName': _shopNameController.text,
          'address': _addressController.text,
          'township': _townshipController.text,
          'location': _locationController.text,
          'role': _roleController.text,
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User updated successfully')),
        );
        Navigator.of(context).pop();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating user: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit User'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _updateUser,
            tooltip: 'Save Changes',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a username';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneNumberController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _shopNameController,
              decoration: const InputDecoration(
                labelText: 'Shop Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _townshipController,
              decoration: const InputDecoration(
                labelText: 'Township',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _roleController,
              decoration: const InputDecoration(
                labelText: 'Role',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a role';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}
