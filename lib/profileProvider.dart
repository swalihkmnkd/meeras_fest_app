import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class ProfileProvider extends ChangeNotifier {
  String selectedRole = "User";
  void changeRole(String role){
    selectedRole=role;
    notifyListeners();
  }
}