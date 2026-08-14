import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TeamModel {
  final String id;
  final String name;
  final String teamId;
  final String leaderName;
  final String assistantLeader;
  final String category;
  final String color;
  final String userName;
  final String password;

  TeamModel({
    required this.id,
    required this.name,
    required this.teamId,
    required this.leaderName,
    required this.assistantLeader,
    required this.category,
    required this.color,
    required this.userName,
    required this.password,
  });

  factory TeamModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return TeamModel(
      id: doc.id,
      name: data['TEAM_NAME'] ?? '',
      teamId: data['TEAM_ID'] ?? '',
      leaderName: data['TEAM_LEADER'] ?? '',
      assistantLeader: data['ASSISTANT_LEADER'] ?? '',
      category: data['TEAM_CATEGORY'] ?? '',
      color: data['TEAM_COLOR'] ?? '',
      userName: data['USER_NAME'] ?? '',
      password: data['PASSWORD'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'TEAM_NAME': name,
      'TEAM_ID': teamId,
      'TEAM_LEADER': leaderName,
      'ASSISTANT_LEADER': assistantLeader,
      'TEAM_CATEGORY': category,
      'TEAM_COLOR': color,
      'USER_NAME': userName,
      'PASSWORD': password,
    };
  }
}

class TeamColorOption {
  final String name;
  final Color color;
  const TeamColorOption(this.name, this.color);
}

const List<TeamColorOption> teamColorOptions = [
  TeamColorOption('Red', Color(0xFFEF4444)),
  TeamColorOption('Blue', Color(0xFF3B82F6)),
  TeamColorOption('Green', Color(0xFF22C55E)),
  TeamColorOption('Yellow', Color(0xFFF59E0B)),
  TeamColorOption('Purple', Color(0xFF8B5CF6)),
  TeamColorOption('Orange', Color(0xFFF97316)),
  TeamColorOption('Teal', Color(0xFF14B8A6)),
];