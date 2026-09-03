import 'package:flutter/material.dart';
import 'package:meeras_fest_app/profile/profileProvider.dart';
import 'package:meeras_fest_app/registration/register_provider.dart';
import 'package:meeras_fest_app/registration/registration_model.dart';
import 'package:meeras_fest_app/registration/student_details_screen.dart';
import 'package:meeras_fest_app/registration/student_id_pdf.dart';
import 'package:provider/provider.dart';

class ListRegistrationScreen extends StatelessWidget {
  const ListRegistrationScreen({super.key});

  static Color _categoryColor(String category) {
    switch (category) {
      case 'Stage':
        return const Color(0xFFFFEDD5);
      case 'Non Stage':
        return const Color(0xFFDBEAFE);
      case 'General':
        return const Color(0xFFDCFCE7);
      default:
        return const Color(0xFFF5F5F5);
    }
  }

  static Color _categoryTextColor(String category) {
    switch (category) {
      case 'Stage':
        return const Color(0xFFC2410C);
      case 'Non Stage':
        return const Color(0xFF1D4ED8);
      case 'General':
        return const Color(0xFF15803D);
      default:
        return Colors.black87;
    }
  }

  Future<void> _handlePrintAll(
      BuildContext context,
      RegistrationProvider provider,
      String teamName,
      ) async {
    final groups = provider.studentWiseGroups;
    if (groups.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No students to print')));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await StudentIdCardPdf.printAll(groups: groups, teamName: teamName);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to generate PDF: $e')));
      }
    } finally {
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamId = context.watch<ProfileProvider>().teamId;
    final teamName = context.watch<ProfileProvider>().teamName ?? '';
    if (teamId != null) {
      context.read<RegistrationProvider>().loadForTeam(teamId);
    }

    return Scaffold(
      body: Consumer<RegistrationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.only(left: 12.0, right: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("Registrations",
                              style: TextStyle(
                                  color: Color(0xff1F2937), fontWeight: FontWeight.bold, fontSize: 18)),
                          Text("View and manage your team's entries",
                              style: TextStyle(
                                  color: Color(0xff6B7280), fontWeight: FontWeight.w400, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Print all student ID cards',
                      icon: const Icon(Icons.print_outlined, color: Color(0xff667EEA)),
                      onPressed: () => _handlePrintAll(context, provider, teamName),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ---- View mode: Student wise / Program wise ----
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: _ViewModeToggle(provider: provider),
              ),

              const SizedBox(height: 12),

              // ---- Filters: Stage type, Category, Gender ----
              _FilterChipRow(
                options: provider.filterOptions,
                selected: provider.selectedFilter,
                onSelected: provider.setFilter,
              ),
              if (provider.programCategoryOptions.length > 1) ...[
                const SizedBox(height: 6),
                _FilterChipRow(
                  options: provider.programCategoryOptions,
                  selected: provider.selectedCategoryFilter,
                  onSelected: provider.setCategoryFilter,
                  accentColor: const Color(0xff667EEA),
                ),
              ],
              if (provider.genderFilterOptions.length > 1) ...[
                const SizedBox(height: 6),
                _FilterChipRow(
                  options: provider.genderFilterOptions,
                  selected: provider.selectedGenderFilter,
                  onSelected: provider.setGenderFilter,
                  accentColor: const Color(0xff22C55E),
                ),
              ],

              const SizedBox(height: 14),

              Expanded(
                child: provider.viewMode == RegistrationViewMode.student
                    ? _StudentWiseList(provider: provider, teamName: teamName)
                    : _ProgramWiseList(
                  provider: provider,
                  categoryColor: _categoryColor,
                  categoryTextColor: _categoryTextColor,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Segmented "Student wise" / "Program wise" toggle.
class _ViewModeToggle extends StatelessWidget {
  final RegistrationProvider provider;
  const _ViewModeToggle({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xffF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ViewModeButton(
              label: 'Student wise',
              icon: Icons.person_outline,
              selected: provider.viewMode == RegistrationViewMode.student,
              onTap: () => provider.setViewMode(RegistrationViewMode.student),
            ),
          ),
          Expanded(
            child: _ViewModeButton(
              label: 'Program wise',
              icon: Icons.event_note_outlined,
              selected: provider.viewMode == RegistrationViewMode.program,
              onTap: () => provider.setViewMode(RegistrationViewMode.program),
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ViewModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: selected ? const Color(0xff667EEA) : const Color(0xff6B7280)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? const Color(0xff1F2937) : const Color(0xff6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A horizontally-scrolling row of pill filter chips.
class _FilterChipRow extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;
  final Color accentColor;

  const _FilterChipRow({
    required this.options,
    required this.selected,
    required this.onSelected,
    this.accentColor = const Color(0xffFF8E53),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        itemBuilder: (context, index) {
          final label = options[index];
          final isSelected = selected == label;
          return InkWell(
            onTap: () => onSelected(label),
            borderRadius: BorderRadius.circular(9999),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? accentColor : const Color(0xFFE5E7EB),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(9999),
                color: isSelected ? accentColor.withValues(alpha: 0.12) : Colors.white,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? accentColor : const Color(0xff4B5563),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(width: 6),
        itemCount: options.length,
      ),
    );
  }
}

/// ================= STUDENT WISE VIEW =================
/// Each student appears once, with their programs bucketed into
/// Stage / Non Stage / General underneath, plus a tappable avatar to
/// upload/replace the student's photo (stored in Firebase Storage).
/// Tapping anywhere else on the card opens the full-screen student detail.
class _StudentWiseList extends StatelessWidget {
  final RegistrationProvider provider;
  final String teamName;
  const _StudentWiseList({required this.provider, required this.teamName});

  @override
  Widget build(BuildContext context) {
    final groups = provider.studentWiseGroups;
    if (groups.isEmpty) {
      return const Center(child: Text('No registrations yet', style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return _StudentGroupCard(provider: provider, group: group, teamName: teamName);
      },
    );
  }
}

class _StudentGroupCard extends StatelessWidget {
  final RegistrationProvider provider;
  final StudentRegistrationGroup group;
  final String teamName;
  const _StudentGroupCard({required this.provider, required this.group, required this.teamName});

  Future<void> _handleUpload(BuildContext context) async {
    final error = await provider.uploadStudentPhoto(group.studentId);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }
  Future<bool> _confirmDeleteRegistration(BuildContext context, String label) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove registration?'),
        content: Text('Remove $label from this program? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _deleteRegistration(
      BuildContext context,
      RegistrationProvider provider,
      RegistrationModel registration,
      ) async {
    final confirmed = await _confirmDeleteRegistration(
      context,
      '${registration.studentName} — ${registration.programName}',
    );
    if (!confirmed) return;

    final error = await provider.deleteRegistration(registration);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Registration removed')));
    }
  }
  void _openDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudentDetailScreen(group: group, teamName: teamName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = provider.photoUploadProgress[group.studentId];
    final hasPhoto = group.photoUrl != null && group.photoUrl!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openDetail(context),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xffF3F4F6),
                          backgroundImage: hasPhoto ? NetworkImage(group.photoUrl!) : null,
                          child: !hasPhoto
                              ? Text(
                            group.studentName.isNotEmpty ? group.studentName[0].toUpperCase() : '?',
                            style: const TextStyle(
                                color: Color(0xff6B7280), fontWeight: FontWeight.bold, fontSize: 16),
                          )
                              : null,
                        ),
                        if (progress != null)
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.all(1.5),
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                value: progress > 0 ? progress : null,
                                color: const Color(0xff667EEA),
                              ),
                            ),
                          ),
                        Positioned(
                          bottom: -2,
                          right: -2,
                          child: InkWell(
                            onTap: progress != null ? null : () => _handleUpload(context),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xff667EEA),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt_rounded, size: 11, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(group.studentName,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xff1F2937))),
                          const SizedBox(height: 2),
                          Text('ID: ${group.registrationNumber}',
                              style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xffF3F4F6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('${group.totalPrograms} programs',
                          style: const TextStyle(fontSize: 10, color: Color(0xff6B7280), fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded, color: Color(0xff9CA3AF)),
                  ],
                ),
                if (group.stagePrograms.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _ProgramTypeSection(
                    label: 'Stage',
                    registrations: group.stagePrograms,
                    bg: const Color(0xFFFFEDD5),
                    fg: const Color(0xFFC2410C),
                    onDelete: (r) => _deleteRegistration(context, provider, r),
                  ),
                ],
                if (group.nonStagePrograms.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _ProgramTypeSection(
                    label: 'Non Stage',
                    registrations: group.nonStagePrograms,
                    bg: const Color(0xFFDBEAFE),
                    fg: const Color(0xFF1D4ED8),
                    onDelete: (r) => _deleteRegistration(context, provider, r),
                  ),
                ],
                if (group.generalPrograms.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _ProgramTypeSection(
                    label: 'General',
                    registrations: group.generalPrograms,
                    bg: const Color(0xFFDCFCE7),
                    fg: const Color(0xFF15803D),
                    onDelete: (r) => _deleteRegistration(context, provider, r),
                  ),
                ],

              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgramTypeSection extends StatelessWidget {
  final String label;
  final List<RegistrationModel> registrations;
  final Color bg;
  final Color fg;
  final void Function(RegistrationModel) onDelete;

  const _ProgramTypeSection({
    required this.label,
    required this.registrations,
    required this.bg,
    required this.fg,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg, letterSpacing: 0.3)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: registrations
              .map((r) => Container(
            padding: const EdgeInsets.only(left: 10, right: 4, top: 5, bottom: 5),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(r.programName,
                    style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w500)),
                const SizedBox(width: 2),
                Consumer<RegistrationProvider>(
                    builder: (context,regPro,child) {
                      if(regPro.isRegistrationClosed){
                        return SizedBox.shrink();
                      }
                      return InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => onDelete(r),
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: Icon(Icons.close_rounded, size: 13, color: fg),
                        ),
                      );
                    }
                ),
              ],
            ),
          ))
              .toList(),
        ),
      ],
    );
  }
}

