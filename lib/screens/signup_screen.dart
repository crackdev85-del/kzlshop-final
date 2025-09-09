import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/constants.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _locationController = TextEditingController();

  String? _selectedTownship;
  List<DocumentSnapshot> _townships = [];

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  bool _isFetchingLocation = false;

  @override
  void initState() {
    super.initState();
    _fetchTownships();
  }

  Future<void> _fetchTownships() async {
    try {
      final snapshot = await _firestore.collection(townshipsCollectionPath).get();
      if (mounted) {
        setState(() {
          _townships = snapshot.docs;
        });
      }
    } catch (e, s) {
      developer.log(
        'Error fetching townships',
        name: 'myapp.signup',
        error: e,
        stackTrace: s,
      );
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

 Future<void> _getCurrentLocation() async {
    if (!mounted) return;
    setState(() {
      _isFetchingLocation = true;
    });

    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('သင့် Location ဖွင့်ပေးရန်လိုပါသည်');
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Location permission တောင်းခြင်းကို ငြင်းပယ်ထားပါသည်။');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showError(
            'Location permission ကို အပြီးတိုင် ငြင်းပယ်ထားသောကြောင့် တောင်းဆို၍မရပါ။');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));

      // Set coordinates to location controller
      final coordinates = '${position.latitude}, ${position.longitude}';

      // Get readable address from coordinates
      String readableAddress = 'Unable to fetch address';
      try {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );

          if (placemarks.isNotEmpty) {
            Placemark place = placemarks[0];
            readableAddress = '${place.street}, ${place.subLocality}, ${place.locality}';
          }
      } catch (e) {
          developer.log('Could not get placemark', name: 'myapp.signup', error: e);
      }

      if (mounted) {
        setState(() {
          _addressController.text = readableAddress;
          _locationController.text = coordinates;
        });
      }

    } catch (e) {
      _showError("Failed to get location: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingLocation = false;
        });
      }
    }
  }

  Future<void> _signup() async {
    if (!mounted) return;

    // Validation
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      _showError('Email နှင့် password ထည့်ပါ။');
      return;
    }
    if (_passwordController.text.trim().length < 6) {
      _showError('Password သည် အနည်းဆုံး 6 အက္ခရာ ဖြစ်ရမည်။');
      return;
    }
    if (_passwordController.text.trim() != _confirmPasswordController.text.trim()) {
      _showError('Passwords do not match');
      return;
    }
    if (_usernameController.text.trim().isEmpty) {
      _showError('Username ထည့်ရန်လိုအပ်သည် (required)');
      return;
    }
    if (_shopNameController.text.trim().isEmpty) {
      _showError('ဆိုင်အမည် ထည့်ရန်လိုအပ်သည် (required)');
      return;
    }
    if (_phoneController.text.trim().isEmpty) {
      _showError('ဖုန်းနံပါတ် ထည့်ရန်လိုအပ်သည် (required)');
      return;
    }
    if (_addressController.text.trim().isEmpty) {
      _showError('လိပ်စာ ထည့်ရန်လိုအပ်သည် (required)');
      return;
    }
    if (_locationController.text.trim().isEmpty) {
      _showError('Location / Map address ထည့်ရန်လိုအပ်သည် (required)');
      return;
    }
    
    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await userCredential.user?.updateDisplayName(_usernameController.text.trim());

      final locationString = _locationController.text.trim();
      GeoPoint? locationGeoPoint;
      if(locationString.contains(',')) {
          final parts = locationString.split(',');
          final lat = double.tryParse(parts[0].trim());
          final lon = double.tryParse(parts[1].trim());
          if(lat != null && lon != null) {
              locationGeoPoint = GeoPoint(lat, lon);
          }
      }

      // Create a document for the user in Firestore
      await _firestore.collection(usersCollectionPath).doc(userCredential.user!.uid).set({
        'email': userCredential.user!.email,
        'username': _usernameController.text.trim(),
        'displayName': _usernameController.text.trim(),
        'shopName': _shopNameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'location': locationGeoPoint,
        'coordinates': locationString, // Storing raw string as well
        'township': _selectedTownship,
        'role': 'user', // Default role
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context); // Go back to login screen

    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Signup failed');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Create Account',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.oswald(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Join us and start shopping',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Form Fields
                  _buildTextField(controller: _usernameController, label: 'Username', icon: Icons.person),
                  const SizedBox(height: 16.0),
                  _buildTextField(controller: _emailController, label: 'Email', icon: Icons.email, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 16.0),
                  _buildTextField(controller: _passwordController, label: 'Password', icon: Icons.lock, obscureText: true),
                  const SizedBox(height: 16.0),
                  _buildTextField(controller: _confirmPasswordController, label: 'Confirm Password', icon: Icons.lock, obscureText: true),
                  const SizedBox(height: 16.0),
                  _buildTextField(controller: _shopNameController, label: 'ဆိုင်အမည်', icon: Icons.store),
                  const SizedBox(height: 16.0),
                  _buildTextField(controller: _phoneController, label: 'ဖုန်းနံပါတ်', icon: Icons.phone, keyboardType: TextInputType.phone),
                  const SizedBox(height: 16.0),
                  _buildTextField(controller: _addressController, label: 'ဆိုင်လိပ်စာ', icon: Icons.location_on),
                  const SizedBox(height: 16.0),
                  _buildTextField(controller: _locationController, label: 'Location / Map address', icon: Icons.map),
                  const SizedBox(height: 16.0),

                  // Township Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _selectedTownship,
                    decoration: const InputDecoration(
                      labelText: 'မြို့နယ်ရွေးရန် (Optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_city),
                    ),
                    items: _townships.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return DropdownMenuItem<String>(
                        value: doc.id,
                        child: Text(data['name'] ?? 'Unknown'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedTownship = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16.0),

                  // Add your location button
                  _isFetchingLocation 
                    ? const Center(child: CircularProgressIndicator()) 
                    : OutlinedButton.icon(
                        onPressed: _getCurrentLocation,
                        icon: const Icon(Icons.my_location),
                        label: const Text('Add your location'),
                        style: OutlinedButton.styleFrom(
                           padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                  
                  const SizedBox(height: 24),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _signup,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text('Sign Up', style: GoogleFonts.lato(fontSize: 18)),
                        ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account?"),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Login'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
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
    return TextField(
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
