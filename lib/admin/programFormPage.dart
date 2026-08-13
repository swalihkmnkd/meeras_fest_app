import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'adminWidgets.dart';
import 'providers/programProvider.dart';

class ProgramFormPage extends StatelessWidget {
  const ProgramFormPage({super.key});

  Future<void> _save(BuildContext context) async {
    final provider = context.read<ProgramProvider>();
    final error = await provider.save();
    if (!context.mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    final wasEditing = provider.isEditing;
    await showAdminSuccessDialog(
      context,
      message: wasEditing ? 'Program updated successfully.' : 'Program added successfully.',
    );
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProgramProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF3F4F6),
          appBar: AppBar(
            title: Text(provider.isEditing ? 'Edit Program' : 'Add Program'),
            backgroundColor: const Color(0xFF10B981),
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
                    label: 'Program Name',
                    icon: Icons.event_note_rounded,
                  ),
                  const SizedBox(height: 14),
                  if (provider.categoryNames.isEmpty)
                    const Text(
                      'No categories found. Create a category first.',
                      style: TextStyle(color: Color(0xFFEF4444), fontSize: 12),
                    )
                  else
                    AdminDropdownField(
                      label: 'Category',
                      icon: Icons.category_rounded,
                      value: provider.category,
                      items: provider.categoryNames,
                      onChanged: provider.setCategory,
                    ),
                  const SizedBox(height: 18),
                  GenderSelector(value: provider.gender, onChanged: provider.setGender),
                  const SizedBox(height: 22),
                  AdminSubmitButton(
                    label: provider.isEditing ? 'Update Program' : 'Save Program',
                    loading: provider.isSaving,
                    onPressed: () => _save(context),
                    color: const Color(0xFF10B981),
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