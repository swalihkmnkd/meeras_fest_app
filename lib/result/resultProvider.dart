import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// One ranked student under a program's results (top 3 by RANK).
class RankedEntry {
  final String studentId;
  final String studentName;
  final String teamName;
  final int rank;
  final num points;
  final String studentCategory;
  final String photoUrl;
  // true when this entry represents a GENERAL (team) result rather
  // than one individual student's result. The UI uses this to decide
  // whether to show the team name + a group icon, or the student's own
  // name + photo.
  final bool isGeneral;

  RankedEntry({
    required this.studentId,
    required this.studentName,
    required this.teamName,
    required this.rank,
    required this.points,
    required this.studentCategory,
    required this.photoUrl,
    required this.isGeneral,
  });
}

/// A program with at least one judged result. `topEntries` is the
/// top-3 ranking (unchanged usage everywhere existing). `allEntries` is
/// every ranked entry for the program, so the UI can offer a "View more"
/// expansion beyond rank 3 without another query.
class ProgramResult {
  final String programId;
  final String programName;
  final String category;
  final String stageType;
  final List<RankedEntry> topEntries;
  final List<RankedEntry> allEntries;

  ProgramResult({
    required this.programId,
    required this.programName,
    required this.category,
    required this.stageType,
    required this.topEntries,
    List<RankedEntry>? allEntries,
  }) : allEntries = allEntries ?? topEntries;

  ProgramResult withEntries(List<RankedEntry> entries) => ProgramResult(
    programId: programId,
    programName: programName,
    category: category,
    stageType: stageType,
    topEntries: entries,
    // Filtering (e.g. by student category) narrows the full list the
    // same way it narrows the top-3, so "View more" still respects
    // whatever filter produced `entries`.
    allEntries: allEntries.where((e) => entries.contains(e)).toList(),
  );
}

/// One student's single best (lowest-numbered) rank across every
/// published result — powers the Poster feature's automatic rank
/// detection.
class StudentBestResult {
  final String studentId;
  final String studentName;
  final String teamName;
  final String photoUrl;
  final String studentCategory;
  final int bestRank;
  final num points;
  final String programName;

  StudentBestResult({
    required this.studentId,
    required this.studentName,
    required this.teamName,
    required this.photoUrl,
    required this.studentCategory,
    required this.bestRank,
    required this.points,
    required this.programName,
  });
}

/// Overall team leaderboard entry — total points summed across every
/// program's top-3 finishers.
class TeamStanding {
  final String teamName;
  final num totalPoints;
  TeamStanding({required this.teamName, required this.totalPoints});
}

/// One team's row in a category grid: every program it has ANY registered
/// entry in (not just top-3), with all of that team's point values for
/// each program (a team can field more than one student per program, so
/// each cell can hold more than one score, stacked).
class TeamRow {
  final String teamName;
  final Map<String, List<num>> pointsByProgram; // programName -> scores
  final num total;

  TeamRow({required this.teamName, required this.pointsByProgram, required this.total});
}

/// A full team-vs-program score grid for one STUDENT_CATEGORY (e.g.
/// "Junior Girls"). programNames are the column order; teamRows are the
/// rows, already sorted by total descending.
class CategoryGrid {
  final String category;
  final List<String> programNames;
  final List<TeamRow> teamRows;

  CategoryGrid({required this.category, required this.programNames, required this.teamRows});
}

/// Combined totals across every category that shares a gender (derived
/// from the category name containing "Girls"/"Boys") — powers the
/// "GIRLS" / "BOYS" overall totals slide.
class GenderTotal {
  final String gender;
  final List<TeamStanding> teamTotals;
  GenderTotal({required this.gender, required this.teamTotals});
}

class ResultProvider extends ChangeNotifier {
  final _programsCollection = FirebaseFirestore.instance.collection('PROGRAMS');
  final _registrationsCollection = FirebaseFirestore.instance.collection('REGISTRATIONS');
  final _teamsCollection = FirebaseFirestore.instance.collection('TEAMS');
  final _studentsCollection = FirebaseFirestore.instance.collection('STUDENTS');

  bool isLoading = false;
  String? errorMessage;

  List<ProgramResult> _allResults = [];
  List<CategoryGrid> _categoryGrids = [];
  List<GenderTotal> _genderTotals = [];

  List<CategoryGrid> get categoryGrids => _categoryGrids;
  List<GenderTotal> get genderTotals => _genderTotals;

  // ---- Filters (used by the older per-program results view) ----
  String? selectedProgramName;
  String? selectedCategory;
  String? selectedStudentCategory;
  String? selectedStageType;

