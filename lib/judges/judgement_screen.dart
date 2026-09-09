import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../profile/profileProvider.dart';
import 'judge_provider.dart';

class JudgePanelPage extends StatelessWidget {
  const JudgePanelPage({super.key});

  static Future<bool> confirmLeave(BuildContext context, JudgeProvider provider) async {
    if (!provider.hasNewScores) return true; // nothing saved this session, leave freely

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave scoring?'),
        content: const Text(
          "You've saved scores in this session. Once you leave, you won't be able to change them here. Continue?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => JudgeProvider()
        ..fetchAssignedPrograms(context.read<ProfileProvider>().entityId ?? ''),
      child: Consumer<JudgeProvider>(
        builder: (context, provider, child) {
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) return;
              final canLeave = await confirmLeave(context, provider);
              if (canLeave && context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: Scaffold(
              backgroundColor: const Color(0xffF7F7F7),
              body: SafeArea(
                child: provider.selectedProgram == null
                    ? _ProgramListView(provider: provider)
                    : _ScoringView(provider: provider),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Step 1: list of programs assigned to this judge.
class _ProgramListView extends StatelessWidget {
  final JudgeProvider provider;
  const _ProgramListView({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Judge Panel",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Text("Your assigned programs", style: TextStyle(fontSize: 12)),
          const SizedBox(height: 16),
          Expanded(
            child: provider.isLoadingPrograms
                ? const Center(child: CircularProgressIndicator())
                : provider.programsError != null
                ? Center(child: Text(provider.programsError!))
                : provider.assignedPrograms.isEmpty
                ? const Center(
              child: Text(
                "No programs assigned to you yet.",
                style: TextStyle(color: Colors.grey),
              ),
            )
                : _ProgramSections(provider: provider),
          ),
        ],
      ),
    );
  }
}

/// Splits assigned programs into "Pending" and "Fully Scored" sections
/// based on provider.programProgress (loaded in the background right
/// after the program list itself). While progress is still loading, a
/// program is shown under Pending by default (isProgramFullyScored
/// defaults to false until its count arrives).
class _ProgramSections extends StatelessWidget {
  final JudgeProvider provider;
  const _ProgramSections({required this.provider});

  @override
  Widget build(BuildContext context) {
    final pending = <AssignedProgram>[];
    final scored = <AssignedProgram>[];
    for (final program in provider.assignedPrograms) {
      (provider.isProgramFullyScored(program) ? scored : pending).add(program);
    }

    return ListView(
      children: [
        if (pending.isNotEmpty) ...[
          _ProgramSectionHeader(
            label: 'Pending',
            count: pending.length,
            color: const Color(0xff5667F6),
            bg: const Color(0xffE7E9FE),
            showLoader: provider.isLoadingProgramProgress,
          ),
          const SizedBox(height: 8),
          for (final program in pending) _ProgramCard(program: program, provider: provider),
          const SizedBox(height: 8),
        ],
        if (scored.isNotEmpty) ...[
          _ProgramSectionHeader(
            label: 'Fully Scored',
            count: scored.length,
            color: const Color(0xff2E7D32),
            bg: const Color(0xffE8F5EC),
          ),
          const SizedBox(height: 8),
          for (final program in scored) _ProgramCard(program: program, provider: provider),
        ],
      ],
    );
  }
}

class _ProgramSectionHeader extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final Color bg;
  final bool showLoader;

  const _ProgramSectionHeader({
    required this.label,
    required this.count,
    required this.color,
    required this.bg,
    this.showLoader = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xff374151))),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
          child: Text(
            '$count',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
          ),
        ),
        if (showLoader) ...[
          const SizedBox(width: 8),
          const SizedBox(
            height: 10,
            width: 10,
            child: CircularProgressIndicator(strokeWidth: 1.5),
          ),
        ],
        const SizedBox(width: 8),
        Expanded(child: Divider(color: Colors.grey.withValues(alpha: 0.3))),
      ],
    );
  }
}

class _ProgramCard extends StatelessWidget {
  final AssignedProgram program;
  final JudgeProvider provider;
  const _ProgramCard({required this.program, required this.provider});

  @override
  Widget build(BuildContext context) {
    final progress = provider.programProgress[program.id];
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        title: Text(program.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (program.category.isNotEmpty)
                _tag(program.category, const Color(0xFFE0E7FF)),
              if (program.studentCategory.isNotEmpty)
                _tag(program.studentCategory, const Color(0xFFFEF9C3)),
              if (program.stageType.isNotEmpty)
                _tag(program.stageType, const Color(0xFFFFEDD5)),
              if (program.isGeneral)
                _tag('General', const Color(0xFFDCFCE7)),
              if (progress != null)
                _tag('${progress.scored}/${progress.total} scored',
                    progress.isComplete
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFF3F4F6)),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => provider.openProgram(program),
      ),
    );
  }

  Widget _tag(String text, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}

/// Step 2: registered students under the open program, with score entry.
class _ScoringView extends StatelessWidget {
  final JudgeProvider provider;
  const _ScoringView({required this.provider});

