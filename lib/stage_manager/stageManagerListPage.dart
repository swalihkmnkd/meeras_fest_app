import 'package:flutter/material.dart';
import 'package:meeras_fest_app/stage_manager/stageManagerModel.dart';
import 'package:meeras_fest_app/stage_manager/stageManagerAdminProvider.dart';
import 'package:meeras_fest_app/stage_manager/stageManagerAddPage.dart';
import 'package:provider/provider.dart';

class StageManagersListPage extends StatelessWidget {
  const StageManagersListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StageManagerAdminProvider()..fetchAll(),
      child: const _StageManagersView(),
    );
  }
}

class _StageManagersView extends StatelessWidget {
  const _StageManagersView();

  void _openAddPage(BuildContext context, {StageManagerModel? editing}) {
    // Grab the SAME provider instance that already lives above this widget.
    final prov = context.read<StageManagerAdminProvider>();
    if (editing != null) {
      prov.startEdit(editing);
    } else {
      prov.startAdd();
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        // Navigator.push mounts the new page in the app's Overlay, which
        // sits ABOVE this ChangeNotifierProvider. Re-providing the exact
        // same instance via .value keeps the Add/Edit page talking to the
        // same provider (and its controllers) as this list.
        builder: (_) => ChangeNotifierProvider.value(
          value: prov,
          child: const StageManagerAddPage(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Stage Managers', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0EA5E9),
        onPressed: () => _openAddPage(context),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Stage Manager', style: TextStyle(color: Colors.white)),
      ),
      body: Consumer<StageManagerAdminProvider>(
        builder: (context, prov, _) {
          if (prov.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (prov.errorMessage != null) {
            return Center(
              child: Text(prov.errorMessage!, style: const TextStyle(color: Color(0xFFEF4444))),
            );
          }
          if (prov.stageManagers.isEmpty) {
            return const Center(
              child: Text(
                'No Stage Managers yet.\nTap "Add Stage Manager" to create a login.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF94A3B8)),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: prov.stageManagers.length,
            itemBuilder: (context, index) {
              final manager = prov.stageManagers[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF0EA5E9).withOpacity(0.1),
                      child: const Icon(Icons.record_voice_over_rounded, color: Color(0xFF0EA5E9)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(manager.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                          const SizedBox(height: 2),
                          Text('Username: ${manager.userName}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF64748B)),
                      onPressed: () => _openAddPage(context, editing: manager),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFFEF4444)),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Remove login?'),
                            content: Text('This deletes "${manager.name}"\'s Stage Manager access.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Remove', style: TextStyle(color: Color(0xFFEF4444))),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          final error = await context.read<StageManagerAdminProvider>().delete(manager.id);
                          if (context.mounted && error != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}