import 'package:cloud_firestore/cloud_firestore.dart';

class ProgramModel {
  final String id; // Firestore doc id = PROGRAM_ID
  final String programName;
  final double firstScore;
  final double secondScore;
  final double thirdScore;
  final double aGradeStart;
  final double bGradeStart;
  final double cGradeStart;
  final double aGradePoint;
  final double bGradePoint;
  final double cGradePoint;
  final String studentCategory; // Boys / Girls / Mixed
  final String programCategory; // Stage / Non Stage / General
  final String? stageType; // Stage / Non Stage
  final int totalParticipants;
  final bool isGeneral; // TRUE if the selected Program Category is General
  final Timestamp? createdAt;
  // Assignment state. Not written by ProgramModel.toMap() — these are only
  // ever changed by JudgeProvider.assignProgram/unassignProgram, so normal
  // program-editing saves never touch them.
  final String status; // '' or 'ASSIGNED'
  final String assignedTo; // judge doc id, or ''

  ProgramModel({
    required this.id,
    required this.programName,
    required this.firstScore,
    required this.secondScore,
    required this.thirdScore,
    required this.aGradeStart,
    required this.bGradeStart,
    required this.cGradeStart,
    required this.aGradePoint,
    required this.bGradePoint,
    required this.cGradePoint,
    required this.studentCategory,
    required this.programCategory,
    required this.totalParticipants,
    this.stageType,
    this.isGeneral = false,
    this.createdAt,
    this.status = '',
    this.assignedTo = '',
  });

  bool get isAssigned => assignedTo.isNotEmpty;

  Map<String, dynamic> toMap() => {
    'PROGRAM_NAME': programName,
    'FIRST_SCORE': firstScore,
    'SECOND_SCORE': secondScore,
    'THIRD_SCORE': thirdScore,
    'A_GRADE_START': aGradeStart,
    'B_GRADE_START': bGradeStart,
    'C_GRADE_START': cGradeStart,
    'A_GRADE_POINT': aGradePoint,
    'B_GRADE_POINT': bGradePoint,
    'C_GRADE_POINT': cGradePoint,
    'STUDENT_CATEGORY': studentCategory,
    'PROGRAM_CATEGORY': programCategory,
    'STAGE_TYPE': stageType,
    'TOTAL_PARTICIPANTS': totalParticipants,
    'IS_GENERAL': isGeneral,
    'createdAt': createdAt ?? FieldValue.serverTimestamp(),
  };

  factory ProgramModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    double num_(dynamic v) =>
        (v is num) ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0;
    int int_(dynamic v) =>
        (v is num) ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0;
    return ProgramModel(
      id: doc.id,
      programName: data['PROGRAM_NAME'] ?? '',
      firstScore: num_(data['FIRST_SCORE']),
      secondScore: num_(data['SECOND_SCORE']),
      thirdScore: num_(data['THIRD_SCORE']),
      aGradeStart: num_(data['A_GRADE_START']),
      bGradeStart: num_(data['B_GRADE_START']),
      cGradeStart: num_(data['C_GRADE_START']),
      aGradePoint: num_(data['A_GRADE_POINT']),
      bGradePoint: num_(data['B_GRADE_POINT']),
      cGradePoint: num_(data['C_GRADE_POINT']),
      studentCategory: data['STUDENT_CATEGORY'] ?? 'Mixed',
      programCategory: data['PROGRAM_CATEGORY'] ?? 'Stage',
      stageType: data['STAGE_TYPE'] as String?,
      totalParticipants: int_(data['TOTAL_PARTICIPANTS']),
      isGeneral: data['IS_GENERAL'] ?? false,
      createdAt: data['createdAt'],
      status: (data['STATUS'] ?? '').toString(),
      assignedTo: (data['ASSIGNED_TO'] ?? '').toString(),
    );
  }

  /// Grade letter for a given mark, or null if below the C threshold.
  String? gradeForMark(double mark) {
    if (mark >= aGradeStart) return 'A';
    if (mark >= bGradeStart) return 'B';
    if (mark >= cGradeStart) return 'C';
    return null;
  }

  /// Points earned for a given mark's grade (0 if no grade).
  double gradePointsForMark(double mark) {
    final grade = gradeForMark(mark);
    switch (grade) {
      case 'A':
        return aGradePoint;
      case 'B':
        return bGradePoint;
      case 'C':
        return cGradePoint;
      default:
        return 0;
    }
  }

  /// Points for finishing 1st/2nd/3rd; 0 for anything else.
  double pointsForPosition(int position) {
    switch (position) {
      case 1:
        return firstScore;
      case 2:
        return secondScore;
      case 3:
        return thirdScore;
      default:
        return 0;
    }
  }
}