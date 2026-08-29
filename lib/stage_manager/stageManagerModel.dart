import 'package:cloud_firestore/cloud_firestore.dart';

class StageManagerModel {
  final String id;
  final String name;
  final String userName;
  final String password;
  final Timestamp? createdAt;

  StageManagerModel({
    required this.id,
    required this.name,
    required this.userName,
    required this.password,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'NAME': name,
    'USER_NAME': userName,
    'PASSWORD': password,
    'createdAt': createdAt ?? FieldValue.serverTimestamp(),
  };

  factory StageManagerModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return StageManagerModel(
      id: doc.id,
      name: (data['NAME'] ?? '').toString(),
      userName: (data['USER_NAME'] ?? '').toString(),
      password: (data['PASSWORD'] ?? '').toString(),
      createdAt: data['createdAt'],
    );
  }
}