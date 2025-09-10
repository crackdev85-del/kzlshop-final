import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/constants.dart';
import 'package:myapp/main.dart';
import 'package:myapp/screens/admin/admin_home_screen.dart';
import 'package:myapp/screens/user/edit_profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<DocumentSnapshot> _userDataFuture;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _userDataFuture = _getUserData();
  }

  Future<DocumentSnapshot> _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        return await FirebaseFirestore.instance.collection(usersCollectionPath).doc(user.uid).get();
      } catch (e) {
        debugPrint("Error loading user data: $e");
        if (!mounted) return Future.error(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user data: $e')),
        );
        return Future.error(e);
      }
    }
    return Future.error('No user logged in');
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 50);
    if (image != null) {
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
              .update({'profilePicture': base64Image});
          // Refresh user data
          setState(() {
            _userDataFuture = _getUserData();
          });
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      } finally {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }


  Future<void> _launchMaps(String? address) async {
    if (address == null || address.isEmpty) return;
    final query = Uri.encodeComponent(address);
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
     try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
         throw 'Could not launch $url';
      }
    } catch(e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open maps: $e')),
      );
    }
  }

  Future<void> _signOutAndNavigate(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onPrimary)),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _userDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Could not load profile data'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('User data not found.'));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final profilePicture = userData['profilePicture'];
          final userName = userData['username'];
          final phoneNumber = userData['phoneNumber'];
          final shopName = userData['shopName'];
          final userRole = userData['role'];
          final userAddress = userData['address'];
          final township = userData['township'];
          final coordinates = userData['coordinates'];

          Widget profileImage;
          if (profilePicture != null) {
            final imageBytes = base64Decode(profilePicture);
            profileImage = CircleAvatar(
              radius: 50,
              backgroundImage: MemoryImage(imageBytes),
            );
          } else {
            profileImage = const CircleAvatar(
              radius: 50,
              child: Icon(Icons.person, size: 50),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  );
                  if (result == true) {
                    setState(() {
                      _userDataFuture = _getUserData();
                    });
                  }
                },
                child: Center(
                  child: Stack(
                    children: [
                      profileImage,
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt),
                          onPressed: _pickImage,
                          tooltip: 'Change Profile Picture',
                        ),
                      ),
                      if (_isUploading)
                        const Positioned.fill(
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                       if (userName != null)
                        ListTile(
                          leading: Icon(Icons.person, color: theme.colorScheme.primary),
                          title: const Text('Username'),
                          subtitle: Text(userName, style: theme.textTheme.bodyLarge),
                        ),
                      ListTile(
                        leading: Icon(Icons.email, color: theme.colorScheme.primary),
                        title: const Text('Email'),
                        subtitle: Text(user?.email ?? 'N/A', style: theme.textTheme.bodyLarge),
                      ),
                      if (phoneNumber != null)
                        ListTile(
                          leading: Icon(Icons.phone, color: theme.colorScheme.primary),
                          title: const Text('Phone Number'),
                          subtitle: Text(phoneNumber, style: theme.textTheme.bodyLarge),
                        ),
                      if (shopName != null)
                        ListTile(
                          leading: Icon(Icons.store, color: theme.colorScheme.primary),
                          title: const Text('Shop Name'),
                          subtitle: Text(shopName, style: theme.textTheme.bodyLarge),
                        ),
                      if (userRole != null)
                        ListTile(
                          leading: Icon(Icons.verified_user, color: theme.colorScheme.primary),
                          title: const Text('Role'),
                          subtitle: Text(userRole, style: theme.textTheme.bodyLarge),
                        ),
                      if (userAddress != null)
                        ListTile(
                          leading: Icon(Icons.location_pin, color: theme.colorScheme.primary),
                          title: const Text('Address'),
                          subtitle: Text(userAddress, style: theme.textTheme.bodyLarge),
                          trailing: IconButton(
                            icon: const Icon(Icons.map),
                            onPressed: () => _launchMaps(userAddress),
                            tooltip: 'View on Google Maps',
                          ),
                        ),
                        if (township != null)
                        ListTile(
                          leading: Icon(Icons.location_city, color: theme.colorScheme.primary),
                          title: const Text('Township'),
                          subtitle: Text(township, style: theme.textTheme.bodyLarge),
                        ),
                        if (coordinates != null)
                        ListTile(
                          leading: Icon(Icons.my_location, color: theme.colorScheme.primary),
                          title: const Text('Location'),
                          subtitle: Text(coordinates, style: theme.textTheme.bodyLarge),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: SwitchListTile(
                  title: const Text('Dark Mode'),
                  secondary: Icon(themeProvider.themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode, color: theme.colorScheme.primary),
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
                      MaterialPageRoute(builder: (context) => const AdminHomeScreen()),
                    );
                  },
                  icon: const Icon(Icons.admin_panel_settings),
                  label: const Text('Admin Panel'),
                ),
              const SizedBox(height: 40),
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
