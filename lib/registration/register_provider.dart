import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:meeras_fest_app/registration/registration_model.dart';

import '../admin/models/categoryModel.dart';
import '../admin/models/programModel.dart';
import '../admin/models/studentModel.dart';

/// Groups a student's registrations for the "Student wise" list view:
/// the student appears once, with their programs bucketed into Stage /
/// Non Stage / General underneath.
class StudentRegistrationGroup {
  final String studentId;
  final String studentName;
  final String registrationNumber;
  final String? photoUrl;
  final List<RegistrationModel> stagePrograms;
  final List<RegistrationModel> nonStagePrograms;
  final List<RegistrationModel> generalPrograms;

  StudentRegistrationGroup({
    required this.studentId,
    required this.studentName,
    required this.registrationNumber,
    required this.photoUrl,
    required this.stagePrograms,
    required this.nonStagePrograms,
    required this.generalPrograms,
  });

  int get totalPrograms =>
      stagePrograms.length + nonStagePrograms.length + generalPrograms.length;
}

/// Groups registrations for the "Program wise" list view: the program
/// appears once, with every registered student + registration id listed
/// underneath.
class ProgramRegistrationGroup {
  final String programId;
  final String programName;
  final String programCategory;
  final String stageType;
  final bool isGeneral;
  final List<RegistrationModel> registrations;

  ProgramRegistrationGroup({
    required this.programId,
    required this.programName,
    required this.programCategory,
    required this.stageType,
    required this.isGeneral,
    required this.registrations,
  });
}

enum RegistrationViewMode { student, program }

class RegistrationProvider extends ChangeNotifier {
  final _teamsCollection = FirebaseFirestore.instance.collection('TEAMS');
  final _studentsCollection = FirebaseFirestore.instance.collection('STUDENTS');
  final _programsCollection = FirebaseFirestore.instance.collection('PROGRAMS');
  final _registrationsCollection = FirebaseFirestore.instance.collection('REGISTRATIONS');
  final _categoriesCollection = FirebaseFirestore.instance.collection('CATEGORIES');
  final _settingsDoc =
  FirebaseFirestore.instance.collection('SETTINGS').doc('REGISTRATION_LIMITS');
  final _storage = FirebaseStorage.instance;

  static const int _photoMaxDimension = 800; // px, longest side
  static const String _photoStorageFolder = 'student_photos';

  // ⬅️ CHANGED: no longer hardcoded — loaded from Firestore in loadForTeam(),
  // editable by the admin via RegistrationSettingsProvider. These are the
  // fallback values used until that load completes (or if the doc is missing).
  int stageLimit = 4;
  int nonStageLimit = 4;

  int _limitFor(String stageType) => stageType == 'Stage' ? stageLimit : nonStageLimit;

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

  /// Stage-type quick filter: 'All' / 'Stage' / 'Non Stage' / 'General'.
  String selectedFilter = 'All';

  /// Program-category filter (e.g. 'Senior', 'Junior' …), 'All' = no filter.
  String selectedCategoryFilter = 'All';

  /// Student/team gender filter ('Boys' / 'Girls' / 'Mixed'), 'All' = no filter.
  String selectedGenderFilter = 'All';

  /// Student wise (grouped by student, programs bucketed underneath) vs
  /// Program wise (grouped by program, students listed underneath).
  RegistrationViewMode viewMode = RegistrationViewMode.student;

  int expandedIndex = -1;

