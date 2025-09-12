import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:moegyi/screens/admin/announcements_tab.dart';
import 'package:moegyi/screens/admin/categories_tab.dart';
import 'package:moegyi/screens/admin/orders_tab.dart';
import 'package:moegyi/screens/admin/products_tab.dart';
import 'package:moegyi/screens/admin/reports_tab.dart';
import 'package:moegyi/screens/admin/settings_tab.dart';
import 'package:moegyi/screens/admin/townships_tab.dart';
import 'package:moegyi/screens/admin/users_tab.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Panel',
            style: theme.textTheme.titleLarge
                ?.copyWith(color: theme.colorScheme.onPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: theme.colorScheme.onPrimary,
          labelColor: theme.colorScheme.onPrimary,
          unselectedLabelColor: theme.colorScheme.onPrimary.withAlpha(178),
          tabs: const [
            Tab(icon: Icon(Icons.fastfood), text: 'Products'),
            Tab(icon: Icon(Icons.category), text: 'Categories'),
            Tab(icon: Icon(Icons.receipt), text: 'Orders'),
            Tab(icon: Icon(Icons.people), text: 'Users'),
            Tab(icon: Icon(Icons.location_city), text: 'Townships'),
            Tab(icon: Icon(Icons.announcement), text: 'Announcements'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Reports'),
            Tab(icon: Icon(Icons.settings), text: 'Settings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ProductsTab(),
          CategoriesTab(),
          OrdersTab(),
          UsersTab(),
          TownshipsTab(),
          AnnouncementsTab(),
          ReportsTab(),
          SettingsTab(),
        ],
      ),
    );
  }
}
