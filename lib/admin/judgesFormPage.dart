import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../judges/judge_provider.dart';
import 'adminWidgets.dart';

class JudgesFormPage extends StatelessWidget {
  const JudgesFormPage({super.key});

  Future<void> _save(BuildContext context) async {
    final provider = context.read<JudgeProvider>();
    final error = await provider.save();
    if (!context.mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    final wasEditing = provider.isEditing;
    await showAdminSuccessDialog(
      context,
      message: wasEditing ? 'Judge updated successfully.' : 'Judge added successfully.',
    );
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<JudgeProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF3F4F6),
          appBar: AppBar(
            title: Text(provider.isEditing ? 'Edit Judge' : 'Add Judge'),
            backgroundColor: const Color(0xFFEF4444),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: AdminCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdminFormField(controller: provider.nameCtrl, label: 'Judge Name', icon: Icons.person_rounded),
                  const SizedBox(height: 14),
                  AdminFormField(
                    controller: provider.phoneCtrl,
                    label: 'Phone Number',
                    icon: Icons.phone_rounded,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 14),
                  AdminFormField(
                    controller: provider.emailCtrl,
                    label: 'Email',
                    icon: Icons.email_rounded,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),
                  if (provider.categoryNames.isEmpty)
                    const Text(
                      'No categories found yet. You can still save the judge and assign a category later.',
                      style: TextStyle(color: Color(0xff6B7280), fontSize: 12),
                    )
                  else
                    AdminDropdownField(
                      label: 'Assigned Category',
                      icon: Icons.category_rounded,
                      value: provider.assignedCategory,
                      items: provider.categoryNames,
                      onChanged: provider.setAssignedCategory,
                    ),
                  const SizedBox(height: 22),
                  AdminSubmitButton(
                    label: provider.isEditing ? 'Update Judge' : 'Save Judge',
                    loading: provider.isSaving,
                    onPressed: () => _save(context),
                    color: const Color(0xFFEF4444),
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