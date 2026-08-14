import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:meeras_fest_app/admin/providers/teamsProvider.dart';
import 'package:meeras_fest_app/admin/student_selection_page.dart';
import 'package:provider/provider.dart';

import 'adminWidgets.dart';
import 'models/teamModel.dart';

class TeamsFormPage extends StatefulWidget {
  const TeamsFormPage({super.key});

  @override
  State<TeamsFormPage> createState() => _TeamsFormPageState();
}

class _TeamsFormPageState extends State<TeamsFormPage> {
  bool _obscurePassword = true;

  Future<void> _save(BuildContext context) async {
    final provider = context.read<TeamProvider>();
    final error = await provider.save();
    if (!context.mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    final wasEditing = provider.isEditing;
    setState(() {}); // refresh "Manage Students" tile after first save
    await showAdminSuccessDialog(
      context,
      message: wasEditing ? 'Team updated successfully.' : 'Team added successfully.',
    );
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
                  AdminFormField(controller: provider.teamIdCtrl, label: 'Team ID', icon: Icons.badge_rounded),
                  const SizedBox(height: 14),
                  AdminFormField(controller: provider.leaderCtrl, label: 'Team Leader', icon: Icons.star_rounded),
                  const SizedBox(height: 14),
                  AdminFormField(controller: provider.assistantLeaderCtrl, label: 'Assistant Leader', icon: Icons.star_half_rounded),
                  const SizedBox(height: 14),
                  AdminFormField(controller: provider.categoryCtrl, label: 'Team Category', icon: Icons.category_rounded),
                  const SizedBox(height: 14),

                  // Team color dropdown
                  Text('Team Color', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: provider.color,
                        isExpanded: true,
                        hint: const Text('Select a color'),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        items: teamColorOptions.map((opt) {
                          return DropdownMenuItem(
                            value: opt.name,
                            child: Row(
                              children: [
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(color: opt.color, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 10),
                                Text(opt.name),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) provider.setColor(value);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  AdminFormField(controller: provider.userNameCtrl, label: 'User Name', icon: Icons.person_rounded),
                  const SizedBox(height: 14),

                  // Password field with visibility toggle
                  TextField(
                    controller: provider.passwordCtrl,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Manage Students entry (only once the team has an id)
                  if (provider.isEditing) ...[
                    _ManageStudentsTile(provider: provider),
                    const SizedBox(height: 22),
                  ],

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

class _ManageStudentsTile extends StatefulWidget {
  final TeamProvider provider;
  const _ManageStudentsTile({required this.provider});

  @override
  State<_ManageStudentsTile> createState() => _ManageStudentsTileState();
}

class _ManageStudentsTileState extends State<_ManageStudentsTile> {
  int? _count;
  int? _boys;
  int? _girls;

  @override
  void initState() {
    super.initState();
    _loadCount();
  }

  Future<void> _loadCount() async {
    final teamId = widget.provider.editingIdForStudents;
    if (teamId == null) return;
    final snap = await FirebaseFirestore.instance
        .collection('STUDENTS')
        .where('TEAM_ID', isEqualTo: teamId)
        .get();
    if (!mounted) return;
    setState(() {
      _count = snap.docs.length;
      _boys = snap.docs.where((d) => d.data()['GENDER'] == 'Male').length;
      _girls = snap.docs.where((d) => d.data()['GENDER'] == 'Female').length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorOpt = teamColorOptions.firstWhere(
          (c) => c.name == widget.provider.color,
      orElse: () => teamColorOptions.first,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final teamId = widget.provider.editingIdForStudents;
        if (teamId == null) return;
        final changed = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => StudentSelectionPage(
              teamId: teamId,
              teamName: widget.provider.nameCtrl.text.trim(),
              teamCategory: widget.provider.categoryCtrl.text.trim(),
              teamColor: colorOpt.color,
              teamColorName: colorOpt.name,
            ),
          ),
        );
        if (changed == true) _loadCount();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorOpt.color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorOpt.color.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(color: colorOpt.color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _count == null
                    ? 'Manage Students'
                    : 'Manage Students  •  $_count added ($_boys boys, $_girls girls)',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}