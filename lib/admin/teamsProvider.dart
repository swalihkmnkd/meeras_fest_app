import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'teamModel.dart';

class TeamProvider extends ChangeNotifier {
  final _collection = FirebaseFirestore.instance.collection('teams');

  List<TeamModel> teams = [];
  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;

  // ---- Form state (used by TeamsFormPage) ----
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController leaderCtrl = TextEditingController();
  String? gender;
  String? _editingId;

  bool get isEditing => _editingId != null;

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
    gender = null;
    notifyListeners();
  }

  void startEdit(TeamModel team) {
    _editingId = team.id;
    nameCtrl.text = team.name;
    leaderCtrl.text = team.leaderName;
    gender = team.gender;
    notifyListeners();
  }

  void setGender(String value) {
    gender = value;
    notifyListeners();
  }

  Future<String?> save() async {
    if (nameCtrl.text.trim().isEmpty) return 'Team name is required';
    if (gender == null) return 'Please select a gender';
    if (leaderCtrl.text.trim().isEmpty) return 'Team leader name is required';

    isSaving = true;
    notifyListeners();
    try {
      final model = TeamModel(
        id: _editingId ?? '',
        name: nameCtrl.text.trim(),
        gender: gender!,
        leaderName: leaderCtrl.text.trim(),
      );

      if (_editingId == null) {
        await _collection.add(model.toMap());
      } else {
        await _collection.doc(_editingId).update(model.toMap());
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
    super.dispose();
  }
}