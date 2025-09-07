import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserDetailScreen extends StatelessWidget {
  final String userId;

  const UserDetailScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Details'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("User not found"));
          }

          Map<String, dynamic> userData = snapshot.data!.data() as Map<String, dynamic>;
          String userName = userData['name'] ?? 'N/A';
          String userEmail = userData['email'] ?? 'N/A';
          String userPhone = userData['phone'] ?? 'N/A';
          String userRole = userData['role'] ?? 'user';
          Timestamp? createdAt = userData['createdAt'] as Timestamp?;
          String joinedDate = createdAt != null ? '${createdAt.toDate().day}/${createdAt.toDate().month}/${createdAt.toDate().year}' : 'N/A';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDetailRow(context, Icons.person, 'Name', userName),
                    _buildDetailRow(context, Icons.email, 'Email', userEmail),
                    _buildDetailRow(context, Icons.phone, 'Phone', userPhone),
                    _buildDetailRow(context, Icons.verified_user, 'Role', userRole),
                    _buildDetailRow(context, Icons.date_range, 'Joined Date', joinedDate),
                    // Add more user details as needed
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
