import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileProvider extends ChangeNotifier {
  final _teamsCollection = FirebaseFirestore.instance.collection('TEAMS');

  static const _kLoggedRole = 'loggedRole';
  static const _kTeamId = 'teamId';
  static const _kTeamName = 'teamName';
  static const _kTeamLeader = 'teamLeader';
  static const _kTeamCategory = 'teamCategory';
  static const _kUserName = 'userName';

  String selectedRole = "User";
  String loggedRole = "Guest";
  bool isLoggedIn = false;
  bool isLoggingIn = false;
  bool isRestoring = true; // true while checking SharedPreferences on app start
  String? loginError;

  // Leader session info
  String? teamId;
  String? teamName;
  String? teamLeader;
  String? teamCategory;

  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();

  ProfileProvider() {
    _restoreSession();
  }

  void changeRole(String role) {
    selectedRole = role;
    loginError = null;
    notifyListeners();
  }

  /// Called once on app start. Reads any saved session and restores it
  /// so the user stays logged in across app restarts.
  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedRole = prefs.getString(_kLoggedRole);

    if (savedRole != null) {
      loggedRole = savedRole;
      isLoggedIn = true;
      teamId = prefs.getString(_kTeamId);
      teamName = prefs.getString(_kTeamName);
      teamLeader = prefs.getString(_kTeamLeader);
      teamCategory = prefs.getString(_kTeamCategory);
    }

    isRestoring = false;
    notifyListeners();
  }

  Future<String?> login() async {
    loginError = null;

    if (selectedRole == "Leader") {
      return _loginAsLeader();
    }

    // Other roles: no credential check for now, just mark as logged in.
    loggedRole = selectedRole;
    isLoggedIn = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLoggedRole, selectedRole);
    notifyListeners();
    return null;
  }

  Future<String?> _loginAsLeader() async {
    final username = emailCtrl.text.trim();
    final password = passwordCtrl.text.trim();

    if (username.isEmpty || password.isEmpty) {
      loginError = 'Enter username and password';
      notifyListeners();
      return loginError;
    }

    isLoggingIn = true;
    notifyListeners();

    try {
      final snap = await _teamsCollection
          .where('USER_NAME', isEqualTo: username)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        loginError = 'Invalid username or password';
        return loginError;
      }

      final doc = snap.docs.first;
      final data = doc.data();

      if ((data['PASSWORD'] ?? '').toString() != password) {
        loginError = 'Invalid username or password';
        return loginError;
      }

      teamId = (data['TEAM_ID'] ?? doc.id).toString();
      teamName = (data['TEAM_NAME'] ?? '').toString();
      teamLeader = (data['TEAM_LEADER'] ?? '').toString();
      teamCategory = (data['TEAM_CATEGORY'] ?? '').toString();
      loggedRole = 'Leader';
      isLoggedIn = true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLoggedRole, 'Leader');
      await prefs.setString(_kTeamId, teamId ?? '');
      await prefs.setString(_kTeamName, teamName ?? '');
      await prefs.setString(_kTeamLeader, teamLeader ?? '');
      await prefs.setString(_kTeamCategory, teamCategory ?? '');
      await prefs.setString(_kUserName, username);

      emailCtrl.clear();
      passwordCtrl.clear();
      loginError = null;
      return null;
    } catch (e) {
      loginError = 'Login failed: $e';
      return loginError;
    } finally {
      isLoggingIn = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    loggedRole = 'Guest';
    isLoggedIn = false;
    teamId = null;
    teamName = null;
    teamLeader = null;
    teamCategory = null;
    notifyListeners();
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    super.dispose();
  }
}