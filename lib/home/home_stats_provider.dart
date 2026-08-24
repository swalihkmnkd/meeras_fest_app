import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class WinnerEntry {
  final String programName;
  final String studentName;
  final String teamName;
  final DateTime? judgedAt;

  WinnerEntry({
    required this.programName,
    required this.studentName,
    required this.teamName,
    required this.judgedAt,
  });
}

class TeamStanding {
  final String teamId;
  final String teamName;
  final num totalPoints;

  TeamStanding({
    required this.teamId,
    required this.teamName,
    required this.totalPoints,
  });
}

class HomeStatsProvider extends ChangeNotifier {
  final _registrationsCollection = FirebaseFirestore.instance.collection('REGISTRATIONS');
  final _teamsCollection = FirebaseFirestore.instance.collection('TEAMS');

  bool isLoading = true;
  String? errorMessage;

  List<WinnerEntry> latestWinners = [];

  /// Key = TEAM_CATEGORY as stored on the team doc (e.g. "Boys" / "Girls"),
  /// each mapped to that category's teams sorted by total points, highest
  /// first. Every team appears here even with 0 points — this is seeded
  /// from TEAMS, not from REGISTRATIONS, so nothing is missing initially.
  Map<String, List<TeamStanding>> standingsByCategory = {};

  Future<void> fetchAll() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _registrationsCollection.where('STATUS', isEqualTo: 'Published').get(),
        _teamsCollection.get(),
      ]);
      final regSnap = results[0];
      final teamSnap = results[1];

      // Team lookups, keyed by doc id AND by the TEAM_ID field (they're
      // usually the same, but this covers both just in case).
      final teamNames = <String, String>{};
      final teamCategoryOf = <String, String>{};
      // category -> teamId -> running point total, seeded to 0 for every
      // team so categories always show their full roster.
      final pointsByCategory = <String, Map<String, num>>{};

      for (final doc in teamSnap.docs) {
        final data = doc.data();
        final name = (data['TEAM_NAME'] ?? '').toString();
        final category = (data['TEAM_CATEGORY'] ?? 'Other').toString();
        final teamIdField = (data['TEAM_ID'] ?? '').toString();

        teamNames[doc.id] = name;
        teamCategoryOf[doc.id] = category;
        if (teamIdField.isNotEmpty) {
          teamNames[teamIdField] = name;
          teamCategoryOf[teamIdField] = category;
        }

        pointsByCategory.putIfAbsent(category, () => {});
        pointsByCategory[category]![doc.id] = 0;
      }

      // ---- Latest 10 rank-1 winners, most recently judged first ----
      final winners = <WinnerEntry>[];
      for (final doc in regSnap.docs) {
        final data = doc.data();
        if (data['RANK'] == 1) {
          final ts = data['judgedAt'];
          final teamId = (data['TEAM_ID'] ?? '').toString();
          winners.add(WinnerEntry(
            programName: (data['PROGRAM_NAME'] ?? '').toString(),
            studentName: (data['STUDENT_NAME'] ?? '').toString(),
            teamName: teamNames[teamId] ?? teamId,
            judgedAt: ts is Timestamp ? ts.toDate() : null,
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

      // ---- Add published points on top of the zero-seeded totals ----
      for (final doc in regSnap.docs) {
        final data = doc.data();
        final teamId = (data['TEAM_ID'] ?? '').toString();
        if (teamId.isEmpty) continue;
        final category = teamCategoryOf[teamId];
        if (category == null) continue; // registration references an unknown team
        final point = (data['POINT'] ?? 0) as num;

        pointsByCategory[category]![teamId] =
            (pointsByCategory[category]![teamId] ?? 0) + point;
      }

      final grouped = <String, List<TeamStanding>>{};
      pointsByCategory.forEach((category, teamPoints) {
        final list = teamPoints.entries
            .map((e) => TeamStanding(
          teamId: e.key,
          teamName: teamNames[e.key] ?? e.key,
          totalPoints: e.value,
        ))
            .toList()
          ..sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
        grouped[category] = list;
      });
      standingsByCategory = grouped;

      errorMessage = null;
    } catch (e) {
      errorMessage = 'Failed to load results: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}