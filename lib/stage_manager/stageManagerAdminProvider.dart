import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:meeras_fest_app/stage_manager/stageManagerModel.dart';


class StageManagerAdminProvider extends ChangeNotifier {
  final _collection = FirebaseFirestore.instance.collection('StageManagers');

  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;

  List<StageManagerModel> stageManagers = [];

  // Currently-editing doc id, if any. Null while adding a new one.
  String? editingId;

  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController userNameCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();

  Future<void> fetchAll() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final snap = await _collection.orderBy('NAME').get();
      stageManagers = snap.docs.map((d) => StageManagerModel.fromDoc(d)).toList();
    } catch (e) {
      errorMessage = 'Failed to load stage managers: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void startAdd() {
    editingId = null;
    nameCtrl.clear();
    userNameCtrl.clear();
    passwordCtrl.clear();
  }

  void startEdit(StageManagerModel manager) {
    editingId = manager.id;
    nameCtrl.text = manager.name;
    userNameCtrl.text = manager.userName;
    passwordCtrl.text = manager.password;
  }

  /// Validates, checks the username is unique, then creates or updates the
  /// StageManagers doc depending on whether [editingId] is set.
  Future<String?> save() async {
    final name = nameCtrl.text.trim();
    final userName = userNameCtrl.text.trim();
    final password = passwordCtrl.text.trim();

    if (name.isEmpty) return 'Enter a name';
    if (userName.isEmpty) return 'Enter a username';
    if (password.isEmpty) return 'Enter a password';

    isSaving = true;
    notifyListeners();
    try {
      // Usernames must be unique across Stage Managers so login can look
      // up exactly one match.
      final clash = await _collection.where('USER_NAME', isEqualTo: userName).limit(1).get();
      if (clash.docs.isNotEmpty && clash.docs.first.id != editingId) {
        return 'That username is already taken';
      }

      if (editingId != null) {
        await _collection.doc(editingId).update({
          'NAME': name,
          'USER_NAME': userName,
          'PASSWORD': password,
        });
      } else {
        final docRef = _collection.doc();
        await docRef.set(StageManagerModel(
          id: docRef.id,
          name: name,
          userName: userName,
          password: password,
        ).toMap());
      }

      startAdd(); // reset the form
      await fetchAll();
      return null;
    } catch (e) {
      return 'Failed to save: $e';
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<String?> delete(String id) async {
    try {
      await _collection.doc(id).delete();
      stageManagers.removeWhere((s) => s.id == id);
      notifyListeners();
      return null;
    } catch (e) {
      return 'Failed to delete: $e';
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    userNameCtrl.dispose();
    passwordCtrl.dispose();
    super.dispose();
  }
}