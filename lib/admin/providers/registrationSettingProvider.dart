import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Admin-editable caps on how many Stage / Non Stage programs a single
/// student may register for. Stored as one doc so it's simple to read from
/// the registration form and simple to edit from the admin side.
///
/// General-category registrations never count toward — or get blocked
/// by — these limits; that exemption lives in RegistrationProvider, not
/// here, since it depends on the category the student picked.
class RegistrationSettingsProvider extends ChangeNotifier {
  final _doc =
  FirebaseFirestore.instance.collection('SETTINGS').doc('REGISTRATION_LIMITS');

  static const int defaultStageLimit = 4;
  static const int defaultNonStageLimit = 4;

  int stageLimit = defaultStageLimit;
  int nonStageLimit = defaultNonStageLimit;

  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;

  final TextEditingController stageLimitCtrl =
  TextEditingController(text: defaultStageLimit.toString());
  final TextEditingController nonStageLimitCtrl =
  TextEditingController(text: defaultNonStageLimit.toString());

  Future<void> fetch() async {
    isLoading = true;
    notifyListeners();
    try {
      final snap = await _doc.get();
      final data = snap.data();
      stageLimit = (data?['STAGE_LIMIT'] as num?)?.toInt() ?? defaultStageLimit;
      nonStageLimit = (data?['NON_STAGE_LIMIT'] as num?)?.toInt() ?? defaultNonStageLimit;
      stageLimitCtrl.text = stageLimit.toString();
      nonStageLimitCtrl.text = nonStageLimit.toString();
      errorMessage = null;
    } catch (e) {
      errorMessage = 'Failed to load registration limits: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> save() async {
    final stage = int.tryParse(stageLimitCtrl.text.trim());
    final nonStage = int.tryParse(nonStageLimitCtrl.text.trim());
    if (stage == null || stage < 0) return 'Enter a valid Stage program limit';
    if (nonStage == null || nonStage < 0) return 'Enter a valid Non Stage program limit';

    isSaving = true;
    notifyListeners();
    try {
      await _doc.set({
        'STAGE_LIMIT': stage,
        'NON_STAGE_LIMIT': nonStage,
      }, SetOptions(merge: true));
      stageLimit = stage;
      nonStageLimit = nonStage;
      return null;
    } catch (e) {
      return 'Failed to save: $e';
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    stageLimitCtrl.dispose();
    nonStageLimitCtrl.dispose();
    super.dispose();
  }
}