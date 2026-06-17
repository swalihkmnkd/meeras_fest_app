import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class ResultProvider extends ChangeNotifier {
  int resultButtonIndex=0;
void selectResultButton(int index){
  resultButtonIndex=index;
  notifyListeners();
}
}