import 'package:cloud_firestore/cloud_firestore.dart';

class JudgeModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final Timestamp? createdAt;
  final String? userName;
  final String? password;
  final List<String> assignedProgramIds;

  JudgeModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    this.createdAt,
    required this.userName,
    required this.password,
    this.assignedProgramIds = const [],
  });

  Map<String, dynamic> toMap() => {
    'NAME': name,
    'PHONE': phone,
    'EMAIL': email,
    'USER_NAME': userName, // was incorrectly `email` before
    'PASSWORD': password, // was incorrectly `email` before
    'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    // ASSIGNED_PROGRAM_IDS is intentionally not written here — it's
    // managed exclusively via arrayUnion/arrayRemove in JudgeProvider's
    // assignProgram/unassignProgram, so a plain save() never clobbers it.
  };

  factory JudgeModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return JudgeModel(
      id: doc.id,
      name: data['NAME'] ?? '',
      phone: data['PHONE'] ?? '',
      email: data['EMAIL'] ?? '',
      userName: data['USER_NAME'] ?? '',
      password: data['PASSWORD'] ?? '',
      createdAt: data['createdAt'],
      assignedProgramIds: (data['ASSIGNED_PROGRAM_IDS'] as List?)
          ?.map((e) => e.toString())
          .toList() ??
          const [],
    );
  }
}