  List<String> get programNameOptions =>
      (_allResults.map((r) => r.programName).where((n) => n.isNotEmpty).toSet().toList()..sort());
  List<String> get categoryOptions =>
      (_allResults.map((r) => r.category).where((c) => c.isNotEmpty).toSet().toList()..sort());
  List<String> get stageTypeOptions =>
      (_allResults.map((r) => r.stageType).where((s) => s.isNotEmpty).toSet().toList()..sort());

  List<String> get studentCategoryOptions => (_allResults
      .expand((r) => r.topEntries)
      .map((e) => e.studentCategory)
      .where((c) => c.isNotEmpty)
      .toSet()
      .toList()
    ..sort());

  List<StudentBestResult> get studentBestResults {
    final byStudent = <String, StudentBestResult>{};
    for (final program in _allResults) {
      for (final entry in program.topEntries) {
        if (entry.studentId.isEmpty) continue;
        final existing = byStudent[entry.studentId];
        if (existing == null || entry.rank < existing.bestRank) {
          byStudent[entry.studentId] = StudentBestResult(
            studentId: entry.studentId,
            studentName: entry.studentName,
            teamName: entry.teamName,
            photoUrl: entry.photoUrl,
            studentCategory: entry.studentCategory,
            bestRank: entry.rank,
            points: entry.points,
            programName: program.programName,
          );
        }
      }
    }
    final list = byStudent.values.toList()..sort((a, b) => a.bestRank.compareTo(b.bestRank));
    return list;
  }

  /// Overall team standings from the top-3-only view (kept for whatever
  /// else in the app still uses it).
  List<TeamStanding> get teamStandings {
    final byTeam = <String, num>{};
    for (final program in _allResults) {
      for (final entry in program.topEntries) {
        if (entry.teamName.isEmpty) continue;
        byTeam[entry.teamName] = (byTeam[entry.teamName] ?? 0) + entry.points;
      }
    }
    final list = byTeam.entries
        .map((e) => TeamStanding(teamName: e.key, totalPoints: e.value))
        .toList()
      ..sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
    return list;
  }

  List<ProgramResult> get results => _allResults.where((r) {
    if (selectedProgramName != null && r.programName != selectedProgramName) return false;
    if (selectedCategory != null && r.category != selectedCategory) return false;
    if (selectedStageType != null && r.stageType != selectedStageType) return false;
    return true;
  }).map((r) {
    if (selectedStudentCategory == null) return r;
    final filteredEntries =
    r.topEntries.where((e) => e.studentCategory == selectedStudentCategory).toList();
    return r.withEntries(filteredEntries);
  }).where((r) => r.topEntries.isNotEmpty).toList();

  bool get hasActiveFilters =>
      selectedProgramName != null ||
          selectedCategory != null ||
          selectedStudentCategory != null ||
          selectedStageType != null;

  void setProgramNameFilter(String? name) {
    selectedProgramName = name;
    notifyListeners();
  }

  void setCategoryFilter(String? category) {
    selectedCategory = category;
    notifyListeners();
  }

  void setStudentCategoryFilter(String? studentCategory) {
    selectedStudentCategory = studentCategory;
    notifyListeners();
  }

  void setStageTypeFilter(String? stageType) {
    selectedStageType = stageType;
    notifyListeners();
  }

  void clearFilters() {
    selectedProgramName = null;
    selectedCategory = null;
    selectedStudentCategory = null;
    selectedStageType = null;
    notifyListeners();
  }

  // ---- deterministic per-team color assignment, stable across slides ----
  static const List<Color> _teamPalette = [
    Color(0xFFEF4444), // red
    Color(0xFF3B82F6), // blue
    Color(0xFF10B981), // green
    Color(0xFFF59E0B), // amber
    Color(0xFF8B5CF6), // purple
    Color(0xFFEC4899), // pink
    Color(0xFF14B8A6), // teal
    Color(0xFFF97316), // orange
  ];

  Map<String, Color> get teamColors {
    final names = <String>{};
    for (final grid in _categoryGrids) {
      for (final row in grid.teamRows) {
        names.add(row.teamName);
      }
    }
    final sorted = names.toList()..sort();
    return {for (var i = 0; i < sorted.length; i++) sorted[i]: _teamPalette[i % _teamPalette.length]};
  }

