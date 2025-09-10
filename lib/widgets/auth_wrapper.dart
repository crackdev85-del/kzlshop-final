import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/constants.dart';
import 'package:myapp/screens/login_screen.dart';
import 'package:myapp/screens/main_screen.dart';
import 'package:myapp/screens/admin/admin_home_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData && snapshot.data != null) {
          // User is logged in, check their role.
          return const RoleBasedDispatcher();
        }
        // User is logged out.
        return const LoginScreen();
      },
    );
  }
}

class RoleBasedDispatcher extends StatelessWidget {
  const RoleBasedDispatcher({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const LoginScreen();
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection(usersCollectionPath).doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError) {
          return const Scaffold(body: Center(child: Text('Something went wrong.')));
        }

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final role = data['role'];

          if (role == 'admin') {
            return const AdminHomeScreen();
          } else {
            return const MainScreen();
          }
        }

        // Fallback for cases where the user doc might not exist yet
        return const MainScreen();
      },
    );
  }
}
