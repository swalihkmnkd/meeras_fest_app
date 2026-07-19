import 'package:flutter/material.dart';

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
}