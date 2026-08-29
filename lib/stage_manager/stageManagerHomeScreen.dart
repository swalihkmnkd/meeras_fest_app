import 'package:flutter/material.dart';
import 'package:meeras_fest_app/stage_manager/programRegistrationScreen.dart';
import 'package:meeras_fest_app/stage_manager/stageManagerProvider.dart';
import 'package:provider/provider.dart';


class StageManagerHomeScreen extends StatefulWidget {
  const StageManagerHomeScreen({super.key});

  @override
  State<StageManagerHomeScreen> createState() => _StageManagerHomeScreenState();
}

class _StageManagerHomeScreenState extends State<StageManagerHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StageManagerProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffFFF9F5),
      appBar: AppBar(
        title: const Text('Assignments'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<StageManagerProvider>(
        builder: (context, pro, child) {
          if (pro.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (pro.loadError != null) {
            return Center(child: Text(pro.loadError!));
          }

          final programs = pro.programSummaries;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _filterDropdown(
                      label: 'Team Category',
                      value: pro.teamCategoryFilter,
                      options: pro.teamCategoryOptions,
                      onChanged: pro.setTeamCategoryFilter,
                    ),
                    _filterDropdown(
                      label: 'Program Category',
                      value: pro.programCategoryFilter,
                      options: pro.programCategoryOptions,
                      onChanged: pro.setProgramCategoryFilter,
                    ),
                    _filterDropdown(
                      label: 'Student Category',
                      value: pro.studentCategoryFilter,
                      options: pro.studentCategoryOptions,
                      onChanged: pro.setStudentCategoryFilter,
                    ),
                    _filterDropdown(
                      label: 'Stage Type',
                      value: pro.stageTypeFilter,
                      options: pro.stageTypeOptions,
                      onChanged: pro.setStageTypeFilter,
                    ),
                    TextButton(
                      onPressed: pro.clearFilters,
                      child: const Text('Clear filters'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: programs.isEmpty
                    ? const Center(child: Text('No programs match these filters'))
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  itemCount: programs.length,
                  itemBuilder: (context, i) {
                    final p = programs[i];
                    final done = p.total > 0 && p.assigned == p.total;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProgramRegistrationsScreen(
                              programId: p.programId,
                              programName: p.programName,
                            ),
                          ),
                        ),
                        title: Text(p.programName,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                            '${p.programCategory} • ${p.stageType}${p.isGeneral ? ' • General' : ''}'),
                        trailing: Chip(
                          label: Text('${p.assigned}/${p.total}'),
                          backgroundColor:
                          done ? const Color(0xffD1FAE5) : const Color(0xffFEF3C7),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _filterDropdown({
    required String label,
    required String? value,
    required List<String> options,
    required void Function(String?) onChanged,
  }) {
    return SizedBox(
      width: 170,
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        items: [
          const DropdownMenuItem(value: null, child: Text('All')),
          ...options.map((o) => DropdownMenuItem(value: o, child: Text(o))),
        ],
        onChanged: onChanged,
      ),
    );
  }
}