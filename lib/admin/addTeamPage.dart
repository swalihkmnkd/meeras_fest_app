import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'adminScreen.dart';
import 'adminWidgets.dart';
import 'models/teamModel.dart';

const List<String> teamCategoryOptions = ['Boys', 'Girls', 'Mixed'];

class AddTeamsPage extends StatefulWidget {
  const AddTeamsPage({super.key});

  @override
  State<AddTeamsPage> createState() => _AddTeamsPageState();
}

class _AddTeamsPageState extends State<AddTeamsPage> {
  final _nameCtrl = TextEditingController();
  final _teamIdCtrl = TextEditingController();
  final _leaderCtrl = TextEditingController();
  final _assistantLeaderCtrl = TextEditingController();
  final _userNameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String? _selectedColor;
  String? _selectedCategory;
  bool _saving = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _teamIdCtrl.dispose();
    _leaderCtrl.dispose();
    _assistantLeaderCtrl.dispose();
    _userNameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _showSnack('Team name is required');
      return;
    }
    if (_teamIdCtrl.text.trim().isEmpty) {
      _showSnack('Team ID is required');
      return;
    }
    if (_leaderCtrl.text.trim().isEmpty) {
      _showSnack('Team leader is required');
      return;
    }
    if (_selectedColor == null) {
      _showSnack('Please select a team color');
      return;
    }
    if (_selectedCategory == null) {
      _showSnack('Please select a team category');
      return;
    }
    if (_userNameCtrl.text.trim().isEmpty) {
      _showSnack('User name is required');
      return;
    }
    if (_passwordCtrl.text.trim().isEmpty) {
      _showSnack('Password is required');
      return;
    }

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('TEAMS').add({
        'TEAM_NAME': _nameCtrl.text.trim(),
        'TEAM_ID': _teamIdCtrl.text.trim(),
        'TEAM_LEADER': _leaderCtrl.text.trim(),
        'ASSISTANT_LEADER': _assistantLeaderCtrl.text.trim(),
        'TEAM_CATEGORY': _selectedCategory,
        'TEAM_COLOR': _selectedColor,
        'USER_NAME': _userNameCtrl.text.trim(),
        'PASSWORD': _passwordCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      _showSnack('Team added successfully');
      _nameCtrl.clear();
      _teamIdCtrl.clear();
      _leaderCtrl.clear();
      _assistantLeaderCtrl.clear();
      _userNameCtrl.clear();
      _passwordCtrl.clear();
      setState(() {
        _selectedColor = null;
        _selectedCategory = null;
      });
    } catch (e) {
      _showSnack('Failed to add team: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
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
              AdminFormField(controller: _teamIdCtrl, label: 'Team ID', icon: Icons.badge_rounded),
              const SizedBox(height: 14),
              AdminFormField(controller: _leaderCtrl, label: 'Team Leader', icon: Icons.star_rounded),
              const SizedBox(height: 14),
              AdminFormField(controller: _assistantLeaderCtrl, label: 'Assistant Leader', icon: Icons.star_half_rounded),
              const SizedBox(height: 14),

              // Team category dropdown
              Text('Team Category', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    hint: const Text('Select a categoryss'),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    items: teamCategoryOptions.map((opt) {
                      return DropdownMenuItem(
                        value: opt,
                        child: Row(
                          children: [
                            const Icon(Icons.category_rounded, size: 18, color: Colors.grey),
                            const SizedBox(width: 10),
                            Text(opt),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedCategory = value),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Team color dropdown
              Text('Team Color', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedColor,
                    isExpanded: true,
                    hint: const Text('Select a color'),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    items: teamColorOptions.map((opt) {
                      return DropdownMenuItem(
                        value: opt.name,
                        child: Row(
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(color: opt.color, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 10),
                            Text(opt.name),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedColor = value),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              AdminFormField(controller: _userNameCtrl, label: 'User Name', icon: Icons.person_rounded),
              const SizedBox(height: 14),

              // Password field with visibility toggle
              TextField(
                controller: _passwordCtrl,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
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