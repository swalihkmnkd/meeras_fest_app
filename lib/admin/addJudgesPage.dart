import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'adminScreen.dart';
import 'adminWidgets.dart';
import 'assign_program_to_judge_screen.dart';

class AddJudgesPage extends StatefulWidget {
  const AddJudgesPage({super.key});

  @override
  State<AddJudgesPage> createState() => _AddJudgesPageState();
}

class _AddJudgesPageState extends State<AddJudgesPage> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Judge name is required')));
      return;
    }
    if (_usernameCtrl.text.trim().isEmpty || _passwordCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Username and password are required')));
      return;
    }

    setState(() => _saving = true);
    try {
      // Lowercase 'judges' — matches the actual collection name in Firestore
      // and the ProfileProvider Judge-login query.
      final docRef = await FirebaseFirestore.instance.collection('judges').add({
        'NAME': _nameCtrl.text.trim(),
        'PHONE': _phoneCtrl.text.trim(),
        'EMAIL': _emailCtrl.text.trim(),
        'USER_NAME': _usernameCtrl.text.trim(),
        'PASSWORD': _passwordCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Judge added successfully')));

      final judgeId = docRef.id;
      final judgeName = _nameCtrl.text.trim();

      _nameCtrl.clear();
      _phoneCtrl.clear();
      _emailCtrl.clear();
      _usernameCtrl.clear();
      _passwordCtrl.clear();

      if (!mounted) return;
      // Jump straight into assigning programs to the judge just created.
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AssignProgramsToJudgePage(
            judgeId: judgeId,
            judgeName: judgeName,
          ),
        ),
      );
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
        title: const Text('Add Judgesfsdf'),
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
              AdminFormField(
                controller: _nameCtrl,
                label: 'Judge Name',
                icon: Icons.person_rounded,
              ),
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
                controller: _usernameCtrl,
                label: 'Username',
                icon: Icons.account_circle_rounded,
              ),
              const SizedBox(height: 14),
              AdminFormField(
                controller: _passwordCtrl,
                label: 'Password',
                icon: Icons.lock_rounded,
                obscureText: true,
              ),
              const SizedBox(height: 22),
              AdminSubmitButton(
                label: 'Save & Assign Programs',
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