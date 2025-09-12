import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:moegyi/constants.dart';

class AnnouncementsTab extends StatefulWidget {
  const AnnouncementsTab({super.key});

  @override
  State<AnnouncementsTab> createState() => _AnnouncementsTabState();
}

class _AnnouncementsTabState extends State<AnnouncementsTab> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _addOrEditAnnouncement({DocumentSnapshot? doc}) async {
    final titleController =
        TextEditingController(text: doc != null ? doc['title'] : '');
    final messageController =
        TextEditingController(text: doc != null ? doc['message'] : '');
    String? imageBase64 = doc != null ? doc['imageUrl'] : null;
    Uint8List? imageBytes;
    if (imageBase64 != null && imageBase64.isNotEmpty) {
      try {
        imageBytes = base64Decode(imageBase64.split(',').last);
      } catch (e) {
        print("Error decoding image: $e");
        imageBytes = null;
      }
    }

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(doc == null ? 'Add Announcement' : 'Edit Announcement'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    TextField(
                      controller: messageController,
                      decoration: const InputDecoration(labelText: 'Message'),
                    ),
                    const SizedBox(height: 16),
                    imageBytes == null
                        ? const Text('No image selected.')
                        : Image.memory(imageBytes!, height: 150),
                    TextButton.icon(
                      icon: const Icon(Icons.image),
                      label: const Text('Pick Image'),
                      onPressed: () async {
                        final XFile? pickedFile =
                            await _picker.pickImage(source: ImageSource.gallery);
                        if (pickedFile != null) {
                          final bytes = await pickedFile.readAsBytes();
                          setDialogState(() {
                            imageBytes = bytes;
                            imageBase64 =
                                'data:image/${pickedFile.path.split('.').last};base64,${base64Encode(bytes)}';
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isNotEmpty) {
                      final data = {
                        'title': titleController.text,
                        'message': messageController.text,
                        'imageUrl': imageBase64,
                        'createdAt': FieldValue.serverTimestamp(),
                      };

                      if (doc == null) {
                        await FirebaseFirestore.instance
                            .collection(announcementsCollectionPath)
                            .add(data);
                      } else {
                        await doc.reference.update(data);
                      }
                      if(mounted){
                        Navigator.of(context).pop();
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteAnnouncement(DocumentReference docRef) async {
     await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Announcement'),
          content: const Text('Are you sure you want to delete this announcement?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await docRef.delete();
                if(mounted){
                   Navigator.of(context).pop();
                }
              },
              child: const Text('Delete'),
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
        stream: FirebaseFirestore.instance
            .collection(announcementsCollectionPath)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading announcements'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final announcements = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              final doc = announcements[index];
              final data = doc.data() as Map<String, dynamic>;
              final String title = data['title'] ?? 'No Title';
              final String message = data['message'] ?? '';
              final String? imageUrl = data['imageUrl'];
              Uint8List? imageBytes;
              if (imageUrl != null && imageUrl.isNotEmpty) {
                try {
                   imageBytes = base64Decode(imageUrl.split(',').last);
                } catch(e) {
                  // Ignore invalid base64
                }
              }

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                elevation: 3,
                child: ListTile(
                  leading: imageBytes != null ? Image.memory(imageBytes, width: 50, height: 50, fit: BoxFit.cover,) : const Icon(Icons.campaign, size: 40),
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(message, maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _addOrEditAnnouncement(doc: doc),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteAnnouncement(doc.reference),
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
        onPressed: () => _addOrEditAnnouncement(),
        tooltip: 'Add Announcement',
        child: const Icon(Icons.add),
      ),
    );
  }
}
