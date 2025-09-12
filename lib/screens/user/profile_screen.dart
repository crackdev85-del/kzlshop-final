import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:moegyi/constants.dart';
import 'package:moegyi/main.dart';
import 'package:moegyi/screens/admin/admin_home_screen.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer' as developer;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<DocumentSnapshot<Map<String, dynamic>>> _userDataFuture;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _userDataFuture = _loadUserData();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _loadUserData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      developer.log('No user logged in', name: 'ProfileScreen');
      return Future.error('No user logged in');
    }
    return FirebaseFirestore.instance
        .collection(usersCollectionPath)
        .doc(user.uid)
        .get();
  }

  void _retryLoadUserData() {
    setState(() {
      _userDataFuture = _loadUserData();
    });
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
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
        _retryLoadUserData(); // Refresh data
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _launchMaps(String? address) async {
    if (address == null || address.isEmpty) return;
    final query = Uri.encodeComponent(address);
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not open maps: $e')));
      }
    }
  }

  Future<void> _signOutAndNavigate(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _retryLoadUserData,
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _userDataFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 60),
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Error loading profile. Please try again.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _retryLoadUserData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('User profile not found.'));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final user = FirebaseAuth.instance.currentUser;

          final String username = userData['username'] ?? 'N/A';
          final String email = user?.email ?? 'N/A';
          final String shopName = userData['shopName'] ?? 'N/A';
          final String phoneNumber = userData['phoneNumber'] ?? 'N/A';
          final String address = userData['address'] ?? 'N/A';
          final String userRole = userData['role'] ?? 'N/A';

          Uint8List? imageBytes;
          final String? photoURL = userData['photoURL'];
          final String? profilePicture = userData['profilePicture'];
          try {
            String? base64String;
            if (photoURL != null &&
                photoURL.isNotEmpty &&
                photoURL.startsWith('data:image')) {
              base64String = photoURL.split(',').last;
            } else if (profilePicture != null && profilePicture.isNotEmpty) {
              base64String = profilePicture;
            }

            if (base64String != null) {
              imageBytes = base64Decode(base64String);
            }
          } catch (e, s) {
            developer.log(
              'Error decoding profile image',
              name: 'ProfileScreen',
              error: e,
              stackTrace: s,
            );
            imageBytes = null;
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: imageBytes != null
                              ? MemoryImage(imageBytes)
                              : null,
                          child: imageBytes == null
                              ? const Icon(Icons.person, size: 60)
                              : null,
                        ),
                        if (_isUploading)
                          const CircularProgressIndicator()
                        else
                          Material(
                            color: theme.colorScheme.secondary,
                            shape: const CircleBorder(),
                            clipBehavior: Clip.antiAlias,
                            child: IconButton(
                              icon: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                              ),
                              onPressed: _pickImage,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(username, style: theme.textTheme.headlineSmall),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.email),
                      title: const Text('Email'),
                      subtitle: Text(email),
                    ),
                    ListTile(
                      leading: const Icon(Icons.store),
                      title: const Text('Shop Name'),
                      subtitle: Text(shopName),
                    ),
                    ListTile(
                      leading: const Icon(Icons.phone),
                      title: const Text('Phone Number'),
                      subtitle: Text(phoneNumber),
                    ),
                    ListTile(
                      leading: const Icon(Icons.location_on),
                      title: const Text('Address'),
                      subtitle: Text(address),
                      trailing: IconButton(
                        icon: const Icon(Icons.map),
                        onPressed: () => _launchMaps(address),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.verified_user),
                      title: const Text('Role'),
                      subtitle: Text(userRole),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: SwitchListTile(
                  title: const Text('Dark Mode'),
                  secondary: Icon(
                    themeProvider.themeMode == ThemeMode.dark
                        ? Icons.dark_mode
                        : Icons.light_mode,
                  ),
                  value: themeProvider.themeMode == ThemeMode.dark,
                  onChanged: (value) {
                    themeProvider.toggleTheme();
                  },
                ),
              ),
              const SizedBox(height: 20),
              if (userRole == 'admin')
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminHomeScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.admin_panel_settings),
                  label: const Text('Admin Panel'),
                ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => _signOutAndNavigate(context),
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
