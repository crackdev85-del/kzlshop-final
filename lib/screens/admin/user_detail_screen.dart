
import 'package:flutter/material.dart';

class UserDetailScreen extends StatelessWidget {
  final String userId;

  const UserDetailScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    // TODO: Fetch user details from Firestore based on userId

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Details'),
      ),
      body: const Center(
        child: Text('Details for user will be here.'),
        // TODO: Display user information like name, email, order history, etc.
      ),
    );
  }
}
