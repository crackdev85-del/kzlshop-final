import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:myapp/constants.dart';

class UserDetailScreen extends StatefulWidget {
  final String userId;
  final bool isEditMode;

  const UserDetailScreen({
    super.key,
    required this.userId,
    this.isEditMode = false,
  });

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  late bool _isEditing;
  bool _isLoading = true;
  bool _isSaving = false;

  final _usernameController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  
  // To store non-editable data
  String? _email;
  String? _role;
  String? _joinedDate;
  String? _photoURL;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.isEditMode;
    _loadUserData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _shopNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection(usersCollectionPath)
          .doc(widget.userId)
          .get();

      if (userDoc.exists && mounted) {
        final userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _usernameController.text = userData['username'] ?? '';
          _shopNameController.text = userData['shopName'] ?? '';
          _phoneController.text = userData['phoneNumber'] ?? '';
          _addressController.text = userData['address'] ?? '';
          _email = userData['email'] ?? 'N/A';
          _role = userData['role'] ?? 'user';
          _photoURL = userData['photoURL'];

          final Timestamp? createdAt = userData['createdAt'] as Timestamp?;
          _joinedDate = createdAt != null
              ? '${createdAt.toDate().day}/${createdAt.toDate().month}/${createdAt.toDate().year}'
              : 'N/A';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user data: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveUserData() async {
    if (mounted) setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection(usersCollectionPath)
          .doc(widget.userId)
          .update({
            'username': _usernameController.text.trim(),
            'shopName': _shopNameController.text.trim(),
            'phoneNumber': _phoneController.text.trim(),
            'address': _addressController.text.trim(),
          });
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User updated successfully'), backgroundColor: Colors.green,)
        );
        setState(() => _isEditing = false);
      }
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving data: $e'), backgroundColor: Colors.red,),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit User' : 'User Details'),
        actions: [
          if (!_isLoading)
            _isEditing
                ? IconButton(
                    icon: const Icon(Icons.save),
                    onPressed: _isSaving ? null : _saveUserData,
                    tooltip: 'Save',
                  )
                : IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => setState(() => _isEditing = true),
                    tooltip: 'Edit',
                  ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isSaving 
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.green),)) // Show a saving indicator
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _photoURL != null ? NetworkImage(_photoURL!) : null,
                    child: _photoURL == null ? const Icon(Icons.person, size: 50) : null,
                  ),
                  const SizedBox(height: 24),
                  _isEditing ? _buildEditFields() : _buildViewFields(),
                ],
              ),
            ),
    );
  }
  
  Widget _buildViewFields() {
    final theme = Theme.of(context);
    return Column(
      children: [
        _buildInfoTile(Icons.person, 'Username', _usernameController.text, theme),
        _buildInfoTile(Icons.store, 'Shop Name', _shopNameController.text, theme),
        _buildInfoTile(Icons.phone, 'Phone', _phoneController.text, theme),
        _buildInfoTile(Icons.location_on, 'Address', _addressController.text, theme),
        _buildInfoTile(Icons.email, 'Email', _email ?? 'N/A', theme),
        _buildInfoTile(Icons.verified_user, 'Role', _role ?? 'N/A', theme),
        _buildInfoTile(Icons.date_range, 'Joined Date', _joinedDate ?? 'N/A', theme),
      ],
    );
  }
  
  Widget _buildInfoTile(IconData icon, String label, String value, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: theme.primaryColor),
        title: Text(label, style: theme.textTheme.titleSmall),
        subtitle: Text(value.isNotEmpty ? value : 'N/A', style: theme.textTheme.bodyLarge),
      ),
    );
  }

  Widget _buildEditFields() {
    return Column(
      children: [
        _buildTextField(_usernameController, 'Username', Icons.person),
        const SizedBox(height: 16),
        _buildTextField(_shopNameController, 'Shop Name', Icons.store),
        const SizedBox(height: 16),
        _buildTextField(_phoneController, 'Phone Number', Icons.phone, TextInputType.phone),
        const SizedBox(height: 16),
        _buildTextField(_addressController, 'Address', Icons.location_on),
         const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, [TextInputType? keyboardType]) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }
}
