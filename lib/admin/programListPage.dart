import 'package:flutter/material.dart';
import 'package:meeras_fest_app/admin/score_calculator_page.dart';
import 'package:provider/provider.dart';

import 'adminWidgets.dart';
import 'programFormPage.dart';
import 'providers/programProvider.dart';

class ProgramsListPage extends StatelessWidget {
  const ProgramsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProgramProvider>(
      builder: (context, provider, child) {
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
          body: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : provider.errorMessage != null
              ? Center(child: Text(provider.errorMessage!))
              : provider.programs.isEmpty
              ? const Center(child: Text('No programs yet'))
              : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: provider.programs.length,
            itemBuilder: (context, i) {
              final p = provider.programs[i];
              return Card(
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
        );
      },
    );
  }
}