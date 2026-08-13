import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String name;
  final String gender;
  final String classFrom;
  final String classTo;
  final Timestamp? createdAt;

  CategoryModel({
    required this.id,
    required this.name,
    required this.gender,
    required this.classFrom,
    required this.classTo,
    this.createdAt,
  });

  String get classRangeLabel => 'Class $classFrom - $classTo';

  Map<String, dynamic> toMap() => {
    'name': name,
    'gender': gender,
    'classFrom': classFrom,
    'classTo': classTo,
    'createdAt': createdAt ?? FieldValue.serverTimestamp(),
  };

  factory CategoryModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return CategoryModel(
      id: doc.id,
      name: data['name'] ?? '',
      gender: data['gender'] ?? 'Mixed',
      classFrom: data['classFrom'] ?? '',
      classTo: data['classTo'] ?? '',
      createdAt: data['createdAt'],
    );
  }
}