import 'package:flutter/material.dart';
import 'package:meeras_fest_app/admin/teamsProvider.dart';
import 'package:provider/provider.dart';

import 'adminWidgets.dart';

class TeamsFormPage extends StatelessWidget {
  const TeamsFormPage({super.key});

  Future<void> _save(BuildContext context) async {
    final provider = context.read<TeamProvider>();
    final error = await provider.save();
    if (!context.mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    final wasEditing = provider.isEditing;
    await showAdminSuccessDialog(
      context,
      message: wasEditing ? 'Team updated successfully.' : 'Team added successfully.',
    );
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TeamProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF3F4F6),
          appBar: AppBar(
            title: Text(provider.isEditing ? 'Edit Team' : 'Add Team'),
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: AdminCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdminFormField(controller: provider.nameCtrl, label: 'Team Name', icon: Icons.groups_rounded),
                  const SizedBox(height: 14),
                  AdminFormField(controller: provider.leaderCtrl, label: 'Team Leader', icon: Icons.star_rounded),
                  const SizedBox(height: 18),
                  GenderSelector(value: provider.gender, onChanged: provider.setGender),
                  const SizedBox(height: 22),
                  AdminSubmitButton(
                    label: provider.isEditing ? 'Update Team' : 'Save Team',
                    loading: provider.isSaving,
                    onPressed: () => _save(context),
                    color: const Color(0xFF3B82F6),
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