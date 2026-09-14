import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/programModel.dart';

/// One judged registration — either still pending ('Resulted') or already
/// live ('Published') — editable by the admin either way.
class PendingResult {
  final String id; // REGISTRATIONS doc id
  final String programId;
  final String programName;
  final String studentName;
  final String teamId;
  final String teamName; // joined from TEAMS, shown instead of studentName for General programs
  final String registerNumber;
  final bool isGeneral;
  num score;
  String grade;
  int? rank;
  num placePoint;
  num totalPoint;
  // ⬅️ NEW — 'Resulted' or 'Published'. Drives which tab this row shows
  // under; flipped locally (no re-fetch needed) whenever publish/republish
  // succeeds.
  String status;
  final TextEditingController scoreController;

  PendingResult({
    required this.id,
    required this.programId,
    required this.programName,
    required this.studentName,
    required this.teamId,
    required this.teamName,
    required this.registerNumber,
    required this.isGeneral,
    required this.score,
    required this.grade,
    required this.rank,
    required this.placePoint,
    required this.totalPoint,
    required this.status, // ⬅️ NEW
  }) : scoreController = TextEditingController(text: score.toString());

  bool get isPublished => status == 'Published';

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
      teamName: teamNames[teamId] ?? teamId,
      registerNumber: (data['REGISTER_NUMBER'] ?? '').toString(),
      isGeneral: data['IS_GENERAL'] == true,
      score: (data['SCORE'] ?? 0) as num,
      grade: (data['GRADE'] ?? '').toString(),
      rank: data['RANK'] is int ? data['RANK'] as int : null,
      placePoint: (data['PLACE_POINT'] ?? 0) as num,
      totalPoint: (data['POINT'] ?? 0) as num,
      status: (data['STATUS'] ?? '').toString(), // ⬅️ NEW
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

/// A program's worth of results (pending OR published — the caller
/// decides which by pre-filtering), grouped so the whole program
/// publishes/republishes together — never just one student's row.
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
  final _teamsCollection = FirebaseFirestore.instance.collection('TEAMS');

  // ⬅️ RENAMED IN SPIRIT ONLY (kept the field name `pendingResults` so
  // nothing else that reads it needs churn) — this now holds BOTH
  // 'Resulted' and 'Published' registrations together. Use
  // pendingByProgram / publishedByProgram below to see just one status.
  List<PendingResult> pendingResults = [];
  Map<String, ProgramModel> _programsById = {};
  bool isLoading = false;
  String? errorMessage;

  final Map<String, bool> _publishingProgram = {};
  bool isPublishingProgram(String programId) => _publishingProgram[programId] ?? false;

  final Map<String, bool> _savingEdit = {};
  bool isSavingEdit(String id) => _savingEdit[id] ?? false;