  // ---------------------------------------------------------------------
  // Shared gender detection — used by BOTH the category grids (score
  // table ordering) and the gender totals slide, so they always agree on
  // which bucket a STUDENT_CATEGORY belongs to.
  //
  // NOTE: if your actual STUDENT_CATEGORY values don't contain the words
  // "boy"/"girl"/"male"/"female" anywhere (e.g. they're coded like
  // "Junior A"/"Junior B", or gender lives in a separate field), this is
  // the ONE place to change — add more patterns here, or swap this to
  // read a dedicated GENDER field instead of parsing the category string.
  // ---------------------------------------------------------------------
  static String _genderFromCategory(String category) {
    final lower = category.toLowerCase().trim();
    if (lower.contains('girl') || lower.contains('female')) return 'Girls';
    if (lower.contains('boy') || lower.contains('male')) return 'Boys';
    return 'Overall';
  }

  static const Map<String, int> _genderOrder = {'Boys': 0, 'Girls': 1, 'Overall': 2};

  // ---------------------------------------------------------------------
  // Shared builder for the old per-program top-3 view.
  // ---------------------------------------------------------------------
  List<ProgramResult> _buildProgramResults({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> programsDocs,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> registrationsDocs,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> teamsDocs,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> studentsDocs,
    bool excludeGeneral = false,
  }) {
    final teamNames = {
      for (final d in teamsDocs) d.id: ((d.data())['NAME'] ?? (d.data())['TEAM_NAME'] ?? '').toString(),
    };
    final studentPhotos = {
      for (final d in studentsDocs) d.id: ((d.data())['PHOTO_URL'] ?? '').toString(),
    };

    final byProgram = <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
    for (final doc in registrationsDocs) {
      final data = doc.data();
      final programId = (data['PROGRAM_ID'] ?? '').toString();
      if (programId.isEmpty) continue;
      if (excludeGeneral && data['IS_GENERAL'] == true) continue;
      byProgram.putIfAbsent(programId, () => []).add(doc);
    }

    final results = <ProgramResult>[];
    for (final programDoc in programsDocs) {
      final regs = byProgram[programDoc.id];
      if (regs == null || regs.isEmpty) continue;

      // A program is "general" if any of its published registrations are
      // flagged IS_GENERAL — in that case every student on a team is
      // really representing one shared team result, so we must collapse
      // each team down to a single (best) entry before ranking. Otherwise
      // a team fielding multiple students could occupy multiple top-3
      // slots and get its points counted multiple times downstream
      // (teamStandings).
      final isGeneral = regs.any((doc) => doc.data()['IS_GENERAL'] == true);

      var entries = regs.map((doc) {
        final data = doc.data();
        final rank = data['RANK'] is int ? data['RANK'] as int : int.tryParse('${data['RANK']}') ?? 0;
        final teamId = (data['TEAM_ID'] ?? '').toString();
        final studentId = (data['STUDENT_ID'] ?? '').toString();
        return RankedEntry(
          studentId: studentId,
          studentName: (data['STUDENT_NAME'] ?? '').toString(),
          teamName: teamNames[teamId] ?? teamId,
          rank: rank,
          points: (data['POINT'] ?? 0) as num,
          studentCategory: (data['STUDENT_CATEGORY'] ?? '').toString(),
          photoUrl: studentPhotos[studentId] ?? '',
          isGeneral: isGeneral,
        );
      }).where((e) => e.rank > 0).toList()
        ..sort((a, b) => a.rank.compareTo(b.rank));

      if (isGeneral) {
        // Keep only the best (lowest-rank; tie-broken by higher points)
        // entry per team so a team can't sweep multiple top-3 slots or
        // contribute more than one score for the same general program.
        final bestByTeam = <String, RankedEntry>{};
        for (final entry in entries) {
          if (entry.teamName.isEmpty) continue;
          final existing = bestByTeam[entry.teamName];
          if (existing == null ||
              entry.rank < existing.rank ||
              (entry.rank == existing.rank && entry.points > existing.points)) {
            bestByTeam[entry.teamName] = entry;
          }
        }
        entries = bestByTeam.values.toList()..sort((a, b) => a.rank.compareTo(b.rank));
      }

      if (entries.isEmpty) continue;

      final programData = programDoc.data();
      results.add(ProgramResult(
        programId: programDoc.id,
        programName: (programData['PROGRAM_NAME'] ?? '').toString(),
        category: (programData['PROGRAM_CATEGORY'] ?? '').toString(),
        stageType: (programData['STAGE_TYPE'] ?? '').toString(),
        topEntries: entries.take(3).toList(),
        // Full ranked list (already rank-sorted above), so the UI can
        // expand a card to show ranks beyond 3 on demand.
        allEntries: entries,
      ));
    }

    results.sort((a, b) => a.programName.compareTo(b.programName));
    return results;
  }

