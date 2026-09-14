import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:meeras_fest_app/registration/registration_model.dart'; // ⚠️ adjust to your real path

/// Drives the Stage Manager's "Assignments" screen: loads every
/// registration + team, lets the Stage Manager filter by team category,
/// program category, student category and stage type, groups the
/// (filtered) registrations by program for browsing, and lets them
/// assign a code letter to each registration within a chosen program.
///
/// For "general" programs, an entire team shares one code letter across
/// all of its registrations in that program — see [teamGroupsForProgram]
/// and [assignCodeLetterForTeam]. For non-general programs, each
/// registration gets its own letter — see [registrationsForProgram] and
/// [assignCodeLetter].
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

      final regsSnap = await _registrationsCollection.where("STATUS",isEqualTo: "Assigned").get();
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
  ///
  /// For "general" programs, `total`/`assigned` count TEAMS (one letter
  /// per team), not individual registrations, since the Stage Manager
  /// assigns one letter per team in that case.
  ///
  /// Also carries the distinct set of team categories represented among
  /// that program's registrations (e.g. a program entered by both
  /// "Senior" and "Junior" teams shows both), so the list screen can
  /// display them as chips on the program card.
  List<ProgramSummary> get programSummaries {
    final byProgram = <String, List<RegistrationModel>>{};
    for (final r in _filtered) {
      byProgram.putIfAbsent(r.programId, () => []).add(r);
    }
    final list = byProgram.entries.map((e) {
      final regs = e.value;
      final isGeneral = regs.first.isGeneral;

      int total;
      int assigned;
      if (isGeneral) {
        final groups = _groupIntoTeams(regs);
        total = groups.length;
        assigned = groups.where((g) => g.isAssigned).length;
      } else {
        total = regs.length;
        assigned = regs.where((r) => r.isAssigned).length;
      }

      final teamCats = _distinct(regs.map((r) => teamCategory(r.teamId)));

      return ProgramSummary(
        programId: e.key,
        programName: regs.first.programName,
        programCategory: regs.first.programCategory,
        stageType: regs.first.stageType,
        isGeneral: isGeneral,
        total: total,
        assigned: assigned,
        teamCategories: teamCats,
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

  /// For "general" programs: one group per team entered in [programId],
  /// carrying every registration that belongs to that team in that
  /// program, so a single letter can be applied to all of them at once.
  List<TeamAssignmentGroup> teamGroupsForProgram(String programId) {
    return _groupIntoTeams(registrationsForProgram(programId));
  }

  List<TeamAssignmentGroup> _groupIntoTeams(List<RegistrationModel> regs) {
    final byTeam = <String, List<RegistrationModel>>{};
    for (final r in regs) {
      byTeam.putIfAbsent(r.teamId, () => []).add(r);
    }
    final groups = byTeam.entries.map((e) {
      final teamRegs = e.value;
      // A team's registrations for a program are expected to share one
      // registration number (they were registered together); fall back
      // to the first non-empty one in case any entry is missing it.
      final regNumber = teamRegs
          .map((r) => r.registrationNumber)
          .firstWhere((n) => n.isNotEmpty, orElse: () => '');
      return TeamAssignmentGroup(
        teamId: e.key,
        teamName: teamName(e.key),
        registerNumber: regNumber,
        regs: teamRegs,
      );
    }).toList();
    groups.sort((a, b) => a.teamName.compareTo(b.teamName));
    return groups;
  }

  /// Letters already taken by OTHER registrations in this program, so
  /// the dropdown can disable them (no two entries share a letter).
  /// Use this for non-general programs (per-entry assignment).
  Set<String> takenLetters(String programId, {String? exceptRegistrationId}) {
    return _all
        .where((r) =>
    r.programId == programId &&
        r.id != exceptRegistrationId &&
        r.isAssigned)
        .map((r) => r.codeLetter)
        .toSet();
  }

  /// Letters already taken by OTHER teams in this program. Use this for
  /// general programs (per-team assignment).
  Set<String> takenLettersForTeams(String programId, {String? exceptTeamId}) {
    return teamGroupsForProgram(programId)
        .where((g) => g.teamId != exceptTeamId)
        .map((g) => g.codeLetter)
        .where((l) => l.isNotEmpty)
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

  /// Applies the same [letter] to every registration belonging to
  /// [teamId] within [programId] — used for "general" programs, where
  /// the whole team shares one code letter. Writes in a single batch.
  Future<void> assignCodeLetterForTeam(
      String programId, String teamId, String? letter) async {
    final regs = _all
        .where((r) => r.programId == programId && r.teamId == teamId)
        .toList();
    if (regs.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    for (final r in regs) {
      batch.update(_registrationsCollection.doc(r.id), {'CODE_LETTER': letter ?? ''});
    }
    await batch.commit();

    for (final r in regs) {
      final idx = _all.indexWhere((x) => x.id == r.id);
      if (idx != -1) _all[idx] = _all[idx].copyWith(codeLetter: letter ?? '');
    }
    notifyListeners();
  }

  /// A, B, C, ... Z, AA, AB, ... — sized to [count] entries. Used to
  /// build the dropdown options for a program with [count] registrations
  /// (or, for general programs, [count] teams).
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
  final List<String> teamCategories;

  ProgramSummary({
    required this.programId,
    required this.programName,
    required this.programCategory,
    required this.stageType,
    required this.isGeneral,
    required this.total,
    required this.assigned,
    this.teamCategories = const [],
  });
}

/// One team's worth of registrations within a single "general" program —
/// all of them get assigned the same code letter together.
class TeamAssignmentGroup {
  final String teamId;
  final String teamName;
  final String registerNumber;
  final List<RegistrationModel> regs;

  TeamAssignmentGroup({
    required this.teamId,
    required this.teamName,
    required this.registerNumber,
    required this.regs,
  });

  bool get isAssigned =>
      regs.isNotEmpty && regs.every((r) => r.isAssigned && r.codeLetter.isNotEmpty);

  /// The team's shared code letter, if every registration in the group
  /// actually carries the same one (it always should, since they're only
  /// ever written together via [assignCodeLetterForTeam]).
  String get codeLetter {
    if (regs.isEmpty) return '';
    final first = regs.first.codeLetter;
    final allSame = regs.every((r) => r.codeLetter == first);
    return allSame ? first : '';
  }
}