  List<ProgramResultsGroup> _groupBy(Iterable<PendingResult> rows) {
    final byProgram = <String, List<PendingResult>>{};
    for (final r in rows) {
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

  /// Still-pending results grouped by program — same shape/behavior as
  /// before this change, just now filtered out of a combined list rather
  /// than being the only thing fetched.
  List<ProgramResultsGroup> get pendingByProgram =>
      _groupBy(pendingResults.where((r) => r.status != 'Published'));

  /// ⬅️ NEW — already-live results grouped by program, so the admin can
  /// review what's currently on the TV/app and, if needed, edit a score
  /// and republish.
  List<ProgramResultsGroup> get publishedByProgram =>
      _groupBy(pendingResults.where((r) => r.status == 'Published'));

  /// Whether "Publish All" (which only ever touches still-pending rows)
  /// has anything to do.
  bool get hasPendingResults => pendingByProgram.isNotEmpty;

  Future<void> fetchPending() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final results0 = await Future.wait([
        // ⬅️ CHANGED — fetch both statuses in one query instead of just
        // 'Resulted', so published results are visible (and editable) too.
        _registrationsCollection.where('STATUS', whereIn: ['Resulted', 'Published']).get(),
        _programsCollection.get(),
        _teamsCollection.get(),
      ]);

      final snap = results0[0] as QuerySnapshot<Map<String, dynamic>>;
      final programSnap = results0[1] as QuerySnapshot<Map<String, dynamic>>;
      final teamsSnap = results0[2] as QuerySnapshot<Map<String, dynamic>>;

      // TEAM_ID -> name, same join pattern ResultProvider uses.
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
  /// ⬅️ FIXED — previously, if this program had no matching ProgramModel
  /// in `_programsById` (e.g. a PROGRAM_ID mismatch, or the program doc
  /// was missing/deleted), this method took an early "no grading rules
  /// available" shortcut that saved SCORE alone and returned — skipping
  /// the entire re-rank pass. That meant RANK never updated even for a
  /// maximum/top score, because rank was silently never recomputed.
  /// Rank is purely a function of relative score and never actually
  /// depended on program config, so the ranking pass below now always
  /// runs regardless of whether `program` resolves. Only grade and
  /// place-points (which DO need program thresholds) fall back to
  /// blank/zero when program config is missing — rank is unaffected.
  ///
  /// STATUS is intentionally left untouched for every row: this can
  /// re-rank a mix of 'Resulted' and already-'Published' registrations
  /// (since a swapped rank affects the whole program, not just the row
  /// being edited) without silently publishing or un-publishing anything.
  /// If a published program's scores change here, use publishProgram()
  /// (shown as "Republish" in the UI for already-published groups) to
  /// push the edited values live — they're already saved either way, but
  /// republishing is the deliberate "yes, show this update" step.
  Future<String?> saveEdit(PendingResult result) async {
    _savingEdit[result.id] = true;
    notifyListeners();
    try {
      // May be null if this program's config wasn't found (mismatched or
      // missing PROGRAM_ID). No longer short-circuits ranking — see note
      // above. Grade/place-point calculation below degrades gracefully.
      final program = _programsById[result.programId];

      final snap = await _registrationsCollection
          .where('PROGRAM_ID', isEqualTo: result.programId)
          .get();

      final rows = <_RankRow>[];
      for (final doc in snap.docs) {
        final data = doc.data();
        // ⬅️ FIXED — previously skipped any sibling whose JUDGED_BY was
        // empty (unless it was the row being edited), which silently
        // excluded scores entered directly on this admin screen (not via
        // the Judge panel) from the ranking pool. Excluded rows never got
        // their RANK rewritten, so they kept stale values forever, and
        // the remaining pool could rank two different scores as tied.
        // Every registration returned for this PROGRAM_ID is already
        // 'Resulted' or 'Published' (see fetchPending's query), so all of
        // them belong in the ranking pool — no JUDGED_BY gate needed here.
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
      // ⬅️ CHANGED — dense ranking: the next distinct score always
      // advances the rank by exactly 1 (1,1,2,2,3), instead of skipping
      // ahead by the size of the previous tie group (1,1,3,3,5). Only the
      // "does the score differ from the previous one" check matters here;
      // the increment itself no longer depends on the row's index `i`.
      // ⬅️ FIXED — previously these maps were ALWAYS keyed by `r.teamId`,
      // even for non-General (individual) programs. For an individual
      // program, `teamId` is just the student's real-life house/team —
      // completely unrelated to competition grouping — so two different
      // students who happen to belong to the same house would collide on
      // the same map key. Whichever of them was processed last in this
      // loop silently overwrote the other's rank/grade/points, which is
      // exactly why unrelated students with different scores ended up
      // sharing one rank. Only General programs should share a key across
      // multiple registrations (one shared team result); individual
      // programs must key by each registration's own id.
      String keyFor(_RankRow r) => result.isGeneral ? r.teamId : r.id;

      final rankByKey = <String, int>{};
      final gradeByKey = <String, String>{};
      final placePointByKey = <String, num>{};
      final totalPointByKey = <String, num>{};

      for (var i = 0; i < forRanking.length; i++) {
        final r = forRanking[i];
        if (previousScore == null || r.score != previousScore) {
          currentRank = previousScore == null ? 1 : currentRank + 1;
        }
        previousScore = r.score;

        // Grade/place-point/total-point need program thresholds — degrade
        // to blank/zero if program config is missing. RANK above does NOT
        // depend on any of this; it's already been assigned from pure
        // score ordering regardless of `program`.
        String grade = '';
        num gradePoint = 0;
        num placePoint = 0;

        if (program != null) {
          if (r.score >= program.aGradeStart) {
            grade = 'A';
          } else if (r.score >= program.bGradeStart) {
            grade = 'B';
          } else if (r.score >= program.cGradeStart) {
            grade = 'C';
          }
          gradePoint = switch (grade) {
            'A' => program.aGradePoint,
            'B' => program.bGradePoint,
            'C' => program.cGradePoint,
            _ => 0,
          };
          placePoint = switch (currentRank) {
            1 => program.firstScore,
            2 => program.secondScore,
            3 => program.thirdScore,
            _ => 0,
          };
        }

        final key = keyFor(r);
        rankByKey[key] = currentRank;
        gradeByKey[key] = grade;
        placePointByKey[key] = placePoint;
        totalPointByKey[key] = gradePoint + placePoint;
      }

      // Apply the computed values back onto every row. For General
      // programs every registration on the same team shares its team's
      // key and therefore its team's values, by design. For individual
      // programs each row has its own unique key (its own id), so each
      // student's own rank/grade/points are applied — never a teammate's.
      for (final r in rows) {
        final key = keyFor(r);
        r.rank = rankByKey[key] ?? 0;
        r.grade = gradeByKey[key] ?? '';
        r.placePoint = placePointByKey[key] ?? 0;
        r.totalPoint = totalPointByKey[key] ?? 0;
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

        // Keep any other still-visible cards (pending OR published) in
        // sync so the admin sees the rank swap immediately, without a
        // full re-fetch. This also updates hidden teammate entries, so
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

  /// Publishes (or **republishes**, if already live) every registration
  /// under [programId] together, in one batch — so a program is never
  /// left partially published. Safe to call again on an already-
  /// published program: it just re-affirms STATUS: 'Published' and stamps
  /// a fresh REPUBLISHED_AT, which is what pushes an edited score out to
  /// the TV/app after the admin changes it post-publish.
  ///
  /// ⬅️ CHANGED — no longer removes rows from `pendingResults`. Instead it
  /// flips each row's local `status` to 'Published', which is what moves
  /// the program from the Pending tab to the Published tab (and keeps it
  /// there, still editable, if it was already published).
  Future<String?> publishProgram(String programId) async {
    final group = pendingResults.where((r) => r.programId == programId).toList();
    if (group.isEmpty) return null;

    _publishingProgram[programId] = true;
    notifyListeners();
    try {
      final wasAlreadyPublished = group.every((r) => r.status == 'Published');
      final batch = FirebaseFirestore.instance.batch();
      for (final r in group) {
        batch.update(_registrationsCollection.doc(r.id), {
          'STATUS': 'Published',
          // Only stamped on a genuine republish (editing after going
          // live) — leaves the original PUBLISHED_AT-style timestamp
          // from JudgeProvider/first publish untouched otherwise.
          if (wasAlreadyPublished) 'REPUBLISHED_AT': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      for (final r in group) {
        r.status = 'Published';
      }
      notifyListeners();
      return null;
    } catch (e) {
      return 'Failed to publish program: $e';
    } finally {
      _publishingProgram[programId] = false;
      notifyListeners();
    }
  }

  /// Publishes everything currently **pending** (status != 'Published'),
  /// across every program, in one batch — a bulk convenience on top of
  /// publishProgram(), not a way to publish a single row. Already-
  /// published groups are untouched by this — use the per-program
  /// "Republish" action for those.
  Future<String?> publishAll() async {
    final toPublish = pendingResults.where((r) => r.status != 'Published').toList();
    if (toPublish.isEmpty) return null;
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final r in toPublish) {
        batch.update(_registrationsCollection.doc(r.id), {'STATUS': 'Published'});
      }
      await batch.commit();
      for (final r in toPublish) {
        r.status = 'Published';
      }
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