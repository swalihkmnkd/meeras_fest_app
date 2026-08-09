import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'adminScreen.dart';
import 'adminWidgets.dart';

class AddProgramsPage extends StatefulWidget {
  const AddProgramsPage({super.key});

  @override
  State<AddProgramsPage> createState() => _AddProgramsPageState();
}

class _AddProgramsPageState extends State<AddProgramsPage> {
  final _nameCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Program name is required')));
      return;
    }
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('programs').add({
        'name': _nameCtrl.text.trim(),
        'category': _categoryCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Program added successfully')));
      _nameCtrl.clear();
      _categoryCtrl.clear();
      _descCtrl.clear();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to add program: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Add Program'),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AdminCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminFormField(controller: _nameCtrl, label: 'Program Name', icon: Icons.event_note_rounded),
              const SizedBox(height: 14),
              AdminFormField(controller: _categoryCtrl, label: 'Category', icon: Icons.category_rounded),
              const SizedBox(height: 14),
              AdminFormField(
                controller: _descCtrl,
                label: 'Description',
                icon: Icons.description_rounded,
                maxLines: 3,
              ),
              const SizedBox(height: 22),
              AdminSubmitButton(
                label: 'Save Program',
                loading: _saving,
                onPressed: _save,
                color: const Color(0xFF10B981),
              ),
            ],
          ),
        ),
      ),
    );
  }
}