  @override
  Widget build(BuildContext context) {
    final program = provider.selectedProgram!;
    final judgeId = context.read<ProfileProvider>().entityId ?? '';
    // General programs collapse multiple same-team registrations down to
    // one visible card each — see JudgeProvider.displayedRegistrations.
    final visibleRegistrations = provider.displayedRegistrations;
    final total = visibleRegistrations.length;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () async {
                  final canLeave = await JudgePanelPage.confirmLeave(context, provider);
                  if (canLeave) provider.closeProgram();
                },
                icon: const Icon(Icons.arrow_back),
              ),
              Expanded(
                child: Text(program.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Progress card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Progress",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    Text(
                      "${provider.submittedCount} / $total Scored",
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xff5667F6), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xffE6E6E6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: total == 0 ? 0 : provider.submittedCount / total,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF667EEA), Color(0xffFF6B6B)],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: provider.isLoadingRegistrations
                ? const Center(child: CircularProgressIndicator())
                : provider.registrationsError != null
                ? Center(child: Text(provider.registrationsError!))
                : visibleRegistrations.isEmpty
                ? const Center(
              child: Text("No students registered for this program.",
                  style: TextStyle(color: Colors.grey)),
            )
                : _RegistrationSections(
              registrations: visibleRegistrations,
              provider: provider,
              judgeId: judgeId,
            ),
          ),
        ],
      ),
    );
  }
}

/// Splits registrations into "To Score" and "Scored" sections so scored
/// students are visually separated instead of mixed into one long list.
class _RegistrationSections extends StatelessWidget {
  final List<RegistrationScore> registrations;
  final JudgeProvider provider;
  final String judgeId;

  const _RegistrationSections({
    required this.registrations,
    required this.provider,
    required this.judgeId,
  });

  @override
  Widget build(BuildContext context) {
    final pending = registrations.where((r) => r.status == "Assigned").toList();
    final scored = registrations.where((r) => r.status != "Assigned").toList();

    return ListView(
      children: [
        if (pending.isNotEmpty) ...[
          _SectionHeader(
            label: 'To Score',
            count: pending.length,
            color: const Color(0xff5667F6),
            bg: const Color(0xffE7E9FE),
          ),
          const SizedBox(height: 8),
          for (final reg in pending) _buildCard(context, reg),
          const SizedBox(height: 8),
        ],
        if (scored.isNotEmpty) ...[
          _SectionHeader(
            label: 'Scored',
            count: scored.length,
            color: const Color(0xff2E7D32),
            bg: const Color(0xffE8F5EC),
          ),
          const SizedBox(height: 8),
          for (final reg in scored) _buildCard(context, reg),
        ],
      ],
    );
  }

  Widget _buildCard(BuildContext context, RegistrationScore reg) {
    return _StudentScoreCard(
      reg: reg,
      saving: provider.isSavingScore(reg.id),
      onScoreChanged: (v) => provider.updateScoreInput(reg, v),
      onSubmit: () async {
        final error = await provider.saveScore(judgeId, reg);
        if (context.mounted && error != null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(error)));
        }
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final Color bg;

  const _SectionHeader({
    required this.label,
    required this.count,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xff374151))),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
          child: Text(
            '$count',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Divider(color: Colors.grey.withValues(alpha: 0.3))),
      ],
    );
  }
}

class _StudentScoreCard extends StatelessWidget {
  final RegistrationScore reg;
  final bool saving;
  final ValueChanged<String> onScoreChanged;
  final VoidCallback onSubmit;

  const _StudentScoreCard({
    required this.reg,
    required this.saving,
    required this.onScoreChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final isScored = reg.status != "Assigned";

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      child: Text(reg.codeLetter ?? reg.studentName,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 2),
                    Align(
                      child: Text("Reg #${reg.registerNumber}",
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ),
                  ],
                ),
              ),
              if (reg.judged)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xffE8F5EC),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Grade ${reg.grade} • ${reg.totalPoint} pts${reg.rank != null ? ' • Rank ${reg.rank}' : ''}",
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xff2E7D32), fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isScored ? const Color(0xffEFEFEF) : const Color(0xffF3F3F3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: reg.controller,
                    enabled: !isScored,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      hintText: 'Score / 100',
                    ),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isScored ? const Color(0xff9CA3AF) : const Color(0xff374151),
                    ),
                    onChanged: onScoreChanged,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // ---- Scored state shows a green pill with a check icon and
              // disables the field above. Unscored state keeps the original
              // Save button (same onSubmit -> saveScore() path). ----
              SizedBox(
                height: 44,
                child: isScored
                    ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xffE8F5EC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xff2E7D32).withValues(alpha: 0.25)),
                  ),
                  alignment: Alignment.center,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 16, color: Color(0xff2E7D32)),
                      SizedBox(width: 6),
                      Text('Scored',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xff2E7D32))),
                    ],
                  ),
                )
                    : ElevatedButton.icon(
                  onPressed: saving ? null : onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff0B132B),
                    disabledBackgroundColor: const Color(0xffB0B7C3),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                  ),
                  icon: saving
                      ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : const Icon(Icons.check_circle_outline, size: 16),
                  label: Text(
                    saving ? '' : 'Save Score',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}