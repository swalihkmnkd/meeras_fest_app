import 'package:flutter/cupertino.dart';

class AdminProvider extends ChangeNotifier {
  bool isAnalyticTab = false;

  void changeAnalyticTab(bool tab) {
    isAnalyticTab = tab;
    notifyListeners();
  }
}