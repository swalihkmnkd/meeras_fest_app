import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'adminWidgets.dart';
import 'providers/categoryProvider.dart';

class CategoryFormPage extends StatelessWidget {
  const CategoryFormPage({super.key});

  Future<void> _save(BuildContext context) async {
    final provider = context.read<CategoryProvider>();
    final error = await provider.save();
    if (!context.mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    final wasEditing = provider.isEditing;
    await showAdminSuccessDialog(
      context,
      message: wasEditing ? 'Category updated successfully.' : 'Category added successfully.',
    );
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF3F4F6),
          appBar: AppBar(
            title: Text(provider.isEditing ? 'Edit Category' : 'Add Category'),
            backgroundColor: const Color(0xFFF59E0B),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: AdminCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdminFormField(
                    controller: provider.nameCtrl,
                    label: 'Category Name',
                    icon: Icons.category_rounded,
                  ),
                  const SizedBox(height: 18),
                  ClassRangeSelector(
                    fromValue: provider.classFrom,
                    toValue: provider.classTo,
                    onFromChanged: provider.setClassFrom,
                    onToChanged: provider.setClassTo,
                  ),
                  const SizedBox(height: 18),
                  GenderSelector(value: provider.gender, onChanged: provider.setGender),
                  const SizedBox(height: 22),
                  AdminSubmitButton(
                    label: provider.isEditing ? 'Update Category' : 'Save Category',
                    loading: provider.isSaving,
                    onPressed: () => _save(context),
                    color: const Color(0xFFF59E0B),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}