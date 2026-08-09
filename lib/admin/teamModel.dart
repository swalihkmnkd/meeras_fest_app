import 'package:cloud_firestore/cloud_firestore.dart';

class TeamModel {
  final String id;
  final String name;
  final String gender;
  final String leaderName;
  final Timestamp? createdAt;

  TeamModel({
    required this.id,
    required this.name,
    required this.gender,
    required this.leaderName,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'gender': gender,
    'teamLeader': leaderName,
    'createdAt': createdAt ?? FieldValue.serverTimestamp(),
  };

  factory TeamModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return TeamModel(
      id: doc.id,
      name: data['name'] ?? '',
      gender: data['gender'] ?? 'Mixed',
      leaderName: data['teamLeader'] ?? '',
      createdAt: data['createdAt'],
    );
  }
}