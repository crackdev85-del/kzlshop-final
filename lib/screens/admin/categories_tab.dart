import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/category_provider.dart';
import '../../models/category.dart';
import 'add_edit_category_screen.dart';

class CategoriesTab extends StatelessWidget {
  const CategoriesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
      ),
      body: StreamBuilder<List<Category>>(
        stream: Provider.of<CategoryProvider>(context).getCategories(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: \${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(children: snapshot.data!.map((doc) => _buildCategoryItem(context, doc)).toList());
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddEditCategoryScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryItem(BuildContext context, Category category) {
    return ListTile(
      title: Text(category.name),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AddEditCategoryScreen(category: category),
          ),
        );
      },
    );
  }
}