/// ================= PROGRAM WISE VIEW =================
/// Each program appears once, with every registered student + registration
/// id listed underneath — including a small avatar (photo if uploaded,
/// initial letter otherwise) so students are recognizable at a glance.
class _ProgramWiseList extends StatelessWidget {
  final RegistrationProvider provider;
  final Color Function(String) categoryColor;
  final Color Function(String) categoryTextColor;

  const _ProgramWiseList({
    required this.provider,
    required this.categoryColor,
    required this.categoryTextColor,
  });

  /// Looks up a student's photo URL from the team roster by id. Returns
  /// null if the student has no photo on file (or isn't found, which
  /// shouldn't normally happen but is handled gracefully either way).
  String? _photoUrlFor(String studentId) {
    for (final s in provider.teamStudents) {
      if (s.id == studentId) return s.photoUrl;
    }
    return null;
  }

  Future<bool> _confirmDeleteRegistration(BuildContext context, String label) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove registration?'),
        content: Text('Remove $label from this program? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _deleteRegistration(
      BuildContext context,
      RegistrationProvider provider,
      RegistrationModel registration,
      ) async {
    final confirmed = await _confirmDeleteRegistration(
      context,
      '${registration.studentName} — ${registration.programName}',
    );
    if (!confirmed) return;

    final error = await provider.deleteRegistration(registration);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Registration removed')));
    }
  }
  @override
  Widget build(BuildContext context) {
    final groups = provider.programWiseGroups;
    if (groups.isEmpty) {
      return const Center(child: Text('No registrations yet', style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        final badgeLabel = group.isGeneral ? 'General' : group.stageType;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(group.programName,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xff1F2937))),
                        const SizedBox(height: 2),
                        Text(group.programCategory,
                            style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: categoryColor(badgeLabel),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(badgeLabel,
                        style: TextStyle(fontSize: 11, color: categoryTextColor(badgeLabel))),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xffF3F4F6)),
              const SizedBox(height: 8),
              ...group.registrations.map((r) {
                final photoUrl = _photoUrlFor(r.studentId);
                final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: const Color(0xffF3F4F6),
                        backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
                        child: !hasPhoto
                            ? Text(
                          r.studentName.isNotEmpty ? r.studentName[0].toUpperCase() : '?',
                          style: const TextStyle(
                              fontSize: 10, color: Color(0xff6B7280), fontWeight: FontWeight.bold),
                        )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(r.studentName,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      ),
                      Text('ID: ${r.registrationNumber}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(width: 8),
                      provider.isRegistrationClosed?SizedBox.shrink():InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => _deleteRegistration(context, provider, r),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xffEF4444)),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}