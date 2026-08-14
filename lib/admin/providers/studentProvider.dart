import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart' as xls;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/studentModel.dart';

class StudentProvider extends ChangeNotifier {
  final _collection = FirebaseFirestore.instance.collection('STUDENTS');

  // Required headers must be present. 'division' is optional -- if the sheet
  // doesn't have that column, division is simply left blank for every row.
  static const _expectedHeaders = ['name', 'class', 'gender', 'roll number'];
  static const _optionalHeaders = ['division'];

  // ---------------------------------------------------------------------
  // Excel upload state
  // ---------------------------------------------------------------------
  String? fileName;
  List<StudentModel> students = [];
  bool isParsing = false;
  bool isUploading = false;
  double uploadProgress = 0;
  String? errorMessage;

  // ---------------------------------------------------------------------
  // Student list / individual CRUD state
  // ---------------------------------------------------------------------
  List<StudentModel> allStudents = [];
  bool isLoadingList = false;
  bool isSavingStudent = false;

  // =======================================================================
  // DOC ID HELPERS
  // =======================================================================

  /// Single source of truth for the Firestore document ID.
  /// Format: Class_Division_GENDER_RollNumber (e.g. "6_B_MALE_001").
  /// Gender is always uppercased here so the ID stays consistent no matter
  /// what casing a caller (dropdown, Excel sheet, etc.) passes in.
  String _docIdFor(StudentModel s) =>
      '${s.studentClass}_${s.division}_${s.gender.toUpperCase()}_${s.rollNumber}';

  /// Bundles the student's map data together with its own docId, so the
  /// docId is also stored as a field inside the document itself.
  Map<String, dynamic> _dataWithDocId(StudentModel s, String docId) => {
    ...s.toMap(),
    'STUDENT_ID': docId,
  };

  // =======================================================================
  // EXCEL UPLOAD
  // =======================================================================

  Future<void> pickAndParseFile() async {
    errorMessage = null;
    students = [];
    fileName = null;
    notifyListeners();

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final picked = result.files.first;
    fileName = picked.name;
    isParsing = true;
    notifyListeners();

    try {
      final bytes = picked.bytes ??
          (picked.path != null ? await File(picked.path!).readAsBytes() : null);

      if (bytes == null) {
        throw Exception('Could not read the selected file.');
      }

      final excelFile = xls.Excel.decodeBytes(bytes);
      final sheet = excelFile.tables[excelFile.tables.keys.first];

      if (sheet == null || sheet.maxRows < 2) {
        throw Exception('The sheet is empty or missing data rows.');
      }

      final headerRow = sheet.row(0);
      final Map<String, int> columnIndex = {};
      for (int i = 0; i < headerRow.length; i++) {
        final raw = headerRow[i]?.value?.toString().trim().toLowerCase();
        if (raw != null &&
            (_expectedHeaders.contains(raw) || _optionalHeaders.contains(raw))) {
          columnIndex[raw] = i;
        }
      }

      final missing = _expectedHeaders.where((h) => !columnIndex.containsKey(h)).toList();
      if (missing.isNotEmpty) {
        throw Exception(
          'Missing column(s) in the sheet: ${missing.join(', ')}. '
              'Expected headers: Name, Class, Gender, Roll Number.',
        );
      }

      final List<StudentModel> parsed = [];
      for (int r = 1; r < sheet.maxRows; r++) {
        final row = sheet.row(r);

        String cell(String key) {
          final idx = columnIndex[key];
          if (idx == null || idx >= row.length) return '';
          return row[idx]?.value?.toString().trim() ?? '';
        }

        final name = cell('name');
        final studentClass = cell('class');
        final division = cell('division');
        final gender = cell('gender');
        final rollNumber = cell('roll number');

        if (name.isEmpty && studentClass.isEmpty && gender.isEmpty && rollNumber.isEmpty) {
          continue;
        }
        if (name.isEmpty || rollNumber.isEmpty) {
          continue;
        }

        parsed.add(StudentModel(
          name: name,
          studentClass: studentClass,
          division: division,
          gender: gender,
          rollNumber: rollNumber, teamId: '', teamName: '', teamColor: '',
        ));
      }

      if (parsed.isEmpty) {
        throw Exception('No valid student rows found in the sheet.');
      }

      students = parsed;
      isParsing = false;
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      isParsing = false;
      notifyListeners();
    }
  }

