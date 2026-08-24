import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../judges/judge_provider.dart';
import '../admin/models/programModel.dart';

class AssignProgramsToJudgePage extends StatefulWidget {
  final String judgeId;
  final String judgeName;

  const AssignProgramsToJudgePage({
    super.key,
    required this.judgeId,
    required this.judgeName,
  });

  @override
  State<AssignProgramsToJudgePage> createState() => _AssignProgramsToJudgePageState();
}

class _AssignProgramsToJudgePageState extends State<AssignProgramsToJudgePage> {
  String? _categoryFilter;
  String? _studentCategoryFilter;
  String? _stageTypeFilter;

  @override
  void initState() {
    super.initState();
    // Make sure the programs cache is loaded — this screen can be reached
    // straight after saving a new judge, before the list page's own
    // fetchProgramsCache() call has necessarily finished.
    final provider = context.read<JudgeProvider>();
    if (provider.programsById.isEmpty) {
      provider.fetchProgramsCache();
    }
  }

  Future<void> _assign(JudgeProvider provider, ProgramModel program) async {
    final error = await provider.assignProgram(widget.judgeId, program.id);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${program.programName} assigned to ${widget.judgeName}')),
      );
    }
  }

  Future<void> _unassign(JudgeProvider provider, ProgramModel program) async {
    final error = await provider.unassignProgram(widget.judgeId, program.id);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${program.programName} unassigned')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<JudgeProvider>(
      builder: (context, provider, child) {
        final assigned = provider.programsForJudge(widget.judgeId);
        final assignedIds = assigned.map((p) => p.id).toSet();

        final allPrograms = provider.programsById.values.toList();
        final categories = <String>{};
        final studentCategories = <String>{};
        final stageTypes = <String>{};
        for (final p in allPrograms) {
          if (p.programCategory.isNotEmpty) categories.add(p.programCategory);
          if (p.studentCategory.isNotEmpty) studentCategories.add(p.studentCategory);
          if ((p.stageType ?? '').isNotEmpty) stageTypes.add(p.stageType!);
        }

        final available = allPrograms.where((p) {
          if (p.isAssigned) return false; // already assigned to someone (including this judge)
          if (_categoryFilter != null && p.programCategory != _categoryFilter) return false;
          if (_studentCategoryFilter != null && p.studentCategory != _studentCategoryFilter) return false;
          if (_stageTypeFilter != null && p.stageType != _stageTypeFilter) return false;
          return true;
        }).toList()
          ..sort((a, b) => a.programName.compareTo(b.programName));

        return Scaffold(
          backgroundColor: const Color(0xFFF3F4F6),
          appBar: AppBar(
            title: Text('Programs — ${widget.judgeName}'),
            backgroundColor: const Color(0xFFEF4444),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: provider.isLoadingProgramsCache && provider.programsById.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              Text(
                'Assigned (${assigned.length})',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xff1F2937)),
              ),
              const SizedBox(height: 10),
              if (assigned.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No programs assigned yet',
                      style: TextStyle(color: Color(0xff9CA3AF), fontSize: 13)),
                )
              else
                ...assigned.map((p) => _ProgramTile(
                  program: p,
                  trailing: TextButton(
                    onPressed: () => _unassign(provider, p),
                    child: const Text('Unassign', style: TextStyle(color: Colors.red)),
                  ),
                )),
              const SizedBox(height: 24),
              const Text(
                'Available programs',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xff1F2937)),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FilterDropdown(
                    label: 'Category',
                    value: _categoryFilter,
                    options: categories.toList()..sort(),
                    onChanged: (v) => setState(() => _categoryFilter = v),
                  ),
                  _FilterDropdown(
                    label: 'Team Category',
                    value: _studentCategoryFilter,
                    options: studentCategories.toList()..sort(),
                    onChanged: (v) => setState(() => _studentCategoryFilter = v),
                  ),
                  _FilterDropdown(
                    label: 'Stage Type',
                    value: _stageTypeFilter,
                    options: stageTypes.toList()..sort(),
                    onChanged: (v) => setState(() => _stageTypeFilter = v),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (available.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text('No unassigned programs match these filters',
                        style: TextStyle(color: Color(0xff9CA3AF))),
                  ),
                )
              else
                ...available.map((p) => _ProgramTile(
                  program: p,
                  trailing: ElevatedButton(
                    onPressed: () => _assign(provider, p),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
                    child: const Text('Assign'),
                  ),
                )),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProgramTile extends StatelessWidget {
  final ProgramModel program;
  final Widget trailing;

  const _ProgramTile({required this.program, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(program.programName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xff1F2937))),
                const SizedBox(height: 3),
                Text(
                  '${program.programCategory} • ${program.studentCategory} • ${program.stageType ?? '-'}',
                  style: const TextStyle(fontSize: 11, color: Color(0xff6B7280)),
                ),
              ],
            ),
          ),
          trailing,
        ],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          hint: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xff6B7280))),
          items: [
            const DropdownMenuItem<String?>(value: null, child: Text('All')),
            ...options.map((o) => DropdownMenuItem<String?>(value: o, child: Text(o))),
          ],
          onChanged: onChanged,
          style: const TextStyle(fontSize: 12, color: Color(0xff1F2937)),
        ),
      ),
    );
  }
}