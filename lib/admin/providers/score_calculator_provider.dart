import 'package:flutter/material.dart';

import '../models/programModel.dart';

class ScoreCalculatorProvider extends ChangeNotifier {
  final TextEditingController markCtrl = TextEditingController();

  ProgramModel? selectedProgram;
  int? position;

  String? grade;
  double? gradePoints;
  double? positionPoints;
  bool _calculated = false;

  bool get hasResult => _calculated;
  double get totalScore => (gradePoints ?? 0) + (positionPoints ?? 0);

  void selectProgram(ProgramModel? program) {
    selectedProgram = program;
    _clearResult();
  }

  void selectPosition(int? value) {
    position = value;
  }

  void _clearResult() {
    grade = null;
    gradePoints = null;
    positionPoints = null;
    _calculated = false;
    notifyListeners();
  }

  void calculate() {
    final program = selectedProgram;
    if (program == null) return;
    final mark = double.tryParse(markCtrl.text.trim());
    grade = mark == null ? null : program.gradeForMark(mark);
    gradePoints = mark == null ? null : program.gradePointsForMark(mark);
    positionPoints = position == null ? null : program.pointsForPosition(position!);
    _calculated = true;
    notifyListeners();
  }

  void reset() {
    markCtrl.clear();
    selectedProgram = null;
    position = null;
    _calculated = false;
    grade = null;
    gradePoints = null;
    positionPoints = null;
    notifyListeners();
  }

  @override
  void dispose() {
    markCtrl.dispose();
    super.dispose();
  }
}