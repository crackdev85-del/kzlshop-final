import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/constants.dart';
import 'package:url_launcher/url_launcher.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  User? _user;
  DocumentSnapshot? _userData;
  bool _isLoading = true;
  bool _isUpdating = false;

  final _usernameController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();

  File? _imageFile;
  String? _photoURL;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _shopNameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    _user = _auth.currentUser;
    if (_user != null) {
      try {
        _userData = await _firestore.collection(usersCollectionPath).doc(_user!.uid).get();
        final data = _userData?.data() as Map<String, dynamic>?;

        if (data != null && mounted) {
          _usernameController.text = data['username'] ?? '';
          _shopNameController.text = data['shopName'] ?? '';
          _phoneController.text = data['phoneNumber'] ?? '';
          _locationController.text = data['coordinates'] ?? '';
          _photoURL = data['photoURL'];
        }
      } catch (e) {
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading data: $e')),
          );
        }
      } 
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null && mounted) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick Image'),
        content: const Text('Choose image source'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
            child: const Text('Camera'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
            child: const Text('Gallery'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchMaps(String coordinates) async {
    if (coordinates.isEmpty) return;
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$coordinates');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
         throw 'Could not launch $url';
      }
    } catch(e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open maps: $e')),
        );
      }
    }
  }

  Future<void> _updateProfile() async {
    if (_user == null) return;
    if(mounted) {
      setState(() {
        _isUpdating = true;
      });
    }

    String? newPhotoURL = _photoURL;

    if (_imageFile != null) {
      try {
        final ref = _storage.ref().child('profile_pictures').child('${_user!.uid}.jpg');
        await ref.putFile(_imageFile!);
        newPhotoURL = await ref.getDownloadURL();
      } catch (e) {
         if(mounted){
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Failed to upload image: $e'),
                backgroundColor: Colors.red,
            ));
         }
      }
    }

    try {
        final locationString = _locationController.text.trim();
        GeoPoint? locationGeoPoint;
        if(locationString.contains(',')) {
            final parts = locationString.split(',');
            if (parts.length == 2) {
                final lat = double.tryParse(parts[0].trim());
                final lon = double.tryParse(parts[1].trim());
                if(lat != null && lon != null) {
                    locationGeoPoint = GeoPoint(lat, lon);
                }
            }
        }

      await _firestore.collection(usersCollectionPath).doc(_user!.uid).update({
        'username': _usernameController.text.trim(),
        'shopName': _shopNameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'coordinates': locationString,
        'location': locationGeoPoint, // Also update the GeoPoint
        'photoURL': newPhotoURL,
      });

      await _user?.updateDisplayName(_usernameController.text.trim());
      if (newPhotoURL != null) {
        await _user?.updatePhotoURL(newPhotoURL);
      }

      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ));
      }

    } catch (e) {
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if(mounted){
        setState(() {
          _isUpdating = false;
          _photoURL = newPhotoURL; // Update UI with new photo
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: _imageFile != null 
                            ? FileImage(_imageFile!) 
                            : (_photoURL != null && _photoURL!.isNotEmpty 
                                ? NetworkImage(_photoURL!) 
                                : null) as ImageProvider?,
                        child: (_imageFile == null && (_photoURL == null || _photoURL!.isEmpty))
                          ? const Icon(Icons.person, size: 60)
                          : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Theme.of(context).primaryColor,
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                            onPressed: _showImageSourceDialog,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  _buildTextField(controller: _usernameController, label: 'Username', icon: Icons.person),
                  const SizedBox(height: 16.0),
                  _buildTextField(controller: _shopNameController, label: 'Shop Name', icon: Icons.store),
                  const SizedBox(height: 16.0),
                   _buildTextField(controller: _phoneController, label: 'Phone Number', icon: Icons.phone, keyboardType: TextInputType.phone),
                  const SizedBox(height: 16.0),

                  // Address field with Map button
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(controller: _locationController, label: 'Location (Lat, Lng)', icon: Icons.map),
                      ),
                      IconButton(
                        icon: const Icon(Icons.open_in_new, semanticLabel: 'View on Map'),
                        onPressed: () => _launchMaps(_locationController.text),
                        tooltip: 'View on Google Maps',
                      ),
                    ],
                  ),

                  const SizedBox(height: 32.0),

                  _isUpdating
                      ? const Center(child: CircularProgressIndicator())
                      : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                            onPressed: _updateProfile,
                            icon: const Icon(Icons.save),
                            label: const Text('Update Profile'),
                             style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                textStyle: GoogleFonts.lato(fontSize: 18),
                              ),
                          ),
                      ),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField({ 
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
    );
  }
}
