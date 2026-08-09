import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'adminWidgets.dart';
import 'caegoryFormPage.dart';
import 'categoryModel.dart';
import 'categoryProvider.dart';

class CategoryListPage extends StatelessWidget {
  const CategoryListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CategoryProvider()..fetchCategories(),
      child: const _CategoryListView(),
    );
  }
}

class _CategoryListView extends StatelessWidget {
  const _CategoryListView();

  Future<void> _openForm(BuildContext context, {CategoryModel? category}) async {
    final provider = context.read<CategoryProvider>();
    if (category == null) {
      provider.startCreate();
    } else {
      provider.startEdit(category);
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: const CategoryFormPage(),
        ),
      ),
    );
    provider.fetchCategories();
  }

  Future<void> _delete(BuildContext context, CategoryModel category) async {
    final confirmed = await showAdminDeleteConfirm(context, itemName: category.name);
    if (!confirmed) return;
    final provider = context.read<CategoryProvider>();
    final error = await provider.deleteCategory(category.id);
    if (!context.mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      provider.fetchCategories();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Categories'),
        backgroundColor: const Color(0xFFF59E0B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFF59E0B),
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('New Category'),
      ),
      body: Consumer<CategoryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.errorMessage != null) {
            return Center(child: Text(provider.errorMessage!));
          }
          if (provider.categories.isEmpty) {
            return const AdminEmptyState(
              icon: Icons.category_rounded,
              message: 'No categories yet. Tap "New Category" to create one.',
            );
          }
          return RefreshIndicator(
            onRefresh: provider.fetchCategories,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: provider.categories.length,
              itemBuilder: (context, index) {
                final category = provider.categories[index];
                return AdminListTile(
                  title: category.name,
                  subtitle: '${category.gender} • ${category.classRangeLabel}',
                  leadingIcon: Icons.category_rounded,
                  leadingColor: const Color(0xFFF59E0B),
                  onEdit: () => _openForm(context, category: category),
                  onDelete: () => _delete(context, category),
                );
              },
            ),
          );
        },
      ),
    );
  }
}