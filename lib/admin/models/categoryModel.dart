import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String name;
  final String gender;
  final String classFrom;
  final String classTo;
  final bool isGeneral;
  final Timestamp? createdAt;

  CategoryModel({
    required this.id,
    required this.name,
    required this.gender,
    required this.classFrom,
    required this.classTo,
    this.isGeneral = false,
    this.createdAt,
  });

  String get classRangeLabel => 'Class $classFrom - $classTo';

  Map<String, dynamic> toMap() => {
    'NAME': name,
    'GENDER': gender,
    'CLASS_FROM': classFrom,
    'CLASS_TO': classTo,
    'IS_GENERAL': isGeneral,
    'CREATED_AT': createdAt ?? FieldValue.serverTimestamp(),
  };

  factory CategoryModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return CategoryModel(
      id: doc.id,
      name: data['NAME'] ?? '',
      gender: data['GENDER'] ?? 'Mixed',
      classFrom: data['CLASS_FROM'] ?? '',
      classTo: data['CLASS_TO'] ?? '',
      isGeneral: data['IS_GENERAL'] ?? false,
      createdAt: data['CREATED_AT'],
    );
  }
}