  Future<String?> uploadToFirebase() async {
    if (students.isEmpty) return null;

    isUploading = true;
    uploadProgress = 0;
    errorMessage = null;
    notifyListeners();

    try {
      const chunkSize = 450;
      int uploaded = 0;

      for (int start = 0; start < students.length; start += chunkSize) {
        final chunk = students.skip(start).take(chunkSize).toList();
        final batch = FirebaseFirestore.instance.batch();

        for (final student in chunk) {
          // Document ID:
          // Class_Division_GENDER_RollNumber
          // Example: 6_B_MALE_001
          final docId = _docIdFor(student);
          final docRef = _collection.doc(docId);

          batch.set(
            docRef,
            _dataWithDocId(student, docId),
            SetOptions(merge: true),
          );
        }

        await batch.commit();

        uploaded += chunk.length;
        uploadProgress = uploaded / students.length;
        notifyListeners();
      }

      final count = students.length;

      // Keep in-memory master list in sync
      final uploadedRollNumbers =
      students.map((s) => s.rollNumber).toSet();

      allStudents = [
        ...allStudents.where(
              (s) => !uploadedRollNumbers.contains(s.rollNumber),
        ),
        ...students,
      ]..sort((a, b) => a.name.compareTo(b.name));

      students = [];
      fileName = null;
      isUploading = false;

      notifyListeners();

      return '$count student(s) were uploaded successfully.';
    } catch (e) {
      isUploading = false;
      errorMessage = 'Upload failed: $e';
      notifyListeners();
      return null;
    }
  }

  // =======================================================================
  // STUDENT LIST (fetch)
  // =======================================================================

  Future<void> fetchAllStudents() async {
    isLoadingList = true;
    notifyListeners();
    try {
      final snap = await _collection.orderBy('NAME').get();
      allStudents = snap.docs.map((d) => StudentModel.fromMap(d.data())).toList();
    } catch (e) {
      errorMessage = 'Failed to load students: $e';
    }
    isLoadingList = false;
    notifyListeners();
  }

  // =======================================================================
  // INDIVIDUAL STUDENT CRUD
  // =======================================================================

  /// Returns an error string if the roll number is already taken by a
  /// different student, otherwise null.
  String? _duplicateRollNumberError(String rollNumber, {String? excludingRollNumber}) {
    final exists = allStudents.any((s) =>
    s.rollNumber == rollNumber && s.rollNumber != excludingRollNumber);
    return exists ? 'A student with this Roll Number already exists.' : null;
  }

  Future<String?> addSingleStudent(StudentModel student) async {
    final dupError = _duplicateRollNumberError(student.rollNumber);
    if (dupError != null) {
      errorMessage = dupError;
      notifyListeners();
      return null;
    }

    isSavingStudent = true;
    notifyListeners();
    try {
      final docId = _docIdFor(student);
      await _collection.doc(docId).set(_dataWithDocId(student, docId));
      allStudents = [...allStudents, student]
        ..sort((a, b) => a.name.compareTo(b.name));
      isSavingStudent = false;
      notifyListeners();
      return '${student.name} was added successfully.';
    } catch (e) {
      isSavingStudent = false;
      errorMessage = 'Failed to add student: $e';
      notifyListeners();
      return null;
    }
  }

  /// [original] is the student's data as it was before editing -- needed
  /// because the doc ID is composite (class_division_gender_roll), so if
  /// any of those fields changed, the old document has to be deleted and
  /// the data re-written under the new ID.
  Future<String?> updateStudent(StudentModel original, StudentModel updated) async {
    final dupError = _duplicateRollNumberError(
      updated.rollNumber,
      excludingRollNumber: original.rollNumber,
    );
    if (dupError != null) {
      errorMessage = dupError;
      notifyListeners();
      return null;
    }

    isSavingStudent = true;
    notifyListeners();
    try {
      final oldDocId = _docIdFor(original);
      final newDocId = _docIdFor(updated);

      if (oldDocId != newDocId) {
        // Composite key changed (class/division/gender/roll), so the data
        // has to move to a new document and the old one removed.
        await _collection.doc(oldDocId).delete();
      }
      await _collection.doc(newDocId).set(_dataWithDocId(updated, newDocId));

      final index = allStudents.indexWhere((s) => s.rollNumber == original.rollNumber);
      if (index != -1) {
        allStudents[index] = updated;
      } else {
        allStudents.add(updated);
      }
      allStudents.sort((a, b) => a.name.compareTo(b.name));

      isSavingStudent = false;
      notifyListeners();
      return '${updated.name} was updated successfully.';
    } catch (e) {
      isSavingStudent = false;
      errorMessage = 'Failed to update student: $e';
      notifyListeners();
      return null;
    }
  }

  Future<String?> deleteStudent(StudentModel student) async {
    try {
      await _collection.doc(_docIdFor(student)).delete();
      allStudents.removeWhere((s) => s.rollNumber == student.rollNumber);
      notifyListeners();
      return '${student.name} was deleted.';
    } catch (e) {
      errorMessage = 'Failed to delete student: $e';
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}