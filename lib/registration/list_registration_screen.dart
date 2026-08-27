import 'package:flutter/material.dart';
import 'package:meeras_fest_app/profile/profileProvider.dart';
import 'package:meeras_fest_app/registration/register_provider.dart';
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

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              const Padding(
                padding: EdgeInsets.only(left: 12.0),
                child: Text("Registrations",
                    style: TextStyle(color: Color(0xff1F2937), fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 12.0),
                child: Text("View and manage your team's entries",
                    style: TextStyle(color: Color(0xff6B7280), fontWeight: FontWeight.w400, fontSize: 12)),
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
                    ? _StudentWiseList(provider: provider)
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
class _StudentWiseList extends StatelessWidget {
  final RegistrationProvider provider;
  const _StudentWiseList({required this.provider});

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
        return _StudentGroupCard(provider: provider, group: group);
      },
    );
  }
}

class _StudentGroupCard extends StatelessWidget {
  final RegistrationProvider provider;
  final StudentRegistrationGroup group;
  const _StudentGroupCard({required this.provider, required this.group});

  Future<void> _handleUpload(BuildContext context) async {
    final error = await provider.uploadStudentPhoto(group.studentId);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = provider.photoUploadProgress[group.studentId];
    final hasPhoto = group.photoUrl != null && group.photoUrl!.isNotEmpty;

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
            ],
          ),
          if (group.stagePrograms.isNotEmpty) ...[
            const SizedBox(height: 12),
            _ProgramTypeSection(
              label: 'Stage',
              programNames: group.stagePrograms.map((r) => r.programName).toList(),
              bg: const Color(0xFFFFEDD5),
              fg: const Color(0xFFC2410C),
            ),
          ],
          if (group.nonStagePrograms.isNotEmpty) ...[
            const SizedBox(height: 8),
            _ProgramTypeSection(
              label: 'Non Stage',
              programNames: group.nonStagePrograms.map((r) => r.programName).toList(),
              bg: const Color(0xFFDBEAFE),
              fg: const Color(0xFF1D4ED8),
            ),
          ],
          if (group.generalPrograms.isNotEmpty) ...[
            const SizedBox(height: 8),
            _ProgramTypeSection(
              label: 'General',
              programNames: group.generalPrograms.map((r) => r.programName).toList(),
              bg: const Color(0xFFDCFCE7),
              fg: const Color(0xFF15803D),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProgramTypeSection extends StatelessWidget {
  final String label;
  final List<String> programNames;
  final Color bg;
  final Color fg;

  const _ProgramTypeSection({
    required this.label,
    required this.programNames,
    required this.bg,
    required this.fg,
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
          children: programNames
              .map((name) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(name, style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w500)),
          ))
              .toList(),
        ),
      ],
    );
  }
}

/// ================= PROGRAM WISE VIEW =================
/// Each program appears once, with every registered student + registration
/// id listed underneath.
class _ProgramWiseList extends StatelessWidget {
  final RegistrationProvider provider;
  final Color Function(String) categoryColor;
  final Color Function(String) categoryTextColor;

  const _ProgramWiseList({
    required this.provider,
    required this.categoryColor,
    required this.categoryTextColor,
  });

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
              ...group.registrations.map((r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: Color(0xff9CA3AF)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(r.studentName,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    ),
                    Text('ID: ${r.registrationNumber}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              )),
            ],
          ),
        );
      },
    );
  }
}