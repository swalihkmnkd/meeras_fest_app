import 'package:cloud_firestore/cloud_firestore.dart';

class RegistrationModel {
  final String id;
  final String studentId;
  final String studentName;
  final String teamId;
  final String programId;
  final String programName;
  final String studentCategory;
  final String programType; // Stage / Non-Stage / General
  final Timestamp? createdAt;

  RegistrationModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.teamId,
    required this.programId,
    required this.programName,
    required this.studentCategory,
    required this.programType,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'STUDENT_ID': studentId,
    'STUDENT_NAME': studentName,
    'TEAM_ID': teamId,
    'PROGRAM_ID': programId,
    'PROGRAM_NAME': programName,
    'STUDENT_CATEGORY': studentCategory,
    'PROGRAM_TYPE': programType,
    'createdAt': createdAt ?? FieldValue.serverTimestamp(),
  };

  factory RegistrationModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return RegistrationModel(
      id: doc.id,
      studentId: data['STUDENT_ID'] ?? '',
      studentName: data['STUDENT_NAME'] ?? '',
      teamId: data['TEAM_ID'] ?? '',
      programId: data['PROGRAM_ID'] ?? '',
      programName: data['PROGRAM_NAME'] ?? '',
      studentCategory: data['STUDENT_CATEGORY'] ?? '',
      programType: data['PROGRAM_TYPE'] ?? '',
      createdAt: data['createdAt'],
    );
  }
}