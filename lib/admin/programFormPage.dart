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

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(top: 6, bottom: 10),
    child: Text(
      text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6B7280)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Consumer<ProgramProvider>(
      builder: (context, provider, child) {
        final categoryReady = provider.studentCategory != null;

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
                  AdminDropdownField(
                    label: 'Team Category',
                    icon: Icons.groups_rounded,
                    value: const ['Boys', 'Girls', 'Mixed'].contains(provider.studentCategory)
                        ? provider.studentCategory
                        : null,
                    items: const ['Boys', 'Girls', 'Mixed'],
                    onChanged: (v) => provider.setStudentCategory(v!),
                  ),
                  const SizedBox(height: 14),

                  // ── Program Category: now Firebase-driven, filtered by Team Category ──
                  AdminDropdownField(
                    label: 'Program Category',
                    icon: Icons.theater_comedy_rounded,
                    // ✅ never pass a value the dropdown doesn't recognize —
                    // that's what triggers the DropdownButtonFormField assertion crash
                    value: provider.programCategoryOptions.contains(provider.programCategory)
                        ? provider.programCategory
                        : null,
                    items: provider.programCategoryOptions,
                    onChanged: (v) {
                      if (!categoryReady || provider.programCategoryOptions.isEmpty) return;
                      if (v != null) provider.setProgramCategory(v);
                    },
                  ),
                  if (!categoryReady)
                    const Padding(
                      padding: EdgeInsets.only(top: 6, left: 4),
                      child: Text(
                        'Select a Team Category first',
                        style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                      ),
                    )
                  else if (provider.isLoadingCategories)
                    const Padding(
                      padding: EdgeInsets.only(top: 6, left: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Loading categories...', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                        ],
                      ),
                    )
                  else if (provider.programCategoryOptions.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 6, left: 4),
                        child: Text(
                          'No categories found for this Team Category',
                          style: TextStyle(fontSize: 12, color: Colors.redAccent),
                        ),
                      ),

                  const SizedBox(height: 14),
                  AdminDropdownField(
                    label: 'Stage / Non Stage',
                    icon: Icons.stairs_rounded,
                    value: const ['Stage', 'Non Stage'].contains(provider.stageType)
                        ? provider.stageType
                        : null,
                    items: const ['Stage', 'Non Stage'],
                    onChanged: (v) {
                      if (v != null) provider.setStageType(v);
                    },
                  ),
                  const SizedBox(height: 14),
                  AdminFormField(
                    controller: provider.totalParticipantsCtrl,
                    label: 'Total Participants',
                    icon: Icons.people_alt_rounded,
                    keyboardType: TextInputType.number,
                  ),
                  _sectionTitle('POSITION SCORES (points awarded)'),
                  Row(
                    children: [
                      Expanded(
                        child: AdminFormField(
                          controller: provider.firstScoreCtrl,
                          label: '1st Place',
                          icon: Icons.looks_one_rounded,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AdminFormField(
                          controller: provider.secondScoreCtrl,
                          label: '2nd Place',
                          icon: Icons.looks_two_rounded,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AdminFormField(
                          controller: provider.thirdScoreCtrl,
                          label: '3rd Place',
                          icon: Icons.looks_3_rounded,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  _sectionTitle('GRADE START MARKS (out of 100)'),
                  Row(
                    children: [
                      Expanded(
                        child: AdminFormField(
                          controller: provider.aGradeCtrl,
                          label: 'A Grade ≥',
                          icon: Icons.star_rounded,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AdminFormField(
                          controller: provider.bGradeCtrl,
                          label: 'B Grade ≥',
                          icon: Icons.star_half_rounded,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AdminFormField(
                          controller: provider.cGradeCtrl,
                          label: 'C Grade ≥',
                          icon: Icons.star_border_rounded,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  _sectionTitle('GRADE POINTS (e.g. A=3, B=2, C=1)'),
                  Row(
                    children: [
                      Expanded(
                        child: AdminFormField(
                          controller: provider.aGradePointCtrl,
                          label: 'A Point',
                          icon: Icons.workspace_premium_rounded,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AdminFormField(
                          controller: provider.bGradePointCtrl,
                          label: 'B Point',
                          icon: Icons.workspace_premium_rounded,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AdminFormField(
                          controller: provider.cGradePointCtrl,
                          label: 'C Point',
                          icon: Icons.workspace_premium_rounded,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
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