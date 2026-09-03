import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// One ranked student under a program's results (top 3 by RANK).
class RankedEntry {
  final String studentName;
  final String teamName;
  final int rank;
  final num points;
  final String studentCategory; // STUDENT_CATEGORY, e.g. "Sub Junior" / "Senior"
  final String photoUrl; // STUDENTS.PHOTO_URL, joined via STUDENT_ID

  RankedEntry({
    required this.studentName,
    required this.teamName,
    required this.rank,
    required this.points,
    required this.studentCategory,
    required this.photoUrl,
  });
}

/// A program with at least one judged result, plus its top-3 ranking.
class ProgramResult {
  final String programId;
  final String programName;
  final String category; // PROGRAM_CATEGORY
  final String stageType; // STAGE_TYPE
  final List<RankedEntry> topEntries; // sorted by rank ascending, max 3

  ProgramResult({
    required this.programId,
    required this.programName,
    required this.category,
    required this.stageType,
    required this.topEntries,
  });

  /// Returns a copy with a different set of entries — used when the
  /// student-category filter narrows down which entries are shown for
  /// this program without needing to re-fetch or mutate the original.
  ProgramResult withEntries(List<RankedEntry> entries) => ProgramResult(
    programId: programId,
    programName: programName,
    category: category,
    stageType: stageType,
    topEntries: entries,
  );
}

class ResultProvider extends ChangeNotifier {
  final _programsCollection = FirebaseFirestore.instance.collection('PROGRAMS');
  final _registrationsCollection = FirebaseFirestore.instance.collection('REGISTRATIONS');
  final _teamsCollection = FirebaseFirestore.instance.collection('TEAMS');
  final _studentsCollection = FirebaseFirestore.instance.collection('STUDENTS');

  bool isLoading = false;
  String? errorMessage;

  List<ProgramResult> _allResults = [];

  // ---- Filters ----
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

  /// Student category lives on each ranked entry, not the program, so this
  /// is flattened across every program's entries rather than read straight
  /// off _allResults like the program-level option lists above.
  List<String> get studentCategoryOptions => (_allResults
      .expand((r) => r.topEntries)
      .map((e) => e.studentCategory)
      .where((c) => c.isNotEmpty)
      .toSet()
      .toList()
    ..sort());

  /// Results after applying whichever filters are currently set. Any
  /// combination can be active at once — all must match.
  ///
  /// programName / category / stageType are program-level, so they simply
  /// keep or drop a whole ProgramResult. studentCategory is entry-level:
  /// it narrows each program's topEntries down to matching entries, and
  /// the program itself is dropped only if none of its entries match.
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

  Future<void> fetchResults() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      // ⬅️ FIXED: only filter by STATUS in the Firestore query. The
      // previous version also chained `.where('RANK', isGreaterThan: 0)`,
      // which (a) requires a composite (STATUS, RANK) index — without one
      // Firestore throws failed-precondition and this fetch fails outright
      // — and (b) silently drops any doc where RANK isn't stored as a
      // numeric type, since Firestore range filters don't coerce types.
      // RANK is already parsed defensively below and filtered to > 0 in
      // memory, so the Firestore-side range filter was both fragile and
      // redundant. A single equality filter needs no composite index.
      final results0 = await Future.wait([
        _programsCollection.get(),
        _registrationsCollection.where('STATUS', isEqualTo: 'Published').get(),
        _teamsCollection.get(),
        _studentsCollection.get(),
      ]);

      final programsSnap = results0[0];
      final registrationsSnap = results0[1];
      final teamsSnap = results0[2];
      final studentsSnap = results0[3];

      final teamNames = {
        for (final d in teamsSnap.docs)
          d.id: ((d.data() as Map<String, dynamic>)['NAME'] ??
              (d.data() as Map<String, dynamic>)['TEAM_NAME'] ??
              '')
              .toString(),
      };

      // STUDENT_ID -> PHOTO_URL, so ranked entries can show the student's photo.
      final studentPhotos = {
        for (final d in studentsSnap.docs)
          d.id: ((d.data() as Map<String, dynamic>)['PHOTO_URL'] ?? '').toString(),
      };

      final byProgram = <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
      for (final doc in registrationsSnap.docs) {
        final programId = (doc.data()['PROGRAM_ID'] ?? '').toString();
        if (programId.isEmpty) continue;
        byProgram.putIfAbsent(programId, () => []).add(doc);
      }

      final results = <ProgramResult>[];
      for (final programDoc in programsSnap.docs) {
        final regs = byProgram[programDoc.id];
        if (regs == null || regs.isEmpty) continue; // no results yet — skip entirely

        final entries = regs.map((doc) {
          final data = doc.data();
          final rank = data['RANK'] is int
              ? data['RANK'] as int
              : int.tryParse('${data['RANK']}') ?? 0;
          final teamId = (data['TEAM_ID'] ?? '').toString();
          final studentId = (data['STUDENT_ID'] ?? '').toString();
          return RankedEntry(
            studentName: (data['STUDENT_NAME'] ?? '').toString(),
            teamName: teamNames[teamId] ?? teamId,
            rank: rank,
            points: (data['POINT'] ?? 0) as num,
            studentCategory: (data['STUDENT_CATEGORY'] ?? '').toString(),
            photoUrl: studentPhotos[studentId] ?? '',
          );
        }).where((e) => e.rank > 0).toList()
          ..sort((a, b) => a.rank.compareTo(b.rank));

        if (entries.isEmpty) continue; // only unjudged / RANK<=0 entries — skip

        final programData = programDoc.data();
        results.add(ProgramResult(
          programId: programDoc.id,
          programName: (programData['PROGRAM_NAME'] ?? '').toString(),
          category: (programData['PROGRAM_CATEGORY'] ?? '').toString(),
          stageType: (programData['STAGE_TYPE'] ?? '').toString(),
          topEntries: entries.take(3).toList(),
        ));
      }

      results.sort((a, b) => a.programName.compareTo(b.programName));
      _allResults = results;
      errorMessage = null;
    } catch (e) {
      errorMessage = 'Failed to load results: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}