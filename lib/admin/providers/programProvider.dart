import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/programModel.dart';

/// ── Adjust these to match your actual Firestore schema for categories ──
const String kCategoriesCollection = 'CATEGORIES';
const String kCategoryNameField = 'NAME';
const String kCategoryTeamCategoryField = 'GENDER'; // matches studentCategory (Boys/Girls/Mixed)

class ProgramProvider extends ChangeNotifier {
  final _collection = FirebaseFirestore.instance.collection('PROGRAMS');

  List<ProgramModel> programs = [];
  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;

  // ---- Form state ----
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController firstScoreCtrl = TextEditingController();
  final TextEditingController secondScoreCtrl = TextEditingController();
  final TextEditingController thirdScoreCtrl = TextEditingController();
  final TextEditingController aGradeCtrl = TextEditingController();
  final TextEditingController bGradeCtrl = TextEditingController();
  final TextEditingController cGradeCtrl = TextEditingController();
  final TextEditingController aGradePointCtrl = TextEditingController();
  final TextEditingController bGradePointCtrl = TextEditingController();
  final TextEditingController cGradePointCtrl = TextEditingController();
  final TextEditingController totalParticipantsCtrl = TextEditingController();
  String? studentCategory; // acts as "Team Category" / "Gender"
  String? programCategory;
  String? stageType; // "Stage" or "Non Stage"
  String? _editingId;

  // ── New: Firebase-driven Program Category options ──
  List<String> programCategoryOptions = [];
  bool isLoadingCategories = false;

  bool get isEditing => _editingId != null;

  ProgramProvider() {
    fetchPrograms();
  }