  /// Per-student upload progress (0.0–1.0) while a photo is being uploaded,
  /// so the UI can show a spinner/progress ring on that student's avatar.
  final Map<String, double> photoUploadProgress = {};

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
        _settingsDoc.get(), // ⬅️ NEW: admin-configured Stage/Non Stage limits
      ]);
      teamStudents = (results[0] as QuerySnapshot<Map<String, dynamic>>)
          .docs
          .map((d) => StudentModel.fromDoc(d))
          .toList();
      programs = (results[1] as QuerySnapshot<Map<String, dynamic>>)
          .docs
          .map((d) => ProgramModel.fromDoc(d))
          .toList();
      allRegistrations = (results[2] as QuerySnapshot<Map<String, dynamic>>)
          .docs
          .map((d) => RegistrationModel.fromDoc(d))
          .toList();
      categories = (results[3] as QuerySnapshot<Map<String, dynamic>>)
          .docs
          .map((d) => CategoryModel.fromDoc(d))
          .toList();

      // ⬅️ NEW: pull the admin-set limits, falling back to the defaults
      // above if the settings doc doesn't exist yet.
      final settingsData =
      (results[4] as DocumentSnapshot<Map<String, dynamic>>).data();
      if (settingsData != null) {
        stageLimit = (settingsData['STAGE_LIMIT'] as num?)?.toInt() ?? stageLimit;
        nonStageLimit = (settingsData['NON_STAGE_LIMIT'] as num?)?.toInt() ?? nonStageLimit;
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

  /// Count of a student's existing registrations of [stageType], **excluding
  /// any that are IS_GENERAL** — General programs are exempt from the
  /// Stage/Non-Stage cap entirely, so they never count toward it.
  int _studentTypeCount(String studentId, String stageType) {
    final fromServer = allRegistrations
        .where((r) => r.studentId == studentId && r.stageType == stageType && !r.isGeneral)
        .length;
    final fromPending = pendingEntries
        .where((r) => r.studentId == studentId && r.stageType == stageType && !r.isGeneral)
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

    // ⬅️ CHANGED: General categories are exempt from the per-student cap,
    // so there's no limit to enforce for them at all.
    final capApplies = !category.isGeneral;
    final cap = _limitFor(program.stageType ?? '');

    final classFrom = int.tryParse(category.classFrom);
    final classTo = int.tryParse(category.classTo);
    if (classFrom == null || classTo == null) return []; // malformed category range

    return teamStudents.where((s) {
      final genderOk = _genderMatches(s.gender, category.gender);
      if (!genderOk) return false;

      final studentClassNum = int.tryParse(s.studentClass);
      if (studentClassNum == null) return false; // malformed CLASS value, skip
      if (studentClassNum < classFrom || studentClassNum > classTo) return false;

      if (_alreadyHas(s.id, program.id)) return false;
      if (capApplies && _studentTypeCount(s.id, program.stageType ?? '') >= cap) return false;
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
    // ⬅️ CHANGED: General categories are exempt from the per-student cap.
    final capApplies = !category.isGeneral;
    final cap = _limitFor(stageType);
    if (capApplies) {
      for (final id in selectedStudentIds) {
        final student = teamStudents.firstWhere((s) => s.id == id);
        if (_alreadyHas(id, program.id)) {
          return '${student.name} is already registered for this program';
        }
        if (_studentTypeCount(id, stageType) >= cap) {
          return '${student.name} has reached the $stageType limit';
        }
      }
    } else {
      // Still block exact duplicate registrations even for General.
      for (final id in selectedStudentIds) {
        final student = teamStudents.firstWhere((s) => s.id == id);
        if (_alreadyHas(id, program.id)) {
          return '${student.name} is already registered for this program';
        }
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
        isGeneral: program.isGeneral,
        registrationId: student.registerNumber??'',
        registrationNumber: student.registerNumber??'',
      ));
    }

    selectedStudentIds.clear();
    selectedProgram = null;
    notifyListeners();
    return null;
  }
  /// Deletes a single registration document from Firestore and refreshes
  /// the local cache. [registration] must be one already persisted
  /// (i.e. its `id` is the real Firestore document id, not a pending entry).
  Future<String?> deleteRegistration(RegistrationModel registration) async {
    if (registration.id.isEmpty) {
      return 'This registration has not been submitted yet';
    }

    try {
      await _registrationsCollection.doc(registration.id).delete();
      await _refreshRegistrations();
      expandedIndex = -1;
      notifyListeners();
      return null;
    } catch (e) {
      return 'Failed to delete registration: $e';
    }
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

  /// Stage-type quick filter options. 'General' is its own bucket, distinct
  /// from Stage/Non Stage, matching how the list/group views split them.
  List<String> get filterOptions => const ['All', 'Stage', 'Non Stage', 'General'];

  /// Program-category options actually present in this team's registrations
  /// (e.g. 'Senior', 'Junior' …), for the category filter chips.
  List<String> get programCategoryOptions {
    final set = teamRegistrations
        .map((r) => r.programCategory)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['All', ...set];
  }

  /// Gender/team-category options actually present in this team's
  /// registrations (e.g. 'Boys', 'Girls', 'Mixed'), for the gender filter.
  List<String> get genderFilterOptions {
    final set = teamRegistrations
        .map((r) => r.studentCategory)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['All', ...set];
  }

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
    var list = teamRegistrations;

    if (selectedFilter != 'All') {
      if (selectedFilter == 'General') {
        list = list.where((r) => r.isGeneral).toList();
      } else {
        list = list.where((r) => !r.isGeneral && r.stageType == selectedFilter).toList();
      }
    }

    if (selectedCategoryFilter != 'All') {
      list = list.where((r) => r.programCategory == selectedCategoryFilter).toList();
    }

    if (selectedGenderFilter != 'All') {
      list = list.where((r) => r.studentCategory == selectedGenderFilter).toList();
    }

    return list;
  }

  /// "Student wise" grouping: each student appears once, with their
  /// programs split into Stage / Non Stage / General underneath.
  List<StudentRegistrationGroup> get studentWiseGroups {
    final byStudent = <String, List<RegistrationModel>>{};
    for (final r in filteredTeamRegistrations) {
      byStudent.putIfAbsent(r.studentId, () => []).add(r);
    }

    final groups = byStudent.entries.map((entry) {
      final regs = entry.value;
      final stage = regs.where((r) => !r.isGeneral && r.stageType == 'Stage').toList();
      final nonStage = regs.where((r) => !r.isGeneral && r.stageType == 'Non Stage').toList();
      final general = regs.where((r) => r.isGeneral).toList();

      String? photoUrl;
      final matchingStudents = teamStudents.where((s) => s.id == entry.key);
      if (matchingStudents.isNotEmpty) {
        photoUrl = matchingStudents.first.photoUrl;
      }

      return StudentRegistrationGroup(
        studentId: entry.key,
        studentName: regs.first.studentName,
        registrationNumber: regs.first.registrationNumber,
        photoUrl: photoUrl,
        stagePrograms: stage,
        nonStagePrograms: nonStage,
        generalPrograms: general,
      );
    }).toList()
      ..sort((a, b) => a.studentName.compareTo(b.studentName));

    return groups;
  }

  /// "Program wise" grouping: each program appears once, with every
  /// registered student + registration id listed underneath.
  List<ProgramRegistrationGroup> get programWiseGroups {
    final byProgram = <String, List<RegistrationModel>>{};
    for (final r in filteredTeamRegistrations) {
      byProgram.putIfAbsent(r.programId, () => []).add(r);
    }

    final groups = byProgram.entries.map((entry) {
      final regs = entry.value
        ..sort((a, b) => a.studentName.compareTo(b.studentName));
      final first = regs.first;
      return ProgramRegistrationGroup(
        programId: entry.key,
        programName: first.programName,
        programCategory: first.programCategory,
        stageType: first.stageType,
        isGeneral: first.isGeneral,
        registrations: regs,
      );
    }).toList()
      ..sort((a, b) => a.programName.compareTo(b.programName));

    return groups;
  }

  void setFilter(String value) {
    selectedFilter = value;
    expandedIndex = -1;
    notifyListeners();
  }

  void setCategoryFilter(String value) {
    selectedCategoryFilter = value;
    expandedIndex = -1;
    notifyListeners();
  }

  void setGenderFilter(String value) {
    selectedGenderFilter = value;
    expandedIndex = -1;
    notifyListeners();
  }

  void setViewMode(RegistrationViewMode mode) {
    viewMode = mode;
    expandedIndex = -1;
    notifyListeners();
  }

  void toggleExpand(int index) {
    expandedIndex = expandedIndex == index ? -1 : index;
    notifyListeners();
  }

  bool isExpanded(int index) => expandedIndex == index;

  // ---- Student photo upload (Firebase Storage) ----

  /// Opens the gallery picker for [studentId], compresses the image, uploads
  /// it to Firebase Storage under `student_photos/{studentId}.jpg`, then
  /// writes the download URL back onto the student's Firestore doc and the
  /// local [teamStudents] cache. Returns an error message on failure, or
  /// null on success / if the user cancelled the picker.
  Future<String?> uploadStudentPhoto(String studentId) async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (file == null) return null; // user cancelled

      photoUploadProgress[studentId] = 0;
      notifyListeners();

      final rawBytes = await file.readAsBytes();
      final bytes = _compressPhoto(rawBytes);

      final storagePath = '$_photoStorageFolder/$studentId.jpg';
      final ref = _storage.ref().child(storagePath);
      final uploadTask = ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      uploadTask.snapshotEvents.listen((event) {
        if (event.totalBytes > 0) {
          photoUploadProgress[studentId] = event.bytesTransferred / event.totalBytes;
          notifyListeners();
        }
      });

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      await _studentsCollection.doc(studentId).update({'PHOTO_URL': downloadUrl});

      final index = teamStudents.indexWhere((s) => s.id == studentId);
      if (index != -1) {
        teamStudents[index] = teamStudents[index].copyWith(photoUrl: downloadUrl);
      }

      return null;
    } catch (e) {
      return 'Failed to upload photo: $e';
    } finally {
      photoUploadProgress.remove(studentId);
      notifyListeners();
    }
  }

  /// Decodes and re-encodes as JPEG (quality 85), shrinking the longest
  /// side to [_photoMaxDimension] px. Pure-Dart (the `image` package), so
  /// it works on web too — no platform channels needed.
  Uint8List _compressPhoto(Uint8List original) {
    final decoded = img.decodeImage(original);
    if (decoded == null) return original;

    img.Image resized = decoded;
    if (decoded.width > _photoMaxDimension || decoded.height > _photoMaxDimension) {
      resized = img.copyResize(
        decoded,
        width: decoded.width >= decoded.height ? _photoMaxDimension : null,
        height: decoded.height > decoded.width ? _photoMaxDimension : null,
      );
    }

    return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
  }
}