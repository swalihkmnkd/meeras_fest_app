import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../judges/judge_provider.dart';
import 'adminWidgets.dart';

import 'judgesFormPage.dart';
import 'models/judgesModel.dart';

class JudgesListPage extends StatelessWidget {
  const JudgesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => JudgeProvider()
        ..fetchJudges()
        ..fetchProgramsCache(),
      child: const _JudgesListView(),
    );
  }
}

class _JudgesListView extends StatelessWidget {
  const _JudgesListView();

  Future<void> _openForm(BuildContext context, {JudgeModel? judge}) async {
    final provider = context.read<JudgeProvider>();
    if (judge == null) {
      provider.startCreate();
    } else {
      provider.startEdit(judge);
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: const JudgesFormPage(),
        ),
      ),
    );
    provider.fetchJudges();
    provider.fetchProgramsCache();
  }

  Future<void> _delete(BuildContext context, JudgeModel judge) async {
    final confirmed = await showAdminDeleteConfirm(context, itemName: judge.name);
    if (!confirmed) return;
    final provider = context.read<JudgeProvider>();
    final error = await provider.deleteJudge(judge.id);
    if (!context.mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
    // deleteJudge already updates local state on success — no refetch needed.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Judges'),
        backgroundColor: const Color(0xFFEF4444),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFEF4444),
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('New Judge'),
      ),
      body: Consumer<JudgeProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.errorMessage != null) {
            return Center(child: Text(provider.errorMessage!));
          }
          if (provider.judges.isEmpty) {
            return const AdminEmptyState(
              icon: Icons.gavel_rounded,
              message: 'No judges yet. Tap "New Judge" to create one.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              await Future.wait([provider.fetchJudges(), provider.fetchProgramsCache()]);
            },
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: provider.judges.length,
              itemBuilder: (context, index) {
                final judge = provider.judges[index];
                final assignedPrograms = provider.programsForJudge(judge.id);

                final subtitleParts = [
                  if (judge.phone.isNotEmpty) judge.phone,
                  assignedPrograms.isEmpty
                      ? 'No programs assigned'
                      : 'Assigned: ${assignedPrograms.map((p) => p.programName).join(', ')}',
                ];
                return AdminListTile(
                  title: judge.name,
                  subtitle: subtitleParts.join(' • '),
                  leadingIcon: Icons.gavel_rounded,
                  leadingColor: const Color(0xFFEF4444),
                  onEdit: () => _openForm(context, judge: judge),
                  onDelete: () => _delete(context, judge),
                );
              },
            ),
          );
        },
      ),
    );
  }
}