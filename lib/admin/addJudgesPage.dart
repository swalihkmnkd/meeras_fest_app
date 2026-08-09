import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'adminScreen.dart';
import 'adminWidgets.dart';

class AddJudgesPage extends StatefulWidget {
  const AddJudgesPage({super.key});

  @override
  State<AddJudgesPage> createState() => _AddJudgesPageState();
}

class _AddJudgesPageState extends State<AddJudgesPage> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Judge name is required')));
      return;
    }
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('judges').add({
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'assignedCategory': _categoryCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Judge added successfully')));
      _nameCtrl.clear();
      _phoneCtrl.clear();
      _emailCtrl.clear();
      _categoryCtrl.clear();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to add judge: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Add Judge'),
        backgroundColor: const Color(0xFFEF4444),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AdminCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminFormField(controller: _nameCtrl, label: 'Judge Name', icon: Icons.person_rounded),
              const SizedBox(height: 14),
              AdminFormField(
                controller: _phoneCtrl,
                label: 'Phone Number',
                icon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),
              AdminFormField(
                controller: _emailCtrl,
                label: 'Email',
                icon: Icons.email_rounded,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              AdminFormField(
                controller: _categoryCtrl,
                label: 'Assigned Category',
                icon: Icons.category_rounded,
              ),
              const SizedBox(height: 22),
              AdminSubmitButton(
                label: 'Save Judge',
                loading: _saving,
                onPressed: _save,
                color: const Color(0xFFEF4444),
              ),
            ],
          ),
        ),
      ),
    );
  }
}