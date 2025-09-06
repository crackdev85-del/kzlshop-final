
import 'package:flutter/material.dart';
import 'package:myapp/screens/admin/announcements_tab.dart';
import 'package:myapp/screens/admin/categories_tab.dart';
import 'package:myapp/screens/admin/orders_tab.dart';
import 'package:myapp/screens/admin/products_tab.dart';
import 'package:myapp/screens/admin/reports_tab.dart';
import 'package:myapp/screens/admin/settings_tab.dart';
import 'package:myapp/screens/admin/townships_tab.dart';
import 'package:myapp/screens/admin/users_tab.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
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
        title: Text('Admin Panel', style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onPrimary)),
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
