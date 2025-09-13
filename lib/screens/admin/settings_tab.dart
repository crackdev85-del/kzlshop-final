import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:moegyi/constants.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  Future<void> _exportCollection(
      BuildContext context, String collectionPath, String fileName) async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection(collectionPath).get();
      final data = snapshot.docs.map((doc) => doc.data()).toList();
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);

      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save File As',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        final file = File(result);
        await file.writeAsString(jsonString);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported to $result')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $error')),
      );
    }
  }

  Future<void> _importCollection(
      BuildContext context, String collectionPath) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        final data = jsonDecode(jsonString) as List;

        final batch = FirebaseFirestore.instance.batch();
        for (final item in data) {
          final docRef =
              FirebaseFirestore.instance.collection(collectionPath).doc();
          batch.set(docRef, item);
        }
        await batch.commit();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Import successful!')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          _buildSectionHeader('Users'),
          ListTile(
            leading: const Icon(Icons.file_upload),
            title: const Text('Import Users'),
            subtitle: const Text('Import users from a JSON file.'),
            onTap: () => _importCollection(context, usersCollectionPath),
          ),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('Export Users'),
            subtitle: const Text('Export all user data to a JSON file.'),
            onTap: () =>
                _exportCollection(context, usersCollectionPath, 'users.json'),
          ),
          const Divider(),
          _buildSectionHeader('Products'),
          ListTile(
            leading: const Icon(Icons.file_upload),
            title: const Text('Import Products'),
            subtitle: const Text('Import products from a JSON file.'),
            onTap: () => _importCollection(context, productsCollectionPath),
          ),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('Export Products'),
            subtitle: const Text('Export all product data to a JSON file.'),
            onTap: () => _exportCollection(
                context, productsCollectionPath, 'products.json'),
          ),
          const Divider(),
          _buildSectionHeader('Orders'),
          ListTile(
            leading: const Icon(Icons.file_upload),
            title: const Text('Import Orders'),
            subtitle: const Text('Import orders from a JSON file.'),
            onTap: () => _importCollection(context, ordersCollectionPath),
          ),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('Export Orders'),
            subtitle: const Text('Export all order data to a JSON file.'),
            onTap: () =>
                _exportCollection(context, ordersCollectionPath, 'orders.json'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
