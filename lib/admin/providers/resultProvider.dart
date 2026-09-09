import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/programModel.dart';

/// One judged-but-not-yet-published registration, editable by the admin
/// before publishing.
class PendingResult {
  final String id; // REGISTRATIONS doc id
  final String programId;
  final String programName;
  final String studentName;
  final String teamId;
  final String teamName; // ⬅️ NEW — joined from TEAMS, shown instead of studentName for General programs
  final String registerNumber;
  final bool isGeneral;
  num score;
  String grade;
  int? rank;
  num placePoint;
  num totalPoint;
  final TextEditingController scoreController;

  PendingResult({
    required this.id,
    required this.programId,
    required this.programName,
    required this.studentName,
    required this.teamId,
    required this.teamName, // ⬅️ NEW
    required this.registerNumber,
    required this.isGeneral,
    required this.score,
    required this.grade,
    required this.rank,
    required this.placePoint,
    required this.totalPoint,
  }) : scoreController = TextEditingController(text: score.toString());

  /// [teamNames] maps TEAM_ID -> team name, resolved once per fetch (see
  /// ResultsPublishProvider.fetchPending) rather than re-queried per doc.
  factory PendingResult.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc,
      Map<String, String> teamNames,
      ) {
    final data = doc.data() ?? {};
    final teamId = (data['TEAM_ID'] ?? '').toString();
    return PendingResult(
      id: doc.id,
      programId: (data['PROGRAM_ID'] ?? '').toString(),
      programName: (data['PROGRAM_NAME'] ?? '').toString(),
      studentName: (data['STUDENT_NAME'] ?? '').toString(),
      teamId: teamId,
      teamName: teamNames[teamId] ?? teamId, // ⬅️ NEW
      registerNumber: (data['REGISTER_NUMBER'] ?? '').toString(),
      isGeneral: data['IS_GENERAL'] == true,
      score: (data['SCORE'] ?? 0) as num,
      grade: (data['GRADE'] ?? '').toString(),
      rank: data['RANK'] is int ? data['RANK'] as int : null,
      placePoint: (data['PLACE_POINT'] ?? 0) as num,
      totalPoint: (data['POINT'] ?? 0) as num,
    );
  }

  void dispose() => scoreController.dispose();
}

/// Internal working row used only while re-ranking a program's
/// registrations inside saveEdit().
class _RankRow {
  final String id;
  final String teamId;
  num score;
  String grade;
  int rank;
  num placePoint;
  num totalPoint;

  _RankRow({
    required this.id,
    required this.teamId,
    required this.score,
    this.grade = '',
    this.rank = 0,
    this.placePoint = 0,
    this.totalPoint = 0,
  });
}

/// A program's worth of pending results, grouped so the whole program
/// publishes together — never just one student's row.
class ProgramResultsGroup {
  final String programId;
  final String programName;
  final List<PendingResult> results;

  ProgramResultsGroup({
    required this.programId,
    required this.programName,
    required this.results,
  });

  /// Results to actually show in the review list. For a General program,
  /// several students from the same team can share a PROGRAM_ID — only
  /// one card per team is shown (first occurrence wins), matching
  /// JudgeProvider.displayedRegistrations. Non-general programs show
  /// every result as before. [results] itself stays untouched —
  /// publishProgram()/publishAll() still act on every real registration,
  /// not just the visible cards.
  List<PendingResult> get displayedResults {
    if (results.isEmpty || !results.first.isGeneral) return results;
    final seenTeamIds = <String>{};
    final list = <PendingResult>[];
    for (final r in results) {
      if (seenTeamIds.add(r.teamId)) list.add(r);
    }
    return list;
  }
}

class ResultsPublishProvider extends ChangeNotifier {
  final _registrationsCollection = FirebaseFirestore.instance.collection('REGISTRATIONS');
  final _programsCollection = FirebaseFirestore.instance.collection('PROGRAMS');
  final _teamsCollection = FirebaseFirestore.instance.collection('TEAMS'); // ⬅️ NEW

  List<PendingResult> pendingResults = [];
  Map<String, ProgramModel> _programsById = {};
  bool isLoading = false;
  String? errorMessage;

  final Map<String, bool> _publishingProgram = {};
  bool isPublishingProgram(String programId) => _publishingProgram[programId] ?? false;

  final Map<String, bool> _savingEdit = {};
  bool isSavingEdit(String id) => _savingEdit[id] ?? false;

  /// Pending results grouped by program, so the UI shows the program name
  /// once with every student under it, and publishes them as one unit — a
  /// program can no longer end up partially published.
  List<ProgramResultsGroup> get pendingByProgram {
    final byProgram = <String, List<PendingResult>>{};
    for (final r in pendingResults) {
      byProgram.putIfAbsent(r.programId, () => []).add(r);
    }
    final groups = byProgram.entries
        .map((e) => ProgramResultsGroup(
      programId: e.key,
      programName: e.value.first.programName,
      results: e.value,
    ))
        .toList();
    groups.sort((a, b) => a.programName.compareTo(b.programName));
    return groups;
  }

