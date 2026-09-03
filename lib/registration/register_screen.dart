import 'package:flutter/material.dart';
import 'package:meeras_fest_app/profile/profileProvider.dart';
import 'package:meeras_fest_app/registration/register_provider.dart';
import 'package:provider/provider.dart';

import '../admin/models/categoryModel.dart';
import '../admin/models/programModel.dart';
import '../admin/models/studentModel.dart';

/// Formats a [Duration] as a short "Xd Yh Zm" / "Yh Zm" / "Zm Ws" / "Ws"
/// countdown string, dropping leading zero units.
String _formatDuration(Duration d) {
  if (d.inDays > 0) return '${d.inDays}d ${d.inHours % 24}h ${d.inMinutes % 60}m';
  if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
  if (d.inMinutes > 0) return '${d.inMinutes}m ${d.inSeconds % 60}s';
  return '${d.inSeconds}s';
}

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  static Color _stageColor(String stageType) {
    switch (stageType) {
      case 'Stage':
        return Colors.orange.shade50;
      case 'Non Stage':
        return Colors.blue.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  static Color _stageTextColor(String stageType) {
    switch (stageType) {
      case 'Stage':
        return Colors.orange.shade800;
      case 'Non Stage':
        return Colors.blue.shade800;
      default:
        return Colors.black87;
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamId = context.watch<ProfileProvider>().teamId;
    // NOTE: adjust `teamCategory` below if your ProfileProvider names the
    // team's own Boy/Girl/Mixed field differently.
    final teamCategory = context.watch<ProfileProvider>().teamCategory;
    if (teamId != null) {
      context.read<RegistrationProvider>().loadForTeam(teamId, teamCategory);
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

                // ⬅️ NEW: registration deadline banner — closed notice once
                // the deadline has passed, or a live countdown before that.
                if (provider.isRegistrationClosed)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.lock_clock_outlined, color: Color(0xFFB91C1C), size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Registration is closed. The deadline has passed.',
                              style: TextStyle(
                                  color: Color(0xFFB91C1C),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (provider.timeUntilDeadline != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.timer_outlined, color: Color(0xFF92400E), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Registration closes in ${_formatDuration(provider.timeUntilDeadline!)}',
                              style: const TextStyle(
                                  color: Color(0xFF92400E),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
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
                                        Expanded(
                                          child: Text(
                                            '${item.programName} · ${item.programCategory}',
                                            style: const TextStyle(fontSize: 12, color: Color(0xff6B7280)),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding:
                                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _stageColor(item.stageType),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(item.stageType,
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: _stageTextColor(item.stageType))),
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
                        // ⬅️ CHANGED: also disabled once registration is closed.
                        onPressed: provider.isSubmitting ||
                            provider.pendingEntries.isEmpty ||
                            provider.isRegistrationClosed
                            ? null
                            : () async {
                          final error = await provider.submitAll();

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  error ?? 'Registrations submitted',
                                ),
                              ),
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
    final closed = provider.isRegistrationClosed; // ⬅️ NEW

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
          // ---- Category (filtered to this team's Boy/Girl/Mixed category) ----
          const _FieldLabel('Category'),
          const SizedBox(height: 8),
          if (provider.categoriesForTeam.isEmpty)
            _BoxWrapper(
              child: const Text('No categories found for your team',
                  style: TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
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
                    items: provider.categoriesForTeam
                        .map((c) => DropdownMenuItem(value: c, child: Text(c.name, style: const TextStyle(fontSize: 12))))
                        .toList(),
                    // ⬅️ CHANGED: disabled once registration is closed.
                    onChanged: closed ? null : provider.setCategory,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 20),

          // ---- Stage / Non Stage ----
          const _FieldLabel('Stage / Non Stage'),
          const SizedBox(height: 8),
          _BoxWrapper(
            child: DropdownButtonHideUnderline(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: DropdownButton<String>(
                  style: const TextStyle(fontSize: 12, color: Colors.black),
                  value: provider.selectedStageType,
                  isExpanded: true,
                  hint: Text(
                    provider.selectedCategory == null ? 'Select category first' : 'Select Stage / Non Stage',
                    style: const TextStyle(color: Color(0xff9CA3AF), fontSize: 12),
                  ),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  items: provider.stageTypeOptions
                      .map((st) => DropdownMenuItem(value: st, child: Text(st, style: const TextStyle(fontSize: 12))))
                      .toList(),
                  // ⬅️ CHANGED: disabled once registration is closed.
                  onChanged: closed || provider.selectedCategory == null ? null : provider.setStageType,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ---- Program ----
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
                    provider.selectedStageType == null ? 'Select Stage / Non Stage first' : 'Select program',
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
                  // ⬅️ CHANGED: disabled once registration is closed.
                  onChanged: closed || provider.selectedStageType == null ? null : provider.setProgram,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ---- Students ----
          const _FieldLabel('Students'),
          const SizedBox(height: 8),
          if (provider.selectedProgram == null)
            _BoxWrapper(
              child: const Text('Select a program first',
                  style: TextStyle(color: Color(0xff9CA3AF), fontSize: 12)),
            )
          else
            _StudentChecklist(provider: provider),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              // ⬅️ CHANGED: disabled once registration is closed.
              onPressed: closed
                  ? null
                  : () {
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
/// Selection is capped at the program's remaining participant count — once
/// reached, unselected checkboxes disable themselves.
class _StudentChecklist extends StatelessWidget {
  final RegistrationProvider provider;
  const _StudentChecklist({required this.provider});

  @override
  Widget build(BuildContext context) {
    final students = provider.eligibleStudents;
    final program = provider.selectedProgram;
    final closed = provider.isRegistrationClosed; // ⬅️ NEW

    if (students.isEmpty) {
      return _BoxWrapper(
        child: const Text('No eligible students for this program',
            style: TextStyle(color: Color(0xff9CA3AF), fontSize: 12)),
      );
    }

    final remaining = program != null ? provider.remainingSlots(program) : 0;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4E4EA)),
      ),
      child: Column(
        children: [
          if (program != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${provider.selectedStudentIds.length}/$remaining slot(s) selected',
                  style: const TextStyle(fontSize: 11, color: Color(0xff9CA3AF)),
                ),
              ),
            ),
          ...students.map((StudentModel s) {
            final selected = provider.selectedStudentIds.contains(s.id);
            // ⬅️ CHANGED: also "at limit" (i.e. can't be tapped) once closed.
            final atLimit =
                closed || (!selected && provider.selectedStudentIds.length >= remaining);
            return InkWell(
              onTap: atLimit
                  ? null
                  : () {
                final ok = provider.toggleStudentSelection(s.id);
                if (!ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No more slots left in this program')),
                  );
                }
              },
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
                      color: selected
                          ? const Color(0xFF1A1A2E)
                          : atLimit
                          ? const Color(0xffE5E7EB)
                          : const Color(0xff9CA3AF),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(s.name,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                              color: atLimit ? const Color(0xff9CA3AF) : const Color(0xFF1F2937))),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
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