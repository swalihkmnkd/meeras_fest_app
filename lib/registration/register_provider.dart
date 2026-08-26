import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:meeras_fest_app/registration/registration_model.dart';

import '../admin/models/categoryModel.dart';
import '../admin/models/programModel.dart';
import '../admin/models/studentModel.dart';

class RegistrationProvider extends ChangeNotifier {
  final _teamsCollection = FirebaseFirestore.instance.collection('TEAMS');
  final _studentsCollection = FirebaseFirestore.instance.collection('STUDENTS');
  final _programsCollection = FirebaseFirestore.instance.collection('PROGRAMS');
  final _registrationsCollection = FirebaseFirestore.instance.collection('REGISTRATIONS');
  final _categoriesCollection = FirebaseFirestore.instance.collection('CATEGORIES');

  // How many programs of each Stage/Non-Stage type a single student may register for.
  static const Map<String, int> maxPerType = {
    'Stage': 4,
    'Non Stage': 4,
  };

  String? _teamId;

  /// The requesting team's own category — 'Boys' / 'Girls' / 'Mixed'.
  /// Passed in from ProfileProvider by the screen. Adjust the field name
  /// on the caller side if your ProfileProvider names it differently.
  String? teamCategory;

  bool isLoading = false;
  String? errorMessage;
  void clearRegistrationSelections() {
    selectedCategory = null;
    selectedStageType = null;
    selectedProgram = null;
    selectedStudentIds.clear();

    notifyListeners();
  }
  List<StudentModel> teamStudents = [];
  List<ProgramModel> programs = [];
  List<RegistrationModel> allRegistrations = []; // every team's registrations (capacity checks)
  List<CategoryModel> categories = [];

  List<String> get categoryNames => categories.map((c) => c.name).toList();

  /// Static list for the Stage / Non Stage dropdown.
  List<String> get stageTypeOptions => const ['Stage', 'Non Stage'];

  /// Categories that match this team's own category. 'Mixed' categories are
  /// always shown since they're open to any team.
  List<CategoryModel> get categoriesForTeam {
    final tc = teamCategory;
    if (tc == null || tc.isEmpty) return categories;
    return categories.where((c) => c.gender == tc || c.gender == 'Mixed').toList();
  }

  // ---- Step 1: category ----
  CategoryModel? selectedCategory;

  // ---- Step 2: Stage / Non Stage ----
  String? selectedStageType;

  // ---- Step 3: program ----
  ProgramModel? selectedProgram;

  // ---- Step 4: multi-select students ----
  final Set<String> selectedStudentIds = {};

  // Staged entries, written to Firestore on "Submit All".
  final List<RegistrationModel> pendingEntries = [];
  bool isSubmitting = false;

  // ---- List screen state ----
  String selectedFilter = 'All';
  int expandedIndex = -1;

  Future<void> loadForTeam(String teamId, [String? teamCategory]) async {
    // Keep team category fresh even on a cache hit.
    this.teamCategory = teamCategory;

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
      print(teamId);
      for(var i in teamStudents){
        print(i.name);
      }
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
    final fromServer = allRegistrations
        .where((r) =>
    r.programId == programId &&
        r.teamId == _teamId)
        .length;

    final fromPending = pendingEntries
        .where((r) =>
    r.programId == programId &&
        r.teamId == _teamId)
        .length;

    return fromServer + fromPending;
  }

  int remainingSlots(ProgramModel p) => p.totalParticipants - _totalCountForProgram(p.id);

  int _studentTypeCount(String studentId, String stageType) {
    final fromServer = allRegistrations
        .where((r) => r.studentId == studentId && r.stageType == stageType)
        .length;
    final fromPending = pendingEntries
        .where((r) => r.studentId == studentId && r.stageType == stageType)
        .length;
    return fromServer + fromPending;
  }

  bool _alreadyHas(String studentId, String programId) {
    return allRegistrations.any((r) => r.studentId == studentId && r.programId == programId) ||
        pendingEntries.any((r) => r.studentId == studentId && r.programId == programId);
  }

  /// Programs matching the selected category's GENDER, the selected
  /// category's NAME, and the selected Stage/Non Stage type — that still
  /// have open slots.
  List<ProgramModel> get programsForSelectedCategory {
    final category = selectedCategory;
    final stageType = selectedStageType;
    if (category == null || stageType == null) return [];
    return programs
        .where((p) =>
    p.studentCategory == category.gender &&
        p.programCategory == category.name &&
        p.stageType == stageType &&
        remainingSlots(p) > 0)
        .toList();
  }

