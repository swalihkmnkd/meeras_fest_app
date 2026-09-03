import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Admin-editable caps on how many Stage / Non Stage programs a single
/// student may register for, plus the registration deadline. Stored as one
/// doc so it's simple to read from the registration form and simple to
/// edit from the admin side.
///
/// General-category registrations never count toward — or get blocked
/// by — the Stage/Non Stage limits; that exemption lives in
/// RegistrationProvider, not here, since it depends on the category the
/// student picked.
class RegistrationSettingsProvider extends ChangeNotifier {
  final _doc =
  FirebaseFirestore.instance.collection('SETTINGS').doc('REGISTRATION_LIMITS');

  static const int defaultStageLimit = 4;
  static const int defaultNonStageLimit = 4;

  int stageLimit = defaultStageLimit;
  int nonStageLimit = defaultNonStageLimit;

  // ⬅️ NEW: registration deadline. Null = no deadline set, registration
  // stays open indefinitely.
  DateTime? deadline;

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

      // ⬅️ NEW
      final deadlineTs = data?['REGISTRATION_DEADLINE'];
      deadline = deadlineTs is Timestamp ? deadlineTs.toDate() : null;

      errorMessage = null;
    } catch (e) {
      errorMessage = 'Failed to load registration limits: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Sets the deadline to an explicit date/time. Pass null to clear it
  /// (registration stays open with no cutoff). Doesn't hit Firestore until
  /// [save] is called, matching how the limit fields behave.
  void setDeadline(DateTime? value) {
    deadline = value;
    notifyListeners();
  }

  /// Clears the deadline (equivalent to setDeadline(null), kept as a named
  /// convenience for the "Remove deadline" button).
  void clearDeadline() => setDeadline(null);

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
        // ⬅️ NEW: null clears the field via FieldValue.delete() so a
        // previously-set deadline can be removed, not just overwritten.
        'REGISTRATION_DEADLINE':
        deadline != null ? Timestamp.fromDate(deadline!) : FieldValue.delete(),
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