import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:meeras_fest_app/stage_manager/stageManagerProvider.dart';
import 'package:meeras_fest_app/registration/registration_model.dart'; // ⚠️ adjust to your real path

// ---------------------------------------------------------------------------
// Palette — kept consistent with StageManagerAddPage
// ---------------------------------------------------------------------------
const _kBg = Color(0xFFF8FAFC);
const _kPrimary = Color(0xFF0EA5E9);
const _kPrimaryDark = Color(0xFF0284C7);
const _kInk = Color(0xFF1F2937);
const _kMuted = Color(0xFF64748B);
const _kBorder = Color(0xFFE2E8F0);
const _kSuccess = Color(0xFF10B981);
const _kSuccessDark = Color(0xFF059669);
const _kAmber = Color(0xFFF59E0B);

/// The Stage Manager's Assignments screen.
///
/// Expects a [StageManagerProvider] to already be available above it in the
/// widget tree (via ChangeNotifierProvider), the same pattern used by
/// StageManagerAddPage / StageManagerAdminProvider.
///
/// Two tabs:
///  • "To Assign" — programs that still have at least one un-lettered entry.
///  • "Assigned"  — programs where every entry already has a code letter.
///
/// Tapping any program card opens a bottom sheet where the Stage Manager
/// assigns / changes a letter for each team entered in that program.
class StageManagerAssignmentsPage extends StatefulWidget {
  const StageManagerAssignmentsPage({super.key});

  @override
  State<StageManagerAssignmentsPage> createState() =>
      _StageManagerAssignmentsPageState();
}

class _StageManagerAssignmentsPageState
    extends State<StageManagerAssignmentsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StageManagerProvider>().load();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<StageManagerProvider>();

    final allPrograms = prov.programSummaries;
    final toAssign = allPrograms.where((p) => p.assigned < p.total).toList();
    final assigned = allPrograms.where((p) => p.assigned == p.total && p.total > 0).toList();

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Assignments', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: _kInk,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Filters',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => _openFilterSheet(context, prov),
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: prov.isLoading ? null : () => prov.load(),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            decoration: BoxDecoration(
              color: _kBg,
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(4),
            child: TabBar(
              indicatorSize: TabBarIndicatorSize.tab,
              controller: _tabController,
              isScrollable: false, // 👈 Equal width tabs
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  colors: [_kPrimary, _kPrimaryDark],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _kPrimary.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: _kMuted,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              dividerColor: Colors.transparent,
              tabs: [
                Tab(text: 'To Assign (${toAssign.length})'),
                Tab(text: 'Assigned (${assigned.length})'),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: _Body(prov: prov, toAssign: toAssign, assigned: assigned, tabController: _tabController),
      ),
    );
  }

  void _openFilterSheet(BuildContext context, StageManagerProvider prov) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _FilterSheet(prov: prov),
    );
  }
}

class _Body extends StatelessWidget {
  final StageManagerProvider prov;
  final List<ProgramSummary> toAssign;
  final List<ProgramSummary> assigned;
  final TabController tabController;

  const _Body({
    required this.prov,
    required this.toAssign,
    required this.assigned,
    required this.tabController,
  });

  @override
  Widget build(BuildContext context) {
    if (prov.isLoading) {
      return const Center(child: CircularProgressIndicator(color: _kPrimary));
    }
    if (prov.loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 40),
              const SizedBox(height: 12),
              Text(prov.loadError!, textAlign: TextAlign.center, style: const TextStyle(color: _kMuted)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => prov.load(), child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return TabBarView(
      controller: tabController,
      children: [
        _ProgramList(
          programs: toAssign,
          prov: prov,
          emptyIcon: Icons.celebration_rounded,
          emptyTitle: 'All caught up!',
          emptySubtitle: 'Every program in the current filter is fully assigned.',
        ),
        _ProgramList(
          programs: assigned,
          prov: prov,
          emptyIcon: Icons.inbox_rounded,
          emptyTitle: 'Nothing assigned yet',
          emptySubtitle: 'Assigned programs will show up here.',
        ),
      ],
    );
  }
}

class _ProgramList extends StatelessWidget {
  final List<ProgramSummary> programs;
  final StageManagerProvider prov;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;

