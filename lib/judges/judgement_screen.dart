import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../profile/profileProvider.dart';
import 'judge_provider.dart';

class JudgePanelPage extends StatelessWidget {
  const JudgePanelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => JudgeProvider()
        ..fetchAssignedPrograms(context.read<ProfileProvider>().entityId ?? ''),
      child: Consumer<JudgeProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            backgroundColor: const Color(0xffF7F7F7),
            body: SafeArea(
              child: provider.selectedProgram == null
                  ? _ProgramListView(provider: provider)
                  : _ScoringView(provider: provider),
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
                : ListView.builder(
              itemCount: provider.assignedPrograms.length,
              itemBuilder: (context, index) {
                final program = provider.assignedPrograms[index];
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
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    title: Text(program.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(
                        spacing: 6,
                        children: [
                          if (program.category.isNotEmpty)
                            _tag(program.category, const Color(0xFFE0E7FF)),
                          if (program.studentCategory.isNotEmpty)
                            _tag(program.studentCategory, const Color(0xFFFEF9C3)),
                          if (program.stageType.isNotEmpty)
                            _tag(program.stageType, const Color(0xFFFFEDD5)),
                        ],
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => provider.openProgram(program),
                  ),
                );
              },
            ),
          ),
        ],
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
    final total = provider.registrations.length;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: provider.closeProgram,
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
                : provider.registrations.isEmpty
                ? const Center(
              child: Text("No students registered for this program.",
                  style: TextStyle(color: Colors.grey)),
            )
                : ListView.builder(
              itemCount: provider.registrations.length,
              itemBuilder: (context, index) {
                final reg = provider.registrations[index];
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
              },
            ),
          ),
        ],
      ),
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
                    Text(reg.studentName,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text("Reg #${reg.registerNumber} • Team ${reg.teamId}",
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
                    color: const Color(0xffF3F3F3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: reg.controller,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      hintText: 'Score / 100',
                    ),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xff374151)),
                    onChanged: onScoreChanged,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: saving ? null : onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff0B132B),
                    disabledBackgroundColor: const Color(0xffB0B7C3),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                  ),
                  child: saving
                      ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : Text(reg.judged ? "Update" : "Submit",
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}