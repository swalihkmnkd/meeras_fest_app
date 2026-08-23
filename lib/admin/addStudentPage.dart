import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'adminWidgets.dart';
import 'models/studentModel.dart';
import 'providers/studentProvider.dart';

class AddStudentsPage extends StatelessWidget {
  const AddStudentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StudentProvider()..fetchAllStudents(),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: const Color(0xFFF3F4F6),
          appBar: AppBar(
            title: const Text('Students'),
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            elevation: 0,
            bottom: const TabBar(
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(text: 'Add Students'),
                Tab(text: 'Student List'),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              _AddStudentsView(),
              _StudentListView(),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// TAB 1: ADD -- toggle between Excel upload and individual add
// =====================================================================

class _AddStudentsView extends StatefulWidget {
  const _AddStudentsView();

  @override
  State<_AddStudentsView> createState() => _AddStudentsViewState();
}

class _AddStudentsViewState extends State<_AddStudentsView> {
  bool _isExcelMode = true;

  Future<void> _uploadExcel(BuildContext context) async {
    final provider = context.read<StudentProvider>();
    final message = await provider.uploadToFirebase();
    if (!context.mounted) return;
    if (message != null) {
      await showAdminSuccessDialog(context, message: message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StudentProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildModeToggle(),
              const SizedBox(height: 16),
              if (_isExcelMode)
                ..._buildExcelSection(context, provider)
              else
                const _IndividualStudentForm(),
              if (provider.errorMessage != null) ...[
                const SizedBox(height: 12),
                _buildErrorBanner(context, provider.errorMessage!),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildModeToggle() {
    return AdminCard(
      child: Row(
        children: [
          Expanded(
            child: _ModeButton(
              label: 'Upload Excel',
              icon: Icons.upload_file_rounded,
              selected: _isExcelMode,
              onTap: () => setState(() => _isExcelMode = true),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ModeButton(
              label: 'Add Individually',
              icon: Icons.person_add_alt_1_rounded,
              selected: !_isExcelMode,
              onTap: () => setState(() => _isExcelMode = false),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildExcelSection(BuildContext context, StudentProvider provider) {
    return [
      AdminCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.info_outline_rounded, color: Color(0xFF6366F1)),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Upload an Excel file (.xlsx) with column headers: '
                    'Name, Class, Gender, Roll Number. A "Division" column '
                    'is optional.',
                style: TextStyle(color: Color(0xff374151), fontSize: 13, height: 1.4),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      AdminCard(
        child: DottedBorderBox(
          onTap: (provider.isParsing || provider.isUploading)
              ? null
              : () => context.read<StudentProvider>().pickAndParseFile(),
          fileName: provider.fileName,
        ),
      ),
      if (provider.isParsing) ...[
        const SizedBox(height: 24),
        const Center(child: CircularProgressIndicator()),
      ],
      if (provider.students.isNotEmpty) ...[
        const SizedBox(height: 20),
        _buildPreviewCard(provider),
        const SizedBox(height: 20),
        _buildUploadButton(context, provider),
      ],
    ];
  }

  Widget _buildPreviewCard(StudentProvider provider) {
    return AdminCard(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.table_rows_rounded, color: Color(0xFF6366F1), size: 18),
                const SizedBox(width: 6),
                Text(
                  'Preview (${provider.students.length} students)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xff1F2937)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 260,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF3F4F6)),
                  columns: const [
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Class')),
                    DataColumn(label: Text('Division')),
                    DataColumn(label: Text('Gender')),
                    DataColumn(label: Text('Roll No.')),
                  ],
                  rows: provider.students
                      .map((s) => DataRow(cells: [
                    DataCell(Text(s.name)),
                    DataCell(Text(s.studentClass)),
                    DataCell(Text(s.division)),
                    DataCell(Text(s.gender)),
                    DataCell(Text(s.rollNumber)),
                  ]))
                      .toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButton(BuildContext context, StudentProvider provider) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: provider.isUploading ? null : () => _uploadExcel(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          elevation: 6,
          shadowColor: const Color(0xFF6366F1).withOpacity(0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: provider.isUploading
            ? Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
                value: provider.uploadProgress > 0 ? provider.uploadProgress : null,
              ),
            ),
            const SizedBox(width: 12),
            Text('Uploading... ${(100 * provider.uploadProgress).toStringAsFixed(0)}%'),
          ],
        )
            : const Text('Upload', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 13)),
          ),
          InkWell(
            onTap: () => context.read<StudentProvider>().clearError(),
            child: const Icon(Icons.close, color: Color(0xFFB91C1C), size: 18),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF6366F1) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? Colors.white : const Color(0xFF6B7280), size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// Shared individual-student form (used for both Add and Edit)
// =====================================================================

class _IndividualStudentForm extends StatefulWidget {
  final StudentModel? existing; // null => add mode, non-null => edit mode

  const _IndividualStudentForm({this.existing});

  @override
  State<_IndividualStudentForm> createState() => _IndividualStudentFormState();
}

class _IndividualStudentFormState extends State<_IndividualStudentForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCt;
  late final TextEditingController _classCt;
  late final TextEditingController _divisionCt;
  late final TextEditingController _rollCt;
  late String _gender;
  late String _teamId;
  late String _teamName;
  late String _teamColor;
  late String _registrationNumber;

  // The exact strings used by the dropdown items below. Firestore data may
  // have been written with different casing (e.g. "FEMALE", "female"), and
  // DropdownButtonFormField requires the current value to match one of its
  // items EXACTLY or it throws an assertion error. So every gender value
  // that enters this form -- whether from an existing student or a default --
  // is passed through _normalizeGender first.
  // Single source of truth for valid gender values. Change this list
  // (e.g. to ['MALE', 'FEMALE']) and every default below follows
  // automatically via _genderOptions.first -- never hardcode a literal
  // like 'Male' elsewhere, or it can drift out of sync with this list
  // and retrigger the DropdownButton "exactly one match" assertion.
  static const _genderOptions = ['Male', 'Female'];

  static String _normalizeGender(String? raw) {
    if (raw == null || raw.trim().isEmpty) return _genderOptions.first;
    final lower = raw.trim().toLowerCase();
    return _genderOptions.firstWhere(
          (option) => option.toLowerCase() == lower,
      orElse: () => _genderOptions.first,
    );
  }

  @override
  void initState() {
    super.initState();
    final s = widget.existing;
    _nameCt = TextEditingController(text: s?.name ?? '');
    _classCt = TextEditingController(text: s?.studentClass ?? '');
    _divisionCt = TextEditingController(text: s?.division ?? '');
    _rollCt = TextEditingController(text: s?.rollNumber ?? '');
    _gender = _normalizeGender(s?.gender);
    _teamId=s?.teamId??'';
    _teamName=s?.teamName??'';
    _teamColor=s?.teamColor??'';
    _registrationNumber=s?.registerNumber??'';
  }

  @override
  void dispose() {
    _nameCt.dispose();
    _classCt.dispose();
    _divisionCt.dispose();
    _rollCt.dispose();
    super.dispose();
  }

  Future<void> _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<StudentProvider>();
    final student = StudentModel(
      name: _nameCt.text.trim(),
      studentClass: _classCt.text.trim(),
      division: _divisionCt.text.trim(),
      gender: _gender,
      rollNumber: _rollCt.text.trim(), teamId: _teamId, teamName:_teamName, teamColor: _teamColor,
      registerNumber: _registrationNumber,
    );

    // Capture the Navigator BEFORE any pop happens below. In edit mode this
    // form lives inside a Dialog route; once that route is popped, this
    // form's own `context` is deactivated and can no longer be used to look
    // up ancestors (e.g. inside showDialog/Navigator.pop) -- that was the
    // cause of the "Looking up a deactivated widget's ancestor is unsafe"
    // crash when tapping OK on the success dialog. `navigator.context` is
    // the Navigator widget's own context, which lives ABOVE the dialog
    // route and stays mounted after we pop just that route, so it's safe
    // to reuse afterwards.
    final navigator = Navigator.of(context);
    final safeContext = navigator.context;

    // NOTE: updateStudent now takes the full original StudentRow (not just
    // the roll number), because the Firestore doc ID is composite
    // (class_division_gender_roll) -- the provider needs the original
    // values to know which document to delete/move if any of those
    // fields changed.
    final message = widget.existing == null
        ? await provider.addSingleStudent(student)
        : await provider.updateStudent(widget.existing!, student);

    if (!safeContext.mounted) return;

    if (message != null) {
      final isEdit = widget.existing != null;
      if (isEdit) {
        navigator.pop(); // close edit dialog via the captured navigator
      } else {
        _formKey.currentState!.reset();
        _nameCt.clear();
        _classCt.clear();
        _divisionCt.clear();
        _rollCt.clear();
        _teamId='';
        _teamName='';
        _teamColor='';
        setState(() => _gender = _genderOptions.first);
      }

      if (!safeContext.mounted) return;
      // Use safeContext (the stable Navigator context) rather than the
      // form's own `context`, which may already be deactivated at this
      // point in edit mode.
      await showAdminSuccessDialog(safeContext, message: message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Consumer<StudentProvider>(
      builder: (context, provider, child) {
        return AdminCard(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isEdit)
                  const Text(
                    'Add a single student',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xff1F2937)),
                  ),
                if (!isEdit) const SizedBox(height: 14),
                TextFormField(
                  controller: _nameCt,
                  decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        controller: _classCt,
                        decoration: const InputDecoration(labelText: 'Class', border: OutlineInputBorder()),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Class is required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _divisionCt,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                          UpperCaseTextFormatter(),
                        ],
                        decoration: const InputDecoration(labelText: 'Division', border: OutlineInputBorder()),
                        // Division is optional -- no validator.
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  // Guaranteed to be one of _genderOptions via _normalizeGender,
                  // so this always matches exactly one DropdownMenuItem.
                  initialValue: _gender,
                  decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
                  items: _genderOptions
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) => setState(() => _gender = v ?? _genderOptions.first),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  controller: _rollCt,
                  decoration: const InputDecoration(labelText: 'Roll Number', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Roll number is required' : null,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: provider.isSavingStudent ? null : () => _submit(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: provider.isSavingStudent
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                        : Text(isEdit ? 'Save Changes' : 'Add Student',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
      composing: TextRange.empty,
    );
  }
}

// =====================================================================
// TAB 2: STUDENT LIST -- with filter (class / division / gender), edit, delete
// =====================================================================

class _StudentListView extends StatefulWidget {
  const _StudentListView();

  @override
  State<_StudentListView> createState() => _StudentListViewState();
}

class _StudentListViewState extends State<_StudentListView> {
  String _query = '';

  // null / 'All' means "no filter applied" for that field.
  String? _classFilter;
  String? _divisionFilter;
  String? _genderFilter;

  static const String _allOption = 'All';

  void _openEditDialog(BuildContext context, StudentModel student) {
    final provider = context.read<StudentProvider>();
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: ChangeNotifierProvider.value(
          value: provider,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _IndividualStudentForm(existing: student),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, StudentModel student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete student?'),
        content: Text('Remove ${student.name} (Roll ${student.rollNumber}) permanently?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final provider = context.read<StudentProvider>();
    final message = await provider.deleteStudent(student);
    if (!context.mounted) return;
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  /// Builds the distinct, sorted set of values for a given field across all
  /// students, prefixed with the "All" option. Blank values are excluded
  /// from the option list (there's nothing meaningful to filter by there).
  List<String> _optionsFor(List<StudentModel> all, String Function(StudentModel) selector) {
    final values = all.map(selector).where((v) => v.trim().isNotEmpty).toSet().toList()
      ..sort();
    return [_allOption, ...values];
  }

  void _clearFilters() {
    setState(() {
      _classFilter = null;
      _divisionFilter = null;
      _genderFilter = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StudentProvider>(
      builder: (context, provider, child) {
        final all = provider.allStudents;

        final classOptions = _optionsFor(all, (s) => s.studentClass);
        final divisionOptions = _optionsFor(all, (s) => s.division);
        final genderOptions = _optionsFor(all, (s) => s.gender);

        final filtered = all.where((s) {
          if (_query.isNotEmpty) {
            final q = _query.toLowerCase();
            final matchesQuery = s.name.toLowerCase().contains(q) ||
                s.rollNumber.toLowerCase().contains(q) ||
                s.studentClass.toLowerCase().contains(q);
            if (!matchesQuery) return false;
          }
          if (_classFilter != null && _classFilter != _allOption && s.studentClass != _classFilter) {
            return false;
          }
          if (_divisionFilter != null && _divisionFilter != _allOption && s.division != _divisionFilter) {
            return false;
          }
          if (_genderFilter != null && _genderFilter != _allOption && s.gender != _genderFilter) {
            return false;
          }
          return true;
        }).toList();

        final hasActiveFilters = (_classFilter != null && _classFilter != _allOption) ||
            (_divisionFilter != null && _divisionFilter != _allOption) ||
            (_genderFilter != null && _genderFilter != _allOption);

        return RefreshIndicator(
          onRefresh: provider.fetchAllStudents,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by name, class or roll number',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _FilterDropdown(
                        label: 'Class',
                        value: _classFilter ?? _allOption,
                        options: classOptions,
                        onChanged: (v) => setState(() => _classFilter = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FilterDropdown(
                        label: 'Division',
                        value: _divisionFilter ?? _allOption,
                        options: divisionOptions,
                        onChanged: (v) => setState(() => _divisionFilter = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FilterDropdown(
                        label: 'Gender',
                        value: _genderFilter ?? _allOption,
                        options: genderOptions,
                        onChanged: (v) => setState(() => _genderFilter = v),
                      ),
                    ),
                  ],
                ),
              ),
              if (hasActiveFilters)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _clearFilters,
                      icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                      label: const Text('Clear filters'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF6366F1),
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Expanded(
                child: provider.isLoadingList
                    ? const Center(child: CircularProgressIndicator())
                    : filtered.isEmpty
                    ? ListView(
                  children: const [
                    SizedBox(height: 80),
                    Center(child: Text('No students found', style: TextStyle(color: Color(0xff6B7280)))),
                  ],
                )
                    : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final s = filtered[index];
                    final subtitleParts = <String>[
                      if (s.studentClass.isNotEmpty) 'Class ${s.studentClass}',
                      if (s.division.isNotEmpty) 'Div ${s.division}',
                      if (s.gender.isNotEmpty) s.gender,
                      'Roll ${s.rollNumber}',
                    ];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                            child: Text(
                              s.name.isNotEmpty ? s.name[0].toUpperCase() : '?',
                              style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xff1F2937))),
                                const SizedBox(height: 2),
                                Text(
                                  subtitleParts.join(' \u2022 '),
                                  style: const TextStyle(fontSize: 12, color: Color(0xff6B7280)),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Color(0xFF6366F1), size: 20),
                            onPressed: () => _openEditDialog(context, s),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                            onPressed: () => _confirmDelete(context, s),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Guard against a stale selection (e.g. the only student in a class was
    // deleted) so the dropdown never holds a value missing from its items.
    final safeValue = options.contains(value) ? value : options.first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: safeValue,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          style: const TextStyle(fontSize: 12, color: Color(0xff374151)),
          items: options
              .map((o) => DropdownMenuItem(
            value: o,
            child: Text(
              o == 'All' ? '$label: All' : o,
              overflow: TextOverflow.ellipsis,
            ),
          ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// A simple dashed-border tap target used for the file picker area.
class DottedBorderBox extends StatelessWidget {
  final VoidCallback? onTap;
  final String? fileName;

  const DottedBorderBox({super.key, required this.onTap, required this.fileName});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.4), width: 1.4),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF6366F1).withOpacity(0.1)),
              child: const Icon(Icons.upload_file_rounded, color: Color(0xFF6366F1), size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              fileName ?? 'Tap to select an Excel file (.xlsx)',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xff374151), fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}