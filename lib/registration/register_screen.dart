import 'package:flutter/material.dart';
import 'package:meeras_fest_app/profile/profileProvider.dart';
import 'package:meeras_fest_app/registration/register_provider.dart';
import 'package:provider/provider.dart';

import '../admin/models/categoryModel.dart';
import '../admin/models/programModel.dart';
import '../admin/models/studentModel.dart';
import '../admin/providers/categoryProvider.dart';



class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  static Color _categoryColor(String category) {
    switch (category) {
      case 'Stage':
        return Colors.orange.shade50;
      case 'Non Stage':
        return Colors.blue.shade50;
      case 'General':
        return Colors.green.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  static Color _categoryTextColor(String category) {
    switch (category) {
      case 'Stage':
        return Colors.orange.shade800;
      case 'Non Stage':
        return Colors.blue.shade800;
      case 'General':
        return Colors.green.shade800;
      default:
        return Colors.black87;
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamId = context.watch<ProfileProvider>().teamId;
    if (teamId != null) {
      context.read<RegistrationProvider>().loadForTeam(teamId);
    }

    return Scaffold(
      body: Consumer<RegistrationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),
                const Padding(
                  padding: EdgeInsets.only(left: 12.0),
                  child: Text("Register Programs",
                      style: TextStyle(
                          color: Color(0xff1F2937), fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 12.0),
                  child: Text("Add participants for your team",
                      style: TextStyle(
                          color: Color(0xff6B7280), fontWeight: FontWeight.w400, fontSize: 12)),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: _RegistrationForm(provider: provider),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: Text(
                    "Added Items (${provider.pendingEntries.length})",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xff1F2937)),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: provider.pendingEntries.length,
                    itemBuilder: (context, index) {
                      final item = provider.pendingEntries[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.studentName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: Color(0xff1F2937))),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(item.programName,
                                            style: const TextStyle(fontSize: 12, color: Color(0xff6B7280))),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding:
                                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _categoryColor(item.programCategory),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(item.programCategory,
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: _categoryTextColor(item.programCategory))),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => provider.removePending(index),
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 23),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 39,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Color(0xffFF8A50), Color(0xffFF5E6C)],
                        ),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: provider.isSubmitting || provider.pendingEntries.isEmpty
                            ? null
                            : () async {
                          final error = await provider.submitAll();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error ?? 'Registrations submitted')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: provider.isSubmitting
                            ? const SizedBox(
                            height: 14,
                            width: 14,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.check_circle_outline, size: 15, color: Colors.white),
                        label: const Text("Submit All Registrations",
                            style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RegistrationForm extends StatelessWidget {
  final RegistrationProvider provider;
  const _RegistrationForm({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const _FieldLabel('Category'),
          const SizedBox(height: 8),
          if (provider.categories.isEmpty)
            _BoxWrapper(
              child: Text('No categories found',
                  style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
            )
          else
            _BoxWrapper(
              child: DropdownButtonHideUnderline(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: DropdownButton<CategoryModel>(
                    style: const TextStyle(fontSize: 12, color: Colors.black),
                    value: provider.selectedCategory,
                    isExpanded: true,
                    hint: const Text('Select category',
                        style: TextStyle(color: Color(0xff9CA3AF), fontSize: 12)),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    items: provider.categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c.name, style: const TextStyle(fontSize: 12))))
                        .toList(),
                    onChanged: provider.setCategory,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 20),

          const _FieldLabel('Program'),
          const SizedBox(height: 8),
          _BoxWrapper(
            child: DropdownButtonHideUnderline(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: DropdownButton<ProgramModel>(
                  style: const TextStyle(fontSize: 12, color: Colors.black),
                  value: provider.selectedProgram,
                  isExpanded: true,
                  hint: Text(
                    provider.selectedCategory == null ? 'Select category first' : 'Select program',
                    style: const TextStyle(color: Color(0xff9CA3AF), fontSize: 12),
                  ),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  items: provider.programsForSelectedCategory
                      .map((p) => DropdownMenuItem(
                    value: p,
                    child: Text(
                      '${p.programName}  (${provider.remainingSlots(p)} left)',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ))
                      .toList(),
                  onChanged: provider.selectedCategory == null ? null : provider.setProgram,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          const _FieldLabel('Students'),
          const SizedBox(height: 8),
          if (provider.selectedProgram == null)
            _BoxWrapper(
              child: Text('Select a program first',
                  style: const TextStyle(color: Color(0xff9CA3AF), fontSize: 12)),
            )
          else
            _StudentChecklist(provider: provider),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final error = provider.addSelectedToList();
                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                }
              },
              icon: const Icon(Icons.add, size: 12),
              label: const Text('Add Selected to List', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A2E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Multi-select list of students eligible for the currently selected program.
class _StudentChecklist extends StatelessWidget {
  final RegistrationProvider provider;
  const _StudentChecklist({required this.provider});

  @override
  Widget build(BuildContext context) {
    final students = provider.eligibleStudents;

    if (students.isEmpty) {
      return _BoxWrapper(
        child: Text('No eligible students for this program',
            style: const TextStyle(color: Color(0xff9CA3AF), fontSize: 12)),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4E4EA)),
      ),
      child: Column(
        children: students.map((StudentModel s) {
          final selected = provider.selectedStudentIds.contains(s.id);
          return InkWell(
            onTap: () => provider.toggleStudentSelection(s.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: s == students.last ? Colors.transparent : const Color(0xFFE4E4EA),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    selected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                    color: selected ? const Color(0xFF1A1A2E) : const Color(0xff9CA3AF),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(s.name,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                            color: const Color(0xFF1F2937))),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)));
  }
}

class _BoxWrapper extends StatelessWidget {
  final Widget child;
  const _BoxWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 50),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4E4EA)),
      ),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: child,
    );
  }
}