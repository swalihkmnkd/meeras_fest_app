import 'package:flutter/material.dart';
import 'package:meeras_fest_app/admin/score_calculator_page.dart';
import 'package:provider/provider.dart';

import 'adminWidgets.dart';
import 'programFormPage.dart';
import 'providers/programProvider.dart';

class ProgramsListPage extends StatefulWidget {
  const ProgramsListPage({super.key});

  @override
  State<ProgramsListPage> createState() => _ProgramsListPageState();
}

class _ProgramsListPageState extends State<ProgramsListPage> {
  // Local list filters — independent of the provider's form-editing state,
  // so browsing the list never disturbs the create/edit form fields.
  //
  // NOTE: ProgramModel has no separate "student category" field — the
  // existing `studentCategory` field (Boys/Girls/Mixed) already serves as
  // "Team Category", so one filter covers both. If a distinct per-student
  // field gets added to the model later, split this into two.
  String? _teamCategoryFilter; // studentCategory
  String? _programCategoryFilter; // programCategory
  String? _stageCategoryFilter; // stageType

  @override
  Widget build(BuildContext context) {
    return Consumer<ProgramProvider>(
      builder: (context, provider, child) {
        final teamCategoryOptions = provider.programs
            .map((p) => p.studentCategory)
            .where((c) => c.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
        final programCategoryOptions = provider.programs
            .map((p) => p.programCategory)
            .where((c) => c.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
        final stageCategoryOptions = provider.programs
            .map((p) => p.stageType ?? '')
            .where((c) => c.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

        final filteredPrograms = provider.programs.where((p) {
          if (_teamCategoryFilter != null &&
              p.studentCategory != _teamCategoryFilter) {
            return false;
          }
          if (_programCategoryFilter != null &&
              p.programCategory != _programCategoryFilter) {
            return false;
          }
          if (_stageCategoryFilter != null &&
              (p.stageType ?? '') != _stageCategoryFilter) {
            return false;
          }
          return true;
        }).toList();

        final hasActiveFilters = _teamCategoryFilter != null ||
            _programCategoryFilter != null ||
            _stageCategoryFilter != null;

        return Scaffold(
          backgroundColor: const Color(0xFFF3F4F6),
          appBar: AppBar(
            title: const Text('Programs'),
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.calculate_rounded),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ScoreCalculatorPage()),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: const Color(0xFF10B981),
            onPressed: () {
              provider.startCreate();
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProgramFormPage()));
            },
            child: const Icon(Icons.add, color: Colors.white),
          ),
          body: Column(
            children: [
              // ---------- Filter row ----------
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _FilterPill(
                      label: 'Team/Student',
                      value: _teamCategoryFilter,
                      options: teamCategoryOptions,
                      onChanged: (v) => setState(() => _teamCategoryFilter = v),
                    ),
                    _FilterPill(
                      label: 'Program',
                      value: _programCategoryFilter,
                      options: programCategoryOptions,
                      onChanged: (v) => setState(() => _programCategoryFilter = v),
                    ),
                    _FilterPill(
                      label: 'Stage',
                      value: _stageCategoryFilter,
                      options: stageCategoryOptions,
                      onChanged: (v) => setState(() => _stageCategoryFilter = v),
                    ),
                    if (hasActiveFilters)
                      GestureDetector(
                        onTap: () => setState(() {
                          _teamCategoryFilter = null;
                          _programCategoryFilter = null;
                          _stageCategoryFilter = null;
                        }),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                          child: Text(
                            'Clear',
                            style: TextStyle(
                              color: Color(0xFFEF4444),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ---------- List ----------
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : provider.errorMessage != null
                    ? Center(child: Text(provider.errorMessage!))
                    : provider.programs.isEmpty
                    ? const Center(child: Text('No programs yet'))
                    : filteredPrograms.isEmpty
                    ? const Center(child: Text('No programs match these filters'))
                    : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredPrograms.length,
                  itemBuilder: (context, i) {
                    final p = filteredPrograms[i];
                    return Card(
                      key: ValueKey(p.id),
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text(p.programName,
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        isThreeLine: true,
                        subtitle: Text(
                          '${p.studentCategory}  •  A≥${p.aGradeStart.toInt()} B≥${p.bGradeStart.toInt()} C≥${p.cGradeStart.toInt()}\n'
                              '1st:${p.firstScore.toInt()}  2nd:${p.secondScore.toInt()}  3rd:${p.thirdScore.toInt()}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Color(0xFF10B981)),
                              onPressed: () {
                                provider.startEdit(p);
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => const ProgramFormPage()));
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Color(0xFFEF4444)),
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Delete Program'),
                                    content: Text('Delete "${p.programName}"?'),
                                    actions: [
                                      TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('Cancel')),
                                      TextButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text('Delete')),
                                    ],
                                  ),
                                );
                                if (confirmed == true) {
                                  final error = await provider.deleteProgram(p.id);
                                  if (error != null && context.mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(content: Text(error)));
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
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

/// Compact, flat dropdown filter pill.
class _FilterPill extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  const _FilterPill({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = value != null;
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFECFDF5) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? const Color(0xFF10B981) : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Center(
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String?>(
            value: value,
            isDense: true,
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 14),
            hint: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xff4B5563))),
            items: [
              DropdownMenuItem<String?>(value: null, child: Text('All $label')),
              ...options.map((o) => DropdownMenuItem<String?>(value: o, child: Text(o))),
            ],
            onChanged: onChanged,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isActive ? const Color(0xFF10B981) : const Color(0xff4B5563),
            ),
          ),
        ),
      ),
    );
  }
}