  List<StudentModel> get eligibleStudents {
    final program = selectedProgram;
    final category = selectedCategory;
    if (program == null || category == null) return [];

    final cap = maxPerType[program.stageType] ?? 0;
    print('DEBUG stageType="${program.stageType}" cap=$cap classFrom=${category.classFrom} classTo=${category.classTo}');
    final classFrom = int.tryParse(category.classFrom);
    final classTo = int.tryParse(category.classTo);
    if (classFrom == null || classTo == null) return []; // malformed category range

    return teamStudents.where((s) {
      final genderOk = _genderMatches(s.gender, category.gender);
      final classNum = int.tryParse(s.studentClass);
      final classOk = classNum != null && classNum >= classFrom && classNum <= classTo;
      print('DEBUG student=${s.name} gender=${s.gender} genderOk=$genderOk studentClass=${s.studentClass} classOk=$classOk');
      if (!genderOk) return false;
      if (!_genderMatches(s.gender, category.gender)) return false;

      final studentClassNum = int.tryParse(s.studentClass);
      if (studentClassNum == null) return false; // malformed CLASS value, skip
      if (studentClassNum < classFrom || studentClassNum > classTo) return false;

      if (_alreadyHas(s.id, program.id)) return false;
      if (_studentTypeCount(s.id, program.stageType ?? '') >= cap) return false;
      return true;
    }).toList();
  }

  /// Normalizes a student's GENDER ("Male"/"Female") against a category or
  /// program's STUDENT_CATEGORY/GENDER value ("Boys"/"Girls"/"Mixed").
  bool _genderMatches(String studentGender, String categoryGender) {
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
    selectedStageType = null;
    selectedProgram = null;
    selectedStudentIds.clear();
    notifyListeners();
  }

  void setStageType(String? stageType) {
    selectedStageType = stageType;
    selectedProgram = null;
    selectedStudentIds.clear();
    notifyListeners();
  }

  void setProgram(ProgramModel? program) {
    selectedProgram = program;
    selectedStudentIds.clear();
    notifyListeners();
  }

  /// Toggles a student's selection. Returns false (and does nothing) if the
  /// student isn't currently selected and the program's remaining slot count
  /// has already been reached by the current selection.
  bool toggleStudentSelection(String studentId) {
    if (selectedStudentIds.contains(studentId)) {
      selectedStudentIds.remove(studentId);
      notifyListeners();
      return true;
    }

    final program = selectedProgram;
    if (program != null) {
      final remaining = remainingSlots(program);
      if (selectedStudentIds.length >= remaining) {
        return false; // slot cap reached, refuse selection
      }
    }

    selectedStudentIds.add(studentId);
    notifyListeners();
    return true;
  }

  /// Stages the currently checked students against the selected program.
  String? addSelectedToList() {
    final program = selectedProgram;
    final category = selectedCategory;
    if (category == null) return 'Please select a category';
    if (selectedStageType == null) return 'Please select Stage / Non Stage';
    if (program == null) return 'Please select a program';
    if (selectedStudentIds.isEmpty) return 'Please select at least one student';

    final remaining = remainingSlots(program);
    if (selectedStudentIds.length > remaining) {
      return 'Only $remaining slot(s) left in ${program.programName}';
    }

    final stageType = program.stageType ?? '';
    final cap = maxPerType[stageType] ?? 0;
    for (final id in selectedStudentIds) {
      final student = teamStudents.firstWhere((s) => s.id == id);
      if (_alreadyHas(id, program.id)) {
        return '${student.name} is already registered for this program';
      }
      if (_studentTypeCount(id, stageType) >= cap) {
        return '${student.name} has reached the $stageType limit';
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
        programCategory: program.programCategory, // actual category name, e.g. "Senior"
        stageType: stageType,
        isGeneral: program.isGeneral,   // ⬅️ NEW
        registrationId: student.registerNumber??'',
        registrationNumber: student.registerNumber??'',
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
    if (pendingEntries.isEmpty) {
      return 'No registrations to submit';
    }

    isSubmitting = true;
    notifyListeners();

    try {
      final batch = FirebaseFirestore.instance.batch();

      // Get all students belonging to this team.
      final studentsSnapshot = await _studentsCollection
          .where('TEAM_ID', isEqualTo: _teamId)
          .get();

      // Student ID -> REGISTER_NUMBER
      final studentRegisterNumbers = <String, String>{};

      for (final doc in studentsSnapshot.docs) {
        final data = doc.data();

        final registerNumber =
        data['REGISTER_NUMBER']?.toString().trim();

        if (registerNumber != null && registerNumber.isNotEmpty) {
          studentRegisterNumbers[doc.id] = registerNumber;
        }
      }

      for (final entry in pendingEntries) {
        final registerNumber =
        studentRegisterNumbers[entry.studentId];

        if (registerNumber == null || registerNumber.isEmpty) {
          return '${entry.studentName} does not have a REGISTER_NUMBER';
        }

        // Unique document ID for student + program.
        final documentId =
            '${registerNumber}_${entry.programId}';

        final ref =
        _registrationsCollection.doc(documentId);

        final data = entry.toMap();

        data['REGISTRATION_ID'] = registerNumber;
        data['REGISTER_NUMBER'] = registerNumber;
        data['TEAM_ID'] = _teamId;
        data['createdAt'] = FieldValue.serverTimestamp();

        batch.set(ref, data);
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

  List<String> get filterOptions => const ['All', 'Stage', 'Non Stage'];

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
    return teamRegistrations.where((r) => r.stageType == selectedFilter).toList();
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