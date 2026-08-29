import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:meeras_fest_app/registration/registration_model.dart'; // ⚠️ adjust to your real path

/// Drives the Stage Manager's "Assignments" screen: loads every
/// registration + team, lets the Stage Manager filter by team category,
/// program category, student category and stage type, groups the
/// (filtered) registrations by program for browsing, and lets them
/// assign a code letter to each registration within a chosen program.
class StageManagerProvider extends ChangeNotifier {
  // ⚠️ Adjust this if your registrations live under a different
  // Firestore collection name.
  final _registrationsCollection =
  FirebaseFirestore.instance.collection('REGISTRATIONS');
  final _teamsCollection = FirebaseFirestore.instance.collection('TEAMS');

  bool isLoading = true;
  String? loadError;

  List<RegistrationModel> _all = [];
  // teamId -> team info, built once from TEAMS so we can show team name
  // and filter by team category without changing RegistrationModel.
  Map<String, _TeamInfo> _teamsById = {};

  // Filters. null means "no filter" (shown as "All").
  String? teamCategoryFilter;
  String? programCategoryFilter;
  String? studentCategoryFilter;
  String? stageTypeFilter;

  Future<void> load() async {
    isLoading = true;
    loadError = null;
    notifyListeners();
    try {
      final teamsSnap = await _teamsCollection.get();
      _teamsById = {
        for (final d in teamsSnap.docs)
          d.id: _TeamInfo(
            name: (d.data()['TEAM_NAME'] ?? '').toString(),
            category: (d.data()['TEAM_CATEGORY'] ?? '').toString(),
          ),
      };

      final regsSnap = await _registrationsCollection.get();
      _all = regsSnap.docs.map(RegistrationModel.fromDoc).toList();
    } catch (e) {
      loadError = 'Failed to load registrations: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String teamName(String teamId) => _teamsById[teamId]?.name ?? teamId;
  String teamCategory(String teamId) => _teamsById[teamId]?.category ?? '';

  // ---- filter option lists, derived from the loaded data ----
  List<String> get teamCategoryOptions =>
      _distinct(_all.map((r) => teamCategory(r.teamId)));
  List<String> get programCategoryOptions =>
      _distinct(_all.map((r) => r.programCategory));
  List<String> get studentCategoryOptions =>
      _distinct(_all.map((r) => r.studentCategory));
  List<String> get stageTypeOptions => _distinct(_all.map((r) => r.stageType));

  List<String> _distinct(Iterable<String> values) {
    final s = values.where((v) => v.isNotEmpty).toSet().toList();
    s.sort();
    return s;
  }

  void setTeamCategoryFilter(String? v) {
    teamCategoryFilter = v;
    notifyListeners();
  }

  void setProgramCategoryFilter(String? v) {
    programCategoryFilter = v;
    notifyListeners();
  }

  void setStudentCategoryFilter(String? v) {
    studentCategoryFilter = v;
    notifyListeners();
  }

  void setStageTypeFilter(String? v) {
    stageTypeFilter = v;
    notifyListeners();
  }

  void clearFilters() {
    teamCategoryFilter = null;
    programCategoryFilter = null;
    studentCategoryFilter = null;
    stageTypeFilter = null;
    notifyListeners();
  }

  List<RegistrationModel> get _filtered {
    return _all.where((r) {
      if (teamCategoryFilter != null &&
          teamCategory(r.teamId) != teamCategoryFilter) {
        return false;
      }
      if (programCategoryFilter != null &&
          r.programCategory != programCategoryFilter) {
        return false;
      }
      if (studentCategoryFilter != null &&
          r.studentCategory != studentCategoryFilter) {
        return false;
      }
      if (stageTypeFilter != null && r.stageType != stageTypeFilter) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Programs that match the current filters, one entry per program,
  /// with an assigned/total count — this powers the home list.
  List<ProgramSummary> get programSummaries {
    final byProgram = <String, List<RegistrationModel>>{};
    for (final r in _filtered) {
      byProgram.putIfAbsent(r.programId, () => []).add(r);
    }
    final list = byProgram.entries.map((e) {
      final regs = e.value;
      return ProgramSummary(
        programId: e.key,
        programName: regs.first.programName,
        programCategory: regs.first.programCategory,
        stageType: regs.first.stageType,
        isGeneral: regs.first.isGeneral,
        total: regs.length,
        assigned: regs.where((r) => r.isAssigned).length,
      );
    }).toList();
    list.sort((a, b) => a.programName.compareTo(b.programName));
    return list;
  }

  /// ALL registrations for one program (not limited by the current
  /// filters) — the assignment screen should see every team entered
  /// for that program, regardless of what the Stage Manager filtered
  /// by to find it, so the letters cover the whole program.
  List<RegistrationModel> registrationsForProgram(String programId) {
    final regs = _all.where((r) => r.programId == programId).toList();
    regs.sort((a, b) => teamName(a.teamId).compareTo(teamName(b.teamId)));
    return regs;
  }

  /// Letters already taken by OTHER registrations in this program, so
  /// the dropdown can disable them (no two entries share a letter).
  Set<String> takenLetters(String programId, {String? exceptRegistrationId}) {
    return _all
        .where((r) =>
    r.programId == programId &&
        r.id != exceptRegistrationId &&
        r.isAssigned)
        .map((r) => r.codeLetter)
        .toSet();
  }

  Future<void> assignCodeLetter(RegistrationModel reg, String? letter) async {
    await _registrationsCollection
        .doc(reg.id)
        .update({'CODE_LETTER': letter ?? ''});
    final idx = _all.indexWhere((r) => r.id == reg.id);
    if (idx != -1) _all[idx] = _all[idx].copyWith(codeLetter: letter ?? '');
    notifyListeners();
  }

  /// A, B, C, ... Z, AA, AB, ... — sized to [count] entries. Used to
  /// build the dropdown options for a program with [count] registrations.
  static List<String> letterOptions(int count) {
    return List.generate(count, (i) => _letterAt(i));
  }

  static String _letterAt(int index) {
    String s = '';
    int n = index;
    do {
      s = String.fromCharCode(65 + (n % 26)) + s;
      n = (n ~/ 26) - 1;
    } while (n >= 0);
    return s;
  }
}

class _TeamInfo {
  final String name;
  final String category;
  _TeamInfo({required this.name, required this.category});
}

class ProgramSummary {
  final String programId;
  final String programName;
  final String programCategory;
  final String stageType;
  final bool isGeneral;
  final int total;
  final int assigned;

  ProgramSummary({
    required this.programId,
    required this.programName,
    required this.programCategory,
    required this.stageType,
    required this.isGeneral,
    required this.total,
    required this.assigned,
  });
}