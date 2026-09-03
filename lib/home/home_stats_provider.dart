import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../admin/models/teamModel.dart';

class WinnerEntry {
  final String programName;
  final String studentName;
  final String teamName;
  final DateTime? judgedAt;
  final String photoUrl;

  WinnerEntry({
    required this.programName,
    required this.studentName,
    required this.teamName,
    required this.judgedAt,
    required this.photoUrl,
  });
}

class TeamStanding {
  final String teamId;
  final String teamName;
  final String leaderName;
  final String colorName;
  final num totalPoints;

  TeamStanding({
    required this.teamId,
    required this.teamName,
    required this.leaderName,
    required this.colorName,
    required this.totalPoints,
  });

  Color get color {
    final match = teamColorOptions.firstWhere(
          (c) => c.name.toLowerCase() == colorName.toLowerCase(),
      orElse: () => teamColorOptions.first,
    );
    return match.color;
  }
}
/// A program that currently has registrations marked STATUS == 'Assigned',
/// i.e. it's on stage / being judged right now.
class LiveProgramInfo {
  final String programId;
  final String programName;
  final List<String> participantNames;

  LiveProgramInfo({
    required this.programId,
    required this.programName,
    required this.participantNames,
  });

  int get participantCount => participantNames.length;
}

class HomeStatsProvider extends ChangeNotifier {
  final _registrationsCollection = FirebaseFirestore.instance.collection('REGISTRATIONS');
  final _teamsCollection = FirebaseFirestore.instance.collection('TEAMS');
  final _studentsCollection = FirebaseFirestore.instance.collection('STUDENTS');

  bool isLoading = true;
  String? errorMessage;

  List<WinnerEntry> latestWinners = [];

  /// Programs currently marked as "Assigned" (i.e. live / on stage now),
  /// grouped by PROGRAM_ID (falling back to PROGRAM_NAME). Kept live via
  /// a Firestore snapshot listener, so this updates the instant a judge
  /// assigns or clears a program — no refresh needed.
  List<LiveProgramInfo> livePrograms = [];

  /// Key = TEAM_CATEGORY as stored on the team doc (e.g. "Boys" / "Girls"),
  /// each mapped to that category's teams sorted by total points, highest
  /// first. Every team appears here even with 0 points — this is seeded
  /// from TEAMS, not from REGISTRATIONS, so nothing is missing initially.
  /// Also kept live: any published result updates the totals instantly.
  Map<String, List<TeamStanding>> standingsByCategory = {};

  // ---- Real-time plumbing ----
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _teamsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _publishedSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _assignedSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _studentsSub;

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _teamDocs = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _publishedDocs = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _assignedDocs = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _studentDocs = [];

  bool _teamsLoaded = false;
  bool _publishedLoaded = false;
  bool _assignedLoaded = false;
  bool _studentsLoaded = false;
  bool _listening = false;

  /// Starts real-time listeners on TEAMS, STUDENTS, and on REGISTRATIONS
  /// (split into the 'Published' and 'Assigned' STATUS queries). Every
  /// listener re-runs [_recompute] on any change, so latestWinners,
  /// livePrograms, and standingsByCategory all stay in sync with Firestore
  /// instantly — no manual re-fetching required anywhere this provider is
  /// used.
  ///
  /// Safe to call more than once (e.g. if a widget rebuilds); listeners
  /// are only ever set up a single time per provider instance.
  Future<void> fetchAll() async {
    if (_listening) return;
    _listening = true;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    _teamsSub = _teamsCollection.snapshots().listen((snap) {
      _teamDocs = snap.docs;
      _teamsLoaded = true;
      _recompute();
    }, onError: (e) {
      errorMessage = 'Failed to load teams: $e';
      _teamsLoaded = true;
      _recompute();
    });

    _studentsSub = _studentsCollection.snapshots().listen((snap) {
      _studentDocs = snap.docs;
      _studentsLoaded = true;
      _recompute();
    }, onError: (e) {
      errorMessage = 'Failed to load students: $e';
      _studentsLoaded = true;
      _recompute();
    });

    _publishedSub = _registrationsCollection
        .where('STATUS', isEqualTo: 'Published')
        .snapshots()
        .listen((snap) {
      _publishedDocs = snap.docs;
      _publishedLoaded = true;
      _recompute();
    }, onError: (e) {
      errorMessage = 'Failed to load results: $e';
      _publishedLoaded = true;
      _recompute();
    });

    _assignedSub = _registrationsCollection
        .where('STATUS', isEqualTo: 'Assigned')
        .snapshots()
        .listen((snap) {
      _assignedDocs = snap.docs;
      _assignedLoaded = true;
      _recompute();
    }, onError: (e) {
      errorMessage = 'Failed to load live programs: $e';
      _assignedLoaded = true;
      _recompute();
    });
  }

