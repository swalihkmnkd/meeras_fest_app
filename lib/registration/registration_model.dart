import 'package:cloud_firestore/cloud_firestore.dart';

class RegistrationModel {
  final String id;
  final String studentId;
  final String studentName;
  final String teamId;
  final String programId;
  final String programName;
  final String studentCategory;
  final String programCategory; // the actual category name, e.g. "Senior" (from CATEGORIES.NAME)
  final String stageType; // "Stage" / "Non Stage"
  final bool isGeneral; // copied from ProgramModel.isGeneral at registration time
  final Timestamp? createdAt;
  final String registrationId;
  final String registrationNumber;

  RegistrationModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.teamId,
    required this.programId,
    required this.programName,
    required this.studentCategory,
    required this.programCategory,
    required this.stageType,
    this.isGeneral = false,
    this.createdAt,
    required this.registrationId,
    required this.registrationNumber,
  });

  Map<String, dynamic> toMap() => {
    'STUDENT_ID': studentId,
    'STUDENT_NAME': studentName,
    'TEAM_ID': teamId,
    'PROGRAM_ID': programId,
    'PROGRAM_NAME': programName,
    'STUDENT_CATEGORY': studentCategory,
    'PROGRAM_CATEGORY': programCategory,
    'STAGE_TYPE': stageType,
    'IS_GENERAL': isGeneral,
    'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    'REGISTRATION_ID': registrationId ,
    'REGISTER_NUMBER': registrationNumber,
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
      programCategory: data['PROGRAM_CATEGORY'] ?? '',
      registrationId: data['REGISTRATION_ID'] ?? '',
      registrationNumber: data['REGISTER_NUMBER'] ?? '',
      // ⚠️ Registrations created before this field existed won't have it —
      // they'll come back as '' here, which just means they won't match
      // any Stage/Non Stage filter. That's expected for legacy data.
      stageType: data['STAGE_TYPE'] ?? '',
      // ⚠️ Same as above: legacy registrations without IS_GENERAL come
      // back as false, which is a safe default.
      isGeneral: data['IS_GENERAL'] ?? false,
      createdAt: data['createdAt'],
    );
  }
}