  // ---------------------------------------------------------------------
  // Grid builder for the TV scoreboard — uses ALL registrations (not just
  // top-3), grouped by STUDENT_CATEGORY, teams as rows, programs as
  // columns.
  //
  // Categories are sorted Boys-first, then Girls, then anything
  // unmatched ("Overall"), and alphabetically within each gender group —
  // using the SAME _genderFromCategory helper as _buildGenderTotals, so
  // the score table and the gender-totals slide always split the same
  // way.
  // ---------------------------------------------------------------------
  List<CategoryGrid> _buildCategoryGrids({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> programsDocs,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> registrationsDocs,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> teamsDocs,
  }) {
    final teamNames = {
      for (final d in teamsDocs) d.id: ((d.data())['NAME'] ?? (d.data())['TEAM_NAME'] ?? '').toString(),
    };
    final programNamesById = {
      for (final d in programsDocs) d.id: (d.data()['PROGRAM_NAME'] ?? '').toString(),
    };

    // category -> team -> program -> list of point values.
    // For a GENERAL program, every student on a team is really contributing
    // to one shared team result, not separate individual scores — so each
    // team keeps only ONE mark per general program (the highest of that
    // team's entries) instead of appending every student's points, which
    // would otherwise multiply a team's total by however many students it
    // registered for that program.
    final data = <String, Map<String, Map<String, List<num>>>>{};
    final categoryPrograms = <String, Set<String>>{};

    for (final doc in registrationsDocs) {
      final d = doc.data();
      final category = (d['STUDENT_CATEGORY'] ?? '').toString();
      if (category.isEmpty) continue;

      final programId = (d['PROGRAM_ID'] ?? '').toString();
      final programName = programNamesById[programId] ?? '';
      if (programName.isEmpty) continue;

      final teamId = (d['TEAM_ID'] ?? '').toString();
      final teamName = teamNames[teamId] ?? teamId;
      if (teamName.isEmpty) continue;

      final points = (d['POINT'] ?? 0) as num;
      final isGeneral = d['IS_GENERAL'] == true;

      final teamsMap = data.putIfAbsent(category, () => {});
      final programsMap = teamsMap.putIfAbsent(teamName, () => {});
      final list = programsMap.putIfAbsent(programName, () => []);

      if (isGeneral) {
        // One mark per team for general programs — keep the team's best
        // score instead of appending every student's points.
        if (list.isEmpty) {
          list.add(points);
        } else if (points > list.first) {
          list[0] = points;
        }
      } else {
        list.add(points);
      }

      categoryPrograms.putIfAbsent(category, () => {}).add(programName);
    }

    final grids = <CategoryGrid>[];
    final categories = data.keys.toList()
      ..sort((a, b) {
        final genderA = _genderFromCategory(a);
        final genderB = _genderFromCategory(b);
        if (genderA != genderB) {
          return _genderOrder[genderA]!.compareTo(_genderOrder[genderB]!);
        }
        return a.compareTo(b);
      });

    for (final category in categories) {
      final teamsMap = data[category]!;
      final programNames = categoryPrograms[category]!.toList()..sort();

      final rows = <TeamRow>[];
      for (final entry in teamsMap.entries) {
        final total = entry.value.values.expand((l) => l).fold<num>(0, (a, b) => a + b);
        rows.add(TeamRow(teamName: entry.key, pointsByProgram: entry.value, total: total));
      }
      rows.sort((a, b) => b.total.compareTo(a.total));

      grids.add(CategoryGrid(category: category, programNames: programNames, teamRows: rows));
    }
    return grids;
  }

  // ---------------------------------------------------------------------
  // Gender totals builder — combines every CategoryGrid's team totals
  // into per-gender buckets using the SAME _genderFromCategory helper as
  // _buildCategoryGrids, in a fixed Boys -> Girls -> Overall slide order.
  // Empty buckets are skipped, so if every category matches a real
  // gender, no stray "Overall" slide appears.
  // ---------------------------------------------------------------------
  List<GenderTotal> _buildGenderTotals(List<CategoryGrid> grids) {
    final byGender = <String, Map<String, num>>{};
    for (final grid in grids) {
      final gender = _genderFromCategory(grid.category);

      final teamTotals = byGender.putIfAbsent(gender, () => {});
      for (final row in grid.teamRows) {
        teamTotals[row.teamName] = (teamTotals[row.teamName] ?? 0) + row.total;
      }
    }

    final result = <GenderTotal>[];
    for (final gender in _genderOrder.keys) {
      final entries = byGender[gender];
      if (entries == null || entries.isEmpty) continue;
      final standings = entries.entries
          .map((e) => TeamStanding(teamName: e.key, totalPoints: e.value))
          .toList()
        ..sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
      result.add(GenderTotal(gender: gender, teamTotals: standings));
    }
    return result;
  }

