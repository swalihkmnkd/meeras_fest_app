import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/teamModel.dart';

const List<String> teamCategoryOptions = ['Boys', 'Girls', 'Mixed'];

class TeamProvider extends ChangeNotifier {
  final _collection = FirebaseFirestore.instance.collection('TEAMS');

  List<TeamModel> teams = [];
  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;

  // ---- Form state (used by TeamsFormPage) ----
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController leaderCtrl = TextEditingController();
  final TextEditingController assistantLeaderCtrl = TextEditingController();
  final TextEditingController userNameCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();
  String? color;
  String? category;
  String? _editingId;

  bool get isEditing => _editingId != null;
  String? get editingIdForStudents => _editingId;

  Future<void> fetchTeams() async {
    isLoading = true;
    notifyListeners();
    try {
      final snap = await _collection.orderBy('createdAt', descending: true).get();
      teams = snap.docs.map((d) => TeamModel.fromDoc(d)).toList();
      errorMessage = null;
    } catch (e) {
      errorMessage = 'Failed to load teams: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void startCreate() {
    _editingId = null;
    nameCtrl.clear();
    leaderCtrl.clear();
    assistantLeaderCtrl.clear();
    userNameCtrl.clear();
    passwordCtrl.clear();
    color = null;
    category = null;
    notifyListeners();
  }

  void startEdit(TeamModel team) {
    _editingId = team.id;
    nameCtrl.text = team.name;
    leaderCtrl.text = team.leaderName;
    assistantLeaderCtrl.text = team.assistantLeader;
    userNameCtrl.text = team.userName;
    passwordCtrl.text = team.password;
    color = team.color;
    category = team.category;
    notifyListeners();
  }

  void setColor(String value) {
    color = value;
    notifyListeners();
  }

  void setCategory(String value) {
    category = value;
    notifyListeners();
  }

  Future<String?> save() async {
    if (nameCtrl.text.trim().isEmpty) return 'Team name is required';
    if (leaderCtrl.text.trim().isEmpty) return 'Team leader name is required';
    if (color == null) return 'Please select a team color';
    if (category == null) return 'Please select a team category';
    if (userNameCtrl.text.trim().isEmpty) return 'User name is required';
    if (passwordCtrl.text.trim().isEmpty) return 'Password is required';

    isSaving = true;
    notifyListeners();
    try {
      final model = TeamModel(
        id: _editingId ?? '',
        name: nameCtrl.text.trim(),
        teamId: _editingId??'',
        leaderName: leaderCtrl.text.trim(),
        assistantLeader: assistantLeaderCtrl.text.trim(),
        category: category!,
        color: color!,
        userName: userNameCtrl.text.trim(),
        password: passwordCtrl.text.trim(),
      );

      final data = model.toMap();
      if (_editingId == null) {
        data['createdAt'] = FieldValue.serverTimestamp();

        final doc = await _collection.add(data);

        _editingId = doc.id;

        // Update the newly created document with its own ID
        await _collection.doc(doc.id).update({
          'TEAM_ID': doc.id,
        });
      } else {
        await _collection.doc(_editingId).update(data);
      }
      return null;
    } catch (e) {
      return 'Failed to save team: $e';
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<String?> deleteTeam(String id) async {
    try {
      await _collection.doc(id).delete();
      return null;
    } catch (e) {
      return 'Failed to delete team: $e';
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    leaderCtrl.dispose();
    assistantLeaderCtrl.dispose();
    userNameCtrl.dispose();
    passwordCtrl.dispose();
    super.dispose();
  }
}