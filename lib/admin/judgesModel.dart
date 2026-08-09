import 'package:cloud_firestore/cloud_firestore.dart';

class JudgeModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String assignedCategory;
  final Timestamp? createdAt;

  JudgeModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.assignedCategory,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'phone': phone,
    'email': email,
    'assignedCategory': assignedCategory,
    'createdAt': createdAt ?? FieldValue.serverTimestamp(),
  };

  factory JudgeModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return JudgeModel(
      id: doc.id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      assignedCategory: data['assignedCategory'] ?? '',
      createdAt: data['createdAt'],
    );
  }
}