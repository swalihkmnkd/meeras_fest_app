import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:meeras_fest_app/registration/registration_model.dart';

import '../admin/models/categoryModel.dart';
import '../admin/models/programModel.dart';
import '../admin/models/studentModel.dart';

class RegistrationProvider extends ChangeNotifier {
  final _studentsCollection = FirebaseFirestore.instance.collection('STUDENTS');
  final _programsCollection = FirebaseFirestore.instance.collection('PROGRAMS');
  final _registrationsCollection = FirebaseFirestore.instance.collection('REGISTRATIONS');
  final _categoriesCollection = FirebaseFirestore.instance.collection('CATEGORIES');

  // How many programs of each PROGRAM_CATEGORY a single student may register for.
  static const Map<String, int> maxPerType = {
    'Stage': 4,
    'Non Stage': 4,
    'General': 2,
  };

  String? _teamId;
  bool isLoading = false;
  String? errorMessage;

  List<StudentModel> teamStudents = [];
  List<ProgramModel> programs = [];
  List<RegistrationModel> allRegistrations = []; // every team's registrations (capacity checks)
  List<CategoryModel> categories = [];

  List<String> get categoryNames => categories.map((c) => c.name).toList();

  // ---- Step 1: category ----
  CategoryModel? selectedCategory;

  // ---- Step 2: program ----
  ProgramModel? selectedProgram;

  // ---- Step 3: multi-select students ----
  final Set<String> selectedStudentIds = {};

  // Staged entries, written to Firestore on "Submit All".
  final List<RegistrationModel> pendingEntries = [];
  bool isSubmitting = false;

  // ---- List screen state ----
  String selectedFilter = 'All';
  int expandedIndex = -1;

