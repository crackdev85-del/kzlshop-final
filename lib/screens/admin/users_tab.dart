import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:myapp/constants.dart';
import 'package:myapp/screens/admin/user_detail_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class UsersTab extends StatelessWidget {
  const UsersTab({super.key});

  Future<void> _editUserRole(BuildContext context, DocumentSnapshot userDoc) async {
    final TextEditingController roleController = TextEditingController();
    roleController.text = (userDoc.data() as Map<String, dynamic>)['role'] ?? 'user';

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit User Role'),
          content: TextField(
            controller: roleController,
            decoration: const InputDecoration(labelText: 'Role'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection(usersCollectionPath)
                    .doc(userDoc.id)
                    .update({'role': roleController.text.trim()});
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchMaps(BuildContext context, String? address) async {
    if (address == null || address.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('No address available for this user.')),
      );
      return;
    }
    final query = Uri.encodeComponent(address);
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
     try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
         throw 'Could not launch $url';
      }
    } catch(e) {
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
              final String address = userData['address'];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(username),
                  subtitle: Text(email),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // View Button
                      IconButton(
                        icon: const Icon(Icons.visibility, color: Colors.blueGrey),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserDetailScreen(userId: userDoc.id, isEditMode: false),
                            ),
                          );
                        },
                        tooltip: 'View User',
                      ),
                      // Edit Button
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () {
                            Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserDetailScreen(userId: userDoc.id, isEditMode: true),
                            ),
                          );
                        },
                        tooltip: 'Edit User',
                      ),
                      // Map Button
                      IconButton(
                        icon: const Icon(Icons.map, color: Colors.green),
                        onPressed: () => _launchMaps(context, address),
                        tooltip: 'View on Map',
                      ),
                       // Role Button
                      IconButton(
                        icon: const Icon(Icons.admin_panel_settings, color: Colors.purple),
                        onPressed: () => _editUserRole(context, userDoc),
                        tooltip: 'Edit Role',
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
