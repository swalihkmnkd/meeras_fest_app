import 'package:flutter/material.dart';
import 'package:meeras_fest_app/admin/providers/teamsProvider.dart';
import 'package:meeras_fest_app/admin/transformPage.dart';
import 'package:provider/provider.dart';

import 'adminWidgets.dart';
import 'models/teamModel.dart';

class TeamsListPage extends StatelessWidget {
  const TeamsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TeamProvider()..fetchTeams(),
      child: const _TeamsListView(),
    );
  }
}

class _TeamsListView extends StatelessWidget {
  const _TeamsListView();

  Future<void> _openForm(BuildContext context, {TeamModel? team}) async {
    final provider = context.read<TeamProvider>();
    if (team == null) {
      provider.startCreate();
    } else {
      provider.startEdit(team);
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: const TeamsFormPage(),
        ),
      ),
    );
    provider.fetchTeams();
  }

  Future<void> _delete(BuildContext context, TeamModel team) async {
    final confirmed = await showAdminDeleteConfirm(context, itemName: team.name);
    if (!confirmed) return;
    final provider = context.read<TeamProvider>();
    final error = await provider.deleteTeam(team.id);
    if (!context.mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      provider.fetchTeams();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Teams'),
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF3B82F6),
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('New Team'),
      ),
      body: Consumer<TeamProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.errorMessage != null) {
            return Center(child: Text(provider.errorMessage!));
          }
          if (provider.teams.isEmpty) {
            return const AdminEmptyState(
              icon: Icons.groups_rounded,
              message: 'No teams yet. Tap "New Team" to create one.',
            );
          }
          return RefreshIndicator(
            onRefresh: provider.fetchTeams,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: provider.teams.length,
              itemBuilder: (context, index) {
                final team = provider.teams[index];
                return AdminListTile(
                  title: team.name,
                  subtitle: '${team.category} • Leader: ${team.leaderName}',
                  leadingIcon: Icons.groups_rounded,
                  leadingColor: const Color(0xFF3B82F6),
                  onEdit: () => _openForm(context, team: team),
                  onDelete: () => _delete(context, team),
                );
              },
            ),
          );
        },
      ),
    );
  }
}