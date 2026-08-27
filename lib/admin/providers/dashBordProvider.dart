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

  /// Registration counts split by Stage / Non Stage.
  /// ⬅️ NEW: registrations where IS_GENERAL is true are excluded from both
  /// counts — a General program isn't a normal per-student Stage/Non-Stage
  /// slot, so it shouldn't inflate these totals. This needs the actual
  /// documents (not an aggregate count()) since the exclusion depends on
  /// a per-doc field combination that isn't worth a composite index for.
  int stageRegistrationCount = 0;
  int nonStageRegistrationCount = 0;

  Future<void> fetchCounts() async {
    isLoading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _db.collection('PROGRAMS').count().get(),
        _db.collection('STUDENTS').count().get(),
        _db.collection('TEAMS').count().get(),
        _db.collection('judges').count().get(),
        _db.collection('CATEGORIES').count().get(),
      ]);

      programCount = results[0].count ?? 0;
      studentCount = results[1].count ?? 0;
      teamCount = results[2].count ?? 0;
      judgeCount = results[3].count ?? 0;
      categoryCount = results[4].count ?? 0;

      final regSnap = await _db.collection('REGISTRATIONS').get();
      int stage = 0;
      int nonStage = 0;
      for (final doc in regSnap.docs) {
        final data = doc.data();
        if (data['IS_GENERAL'] == true) continue; // ⬅️ excluded, as requested
        final stageType = (data['STAGE_TYPE'] ?? '').toString();
        if (stageType == 'Stage') {
          stage++;
        } else if (stageType == 'Non Stage') {
          nonStage++;
        }
      }
      stageRegistrationCount = stage;
      nonStageRegistrationCount = nonStage;

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