  /// Rebuilds latestWinners / livePrograms / standingsByCategory from
  /// whatever the four listeners currently hold. Called after every
  /// snapshot from any of them, so a change in just one collection (say,
  /// a single registration flipping to 'Assigned') still recomputes
  /// everything derived from the latest combined state.
  void _recompute() {
    // Still waiting on the first snapshot from one or more listeners.
    if (!_teamsLoaded || !_publishedLoaded || !_assignedLoaded || !_studentsLoaded) {
      notifyListeners();
      return;
    }

    try {
      final teamNames = <String, String>{};
      final teamCategoryOf = <String, String>{};
      final teamLeaderOf = <String, String>{};
      final teamColorOf = <String, String>{};
      final pointsByCategory = <String, Map<String, num>>{};

      for (final doc in _teamDocs) {
        final data = doc.data();
        final name = (data['TEAM_NAME'] ?? '').toString();
        final category = (data['TEAM_CATEGORY'] ?? 'Other').toString();
        final teamIdField = (data['TEAM_ID'] ?? '').toString();
        final leaderName = (data['TEAM_LEADER'] ?? '').toString();
        final colorName = (data['TEAM_COLOR'] ?? '').toString();

        teamNames[doc.id] = name;
        teamCategoryOf[doc.id] = category;
        teamLeaderOf[doc.id] = leaderName;
        teamColorOf[doc.id] = colorName;
        if (teamIdField.isNotEmpty) {
          teamNames[teamIdField] = name;
          teamCategoryOf[teamIdField] = category;
          teamLeaderOf[teamIdField] = leaderName;
          teamColorOf[teamIdField] = colorName;
        }

        pointsByCategory.putIfAbsent(category, () => {});
        pointsByCategory[category]![doc.id] = 0;
      }

      // STUDENT_ID -> PHOTO_URL, so winners can show the student's photo.
      final studentPhotos = <String, String>{
        for (final doc in _studentDocs) doc.id: (doc.data()['PHOTO_URL'] ?? '').toString(),
      };

      // ---- Latest 10 rank-1 winners, most recently judged first ----
      final winners = <WinnerEntry>[];
      for (final doc in _publishedDocs) {
        final data = doc.data();
        if (data['RANK'] == 1) {
          final ts = data['judgedAt'];
          final teamId = (data['TEAM_ID'] ?? '').toString();
          final studentId = (data['STUDENT_ID'] ?? '').toString();
          winners.add(WinnerEntry(
            programName: (data['PROGRAM_NAME'] ?? '').toString(),
            studentName: (data['STUDENT_NAME'] ?? '').toString(),
            teamName: teamNames[teamId] ?? teamId,
            judgedAt: ts is Timestamp ? ts.toDate() : null,
            photoUrl: studentPhotos[studentId] ?? '',
          ));
        }
      }
      winners.sort((a, b) {
        if (a.judgedAt == null && b.judgedAt == null) return 0;
        if (a.judgedAt == null) return 1;
        if (b.judgedAt == null) return -1;
        return b.judgedAt!.compareTo(a.judgedAt!);
      });
      latestWinners = winners.take(10).toList();

      // ---- Live programs (STATUS == 'Assigned'), grouped by program ----
      final liveByProgram = <String, List<String>>{};
      final liveProgramNames = <String, String>{};
      for (final doc in _assignedDocs) {
        final data = doc.data();
        final programId = (data['PROGRAM_ID'] ?? '').toString();
        final programName = (data['PROGRAM_NAME'] ?? '').toString();
        final studentName = (data['STUDENT_NAME'] ?? '').toString();
        final key = programId.isNotEmpty ? programId : programName;
        if (key.isEmpty) continue;

        liveProgramNames.putIfAbsent(key, () => programName);
        liveByProgram.putIfAbsent(key, () => []);
        if (studentName.isNotEmpty) {
          liveByProgram[key]!.add(studentName);
        }
      }
      livePrograms = liveByProgram.entries
          .map((e) => LiveProgramInfo(
        programId: e.key,
        programName: liveProgramNames[e.key] ?? e.key,
        participantNames: e.value,
      ))
          .toList()
        ..sort((a, b) => a.programName.compareTo(b.programName));

      // ---- Add published points on top of the zero-seeded totals ----
      // For IS_GENERAL registrations, multiple students from the same team
      // can be registered under the same PROGRAM_ID (e.g. group items under
      // a "General" program category). In that case the team should only be
      // credited once for that team+program combination, not once per
      // student — so we track which (teamId, programId) general pairs have
      // already contributed points and skip the rest.
      final generalCounted = <String>{};
      for (final doc in _publishedDocs) {
        final data = doc.data();
        final teamId = (data['TEAM_ID'] ?? '').toString();
        if (teamId.isEmpty) continue;
        final category = teamCategoryOf[teamId];
        if (category == null) continue; // registration references an unknown team
        final point = (data['POINT'] ?? 0) as num;
        final programId = (data['PROGRAM_ID'] ?? '').toString();
        final isGeneral = data['IS_GENERAL'] == true;

        if (isGeneral) {
          final key = '$teamId|$programId';
          if (generalCounted.contains(key)) {
            continue; // already added this team's points for this general program
          }
          generalCounted.add(key);
        }

        pointsByCategory[category]![teamId] =
            (pointsByCategory[category]![teamId] ?? 0) + point;
      }

      final grouped = <String, List<TeamStanding>>{};
      pointsByCategory.forEach((category, teamPoints) {
        final list = teamPoints.entries
            .map((e) => TeamStanding(
          teamId: e.key,
          teamName: teamNames[e.key] ?? e.key,
          leaderName: teamLeaderOf[e.key] ?? '',
          colorName: teamColorOf[e.key] ?? '',
          totalPoints: e.value,
        ))
            .toList()
          ..sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
        grouped[category] = list;
      });
      standingsByCategory = grouped;

      errorMessage = null;
    } catch (e) {
      errorMessage = 'Failed to process results: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _teamsSub?.cancel();
    _publishedSub?.cancel();
    _assignedSub?.cancel();
    _studentsSub?.cancel();
    super.dispose();
  }
}