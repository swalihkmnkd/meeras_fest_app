import 'package:flutter/material.dart';
import 'package:meeras_fest_app/admin/providers/student_selection_provider.dart';
import 'package:provider/provider.dart';

import 'models/studentModel.dart';

class StudentSelectionPage extends StatelessWidget {
  final String teamId;
  final String teamName;
  final String teamCategory;
  final Color teamColor;
  final String teamColorName;

  const StudentSelectionPage({
    super.key,
    required this.teamId,
    required this.teamName,
    required this.teamCategory,
    required this.teamColor,
    required this.teamColorName,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StudentSelectionProvider(
        teamId: teamId,
        teamName: teamName,
        teamCategory: teamCategory,
        teamColor: teamColorName,
      )..fetchStudents(),
      child: _StudentSelectionView(teamColor: teamColor),
    );
  }
}

class _StudentSelectionView extends StatelessWidget {
  final Color teamColor;
  const _StudentSelectionView({required this.teamColor});

  Future<void> _save(BuildContext context) async {
    final provider = context.read<StudentSelectionProvider>();
    final error = await provider.saveAssignments();
    if (!context.mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Select Students'),
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<StudentSelectionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.errorMessage != null) {
            return Center(child: Text(provider.errorMessage!));
          }
          if (provider.students.isEmpty) {
            return const Center(child: Text('No students found for this category.'));
          }

          return Column(
            children: [
              _buildSummaryBar(provider),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                  itemCount: provider.students.length,
                  itemBuilder: (context, index) {
                    final student = provider.students[index];
                    final selected = provider.isSelected(student.id);
                    final lockedByOtherTeam = !selected &&
                        student.isAssigned &&
                        student.teamId != provider.teamId;

                    return _StudentTile(
                      student: student,
                      selected: selected,
                      teamColor: teamColor,
                      disabled: lockedByOtherTeam,
                      onTap: lockedByOtherTeam
                          ? null
                          : () => provider.toggle(student.id),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Consumer<StudentSelectionProvider>(
        builder: (context, provider, child) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: provider.isSaving ? null : () => _save(context),
                  child: provider.isSaving
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : Text('Save (${provider.selectedCount} selected)'),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryBar(StudentSelectionProvider provider) {
    final isMixed = provider.students.any((s) => s.gender == 'Male') &&
        provider.students.any((s) => s.gender == 'Female');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(color: teamColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isMixed
                  ? '${provider.selectedCount} selected  •  ${provider.selectedBoysCount} boys, ${provider.selectedGirlsCount} girls'
                  : '${provider.selectedCount} selected',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentTile extends StatelessWidget {
  final StudentModel student;
  final bool selected;
  final bool disabled;
  final Color teamColor;
  final VoidCallback? onTap;

  const _StudentTile({
    required this.student,
    required this.selected,
    required this.disabled,
    required this.teamColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.45 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? teamColor : Colors.grey.shade300,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: student.gender == 'Female'
                        ? Colors.pink.shade100
                        : Colors.blue.shade100,
                    child: Icon(
                      student.gender == 'Female' ? Icons.female_rounded : Icons.male_rounded,
                      color: student.gender == 'Female' ? Colors.pink : Colors.blue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(student.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        if (disabled)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'In team: ${student.teamName}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    color: selected ? teamColor : Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}