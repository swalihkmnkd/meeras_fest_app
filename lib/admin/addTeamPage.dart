import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'adminScreen.dart';
import 'adminWidgets.dart';

class AddTeamsPage extends StatefulWidget {
  const AddTeamsPage({super.key});

  @override
  State<AddTeamsPage> createState() => _AddTeamsPageState();
}

class _AddTeamsPageState extends State<AddTeamsPage> {
  final _nameCtrl = TextEditingController();
  final _classCtrl = TextEditingController();
  final _leaderCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _classCtrl.dispose();
    _leaderCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Team name is required')));
      return;
    }
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('teams').add({
        'name': _nameCtrl.text.trim(),
        'class': _classCtrl.text.trim(),
        'teamLeader': _leaderCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Team added successfully')));
      _nameCtrl.clear();
      _classCtrl.clear();
      _leaderCtrl.clear();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to add team: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Add Team'),
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AdminCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminFormField(controller: _nameCtrl, label: 'Team Name', icon: Icons.groups_rounded),
              const SizedBox(height: 14),
              AdminFormField(controller: _classCtrl, label: 'Class', icon: Icons.class_rounded),
              const SizedBox(height: 14),
              AdminFormField(controller: _leaderCtrl, label: 'Team Leader', icon: Icons.star_rounded),
              const SizedBox(height: 22),
              AdminSubmitButton(
                label: 'Save Team',
                loading: _saving,
                onPressed: _save,
                color: const Color(0xFF3B82F6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}