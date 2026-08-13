import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'adminWidgets.dart';
import 'programFormPage.dart';
import 'models/programModel.dart';
import 'providers/programProvider.dart';

class ProgramListPage extends StatelessWidget {
  const ProgramListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProgramProvider()..fetchPrograms(),
      child: const _ProgramListView(),
    );
  }
}

class _ProgramListView extends StatelessWidget {
  const _ProgramListView();

  Future<void> _openForm(BuildContext context, {ProgramModel? program}) async {
    final provider = context.read<ProgramProvider>();
    if (program == null) {
      provider.startCreate();
    } else {
      provider.startEdit(program);
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: const ProgramFormPage(),
        ),
      ),
    );
    provider.fetchPrograms();
  }

  Future<void> _delete(BuildContext context, ProgramModel program) async {
    final confirmed = await showAdminDeleteConfirm(context, itemName: program.name);
    if (!confirmed) return;
    final provider = context.read<ProgramProvider>();
    final error = await provider.deleteProgram(program.id);
    if (!context.mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      provider.fetchPrograms();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Programs'),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF10B981),
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('New Program'),
      ),
      body: Consumer<ProgramProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.errorMessage != null) {
            return Center(child: Text(provider.errorMessage!));
          }
          if (provider.programs.isEmpty) {
            return const AdminEmptyState(
              icon: Icons.event_note_rounded,
              message: 'No programs yet. Tap "New Program" to create one.',
            );
          }
          return RefreshIndicator(
            onRefresh: provider.fetchPrograms,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: provider.programs.length,
              itemBuilder: (context, index) {
                final program = provider.programs[index];
                return AdminListTile(
                  title: program.name,
                  subtitle: '${program.category} • ${program.gender}',
                  leadingIcon: Icons.event_note_rounded,
                  leadingColor: const Color(0xFF10B981),
                  onEdit: () => _openForm(context, program: program),
                  onDelete: () => _delete(context, program),
                );
              },
            ),
          );
        },
      ),
    );
  }
}