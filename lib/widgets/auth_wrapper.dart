
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myapp/constants.dart';
import 'package:myapp/screens/admin_screen.dart';
import 'package:myapp/screens/create_admin_screen.dart';
import 'package:myapp/screens/home_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<bool> _isAdminUser(User user) async {
    final userDoc = await FirebaseFirestore.instance
        .collection(usersCollectionPath)
        .doc(user.uid)
        .get();
    if (userDoc.exists && userDoc.data()!['role'] == 'admin') {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (userSnapshot.hasData && userSnapshot.data != null) {
          // User is logged in, check if admin
          return FutureBuilder<bool>(
            future: _isAdminUser(userSnapshot.data!),
            builder: (context, isAdminSnapshot) {
              if (isAdminSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (isAdminSnapshot.hasData && isAdminSnapshot.data == true) {
                return const AdminScreen();
              } else {
                return const HomeScreen();
              }
            },
          );
        } else {
          // User is not logged in, check if an admin account exists
          return FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection(usersCollectionPath)
                .where('role', isEqualTo: 'admin')
                .limit(1)
                .get(),
            builder: (context, adminSnapshot) {
              if (adminSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (adminSnapshot.hasError) {
                return Scaffold(
                  body: Center(child: Text('Error: ${adminSnapshot.error}')),
                );
              }

              final bool hasAdmin = adminSnapshot.hasData && adminSnapshot.data!.docs.isNotEmpty;

              if (hasAdmin) {
                // If admin exists, show login screen
                return const HomeScreen(); // Or your preferred login screen
              } else {
                // If no admin exists, show create admin screen
                return const CreateAdminScreen();
              }
            },
          );
        }
      },
    );
  }
}
