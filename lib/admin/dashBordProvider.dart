import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DashboardProvider extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;

  bool isLoading = false;
  String? errorMessage;

  int programCount = 0;
  int studentCount = 0;
  int teamCount = 0;
  int judgeCount = 0;
  int categoryCount = 0;

  Future<void> fetchCounts() async {
    isLoading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _db.collection('programs').count().get(),
        _db.collection('STUDENTS').count().get(),
        _db.collection('teams').count().get(),
        _db.collection('judges').count().get(),
        _db.collection('categories').count().get(),
      ]);

      programCount = results[0].count ?? 0;
      studentCount = results[1].count ?? 0;
      teamCount = results[2].count ?? 0;
      judgeCount = results[3].count ?? 0;
      categoryCount = results[4].count ?? 0;
      errorMessage = null;
    } catch (e) {
      // Falls back to 0s if aggregate count() isn't available on the
      // current cloud_firestore version / Firestore backend.
      errorMessage = 'Failed to load counts: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}