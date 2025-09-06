import 'package:flutter/material.dart';

class TempAdminScreen extends StatelessWidget {
  const TempAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel (Debug)'),
      ),
      body: const Center(
        child: Text('Debug Admin Panel is showing.'),
      ),
    );
  }
}
