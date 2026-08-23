import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../registration/register_provider.dart';

class HomeProvider extends ChangeNotifier {
  int selectedBottomIndex=0;
  void changeBottomIndex(int index){
    selectedBottomIndex=index;
    notifyListeners();
  }
}