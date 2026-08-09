import 'package:cloud_firestore/cloud_firestore.dart';

class ProgramModel {
  final String id;
  final String name;
  final String category;
  final String gender;
  final Timestamp? createdAt;

  ProgramModel({
    required this.id,
    required this.name,
    required this.category,
    required this.gender,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'category': category,
    'gender': gender,
    'createdAt': createdAt ?? FieldValue.serverTimestamp(),
  };

  factory ProgramModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ProgramModel(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      gender: data['gender'] ?? 'Mixed',
      createdAt: data['createdAt'],
    );
  }
}