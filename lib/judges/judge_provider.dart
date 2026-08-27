import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../admin/models/judgesModel.dart';
import '../admin/models/programModel.dart';

/// A program assigned to the logged-in judge, with its grading rules
/// read dynamically from whatever *_GRADE_START / *_GRADE_POINT fields
/// exist on the PROGRAMS doc (works for A/B/C or any other grade set).
class AssignedProgram {
  final String id;
  final String name;
  final String category;
  final String studentCategory;
  final String stageType;
  final bool isGeneral;
  final num firstScore;
  final num secondScore;
  final num thirdScore;
  final Map<String, num> gradeStarts;
  final Map<String, num> gradePoints;

  AssignedProgram({
    required this.id,
    required this.name,
    required this.category,
    required this.studentCategory,
    required this.stageType,
    required this.isGeneral,
    required this.firstScore,
    required this.secondScore,
    required this.thirdScore,
    required this.gradeStarts,
    required this.gradePoints,
  });

  factory AssignedProgram.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final gradeStarts = <String, num>{};
    final gradePoints = <String, num>{};

    data.forEach((key, value) {
      if (value is num) {
        if (key.endsWith('_GRADE_START')) {
          gradeStarts[key.substring(0, key.length - '_GRADE_START'.length)] = value;
        } else if (key.endsWith('_GRADE_POINT')) {
          gradePoints[key.substring(0, key.length - '_GRADE_POINT'.length)] = value;
        }
      }
    });

    return AssignedProgram(
      id: doc.id,
      name: (data['PROGRAM_NAME'] ?? '').toString(),
      category: (data['PROGRAM_CATEGORY'] ?? '').toString(),
      studentCategory: (data['STUDENT_CATEGORY'] ?? '').toString(),
      stageType: (data['STAGE_TYPE'] ?? '').toString(),
      isGeneral: data['IS_GENERAL'] == true,
      firstScore: (data['FIRST_SCORE'] ?? 0) as num,
      secondScore: (data['SECOND_SCORE'] ?? 0) as num,
      thirdScore: (data['THIRD_SCORE'] ?? 0) as num,
      gradeStarts: gradeStarts,
      gradePoints: gradePoints,
    );
  }

  /// Highest grade whose threshold [score] meets, e.g. {A:90,B:80,C:70}
  /// with a score of 85 returns 'B'. Empty string if no thresholds are set.
  String gradeFor(num score) {
    final letters = gradeStarts.keys.toList()
      ..sort((a, b) => gradeStarts[b]!.compareTo(gradeStarts[a]!));
    for (final letter in letters) {
      if (score >= gradeStarts[letter]!) return letter;
    }
    return letters.isEmpty ? '' : letters.last;
  }

  num gradePointFor(String grade) => gradePoints[grade] ?? 0;
}

/// One registered student under the currently-open program, plus their
/// live score-entry state.
class RegistrationScore {
  final String id; // REGISTRATIONS doc id
  final String studentName;
  final String studentCategory;
  final String teamId;
  final String registerNumber;
  num score;
  String grade;
  int? rank;
  num placePoint;
  num totalPoint;
  bool judged;
  final String status; // '', 'Assigned', 'Resulted', 'Published'
  final TextEditingController controller;

  RegistrationScore({
    required this.id,
    required this.studentName,
    required this.studentCategory,
    required this.teamId,
    required this.registerNumber,
    required this.score,
    required this.grade,
    required this.rank,
    required this.placePoint,
    required this.totalPoint,
    required this.judged,
    required this.status,
  }) : controller = TextEditingController(text: judged ? score.toString() : '');

  factory RegistrationScore.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final judged = (data['JUDGED_BY'] ?? '').toString().isNotEmpty;
    return RegistrationScore(
      id: doc.id,
      studentName: (data['STUDENT_NAME'] ?? '').toString(),
      studentCategory: (data['STUDENT_CATEGORY'] ?? '').toString(),
      teamId: (data['TEAM_ID'] ?? '').toString(),
      registerNumber: (data['REGISTER_NUMBER'] ?? '').toString(),
      score: (data['SCORE'] ?? 0) as num,
      grade: (data['GRADE'] ?? '').toString(),
      rank: data['RANK'] is int ? data['RANK'] as int : null,
      placePoint: (data['PLACE_POINT'] ?? 0) as num,
      totalPoint: (data['POINT'] ?? 0) as num,
      judged: judged,
      status: (data['STATUS'] ?? '').toString(),
    );
  }

  void dispose() => controller.dispose();
}

