import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../adminConstents.dart';
import '../models/categoryModel.dart';

class CategoryProvider extends ChangeNotifier {
  final _collection = FirebaseFirestore.instance.collection('CATEGORIES');

  List<CategoryModel> categories = [];
  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;

  // ---- Form state (used by CategoryFormPage) ----
  final TextEditingController nameCtrl = TextEditingController();
  String? gender;
  String? classFrom;
  String? classTo;
  String? _editingId;
  CategoryProvider() {
    fetchCategories();
  }

  List<String> get categoryNames => categories.map((c) => c.name).toList();
  bool get isEditing => _editingId != null;

  Future<void> fetchCategories() async {
    isLoading = true;
    notifyListeners();
    try {
      final snap = await _collection.orderBy('CREATED_AT', descending: true).get();
      categories = snap.docs.map((d) => CategoryModel.fromDoc(d)).toList();
      errorMessage = null;
    } catch (e) {
      errorMessage = 'Failed to load categories: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Populates the form fields for creating a brand-new category.
  void startCreate() {
    _editingId = null;
    nameCtrl.clear();
    gender = null;
    classFrom = null;
    classTo = null;
    notifyListeners();
  }

  /// Populates the form fields for editing an existing category.
  void startEdit(CategoryModel category) {
    _editingId = category.id;
    nameCtrl.text = category.name;
    gender = category.gender;
    classFrom = category.classFrom;
    classTo = category.classTo;
    notifyListeners();
  }

  void setGender(String value) {
    gender = value;
    notifyListeners();
  }

  void setClassFrom(String? value) {
    classFrom = value;
    notifyListeners();
  }

  void setClassTo(String? value) {
    classTo = value;
    notifyListeners();
  }

  /// Validates and saves (create or update). Returns null on success,
  /// or an error string to show the user.
  Future<String?> save() async {
    if (nameCtrl.text.trim().isEmpty) return 'Category name is required';
    if (gender == null) return 'Please select a gender';
    if (classFrom == null || classTo == null) return 'Please select the class range';
    if (!isClassRangeInOrder(classFrom!, classTo!)) {
      return '"From Class" must come before or equal to "To Class"';
    }

    isSaving = true;
    notifyListeners();
    try {
      final model = CategoryModel(
        id: _editingId ?? '',
        name: nameCtrl.text.trim(),
        gender: gender!,
        classFrom: classFrom!,
        classTo: classTo!,
      );

      if (_editingId == null) {
        await _collection.add(model.toMap());
      } else {
        await _collection.doc(_editingId).update(model.toMap());
      }
      return null;
    } catch (e) {
      return 'Failed to save category: $e';
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<String?> deleteCategory(String id) async {
    try {
      await _collection.doc(id).delete();
      return null;
    } catch (e) {
      return 'Failed to delete category: $e';
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    super.dispose();
  }
}