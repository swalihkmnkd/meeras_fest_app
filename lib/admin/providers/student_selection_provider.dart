import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/studentModel.dart';

class StudentSelectionProvider extends ChangeNotifier {
  final String teamId;
  final String teamName;
  final String teamCategory; // 'Girls' | 'Boys' | 'Mixed'
  final String teamColor;

  StudentSelectionProvider({
    required this.teamId,
    required this.teamName,
    required this.teamCategory,
    required this.teamColor,
  });

  final _collection = FirebaseFirestore.instance.collection('STUDENTS');

  List<StudentModel> students = [];
  final Set<String> selectedIds = {}; // holds StudentModel.id (doc id)
  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;

  int get selectedCount => selectedIds.length;

  int get selectedBoysCount => students
      .where((s) => selectedIds.contains(s.id) && s.gender == 'Male')
      .length;

  int get selectedGirlsCount => students
      .where((s) => selectedIds.contains(s.id) && s.gender == 'Female')
      .length;

  bool isSelected(String studentId) => selectedIds.contains(studentId);

  Future<void> fetchStudents() async {
    isLoading = true;
    notifyListeners();
    try {
      Query query = _collection;
      if (teamCategory == 'Girls') {
        query = query.where('GENDER', isEqualTo: 'Female');
      } else if (teamCategory == 'Boys') {
        query = query.where('GENDER', isEqualTo: 'Male');
      }
      // 'Mixed' (or anything else) -> no gender filter, fetch all.

      final snap = await query.get();
      students = snap.docs.map((d) => StudentModel.fromDoc(d)).toList();

      // Pre-select students already assigned to this team.
      selectedIds
        ..clear()
        ..addAll(students.where((s) => s.teamId == teamId).map((s) => s.id));

      errorMessage = null;
    } catch (e) {
      errorMessage = 'Failed to load students: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void toggle(String studentId) {
    final student = students.firstWhere((s) => s.id == studentId);
    // Prevent selecting a student who is already on a different team.
    if (!selectedIds.contains(studentId) &&
        student.isAssigned &&
        student.teamId != teamId) {
      return;
    }
    if (selectedIds.contains(studentId)) {
      selectedIds.remove(studentId);
    } else {
      selectedIds.add(studentId);
    }
    notifyListeners();
  }
  Future<int?> _getTeamNumber() async {
    if (teamId.isEmpty) return null;

    final snapshot = await FirebaseFirestore.instance
        .collection('TEAMS')
        .orderBy('createdAt')
        .get();

    for (int i = 0; i < snapshot.docs.length; i++) {
      if (snapshot.docs[i].id == teamId) {
        return i + 1;
      }
    }

    return null;
  }
  Future<String?> saveAssignments() async {
    isSaving = true;
    notifyListeners();

    try {
      final batch = FirebaseFirestore.instance.batch();

      final originallyAssigned = students
          .where((s) => s.teamId == teamId)
          .map((s) => s.id)
          .toSet();

      // Students being removed from this team.
      final removedIds = originallyAssigned
          .difference(selectedIds);

      // Students newly selected.
      final newlySelectedIds = selectedIds
          .difference(originallyAssigned);

      // ------------------------------------------------------------
      // 1. Get currently used REGISTER_NUMBER values for this team
      // ------------------------------------------------------------

      final teamStudentsSnapshot = await _collection
          .where('TEAM_ID', isEqualTo: teamId)
          .get();

      final usedNumbers = <int>{};

      for (final doc in teamStudentsSnapshot.docs) {
        final value = doc.data()['REGISTER_NUMBER'];

        final number = int.tryParse(value?.toString() ?? '');

        if (number != null) {
          usedNumbers.add(number);
        }
      }

      // ------------------------------------------------------------
      // 2. Find team number
      // ------------------------------------------------------------

      final teamNumber = await _getTeamNumber();

      if (teamNumber == null) {
        return 'Team not found';
      }

      // Team 1 -> 100-199
      // Team 2 -> 200-299
      // Team 3 -> 300-399

      final startNumber = teamNumber * 100;
      final endNumber = startNumber + 99;

      // ------------------------------------------------------------
      // 3. Removed students
      // ------------------------------------------------------------

      for (final id in removedIds) {
        batch.update(_collection.doc(id), {
          'TEAM_ID': '',
          'TEAM_NAME': '',
          'TEAM_COLOR': '',
          'REGISTER_NUMBER': '',
        });
      }

      // ------------------------------------------------------------
      // 4. Newly selected students
      // ------------------------------------------------------------

      for (final id in newlySelectedIds) {
        // Find first missing number.
        int? registerNumber;

        for (int number = startNumber;
        number <= endNumber;
        number++) {
          if (!usedNumbers.contains(number)) {
            registerNumber = number;
            break;
          }
        }

        if (registerNumber == null) {
          return 'No registration number available for this team';
        }

        // Reserve this number for the current batch.
        usedNumbers.add(registerNumber);

        batch.update(_collection.doc(id), {
          'TEAM_ID': teamId,
          'TEAM_NAME': teamName,
          'TEAM_COLOR': teamColor,
          'REGISTER_NUMBER': registerNumber,
        });
      }

      await batch.commit();

      return null;
    } catch (e) {
      return 'Failed to save students: $e';
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}