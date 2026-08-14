import 'package:cloud_firestore/cloud_firestore.dart';

class StudentModel {
  final String id; // Firestore document id (STUDENT_ID) -- the true unique key
  final String name;
  final String studentClass;
  final String division;
  final String gender;
  final String rollNumber;
  final String teamId;
  final String teamName;
  final String teamColor;

  StudentModel({
    this.id = '',
    required this.name,
    required this.studentClass,
    this.division = '',
    required this.gender,
    required this.rollNumber,
    required this.teamId,
    required this.teamName,
    required this.teamColor,
  });

  Map<String, dynamic> toMap() => {
    'NAME': name,
    'CLASS': studentClass,
    'DIVISION': division,
    'GENDER': gender,
    'ROLL_NUMBER': rollNumber,
    'TEAM_ID': teamId,
    'TEAM_NAME': teamName,
    'TEAM_COLOR': teamColor,
  };

  bool get isAssigned => teamId.isNotEmpty;

  factory StudentModel.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};
    return StudentModel(
      id: doc.id, // real unique key
      name: map['NAME']?.toString() ?? '',
      studentClass: map['CLASS']?.toString() ?? '',
      division: map['DIVISION']?.toString() ?? '',
      gender: map['GENDER']?.toString() ?? '',
      rollNumber: map['ROLL_NUMBER']?.toString() ?? '',
      teamId: map['TEAM_ID']?.toString() ?? '',
      teamName: map['TEAM_NAME']?.toString() ?? '',
      teamColor: map['TEAM_COLOR']?.toString() ?? '',
    );
  }

  factory StudentModel.fromMap(Map<String, dynamic> map) => StudentModel(
    id: map['STUDENT_ID']?.toString() ?? '',
    name: map['NAME']?.toString() ?? '',
    studentClass: map['CLASS']?.toString() ?? '',
    division: map['DIVISION']?.toString() ?? '',
    gender: map['GENDER']?.toString() ?? '',
    rollNumber: map['ROLL_NUMBER']?.toString() ?? '',
    teamId: map['TEAM_ID']?.toString() ?? '',
    teamName: map['TEAM_NAME']?.toString() ?? '',
    teamColor: map['TEAM_COLOR']?.toString() ?? '',
  );

  StudentModel copyWith({
    String? id,
    String? name,
    String? studentClass,
    String? division,
    String? gender,
    String? rollNumber,
    String? teamId,
    String? teamName,
    String? teamColor,
  }) {
    return StudentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      studentClass: studentClass ?? this.studentClass,
      division: division ?? this.division,
      gender: gender ?? this.gender,
      rollNumber: rollNumber ?? this.rollNumber,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      teamColor: teamColor ?? this.teamColor,
    );
  }
}