import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myapp/constants.dart';
import 'package:myapp/main.dart';
import 'package:myapp/screens/admin/admin_home_screen.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _userRole;
  String? _userAddress;

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  Future<void> _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection(usersCollectionPath).doc(user.uid).get();
        if (doc.exists && mounted) {
          setState(() {
            _userRole = doc.data()!['role'];
            _userAddress = doc.data()!['address'];
          });
        }
      } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading user data: $e')),
        );
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
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.email, color: theme.colorScheme.primary),
                    title: const Text('Email'),
                    subtitle: Text(user?.email ?? 'N/A', style: theme.textTheme.bodyLarge),
                  ),
                  if (_userRole != null)
                    ListTile(
                      leading: Icon(Icons.verified_user, color: theme.colorScheme.primary),
                      title: const Text('Role'),
                      subtitle: Text(_userRole!, style: theme.textTheme.bodyLarge),
                    ),
                  if (_userAddress != null)
                    ListTile(
                      leading: Icon(Icons.location_pin, color: theme.colorScheme.primary),
                      title: const Text('Address'),
                      subtitle: Text(_userAddress!, style: theme.textTheme.bodyLarge),
                      trailing: IconButton(
                        icon: const Icon(Icons.map),
                        onPressed: () => _launchMaps(_userAddress),
                        tooltip: 'View on Google Maps',
                      ),
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
          if (_userRole == 'admin')
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
      ),
    );
  }
}
