import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../judges/judge_provider.dart';
import 'adminWidgets.dart';
import 'assign_program_to_judge_screen.dart';

class JudgesFormPage extends StatelessWidget {
  const JudgesFormPage({super.key});

  Future<void> _save(BuildContext context) async {
    final provider = context.read<JudgeProvider>();
    final wasEditing = provider.isEditing;
    final error = await provider.save();
    if (!context.mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    if (wasEditing) {
      // Editing an existing judge: just confirm and go back, same as before.
      await showAdminSuccessDialog(context, message: 'Judge updated successfully.');
      if (context.mounted) Navigator.pop(context);
      return;
    }

    // New judge: go straight to assigning programs instead of popping back.
    final judgeId = provider.lastSavedId;
    final judgeName = provider.lastSavedName ?? '';
    if (judgeId == null) {
      if (context.mounted) Navigator.pop(context);
      return;
    }

    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        // Wrapped with ChangeNotifierProvider.value — without this the
        // assign screen has no JudgeProvider in its context and
        // context.read<JudgeProvider>() throws.
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: AssignProgramsToJudgePage(
            judgeId: judgeId,
            judgeName: judgeName,
          ),
        ),
      ),
    );
  }

  void _openAssignPrograms(BuildContext context, JudgeProvider provider) {
    final judgeId = provider.editingId;
    if (judgeId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: AssignProgramsToJudgePage(
            judgeId: judgeId,
            judgeName: provider.nameCtrl.text.trim(),
          ),
        ),
      ),
    );
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
                  AdminFormField(
                    controller: provider.nameCtrl,
                    label: 'Judge Name',
                    icon: Icons.person_rounded,
                  ),
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
                  AdminFormField(
                    controller: provider.usernameCtrl,
                    label: 'Username',
                    icon: Icons.account_circle_rounded,
                  ),
                  const SizedBox(height: 14),
                  AdminFormField(
                    controller: provider.passwordCtrl,
                    label: provider.isEditing ? 'Password (leave blank to keep current)' : 'Password',
                    icon: Icons.lock_rounded,
                    obscureText: true,
                  ),
                  const SizedBox(height: 22),
                  AdminSubmitButton(
                    label: provider.isEditing ? 'Update Judge' : 'Save & Assign Programs',
                    loading: provider.isSaving,
                    onPressed: () => _save(context),
                    color: const Color(0xFFEF4444),
                  ),
                  if (provider.isEditing) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _openAssignPrograms(context, provider),
                        icon: const Icon(Icons.event_note_rounded, color: Color(0xFFEF4444)),
                        label: Text(
                          'Assign Programs (${provider.programsForJudge(provider.editingId ?? '').length} assigned)',
                          style: const TextStyle(color: Color(0xFFEF4444)),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFEF4444)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}