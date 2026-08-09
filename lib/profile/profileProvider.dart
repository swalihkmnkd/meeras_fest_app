import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class ProfileProvider extends ChangeNotifier {
  String selectedRole = "Gust";

  void changeRole(String role) {
    selectedRole = role;
    notifyListeners();
  }
String loggedRole='Gust';
  void changeLoginRole(String role){
    loggedRole=role;

    notifyListeners();
}
}