
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:myapp/constants.dart';

class TownshipsTab extends StatelessWidget {
  const TownshipsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection(townshipsCollectionPath).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No townships found.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final townshipDoc = snapshot.data!.docs[index];
              final townshipData = townshipDoc.data() as Map<String, dynamic>;

              final String name = townshipData['name'] ?? 'No Name';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          _showEditTownshipDialog(context, townshipDoc);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _showDeleteConfirmationDialog(context, townshipDoc);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddTownshipDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddTownshipDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Township'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Township Name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final String name = nameController.text.trim();
                if (name.isNotEmpty) {
                  try {
                    await FirebaseFirestore.instance.collection(townshipsCollectionPath).add({'name': name});
                    if (context.mounted) Navigator.of(context).pop();
                  } catch (e) {
                    // Handle error
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showEditTownshipDialog(BuildContext context, DocumentSnapshot townshipDoc) {
    final TextEditingController nameController =
        TextEditingController(text: (townshipDoc.data() as Map<String, dynamic>)['name']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Township'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Township Name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final String name = nameController.text.trim();
                if (name.isNotEmpty) {
                  try {
                    await townshipDoc.reference.update({'name': name});
                    if (context.mounted) Navigator.of(context).pop();
                  } catch (e) {
                    // Handle error
                  }
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, DocumentSnapshot townshipDoc) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Township'),
          content: const Text('Are you sure you want to delete this township?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await townshipDoc.reference.delete();
                  if (context.mounted) Navigator.of(context).pop();
                } catch (e) {
                  // Handle error
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
