import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class AdminProvider extends ChangeNotifier {
bool isAnalyticTab=false;
void changeAnalyticTab(bool tab){
  isAnalyticTab=tab;
  notifyListeners();
}
}