  Future<void> fetchPending() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final results0 = await Future.wait([
        _registrationsCollection.where('STATUS', isEqualTo: 'Resulted').get(),
        _programsCollection.get(),
        _teamsCollection.get(), // ⬅️ NEW
      ]);

      final snap = results0[0] as QuerySnapshot<Map<String, dynamic>>;
      final programSnap = results0[1] as QuerySnapshot<Map<String, dynamic>>;
      final teamsSnap = results0[2] as QuerySnapshot<Map<String, dynamic>>;

      // ⬅️ NEW — TEAM_ID -> name, same join pattern ResultProvider uses.
      final teamNames = {
        for (final d in teamsSnap.docs)
          d.id: (d.data()['NAME'] ?? d.data()['TEAM_NAME'] ?? '').toString(),
      };

      for (final r in pendingResults) {
        r.dispose();
      }
      pendingResults = snap.docs.map((d) => PendingResult.fromDoc(d, teamNames)).toList()
        ..sort((a, b) => a.programName.compareTo(b.programName));

      // Needed so an edited score can be re-graded using that program's
      // A/B/C thresholds and 1st/2nd/3rd place scores.
      _programsById = {
        for (final d in programSnap.docs) d.id: ProgramModel.fromDoc(d),
      };

      errorMessage = null;
    } catch (e) {
      errorMessage = 'Failed to load results: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Recomputes grade + total points locally as the admin types a new
  /// score, using that program's A/B/C thresholds. This is just a live
  /// preview — rank isn't touched here, since ranking depends on every
  /// other student (or, for General, every other team) in the program
  /// too. The real re-rank + teammate sync happens in saveEdit(), same
  /// as the judge panel does.
  void updateScore(PendingResult result, String value) {
    num score = num.tryParse(value) ?? result.score;
    if (score < 0) score = 0;
    if (score > 100) score = 100;
    result.score = score;

    final program = _programsById[result.programId];
    if (program != null) {
      String grade;
      if (score >= program.aGradeStart) {
        grade = 'A';
      } else if (score >= program.bGradeStart) {
        grade = 'B';
      } else if (score >= program.cGradeStart) {
        grade = 'C';
      } else {
        grade = '';
      }
      final gradePoint = switch (grade) {
        'A' => program.aGradePoint,
        'B' => program.bGradePoint,
        'C' => program.cGradePoint,
        _ => 0,
      };
      result.grade = grade;
      result.totalPoint = gradePoint + result.placePoint;
    }
    notifyListeners();
  }

  /// Saves [result]'s edited score, then re-ranks **every judged
  /// registration under the same program** — same standard-competition
  /// ranking (ties share a rank) the judge panel uses — and writes the
  /// updated SCORE/GRADE/RANK/PLACE_POINT/POINT back for all of them.
  ///
  /// For General programs, several students from the same team can be
  /// registered under the same PROGRAM_ID, but displayedResults only
  /// shows one card per team. Editing that one card (a) syncs the edited
  /// SCORE to every OTHER registration sharing that TEAM_ID before
  /// ranking, and (b) ranks once PER TEAM rather than once per
  /// registration, so a team is never ranked against its own other
  /// entries. The resulting rank/grade/points are then written back to
  /// every registration on that team, not just the one edited —
  /// mirroring JudgeProvider.saveScore. Non-general programs are
  /// unaffected: ranking stays per-registration exactly as before.
  ///
  /// STATUS is intentionally left untouched for every row: this can
  /// re-rank a mix of 'Resulted' and already-'Published' registrations
  /// (since a swapped rank affects the whole program, not just the row
  /// being edited) without silently publishing or un-publishing anything.
  Future<String?> saveEdit(PendingResult result) async {
    _savingEdit[result.id] = true;
    notifyListeners();
    try {
      final program = _programsById[result.programId];
      if (program == null) {
        // No grading rules available — fall back to a plain single-row save.
        await _registrationsCollection.doc(result.id).update({
          'SCORE': result.score,
          'GRADE': result.grade,
          'POINT': result.totalPoint,
        });
        return null;
      }

      final snap = await _registrationsCollection
          .where('PROGRAM_ID', isEqualTo: result.programId)
          .get();

      final rows = <_RankRow>[];
      for (final doc in snap.docs) {
        final data = doc.data();
        final judgedBy = (data['JUDGED_BY'] ?? '').toString();
        // Only re-rank registrations that have actually been judged —
        // plus the row being edited, in case it's somehow missing that flag.
        if (judgedBy.isEmpty && doc.id != result.id) continue;

        final teamId = (data['TEAM_ID'] ?? '').toString();
        // General: every registration on the edited student's team gets
        // synced to the score just entered — one card represents the
        // whole team's shared result.
        final sameTeamAsEdited = result.isGeneral && teamId == result.teamId;
        final score = (doc.id == result.id || sameTeamAsEdited)
            ? result.score
            : (data['SCORE'] ?? 0) as num;
        rows.add(_RankRow(id: doc.id, teamId: teamId, score: score));
      }

      // Rank once per team for General (avoids a team competing against
      // its own other entries); once per registration otherwise —
      // unchanged from before for non-General programs.
      final List<_RankRow> forRanking;
      if (result.isGeneral) {
        final seenTeamIds = <String>{};
        forRanking = [
          for (final r in rows)
            if (seenTeamIds.add(r.teamId)) r,
        ];
      } else {
        forRanking = List.of(rows);
      }
      forRanking.sort((a, b) => b.score.compareTo(a.score));

      int currentRank = 0;
      num? previousScore;
      final rankByTeamId = <String, int>{};
      final gradeByTeamId = <String, String>{};
      final placePointByTeamId = <String, num>{};
      final totalPointByTeamId = <String, num>{};

      for (var i = 0; i < forRanking.length; i++) {
        final r = forRanking[i];
        if (previousScore == null || r.score != previousScore) {
          currentRank = i + 1;
        }
        previousScore = r.score;

        String grade;
        if (r.score >= program.aGradeStart) {
          grade = 'A';
        } else if (r.score >= program.bGradeStart) {
          grade = 'B';
        } else if (r.score >= program.cGradeStart) {
          grade = 'C';
        } else {
          grade = '';
        }
        final gradePoint = switch (grade) {
          'A' => program.aGradePoint,
          'B' => program.bGradePoint,
          'C' => program.cGradePoint,
          _ => 0,
        };
        final placePoint = switch (currentRank) {
          1 => program.firstScore,
          2 => program.secondScore,
          3 => program.thirdScore,
          _ => 0,
        };

        rankByTeamId[r.teamId] = currentRank;
        gradeByTeamId[r.teamId] = grade;
        placePointByTeamId[r.teamId] = placePoint;
        totalPointByTeamId[r.teamId] = gradePoint + placePoint;
      }

      // Apply the computed (per-team, for General) values back onto every
      // row so all of a team's registrations end up identical.
      for (final r in rows) {
        r.rank = rankByTeamId[r.teamId] ?? 0;
        r.grade = gradeByTeamId[r.teamId] ?? '';
        r.placePoint = placePointByTeamId[r.teamId] ?? 0;
        r.totalPoint = totalPointByTeamId[r.teamId] ?? 0;
      }

      final batch = FirebaseFirestore.instance.batch();
      for (final r in rows) {
        batch.update(_registrationsCollection.doc(r.id), {
          'SCORE': r.score,
          'GRADE': r.grade,
          'RANK': r.rank,
          'PLACE_POINT': r.placePoint,
          'POINT': r.totalPoint,
        });

        // Keep any other still-visible pending cards in sync so the admin
        // sees the rank swap immediately, without a full re-fetch. This
        // also updates hidden teammate entries in pendingResults, so
        // publishProgram()/publishAll() publish their already-synced
        // values even though only one card was shown for them.
        final match = pendingResults.where((p) => p.id == r.id);
        if (match.isNotEmpty) {
          final p = match.first;
          p.score = r.score;
          p.grade = r.grade;
          p.rank = r.rank;
          p.placePoint = r.placePoint;
          p.totalPoint = r.totalPoint;
          p.scoreController.text = r.score.toString();
        }
      }
      await batch.commit();
      notifyListeners();
      return null;
    } catch (e) {
      return 'Failed to save edit: $e';
    } finally {
      _savingEdit[result.id] = false;
      notifyListeners();
    }
  }

  /// Publishes every currently-pending ('Resulted') registration under
  /// [programId] together, in one batch — so a program is never left
  /// partially published (some students published, others still pending).
  /// Operates on every real registration (via pendingResults), not just
  /// the visible General-collapsed cards.
  Future<String?> publishProgram(String programId) async {
    final group = pendingResults.where((r) => r.programId == programId).toList();
    if (group.isEmpty) return null;

    _publishingProgram[programId] = true;
    notifyListeners();
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final r in group) {
        batch.update(_registrationsCollection.doc(r.id), {'STATUS': 'Published'});
      }
      await batch.commit();
      for (final r in group) {
        pendingResults.remove(r);
        r.dispose();
      }
      return null;
    } catch (e) {
      return 'Failed to publish program: $e';
    } finally {
      _publishingProgram[programId] = false;
      notifyListeners();
    }
  }

  /// Publishes everything currently pending, across every program, in one
  /// batch — a bulk convenience on top of publishProgram(), not a way to
  /// publish a single row.
  Future<String?> publishAll() async {
    if (pendingResults.isEmpty) return null;
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final r in pendingResults) {
        batch.update(_registrationsCollection.doc(r.id), {'STATUS': 'Published'});
      }
      await batch.commit();
      for (final r in pendingResults) {
        r.dispose();
      }
      pendingResults = [];
      notifyListeners();
      return null;
    } catch (e) {
      return 'Failed to publish all: $e';
    }
  }

  @override
  void dispose() {
    for (final r in pendingResults) {
      r.dispose();
    }
    super.dispose();
  }
}