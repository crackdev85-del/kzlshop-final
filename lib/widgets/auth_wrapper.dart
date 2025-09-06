import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myapp/constants.dart';
import 'package:myapp/screens/user/home_screen.dart';
import 'package:myapp/screens/login_screen.dart';
import 'package:myapp/screens/admin/admin_home_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

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
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection(usersCollectionPath)
                .doc(userSnapshot.data!.uid)
                .get(),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (roleSnapshot.hasData && roleSnapshot.data!.exists) {
                final role = roleSnapshot.data!['role'];
                if (role == 'admin') {
                  return const AdminHomeScreen();
                } else {
                  return const HomeScreen();
                }
              }

              // If no role or document, default to HomeScreen
              return const HomeScreen();
            },
          );
        } else {
          // User is not logged in, show login screen
          return const LoginScreen();
        }
      },
    );
  }
}
