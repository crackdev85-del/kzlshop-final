import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:myapp/constants.dart';
import 'package:myapp/screens/admin/edit_user_screen.dart';
import 'package:myapp/screens/admin/user_detail_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class UsersTab extends StatelessWidget {
  const UsersTab({super.key});

  Future<void> _launchMaps(BuildContext context, String? location) async {
    if (location == null || location.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No location available for this user.')),
      );
      return;
    }
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$location');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open maps: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection(usersCollectionPath).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final userDoc = snapshot.data!.docs[index];
              final userData = userDoc.data() as Map<String, dynamic>?;

              if (userData == null) {
                return const SizedBox.shrink();
              }

              final String email = userData['email'] ?? 'No Email';
              final String username = userData['username'] ?? 'No Username';
              final String? location = userData['location'];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserDetailScreen(userId: userDoc.id, isEditMode: false),
                      ),
                    );
                  },
                  title: Text(username),
                  subtitle: Text(email),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Edit Button
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditUserScreen(userDoc: userDoc),
                            ),
                          );
                        },
                        tooltip: 'Edit User',
                      ),
                      // Map Button
                      IconButton(
                        icon: const Icon(Icons.map, color: Colors.green),
                        onPressed: () => _launchMaps(context, location),
                        tooltip: 'View on Map',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
