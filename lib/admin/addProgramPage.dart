import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'adminScreen.dart';
import 'adminWidgets.dart';

/// ── Adjust these to match your actual Firestore schema ──
const String kCategoriesCollection = 'CATEGORIES';
const String kCategoryNameField = 'name';
const String kCategoryTeamCategoryField = 'teamCategory';
const String kCategoryGenderField = 'gender';

/// Static option lists — change these if you pull them from Firestore too.
const List<String> kTeamCategoryOptions = ['Sub Junior', 'Junior', 'Senior', 'Super Senior'];
const List<String> kGenderOptions = ['Male', 'Female'];

class AddProgramsPage extends StatefulWidget {
  const AddProgramsPage({super.key});

  @override
  State<AddProgramsPage> createState() => _AddProgramsPageState();
}

class _AddProgramsPageState extends State<AddProgramsPage> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _saving = false;

  // ── New: Team Category / Gender / dynamic Category ──
  String? _selectedTeamCategory;
  String? _selectedGender;
  String? _selectedCategory;

  bool _loadingCategories = false;
  List<String> _categoryOptions = [];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  /// Fetches Category options from Firebase filtered by the selected
  /// Team Category AND Gender. Docs with gender == "Both" are included
  /// for either gender selection.
  Future<void> _fetchCategories() async {
    if (_selectedTeamCategory == null || _selectedGender == null) return;

    setState(() {
      _loadingCategories = true;
      _categoryOptions = [];
      _selectedCategory = null;
    });

    try {
      final snap = await FirebaseFirestore.instance
          .collection(kCategoriesCollection)
          .where(kCategoryTeamCategoryField, isEqualTo: _selectedTeamCategory)
          .where(kCategoryGenderField, whereIn: [_selectedGender, 'Both'])
          .get();

      final names = snap.docs
          .map((d) => (d.data()[kCategoryNameField] ?? '').toString())
          .where((name) => name.isNotEmpty)
          .toList();

      if (!mounted) return;
      setState(() {
        _categoryOptions = names;
        _loadingCategories = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingCategories = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to load categories: $e')));
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Program name is required')));
      return;
    }
    if (_selectedTeamCategory == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please select a Team Category')));
      return;
    }
    if (_selectedGender == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please select a Gender')));
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please select a Category')));
      return;
    }

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('programs').add({
        'name': _nameCtrl.text.trim(),
        'teamCategory': _selectedTeamCategory,
        'gender': _selectedGender,
        'category': _selectedCategory,
        'description': _descCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Program added successfully')));
      _nameCtrl.clear();
      _descCtrl.clear();
      setState(() {
        _selectedTeamCategory = null;
        _selectedGender = null;
        _selectedCategory = null;
        _categoryOptions = [];
      });
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
              AdminFormField(
                controller: _nameCtrl,
                label: 'Program Name',
                icon: Icons.event_note_rounded,
              ),
              const SizedBox(height: 14),

              // ── Team Category dropdown ──
              _buildDropdownField(
                label: 'Team Category',
                icon: Icons.groups_rounded,
                value: _selectedTeamCategory,
                items: kTeamCategoryOptions,
                onChanged: (val) {
                  setState(() => _selectedTeamCategory = val);
                  _fetchCategories();
                },
              ),
              const SizedBox(height: 14),

              // ── Gender dropdown ──
              _buildDropdownField(
                label: 'Gender',
                icon: Icons.wc_rounded,
                value: _selectedGender,
                items: kGenderOptions,
                onChanged: (val) {
                  setState(() => _selectedGender = val);
                  _fetchCategories();
                },
              ),
              const SizedBox(height: 14),

              // ── Category dropdown, populated from Firebase ──
              _buildDropdownField(
                label: 'Category',
                icon: Icons.category_rounded,
                value: _selectedCategory,
                items: _categoryOptions,
                enabled: _selectedTeamCategory != null && _selectedGender != null,
                loading: _loadingCategories,
                hintOverride: _selectedTeamCategory == null || _selectedGender == null
                    ? 'Select Team Category & Gender first'
                    : (_categoryOptions.isEmpty && !_loadingCategories
                    ? 'No categories found'
                    : null),
                onChanged: (val) => setState(() => _selectedCategory = val),
              ),
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

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool enabled = true,
    bool loading = false,
    String? hintOverride,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
        color: enabled ? Colors.white : Colors.grey.shade100,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          value: (value != null && items.contains(value)) ? value : null,
          isExpanded: true,
          icon: loading
              ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Icon(Icons.keyboard_arrow_down_rounded),
          decoration: InputDecoration(
            border: InputBorder.none,
            icon: Icon(icon, color: const Color(0xFF10B981)),
            labelText: label,
            hintText: hintOverride,
          ),
          items: items
              .map((item) => DropdownMenuItem<String>(
            value: item,
            child: Text(item, overflow: TextOverflow.ellipsis),
          ))
              .toList(),
          onChanged: enabled && !loading ? onChanged : null,
        ),
      ),
    );
  }
}