class JudgeProvider extends ChangeNotifier {
  // ================= Admin: manage judges =================
  final _collection = FirebaseFirestore.instance.collection('judges');
  final _programsCollection = FirebaseFirestore.instance.collection('PROGRAMS');

  List<JudgeModel> judges = [];
  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;

  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController usernameCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();
  String? _editingId;

  bool get isEditing => _editingId != null;
  String? get editingId => _editingId;

  String? lastSavedId;
  String? lastSavedName;

  // ---- Programs cache, shared by "assigned programs" display + assign screen ----
  Map<String, ProgramModel> programsById = {};
  bool isLoadingProgramsCache = false;

  Future<void> fetchJudges() async {
    isLoading = true;
    notifyListeners();
    try {
      final judgeSnap =
      await _collection.orderBy('createdAt', descending: true).get();
      judges = judgeSnap.docs.map((d) => JudgeModel.fromDoc(d)).toList();
      errorMessage = null;
    } catch (e) {
      errorMessage = 'Failed to load judges: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Loads every program once so the judges list can show assigned-program
  /// names, and the assign screen can filter by category without a query
  /// per keystroke. Call alongside fetchJudges().
  Future<void> fetchProgramsCache() async {
    isLoadingProgramsCache = true;
    notifyListeners();
    try {
      final snap = await _programsCollection.get();
      programsById = {for (final d in snap.docs) d.id: ProgramModel.fromDoc(d)};
    } catch (e) {
      errorMessage = 'Failed to load programs: $e';
    } finally {
      isLoadingProgramsCache = false;
      notifyListeners();
    }
  }

  /// Programs currently assigned to [judgeId], looked up from the cache.
  List<ProgramModel> programsForJudge(String judgeId) {
    final matches = judges.where((j) => j.id == judgeId);
    if (matches.isEmpty) return [];
    final judge = matches.first;
    return judge.assignedProgramIds
        .map((id) => programsById[id])
        .whereType<ProgramModel>()
        .toList();
  }

  void startCreate() {
    _editingId = null;
    nameCtrl.clear();
    phoneCtrl.clear();
    emailCtrl.clear();
    usernameCtrl.clear();
    passwordCtrl.clear();
    lastSavedId = null;
    lastSavedName = null;
    notifyListeners();
  }

  void startEdit(JudgeModel judge) {
    _editingId = judge.id;
    nameCtrl.text = judge.name;
    phoneCtrl.text = judge.phone;
    emailCtrl.text = judge.email;
    usernameCtrl.text = judge.userName ?? '';
    passwordCtrl.text = judge.password ?? '';
    notifyListeners();
  }

  Future<String?> save() async {
    if (nameCtrl.text.trim().isEmpty) return 'Judge name is required';
    if (usernameCtrl.text.trim().isEmpty) return 'Username is required';
    if (!isEditing && passwordCtrl.text.trim().isEmpty) {
      return 'Password is required';
    }

    isSaving = true;
    notifyListeners();
    try {
      final data = <String, dynamic>{
        'NAME': nameCtrl.text.trim(),
        'PHONE': phoneCtrl.text.trim(),
        'EMAIL': emailCtrl.text.trim(),
        'USER_NAME': usernameCtrl.text.trim(),
      };
      if (passwordCtrl.text.trim().isNotEmpty) {
        data['PASSWORD'] = passwordCtrl.text.trim();
      }

      if (_editingId == null) {
        data['createdAt'] = FieldValue.serverTimestamp();
        data['ASSIGNED_PROGRAM_IDS'] = <String>[];
        final docRef = await _collection.add(data);
        lastSavedId = docRef.id;
      } else {
        await _collection.doc(_editingId).update(data);
        lastSavedId = _editingId;
      }
      lastSavedName = nameCtrl.text.trim();
      return null;
    } catch (e) {
      return 'Failed to save judge: $e';
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  /// Deletes the judge, and first clears STATUS/ASSIGNED_TO on every program
  /// still pointing at them — queried directly from PROGRAMS (not just the
  /// judge's own ASSIGNED_PROGRAM_IDS array) so cleanup is correct even if
  /// that array ever drifted out of sync.
  Future<String?> deleteJudge(String id) async {
    try {
      final assignedSnap =
      await _programsCollection.where('ASSIGNED_TO', isEqualTo: id).get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in assignedSnap.docs) {
        batch.update(doc.reference, {'STATUS': '', 'ASSIGNED_TO': ''});
      }
      batch.delete(_collection.doc(id));
      await batch.commit();

      judges.removeWhere((j) => j.id == id);
      for (final doc in assignedSnap.docs) {
        final existing = programsById[doc.id];
        if (existing != null) {
          programsById[doc.id] = ProgramModel(
            id: existing.id,
            programName: existing.programName,
            firstScore: existing.firstScore,
            secondScore: existing.secondScore,
            thirdScore: existing.thirdScore,
            aGradeStart: existing.aGradeStart,
            bGradeStart: existing.bGradeStart,
            cGradeStart: existing.cGradeStart,
            aGradePoint: existing.aGradePoint,
            bGradePoint: existing.bGradePoint,
            cGradePoint: existing.cGradePoint,
            studentCategory: existing.studentCategory,
            programCategory: existing.programCategory,
            stageType: existing.stageType,
            totalParticipants: existing.totalParticipants,
            isGeneral: existing.isGeneral,
            createdAt: existing.createdAt,
            status: '',
            assignedTo: '',
          );
        }
      }
      notifyListeners();
      return null;
    } catch (e) {
      return 'Failed to delete judge: $e';
    }
  }

  /// Assigns [programId] to [judgeId]: sets STATUS/ASSIGNED_TO on the
  /// program and adds the id to the judge's ASSIGNED_PROGRAM_IDS array,
  /// both in a single batch so they can't drift out of sync.
  ///
  /// ⬅️ NEW: also sets STATUS = 'Assigned' on every REGISTRATIONS doc
  /// matching this PROGRAM_ID, so it's visible that those students are now
  /// up for judging. Registrations already 'Resulted' or 'Published' (i.e.
  /// already judged) are left untouched — assigning a program shouldn't
  /// erase existing results.
  Future<String?> assignProgram(String judgeId, String programId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      batch.update(_programsCollection.doc(programId), {
        'STATUS': 'ASSIGNED',
        'ASSIGNED_TO': judgeId,
      });
      batch.update(_collection.doc(judgeId), {
        'ASSIGNED_PROGRAM_IDS': FieldValue.arrayUnion([programId]),
      });

      final regSnap = await _registrationsCollection
          .where('PROGRAM_ID', isEqualTo: programId)
          .get();
      for (final doc in regSnap.docs) {
        final status = (doc.data()['STATUS'] ?? '').toString();
        if (status == 'Resulted' || status == 'Published') continue;
        batch.update(doc.reference, {'STATUS': 'Assigned'});
      }

      await batch.commit();
      await Future.wait([fetchJudges(), fetchProgramsCache()]);
      return null;
    } catch (e) {
      return 'Failed to assign program: $e';
    }
  }

  /// Reverses assignProgram: clears STATUS/ASSIGNED_TO on the program and
  /// removes the id from the judge's ASSIGNED_PROGRAM_IDS array.
  ///
  /// ⬅️ NEW: also reverts STATUS back to '' on this program's registrations
  /// — but only the ones still sitting at 'Assigned'. Registrations that
  /// already moved on to 'Resulted' or 'Published' are left as-is, since
  /// unassigning shouldn't undo work a judge already did.
  Future<String?> unassignProgram(String judgeId, String programId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      batch.update(_programsCollection.doc(programId), {
        'STATUS': '',
        'ASSIGNED_TO': '',
      });
      batch.update(_collection.doc(judgeId), {
        'ASSIGNED_PROGRAM_IDS': FieldValue.arrayRemove([programId]),
      });

      final regSnap = await _registrationsCollection
          .where('PROGRAM_ID', isEqualTo: programId)
          .get();
      for (final doc in regSnap.docs) {
        final status = (doc.data()['STATUS'] ?? '').toString();
        if (status != 'Assigned') continue;
        batch.update(doc.reference, {'STATUS': ''});
      }

      await batch.commit();
      await Future.wait([fetchJudges(), fetchProgramsCache()]);
      return null;
    } catch (e) {
      return 'Failed to unassign program: $e';
    }
  }

  // ================= Judge panel: assigned programs & scoring =================
  final _registrationsCollection =
  FirebaseFirestore.instance.collection('REGISTRATIONS');

  List<AssignedProgram> assignedPrograms = [];
  bool isLoadingPrograms = false;
  String? programsError;

  AssignedProgram? selectedProgram;
  List<RegistrationScore> registrations = [];
  bool isLoadingRegistrations = false;
  String? registrationsError;

  final Map<String, bool> _savingScore = {};
  bool isSavingScore(String registrationId) => _savingScore[registrationId] ?? false;

  /// Registrations to actually show in the scoring list. For a General
  /// program, several students from the same team can be registered under
  /// the same PROGRAM_ID — only one card per team is shown in that case
  /// (first occurrence wins). Non-general programs show every registration
  /// as before.
  List<RegistrationScore> get displayedRegistrations {
    final program = selectedProgram;
    if (program == null || !program.isGeneral) return registrations;

    final seenTeamIds = <String>{};
    final result = <RegistrationScore>[];
    for (final r in registrations) {
      if (seenTeamIds.add(r.teamId)) {
        result.add(r);
      }
    }
    return result;
  }

  int get submittedCount => displayedRegistrations.where((r) => r.judged).length;

  Future<void> fetchAssignedPrograms(String judgeId) async {
    if (judgeId.isEmpty) {
      programsError = 'No judge id found — please log in again.';
      notifyListeners();
      return;
    }
    isLoadingPrograms = true;
    programsError = null;
    notifyListeners();
    try {
      final snap = await _programsCollection
          .where('ASSIGNED_TO', isEqualTo: judgeId)
          .get();
      assignedPrograms = snap.docs.map(AssignedProgram.fromDoc).toList();
    } catch (e) {
      programsError = 'Failed to load assigned programs: $e';
    } finally {
      isLoadingPrograms = false;
      notifyListeners();
    }
  }

  Future<void> openProgram(AssignedProgram program) async {
    selectedProgram = program;
    isLoadingRegistrations = true;
    registrationsError = null;
    for (final r in registrations) {
      r.dispose();
    }
    registrations = [];
    notifyListeners();
    try {
      final snap = await _registrationsCollection
          .where('PROGRAM_ID', isEqualTo: program.id)
          .get();
      // ⬅️ NEW: once the admin has published a result, it's final — it
      // no longer shows (or can be re-scored) in the judge panel.
      registrations = snap.docs
          .map(RegistrationScore.fromDoc)
          .where((r) => r.status != 'Published')
          .toList()
        ..sort((a, b) => a.registerNumber.compareTo(b.registerNumber));
    } catch (e) {
      registrationsError = 'Failed to load registrations: $e';
    } finally {
      isLoadingRegistrations = false;
      notifyListeners();
    }
  }

  void closeProgram() {
    for (final r in registrations) {
      r.dispose();
    }
    registrations = [];
    selectedProgram = null;
    notifyListeners();
  }

  void updateScoreInput(RegistrationScore reg, String value) {
    num score = num.tryParse(value) ?? 0;
    if (score < 0) score = 0;
    if (score > 100) score = 100;
    reg.score = score;
    notifyListeners();
  }

  /// Saves this student's score, computes their grade, then re-ranks
  /// every judged student in the current program by score (standard
  /// competition ranking — ties share a rank) and writes rank + points
  /// back to Firestore for all of them, not just the one just entered.
  Future<String?> saveScore(String judgeId, RegistrationScore reg) async {
    final program = selectedProgram;
    if (program == null) return 'No program selected';

    _savingScore[reg.id] = true;
    notifyListeners();
    try {
      reg.grade = program.gradeFor(reg.score);
      reg.judged = true;

      final judged = registrations.where((r) => r.judged).toList()
        ..sort((a, b) => b.score.compareTo(a.score));

      int currentRank = 0;
      num? previousScore;
      for (var i = 0; i < judged.length; i++) {
        final r = judged[i];
        if (previousScore == null || r.score != previousScore) {
          currentRank = i + 1;
        }
        r.rank = currentRank;
        previousScore = r.score;

        r.placePoint = switch (r.rank) {
          1 => program.firstScore,
          2 => program.secondScore,
          3 => program.thirdScore,
          _ => 0,
        };
        r.totalPoint = program.gradePointFor(r.grade) + r.placePoint;
      }

      final batch = FirebaseFirestore.instance.batch();
      for (final r in judged) {
        batch.update(_registrationsCollection.doc(r.id), {
          'SCORE': r.score,
          'GRADE': r.grade,
          'RANK': r.rank,
          'PLACE_POINT': r.placePoint,
          'POINT': r.totalPoint,
          'JUDGED_BY': judgeId,
          'STATUS':"Resulted",
          'judgedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      notifyListeners();
      return null;
    } catch (e) {
      return 'Failed to save score: $e';
    } finally {
      _savingScore[reg.id] = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
    usernameCtrl.dispose();
    passwordCtrl.dispose();
    for (final r in registrations) {
      r.dispose();
    }
    super.dispose();
  }
}