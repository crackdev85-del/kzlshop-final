
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:moegyi/constants.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  Future<void> _backupCollection(
      BuildContext context, String collectionPath, String title) async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection(collectionPath).get();
      final data = snapshot.docs.map((doc) => doc.data()).toList();
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);

      // ignore: use_build_context_synchronously
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: double.maxFinite,
            child: SelectableText(
              jsonString,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Copy'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: jsonString));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard!')),
                );
              },
            ),
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
      );
    } catch (error) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup failed: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          ListTile(
            leading: const Icon(Icons.people_alt_outlined),
            title: const Text('Backup Users'),
            subtitle: const Text('Save all user data to a JSON file.'),
            onTap: () =>
                _backupCollection(context, usersCollectionPath, 'Users Backup'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: const Text('Backup Products'),
            subtitle: const Text('Save all product data to a JSON file.'),
            onTap: () => _backupCollection(
                context, productsCollectionPath, 'Products Backup'),
          ),
        ],
      ),
    );
  }
}