  const _ProgramList({
    required this.programs,
    required this.prov,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  @override
  Widget build(BuildContext context) {
    if (programs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(emptyIcon, size: 52, color: _kBorder),
              const SizedBox(height: 14),
              Text(emptyTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _kInk)),
              const SizedBox(height: 6),
              Text(emptySubtitle, textAlign: TextAlign.center, style: const TextStyle(color: _kMuted)),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: _kPrimary,
      onRefresh: () => prov.load(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: programs.length,
        itemBuilder: (context, i) => _ProgramCard(program: programs[i], prov: prov),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Program card — the "3D" elevated tile
// ---------------------------------------------------------------------------
class _ProgramCard extends StatelessWidget {
  final ProgramSummary program;
  final StageManagerProvider prov;

  const _ProgramCard({required this.program, required this.prov});

  @override
  Widget build(BuildContext context) {
    final done = program.total > 0 && program.assigned == program.total;
    final progress = program.total == 0 ? 0.0 : program.assigned / program.total;
    final accent = done ? _kSuccess : _kPrimary;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.10),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
          const BoxShadow(
            color: Colors.black12,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openAssignSheet(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Progress "badge" — reads like a raised disc
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: done
                          ? [_kSuccess, _kSuccessDark]
                          : [_kPrimary.withOpacity(0.15), _kPrimary.withOpacity(0.05)],
                    ),
                    boxShadow: done
                        ? [BoxShadow(color: _kSuccess.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))]
                        : [],
                  ),
                  child: Center(
                    child: done
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 26)
                        : Text(
                      '${program.assigned}/${program.total}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: _kPrimaryDark, fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        program.programName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _kInk),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _Tag(text: program.programCategory, color: _kPrimary),
                          _Tag(text: program.stageType, color: _kAmber),
                          if (program.isGeneral) const _Tag(text: 'General', color: _kMuted),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: _kBorder,
                          valueColor: AlwaysStoppedAnimation(accent),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right_rounded, color: _kMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openAssignSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: prov,
        child: _AssignSheet(programId: program.programId, programName: program.programName),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  const _Tag({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

// ---------------------------------------------------------------------------
// Assign sheet — pick / change a letter for each team in the program
// ---------------------------------------------------------------------------
class _AssignSheet extends StatelessWidget {
  final String programId;
  final String programName;

  const _AssignSheet({required this.programId, required this.programName});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<StageManagerProvider>();
    final regs = prov.registrationsForProgram(programId);
    final letters = StageManagerProvider.letterOptions(regs.length);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(color: _kBorder, borderRadius: BorderRadius.circular(10)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        programName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: _kInk),
                      ),
                    ),
                    Text('${regs.where((r) => r.isAssigned).length}/${regs.length} assigned',
                        style: const TextStyle(color: _kMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: regs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final reg = regs[i];
                    final taken = prov.takenLetters(programId, exceptRegistrationId: reg.id);
                    return _AssignRow(
                      reg: reg,
                      letters: letters,
                      takenLetters: taken,
                      onChanged: (letter) => prov.assignCodeLetter(reg, letter),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AssignRow extends StatelessWidget {
  final RegistrationModel reg;
  final List<String> letters;
  final Set<String> takenLetters;
  final ValueChanged<String?> onChanged;

  const _AssignRow({
    required this.reg,
    required this.letters,
    required this.takenLetters,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final assigned = reg.isAssigned;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: assigned ? _kSuccess.withOpacity(0.06) : _kBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: assigned ? _kSuccess.withOpacity(0.35) : _kBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: assigned ? _kSuccess : Colors.white,
            child: Text(
              assigned && reg.codeLetter.isNotEmpty ? reg.codeLetter : '—',
              style: TextStyle(
                color: assigned ? Colors.white : _kMuted,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reg.programName, style: const TextStyle(fontWeight: FontWeight.w600, color: _kInk)),
                if (reg.studentCategory.isNotEmpty)
                  Text(reg.studentCategory, style: const TextStyle(fontSize: 12, color: _kMuted)),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: assigned && reg.codeLetter.isNotEmpty ? reg.codeLetter : null,
                hint: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text('Set', style: TextStyle(color: _kMuted, fontSize: 13)),
                ),
                borderRadius: BorderRadius.circular(12),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                items: letters.map((l) {
                  final disabled = takenLetters.contains(l) && l != reg.codeLetter;
                  return DropdownMenuItem(
                    value: l,
                    enabled: !disabled,
                    child: Text(l, style: TextStyle(color: disabled ? _kBorder : _kInk)),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter sheet
// ---------------------------------------------------------------------------
class _FilterSheet extends StatelessWidget {
  final StageManagerProvider prov;
  const _FilterSheet({required this.prov});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: _kBorder, borderRadius: BorderRadius.circular(10)),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Filters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: _kInk)),
                TextButton(
                  onPressed: () {
                    prov.clearFilters();
                    Navigator.pop(context);
                  },
                  child: const Text('Clear all'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _FilterDropdown(
              label: 'Team category',
              value: prov.teamCategoryFilter,
              options: prov.teamCategoryOptions,
              onChanged: prov.setTeamCategoryFilter,
            ),
            _FilterDropdown(
              label: 'Program category',
              value: prov.programCategoryFilter,
              options: prov.programCategoryOptions,
              onChanged: prov.setProgramCategoryFilter,
            ),
            _FilterDropdown(
              label: 'Student category',
              value: prov.studentCategoryFilter,
              options: prov.studentCategoryOptions,
              onChanged: prov.setStudentCategoryFilter,
            ),
            _FilterDropdown(
              label: 'Stage type',
              value: prov.stageTypeFilter,
              options: prov.stageTypeOptions,
              onChanged: prov.setStageTypeFilter,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Apply', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _kMuted)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: _kBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                isExpanded: true,
                value: value,
                hint: const Text('All', style: TextStyle(color: _kMuted)),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('All')),
                  ...options.map((o) => DropdownMenuItem<String?>(value: o, child: Text(o))),
                ],
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}