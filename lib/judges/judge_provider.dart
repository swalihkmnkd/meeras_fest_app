import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../admin/models/judgesModel.dart';

class JudgeProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> scores = [
    {
      "title": "Classical Dance",
      "participant": "Alice Johnson • Phoenix",
      "category": "Dance",
      "score": 0,
      "submitted": false,
    },
    {
      "title": "Classical Dance",
      "participant": "Sarah Smith • Thunderbolts",
      "category": "Dance",
      "score": 85,
      "submitted": true,
    },
    {
      "title": "Group Song",
      "participant": "Team Alpha • Thunderbolts",
      "category": "Music",
      "score": 0,
      "submitted": false,
    },
    {
      "title": "Water Color",
      "participant": "John Doe • Phoenix",
      "category": "Art",
      "score": 0,
      "submitted": false,
    },
  ];

  int get submittedCount =>
      scores.where((item) => item["submitted"] == true).length;
  void increaseScore(int index) {
    if (scores[index]["score"] < 100) {
      updateScore(index, scores[index]["score"] + 1);
    }
  }

  void decreaseScore(int index) {
    if (scores[index]["score"] > 0) {
      updateScore(index, scores[index]["score"] - 1);
    }
  }

  void updateScore(int index, int score) {
    score = score.clamp(0, 100);

    scores[index]["score"] = score;

    final controller = scores[index]["controller"] as TextEditingController;

    if (controller.text != score.toString()) {
      controller.value = TextEditingValue(
        text: score.toString(),
        selection: TextSelection.collapsed(
          offset: score.toString().length,
        ),
      );
    }

    notifyListeners();
  }
  void submitScore(int index) {
    if (scores[index]["score"] >= 1) {
      scores[index]["submitted"] = true;
      notifyListeners();
    }
  }
  final _collection = FirebaseFirestore.instance.collection('judges');
  final _categoryCollection = FirebaseFirestore.instance.collection('categories');

  List<JudgeModel> judges = [];
  List<String> categoryNames = [];
  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;

  // ---- Form state (used by JudgesFormPage) ----
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  String? assignedCategory;
  String? _editingId;

  bool get isEditing => _editingId != null;

  Future<void> fetchJudges() async {
    isLoading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _collection.orderBy('createdAt', descending: true).get(),
        _categoryCollection.get(),
      ]);
      final judgeSnap = results[0];
      final categorySnap = results[1];

      judges = judgeSnap.docs.map((d) => JudgeModel.fromDoc(d)).toList();
      categoryNames = categorySnap.docs
          .map((d) => (d.data()['name'] ?? '').toString())
          .where((n) => n.isNotEmpty)
          .toList();
      errorMessage = null;
    } catch (e) {
      errorMessage = 'Failed to load judges: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void startCreate() {
    _editingId = null;
    nameCtrl.clear();
    phoneCtrl.clear();
    emailCtrl.clear();
    assignedCategory = null;
    notifyListeners();
  }

  void startEdit(JudgeModel judge) {
    _editingId = judge.id;
    nameCtrl.text = judge.name;
    phoneCtrl.text = judge.phone;
    emailCtrl.text = judge.email;
    assignedCategory = judge.assignedCategory.isEmpty ? null : judge.assignedCategory;
    notifyListeners();
  }

  void setAssignedCategory(String? value) {
    assignedCategory = value;
    notifyListeners();
  }

  Future<String?> save() async {
    if (nameCtrl.text.trim().isEmpty) return 'Judge name is required';

    isSaving = true;
    notifyListeners();
    try {
      final model = JudgeModel(
        id: _editingId ?? '',
        name: nameCtrl.text.trim(),
        phone: phoneCtrl.text.trim(),
        email: emailCtrl.text.trim(),
        assignedCategory: assignedCategory ?? '',
      );

      if (_editingId == null) {
        await _collection.add(model.toMap());
      } else {
        await _collection.doc(_editingId).update(model.toMap());
      }
      return null;
    } catch (e) {
      return 'Failed to save judge: $e';
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<String?> deleteJudge(String id) async {
    try {
      await _collection.doc(id).delete();
      return null;
    } catch (e) {
      return 'Failed to delete judge: $e';
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
    super.dispose();
  }
}