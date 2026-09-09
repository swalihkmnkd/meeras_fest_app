import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:meeras_fest_app/poster/poster_template_model.dart';


/// Top-level so it can run on a background isolate via compute().
/// Downscales toward the 1080-wide poster canvas — no point storing a
/// much larger background than will ever be drawn.
Uint8List _compressBackground(Uint8List original) {
  final decoded = img.decodeImage(original);
  if (decoded == null) return original;
  img.Image resized = decoded;
  if (decoded.width > 1080) {
    resized = img.copyResize(decoded, width: 1080);
  }
  return Uint8List.fromList(img.encodeJpg(resized, quality: 90));
}

/// Admin-only CRUD for POSTER_TEMPLATES/{rank_1,rank_2,rank_3,default}.
/// Edits are buffered locally per rank key until [saveCurrent] is called,
/// so switching rank tabs never touches Firestore, and saving one rank
/// only ever writes that one document (spec §17).
class PosterTemplateProvider extends ChangeNotifier {
  final _col = FirebaseFirestore.instance.collection('POSTER_TEMPLATES');
  final _storage = FirebaseStorage.instance;

  static const List<String> rankKeys = ['rank_1', 'rank_2', 'rank_3', 'default'];

  final Map<String, PosterTemplateModel> _templates = {
    for (final k in rankKeys) k: PosterTemplateModel.empty(k),
  };

  String currentRankKey = 'rank_1';
  bool isLoading = false;
  bool isSaving = false;
  bool isUploadingBackground = false;
  String? errorMessage;

  PosterTemplateModel get current => _templates[currentRankKey]!;

  void selectRankKey(String key) {
    currentRankKey = key;
    notifyListeners();
  }

  /// ⬅️ FIXED: previously awaited each rank's doc.get() one at a time
  /// (4 sequential round trips), which is what made this page slow to
  /// open. Firestore has no multi-doc-by-id "in" fetch across different
  /// doc IDs in one call here, so instead we fire all 4 gets at once with
  /// Future.wait and let them resolve in parallel — same number of reads,
  /// but bounded by the slowest single request instead of the sum of all four.
  Future<void> fetchAll() async {
    isLoading = true;
    notifyListeners();
    try {
      final docs = await Future.wait(rankKeys.map((key) => _col.doc(key).get()));
      for (var i = 0; i < rankKeys.length; i++) {
        final key = rankKeys[i];
        final doc = docs[i];
        _templates[key] = doc.exists ? PosterTemplateModel.fromDoc(doc) : PosterTemplateModel.empty(key);
      }
      errorMessage = null;
    } catch (e) {
      errorMessage = 'Failed to load poster templates: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Applies a local (unsaved) edit to whichever rank is currently selected.
  void updateCurrent(PosterTemplateModel Function(PosterTemplateModel) update) {
    _templates[currentRankKey] = update(current);
    notifyListeners();
  }

  Future<String?> pickAndUploadBackground() async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 95);
      if (file == null) return null; // cancelled

      isUploadingBackground = true;
      notifyListeners();

      final rawBytes = await file.readAsBytes();
      // ⬅️ Offloaded to a background isolate via compute() — decode/resize/
      // encode is CPU-heavy and was previously running on the UI isolate,
      // which could visibly stall the app for a moment on large images.
      final bytes = await compute(_compressBackground, rawBytes);

      final path = 'poster_templates/${currentRankKey}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child(path);
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      final url = await ref.getDownloadURL();

      updateCurrent((t) => t.copyWith(backgroundImageUrl: url, backgroundStoragePath: path));
      return null;
    } catch (e) {
      return 'Failed to upload background: $e';
    } finally {
      isUploadingBackground = false;
      notifyListeners();
    }
  }

  String? validate(PosterTemplateModel t) {
    if (t.backgroundImageUrl.isEmpty) return 'Please upload a background image first';
    if (t.studentImage.width <= 0 || t.studentImage.height <= 0) {
      return 'Student image size must be greater than zero';
    }
    if (t.studentImage.x < -200 || t.studentImage.x > 1280 || t.studentImage.y < -200 || t.studentImage.y > 2120) {
      return 'Student image position is far outside the poster canvas';
    }
    for (final cfg in [t.studentName, t.score, t.teamName, t.rankLabel, t.programName]) {
      if (cfg.fontSize <= 0) return 'Font sizes must be greater than zero';
    }
    return null;
  }

  Future<String?> saveCurrent() async {
    final t = current;
    final error = validate(t);
    if (error != null) return error;

    isSaving = true;
    notifyListeners();
    try {
      await _col.doc(currentRankKey).set({
        ...t.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      return 'Failed to save template: $e';
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}