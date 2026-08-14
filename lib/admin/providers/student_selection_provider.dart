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

  Future<String?> saveAssignments() async {
    isSaving = true;
    notifyListeners();
    try {
      final batch = FirebaseFirestore.instance.batch();
      final originallyAssigned =
      students.where((s) => s.teamId == teamId).map((s) => s.id).toSet();

      // Newly selected -> assign team info.
      for (final id in selectedIds.difference(originallyAssigned)) {
        batch.update(_collection.doc(id), {
          'TEAM_ID': teamId,
          'TEAM_NAME': teamName,
          'TEAM_COLOR': teamColor,
        });
      }

      // Deselected -> clear team info.
      for (final id in originallyAssigned.difference(selectedIds)) {
        batch.update(_collection.doc(id), {
          'TEAM_ID': '',
          'TEAM_NAME': '',
          'TEAM_COLOR': '',
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