  Future<void> loadForTeam(String teamId) async {
    if (_teamId == teamId && programs.isNotEmpty) return; // already loaded
    _teamId = teamId;
    isLoading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _studentsCollection.where('TEAM_ID', isEqualTo: teamId).get(),
        _programsCollection.get(),
        _registrationsCollection.get(),
        _categoriesCollection.get(),
      ]);
      teamStudents = results[0].docs.map((d) => StudentModel.fromDoc(d)).toList();
      programs = results[1].docs.map((d) => ProgramModel.fromDoc(d)).toList();
      allRegistrations = results[2].docs.map((d) => RegistrationModel.fromDoc(d)).toList();
      categories = results[3].docs.map((d) => CategoryModel.fromDoc(d)).toList();
      errorMessage = null;
    } catch (e) {
      errorMessage = 'Failed to load registration data: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _refreshRegistrations() async {
    final snap = await _registrationsCollection.get();
    allRegistrations = snap.docs.map((d) => RegistrationModel.fromDoc(d)).toList();
  }

  // ---- Derived: pick lists ----

  int _totalCountForProgram(String programId) {
    final fromServer = allRegistrations.where((r) => r.programId == programId).length;
    final fromPending = pendingEntries.where((r) => r.programId == programId).length;
    return fromServer + fromPending;
  }

  int remainingSlots(ProgramModel p) => p.totalParticipants - _totalCountForProgram(p.id);

  int _studentTypeCount(String studentId, String programCategory) {
    final fromServer = allRegistrations
        .where((r) => r.studentId == studentId && r.programCategory == programCategory)
        .length;
    final fromPending = pendingEntries
        .where((r) => r.studentId == studentId && r.programCategory == programCategory)
        .length;
    return fromServer + fromPending;
  }

  bool _alreadyHas(String studentId, String programId) {
    return allRegistrations.any((r) => r.studentId == studentId && r.programId == programId) ||
        pendingEntries.any((r) => r.studentId == studentId && r.programId == programId);
  }

  /// Programs matching the selected category's GENDER that still have open slots.
  /// Programs matching the selected category's GENDER that still have open slots.
  List<ProgramModel> get programsForSelectedCategory {
    final category = selectedCategory;
    if (category == null) return [];
    return programs
        .where((p) => p.studentCategory == category.gender && remainingSlots(p) > 0)
        .toList();
  }


  List<StudentModel> get eligibleStudents {
    final program = selectedProgram;
    final category = selectedCategory;
    if (program == null || category == null) return [];
    final cap = maxPerType[program.programCategory] ?? 0;
    //
    final classFrom = int.tryParse(category.classFrom);
    final classTo = int.tryParse(category.classTo);
    if (classFrom == null || classTo == null) return []; // malformed category range

    return teamStudents.where((s) {

      print(s.gender);
      print(category.gender);
      if (!_genderMatches(s.gender, category.gender)) return false;

      final studentClassNum = int.tryParse(s.studentClass);
      if (studentClassNum == null) return false; // malformed CLASS value, skip

      if (studentClassNum < classFrom || studentClassNum > classTo) return false;

      if (_alreadyHas(s.id, program.id)) return false;
      if (_studentTypeCount(s.id, program.programCategory) >= cap) return false;
      return true;
    }).toList();
  }
  /// Normalizes a student's GENDER ("Male"/"Female") against a category or
  /// program's STUDENT_CATEGORY/GENDER value ("Boys"/"Girls"/"Mixed").
  bool  _genderMatches(String studentGender, String categoryGender) {
    if (categoryGender == 'Mixed') return true;
    final normalizedStudent = studentGender == 'Male'
        ? 'Boys'
        : studentGender == 'Female'
        ? 'Girls'
        : studentGender; // fallback, in case it's already "Boys"/"Girls"
    return normalizedStudent == categoryGender;
  }
  // ---- Selection setters ----

  void setCategory(CategoryModel? category) {
    selectedCategory = category;
    selectedProgram = null;
    selectedStudentIds.clear();
    notifyListeners();
  }

  void setProgram(ProgramModel? program) {
    selectedProgram = program;
    selectedStudentIds.clear();
    notifyListeners();
  }

  void toggleStudentSelection(String studentId) {
    if (selectedStudentIds.contains(studentId)) {
      selectedStudentIds.remove(studentId);
    } else {
      selectedStudentIds.add(studentId);
    }
    notifyListeners();
  }

  /// Stages the currently checked students against the selected program.
  String? addSelectedToList() {
    final program = selectedProgram;
    final category = selectedCategory;
    if (category == null) return 'Please select a category';
    if (program == null) return 'Please select a program';
    if (selectedStudentIds.isEmpty) return 'Please select at least one student';

    final remaining = remainingSlots(program);
    if (selectedStudentIds.length > remaining) {
      return 'Only $remaining slot(s) left in ${program.programName}';
    }

    final cap = maxPerType[program.programCategory] ?? 0;
    for (final id in selectedStudentIds) {
      final student = teamStudents.firstWhere((s) => s.id == id);
      if (_alreadyHas(id, program.id)) {
        return '${student.name} is already registered for this program';
      }
      if (_studentTypeCount(id, program.programCategory) >= cap) {
        return '${student.name} has reached the ${program.programCategory} limit';
      }
    }

    for (final id in selectedStudentIds) {
      final student = teamStudents.firstWhere((s) => s.id == id);
      pendingEntries.add(RegistrationModel(
        id: '',
        studentId: student.id,
        studentName: student.name,
        teamId: _teamId ?? '',
        programId: program.id,
        programName: program.programName,
        studentCategory: student.gender,
        programCategory: program.programCategory,
      ));
    }

    selectedStudentIds.clear();
    selectedProgram = null;
    notifyListeners();
    return null;
  }

  void removePending(int index) {
    pendingEntries.removeAt(index);
    notifyListeners();
  }

  Future<String?> submitAll() async {
    if (pendingEntries.isEmpty) return 'No registrations to submit';
    isSubmitting = true;
    notifyListeners();
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final entry in pendingEntries) {
        final ref = _registrationsCollection.doc();
        batch.set(ref, entry.toMap());
      }
      await batch.commit();
      pendingEntries.clear();
      await _refreshRegistrations();
      return null;
    } catch (e) {
      return 'Failed to submit registrations: $e';
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  // ---- List screen ----

  List<String> get filterOptions => const ['All', 'Stage', 'Non Stage', 'General'];

  List<RegistrationModel> get teamRegistrations {
    final list = allRegistrations.where((r) => r.teamId == _teamId).toList();
    list.sort((a, b) {
      final at = a.createdAt?.millisecondsSinceEpoch ?? 0;
      final bt = b.createdAt?.millisecondsSinceEpoch ?? 0;
      return bt.compareTo(at);
    });
    return list;
  }

  List<RegistrationModel> get filteredTeamRegistrations {
    if (selectedFilter == 'All') return teamRegistrations;
    return teamRegistrations.where((r) => r.programCategory == selectedFilter).toList();
  }

  void setFilter(String value) {
    selectedFilter = value;
    expandedIndex = -1;
    notifyListeners();
  }

  void toggleExpand(int index) {
    expandedIndex = expandedIndex == index ? -1 : index;
    notifyListeners();
  }

  bool isExpanded(int index) => expandedIndex == index;
}