  Future<void> fetchPrograms() async {
    isLoading = true;
    notifyListeners();
    try {
      final snap = await _collection.orderBy('createdAt', descending: true).get();
      programs = snap.docs.map((d) => ProgramModel.fromDoc(d)).toList();
      errorMessage = null;
    } catch (e) {
      errorMessage = 'Failed to load programs: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Fetches Program Category options from Firebase filtered by the
  /// currently selected Team Category (studentCategory). If the current
  /// programCategory value isn't among the fetched options (e.g. stale
  /// data from before this field's format changed), it's cleared —
  /// keeping an invalid value crashes DropdownButtonFormField.
  Future<void> _loadCategoryOptions() async {
    if (studentCategory == null) {
      programCategoryOptions = [];
      programCategory = null;
      notifyListeners();
      return;
    }

    isLoadingCategories = true;
    notifyListeners();

    try {
      final snap = await FirebaseFirestore.instance
          .collection(kCategoriesCollection)
          .where(kCategoryTeamCategoryField, isEqualTo: studentCategory)
          .get();

      programCategoryOptions = snap.docs
          .map((d) => (d.data()[kCategoryNameField] ?? '').toString())
          .where((name) => name.isNotEmpty)
          .toList();

      // ✅ Always clear an invalid/stale selection — keeping a value that
      // isn't in the fetched options crashes DropdownButtonFormField.
      if (!programCategoryOptions.contains(programCategory)) {
        programCategory = null;
      }
    } catch (e) {
      errorMessage = 'Failed to load categories: $e';
      programCategoryOptions = [];
    } finally {
      isLoadingCategories = false;
      notifyListeners();
    }
  }

  void startCreate() {
    _editingId = null;
    nameCtrl.clear();
    firstScoreCtrl.clear();
    secondScoreCtrl.clear();
    thirdScoreCtrl.clear();
    aGradeCtrl.clear();
    bGradeCtrl.clear();
    cGradeCtrl.clear();
    aGradePointCtrl.clear();
    bGradePointCtrl.clear();
    cGradePointCtrl.clear();
    totalParticipantsCtrl.clear();
    studentCategory = null;
    programCategory = null;
    programCategoryOptions = [];
    stageType = null;
    notifyListeners();
  }

  void startEdit(ProgramModel program) {
    _editingId = program.id;
    nameCtrl.text = program.programName;
    firstScoreCtrl.text = program.firstScore.toStringAsFixed(0);
    secondScoreCtrl.text = program.secondScore.toStringAsFixed(0);
    thirdScoreCtrl.text = program.thirdScore.toStringAsFixed(0);
    aGradeCtrl.text = program.aGradeStart.toStringAsFixed(0);
    bGradeCtrl.text = program.bGradeStart.toStringAsFixed(0);
    cGradeCtrl.text = program.cGradeStart.toStringAsFixed(0);
    aGradePointCtrl.text = program.aGradePoint.toStringAsFixed(0);
    bGradePointCtrl.text = program.bGradePoint.toStringAsFixed(0);
    cGradePointCtrl.text = program.cGradePoint.toStringAsFixed(0);
    totalParticipantsCtrl.text = program.totalParticipants.toString();
    studentCategory = program.studentCategory;
    programCategory = program.programCategory; // tentative until options load
    // ⚠️ TODO: ProgramModel has no stageType field yet, so it can't be
    // restored here. Add `final String stageType;` to ProgramModel
    // (+ fromDoc/toMap) to make editing round-trip this value.
    stageType = program.stageType;
    notifyListeners();

    // ✅ fetch matching categories; stale/mismatched selections get cleared
    _loadCategoryOptions();
  }

  void setStudentCategory(String value) {
    studentCategory = value;
    programCategory = null; // reset — must re-select from filtered options
    notifyListeners();
    _loadCategoryOptions(); // ✅ fetch categories matching the new Team Category
  }

  void setProgramCategory(String value) {
    programCategory = value;
    notifyListeners();
  }

  void setStageType(String value) {
    stageType = value;
    notifyListeners();
  }

  double? _parseUnder100(String text) {
    final v = double.tryParse(text.trim());
    if (v == null || v < 0 || v >= 100) return null;
    return v;
  }

  double? _parsePoint(String text) {
    final v = double.tryParse(text.trim());
    if (v == null || v < 0) return null;
    return v;
  }

  int? _parseParticipantCount(String text) {
    final v = int.tryParse(text.trim());
    if (v == null || v < 0) return null;
    return v;
  }

  Future<String?> save() async {
    if (nameCtrl.text.trim().isEmpty) return 'Program name is required';
    if (studentCategory == null) return 'Please select a Team Category';
    if (programCategory == null) return 'Please select a Category';
    if (stageType == null) return 'Please select Stage / Non Stage';

    final first = _parseUnder100(firstScoreCtrl.text);
    final second = _parseUnder100(secondScoreCtrl.text);
    final third = _parseUnder100(thirdScoreCtrl.text);
    final aGrade = _parseUnder100(aGradeCtrl.text);
    final bGrade = _parseUnder100(bGradeCtrl.text);
    final cGrade = _parseUnder100(cGradeCtrl.text);

    if ([first, second, third, aGrade, bGrade, cGrade].contains(null)) {
      return 'All score fields must be numbers below 100';
    }
    if (!(aGrade! > bGrade! && bGrade > cGrade!)) {
      return 'Grade marks must satisfy A > B > C';
    }

    final aPoint = _parsePoint(aGradePointCtrl.text);
    final bPoint = _parsePoint(bGradePointCtrl.text);
    final cPoint = _parsePoint(cGradePointCtrl.text);

    if ([aPoint, bPoint, cPoint].contains(null)) {
      return 'Grade points must be valid numbers';
    }

    final totalParticipants = _parseParticipantCount(totalParticipantsCtrl.text);
    if (totalParticipants == null) return 'Total participants must be a valid number';

    isSaving = true;
    notifyListeners();
    try {
      final model = ProgramModel(
        id: _editingId ?? '',
        programName: nameCtrl.text.trim(),
        firstScore: first!,
        secondScore: second!,
        thirdScore: third!,
        aGradeStart: aGrade,
        bGradeStart: bGrade,
        cGradeStart: cGrade,
        aGradePoint: aPoint!,
        bGradePoint: bPoint!,
        cGradePoint: cPoint!,
        studentCategory: studentCategory!,
        programCategory: programCategory!,
        totalParticipants: totalParticipants,
        stageType: stageType,
      );

      // ⚠️ stageType is merged in manually since ProgramModel doesn't
      // define it yet — once you add it to the model, this can just
      // become part of model.toMap() instead.
      final data = model.toMap();

      if (_editingId == null) {
        await _collection.add(data);
      } else {
        await _collection.doc(_editingId).update(data);
      }
      await fetchPrograms();
      return null;
    } catch (e) {
      return 'Failed to save program: $e';
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<String?> deleteProgram(String id) async {
    try {
      await _collection.doc(id).delete();
      programs.removeWhere((p) => p.id == id);
      notifyListeners();
      return null;
    } catch (e) {
      return 'Failed to delete program: $e';
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    firstScoreCtrl.dispose();
    secondScoreCtrl.dispose();
    thirdScoreCtrl.dispose();
    aGradeCtrl.dispose();
    bGradeCtrl.dispose();
    cGradeCtrl.dispose();
    aGradePointCtrl.dispose();
    bGradePointCtrl.dispose();
    cGradePointCtrl.dispose();
    totalParticipantsCtrl.dispose();
    super.dispose();
  }
}