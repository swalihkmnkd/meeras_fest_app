import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'programModel.dart';

class ProgramProvider extends ChangeNotifier {
  final _collection = FirebaseFirestore.instance.collection('programs');
  final _categoryCollection = FirebaseFirestore.instance.collection('categories');

  List<ProgramModel> programs = [];
  List<String> categoryNames = [];
  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;

  // ---- Form state (used by ProgramFormPage) ----
  final TextEditingController nameCtrl = TextEditingController();
  String? category;
  String? gender;
  String? _editingId;

  bool get isEditing => _editingId != null;

  Future<void> fetchPrograms() async {
    isLoading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _collection.orderBy('createdAt', descending: true).get(),
        _categoryCollection.get(),
      ]);
      final programSnap = results[0];
      final categorySnap = results[1];

      programs = programSnap.docs.map((d) => ProgramModel.fromDoc(d)).toList();
      categoryNames = categorySnap.docs
          .map((d) => (d.data()['name'] ?? '').toString())
          .where((n) => n.isNotEmpty)
          .toList();
      errorMessage = null;
    } catch (e) {
      errorMessage = 'Failed to load programs: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void startCreate() {
    _editingId = null;
    nameCtrl.clear();
    category = null;
    gender = null;
    notifyListeners();
  }

  void startEdit(ProgramModel program) {
    _editingId = program.id;
    nameCtrl.text = program.name;
    category = program.category.isEmpty ? null : program.category;
    gender = program.gender;
    notifyListeners();
  }

  void setCategory(String? value) {
    category = value;
    notifyListeners();
  }

  void setGender(String value) {
    gender = value;
    notifyListeners();
  }

  Future<String?> save() async {
    if (nameCtrl.text.trim().isEmpty) return 'Program name is required';
    if (category == null) return 'Please select a category';
    if (gender == null) return 'Please select a gender';

    isSaving = true;
    notifyListeners();
    try {
      final model = ProgramModel(
        id: _editingId ?? '',
        name: nameCtrl.text.trim(),
        category: category!,
        gender: gender!,
      );

      if (_editingId == null) {
        await _collection.add(model.toMap());
      } else {
        await _collection.doc(_editingId).update(model.toMap());
      }
      return null;
    } catch (e) {
      return 'Failed to save program: $e';
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<String?> deleteProgram(String id) async {
    try {
      await _collection.doc(id).delete();
      return null;
    } catch (e) {
      return 'Failed to delete program: $e';
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    super.dispose();
  }
}