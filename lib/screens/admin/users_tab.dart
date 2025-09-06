
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:myapp/constants.dart';

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
                    .update({'role': roleController.text});
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final userDoc = snapshot.data!.docs[index];
              final userData = userDoc.data() as Map<String, dynamic>;

              final String email = userData['email'] ?? 'No Email';
              final String username = userData['username'] ?? 'No Username';
              final String role = userData['role'] ?? 'user';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(username),
                  subtitle: Text(email),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(role),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editUserRole(context, userDoc),
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
