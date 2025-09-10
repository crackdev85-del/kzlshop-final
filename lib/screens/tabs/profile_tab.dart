import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/constants.dart';
import 'package:myapp/screens/login_screen.dart';
import 'dart:developer' as developer;

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  late Future<DocumentSnapshot<Map<String, dynamic>>> _userFuture;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _userFuture = _fetchUserData();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return FirebaseFirestore.instance.collection(usersCollectionPath).doc(user.uid).get();
    }
    throw Exception('No user is currently logged in.');
  }

    Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final imageBytes = await image.readAsBytes();
      final base64Image = base64Encode(imageBytes);
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection(usersCollectionPath)
            .doc(user.uid)
            .update({'photoURL': 'data:image/png;base64,$base64Image'});
        _refreshUserData(); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
    } finally {
      if(mounted){
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _refreshUserData() {
    setState(() {
      _userFuture = _fetchUserData();
    });
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to log out: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Could not load profile data.'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _refreshUserData,
                  child: const Text('Try Again'),
                ),
                const SizedBox(height: 16),
                TextButton(
                    onPressed: _logout,
                    child: const Text('Logout', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
        }

        final userData = snapshot.data!.data()!;
        final currentUser = FirebaseAuth.instance.currentUser;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _refreshUserData,
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildProfileHeader(context, userData, currentUser),
              const SizedBox(height: 32),
              _buildProfileInfoCard(context, userData),
              const SizedBox(height: 32),
              _buildActionButtons(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(
      BuildContext context, Map<String, dynamic> userData, User? currentUser) {
    final theme = Theme.of(context);
    final String username = userData['username'] ?? 'N/A';

    Uint8List? imageBytes;
    final String? photoURL = userData['photoURL'];
    try {
      if (photoURL != null && photoURL.isNotEmpty && photoURL.startsWith('data:image')) {
          imageBytes = base64Decode(photoURL.split(',').last);
      }
    } catch (e, s) {
      developer.log('Error decoding profile image', name: 'ProfileTab', error: e, stackTrace: s);
      imageBytes = null;
    }

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: imageBytes != null ? MemoryImage(imageBytes) : null,
              child: imageBytes == null ? const Icon(Icons.person, size: 60) : null,
            ),
            if (_isUploading)
              const CircularProgressIndicator()
            else
              Material(
                  color: theme.colorScheme.secondary,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                      onPressed: _pickImage,
                  ),
              )
          ],
        ),
        const SizedBox(height: 16),
        Text(
          username,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          currentUser?.email ?? 'No email',
          style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildProfileInfoCard(
      BuildContext context, Map<String, dynamic> userData) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Information',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.store, 'Shop Name', userData['shopName'] ?? 'Not provided'),
            _buildInfoRow(Icons.phone, 'Phone', userData['phoneNumber'] ?? 'Not provided'),
            _buildInfoRow(Icons.location_on, 'Address', userData['address'] ?? 'Not provided'),
            _buildInfoRow(Icons.map, 'Township', userData['township'] ?? 'Not provided'),
             _buildInfoRow(Icons.pin_drop, 'Location', userData['coordinates'] ?? 'Not provided'), // Use coordinates field
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey[500]),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 2),
                Text(value, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        TextButton.icon(
          onPressed: _logout,
          icon: const Icon(Icons.logout, color: Colors.red),
          label: const Text('Logout', style: TextStyle(color: Colors.red)),
          style: TextButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
      ],
    );
  }
}
