import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';


/// A single carousel image document stored in Firestore, at
/// collection('carousel')/{id} with fields: imageUrl, storagePath,
/// order, createdAt.
class CarouselImageModel {
  final String id;
  final String imageUrl;
  final String storagePath;
  final int order;
  final DateTime? createdAt;

  CarouselImageModel({
    required this.id,
    required this.imageUrl,
    required this.storagePath,
    required this.order,
    required this.createdAt,
  });

  factory CarouselImageModel.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final ts = data['createdAt'];
    return CarouselImageModel(
      id: doc.id,
      imageUrl: data['imageUrl'] ?? '',
      storagePath: data['storagePath'] ?? '',
      order: data['order'] is int ? data['order'] as int : 0,
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}

class CarouselProvider extends ChangeNotifier {
  CarouselProvider() {
    _listenToCarousel();
  }

  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  static const String _collection = 'carousel';
  static const String _storageFolder = 'carousel_images';

  // Only compress if the picked file is larger than this.
  static const int _compressThresholdBytes = 800 * 1024; // 800 KB
  static const int _maxDimension = 1600; // px, longest side

  List<CarouselImageModel> _images = [];
  List<CarouselImageModel> get images => _images;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isUploading = false;
  bool get isUploading => _isUploading;

  // Per-in-flight-upload progress (0.0–1.0), keyed by a temp local id, so
  // the UI can render a progress tile for each image being uploaded.
  final Map<String, double> _uploadProgress = {};
  Map<String, double> get uploadProgress => _uploadProgress;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  /// Real-time listener. Any add/delete — from this screen, another admin,
  /// or later the home page — updates [images] and notifies listeners
  /// immediately. No manual re-fetching needed anywhere this provider is used.
  void _listenToCarousel() {
    _sub = _firestore
        .collection(_collection)
        .orderBy('order')
        .snapshots()
        .listen((snapshot) {
      _images = snapshot.docs.map(CarouselImageModel.fromDoc).toList();
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    }, onError: (e) {
      _errorMessage = 'Failed to load carousel: $e';
      _isLoading = false;
      notifyListeners();
    });
  }

  /// Opens the gallery picker (multi-select), compresses each image if
  /// needed, uploads to Storage, then writes a Firestore doc per image.
  /// Works on web: uses XFile.readAsBytes() + Storage.putData(), no dart:io.
  Future<void> pickAndUploadImages() async {
    try {
      final picker = ImagePicker();
      final List<XFile> picked = await picker.pickMultiImage(imageQuality: 100);
      if (picked.isEmpty) return;

      _isUploading = true;
      _errorMessage = null;
      notifyListeners();

      for (final file in picked) {
        await _uploadSingleImage(file);
      }
    } catch (e) {
      _errorMessage = 'Failed to pick/upload images: $e';
    } finally {
      _isUploading = false;
      _uploadProgress.clear();
      notifyListeners();
    }
  }

  Future<void> _uploadSingleImage(XFile file) async {
    final tempId = '${DateTime.now().microsecondsSinceEpoch}_${file.name}';
    _uploadProgress[tempId] = 0;
    notifyListeners();

    try {
      final rawBytes = await file.readAsBytes();
      final bytes = _compressIfNeeded(rawBytes);

      final safeName = file.name.replaceAll(RegExp(r'\s+'), '_');
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$safeName.jpg';
      final storagePath = '$_storageFolder/$fileName';
      final ref = _storage.ref().child(storagePath);

      final uploadTask = ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      uploadTask.snapshotEvents.listen((event) {
        if (event.totalBytes > 0) {
          _uploadProgress[tempId] = event.bytesTransferred / event.totalBytes;
          notifyListeners();
        }
      });

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      await _firestore.collection(_collection).add({
        'imageUrl': downloadUrl,
        'storagePath': storagePath,
        'order': _images.length,
        'createdAt': FieldValue.serverTimestamp(),
      });
      // No manual local list update needed — the snapshots() listener
      // above will pick this up and notify automatically.
    } finally {
      _uploadProgress.remove(tempId);
    }
  }

  /// Decodes and re-encodes as JPEG (quality 80), shrinking the longest
  /// side to [_maxDimension] px, only when the original exceeds the
  /// threshold. Pure-Dart (the `image` package), so it works on web too —
  /// no platform channels, unlike flutter_image_compress.
  Uint8List _compressIfNeeded(Uint8List original) {
    if (original.lengthInBytes <= _compressThresholdBytes) {
      return original;
    }

    final decoded = img.decodeImage(original);
    if (decoded == null) return original;

    img.Image resized = decoded;
    if (decoded.width > _maxDimension || decoded.height > _maxDimension) {
      resized = img.copyResize(
        decoded,
        width: decoded.width >= decoded.height ? _maxDimension : null,
        height: decoded.height > decoded.width ? _maxDimension : null,
      );
    }

    return Uint8List.fromList(img.encodeJpg(resized, quality: 80));
  }

  /// Deletes the Storage object first, then the Firestore doc. If the
  /// Storage object is already gone (e.g. deleted manually) that specific
  /// error is ignored so the Firestore doc still gets cleaned up.
  Future<void> deleteImage(CarouselImageModel image) async {
    try {
      try {
        await _storage.ref().child(image.storagePath).delete();
      } on FirebaseException catch (e) {
        if (e.code != 'object-not-found') rethrow;
      }
      await _firestore.collection(_collection).doc(image.id).delete();
    } catch (e) {
      _errorMessage = 'Failed to delete image: $e';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}