  Future<void> fetchResults() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final results0 = await Future.wait([
        _programsCollection.get(),
        _registrationsCollection.where('STATUS', isEqualTo: 'Published').get(),
        _teamsCollection.get(),
        _studentsCollection.get(),
      ]);

      _allResults = _buildProgramResults(
        programsDocs: results0[0].docs,
        registrationsDocs: results0[1].docs,
        teamsDocs: results0[2].docs,
        studentsDocs: results0[3].docs,
        excludeGeneral: false,
      );
      _categoryGrids = _buildCategoryGrids(
        programsDocs: results0[0].docs,
        registrationsDocs: results0[1].docs,
        teamsDocs: results0[2].docs,
      );
      _genderTotals = _buildGenderTotals(_categoryGrids);
      errorMessage = null;
    } catch (e) {
      errorMessage = 'Failed to load results: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchResultsPoster() async {
    isLoading = true;
    errorMessage = null;
    _allResults = [];
    notifyListeners();
    try {
      final results0 = await Future.wait([
        _programsCollection.get(),
        _registrationsCollection.where('STATUS', isEqualTo: 'Published').get(),
        _teamsCollection.get(),
        _studentsCollection.get(),
      ]);

      _allResults = _buildProgramResults(
        programsDocs: results0[0].docs,
        registrationsDocs: results0[1].docs,
        teamsDocs: results0[2].docs,
        studentsDocs: results0[3].docs,
        excludeGeneral: true,
      );
      errorMessage = null;
    } catch (e) {
      errorMessage = 'Failed to load results: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------
  // Realtime scoreboard support.
  // ---------------------------------------------------------------------
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _programsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _registrationsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _teamsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _studentsSub;

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _liveProgramsDocs = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _liveRegistrationsDocs = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _liveTeamsDocs = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _liveStudentsDocs = [];

  bool _liveStarted = false;

  void startLiveResults({bool excludeGeneral = false}) {
    if (_liveStarted) return;
    _liveStarted = true;
    isLoading = true;
    notifyListeners();

    void rebuild() {
      _allResults = _buildProgramResults(
        programsDocs: _liveProgramsDocs,
        registrationsDocs: _liveRegistrationsDocs,
        teamsDocs: _liveTeamsDocs,
        studentsDocs: _liveStudentsDocs,
        excludeGeneral: excludeGeneral,
      );
      _categoryGrids = _buildCategoryGrids(
        programsDocs: _liveProgramsDocs,
        registrationsDocs: _liveRegistrationsDocs,
        teamsDocs: _liveTeamsDocs,
      );
      _genderTotals = _buildGenderTotals(_categoryGrids);
      isLoading = false;
      errorMessage = null;
      notifyListeners();
    }

    _programsSub = _programsCollection.snapshots().listen((snap) {
      _liveProgramsDocs = snap.docs;
      rebuild();
    }, onError: (e) {
      errorMessage = 'Failed to load results: $e';
      isLoading = false;
      notifyListeners();
    });

    _registrationsSub = _registrationsCollection
        .where('STATUS', isEqualTo: 'Published')
        .snapshots()
        .listen((snap) {
      _liveRegistrationsDocs = snap.docs;
      rebuild();
    }, onError: (e) {
      errorMessage = 'Failed to load results: $e';
      isLoading = false;
      notifyListeners();
    });

    _teamsSub = _teamsCollection.snapshots().listen((snap) {
      _liveTeamsDocs = snap.docs;
      rebuild();
    });

    _studentsSub = _studentsCollection.snapshots().listen((snap) {
      _liveStudentsDocs = snap.docs;
      rebuild();
    });
  }

  void stopLiveResults() {
    _programsSub?.cancel();
    _registrationsSub?.cancel();
    _teamsSub?.cancel();
    _studentsSub?.cancel();
    _programsSub = null;
    _registrationsSub = null;
    _teamsSub = null;
    _studentsSub = null;
    _liveStarted = false;
  }

  @override
  void dispose() {
    stopLiveResults();
    super.dispose();
  }
}