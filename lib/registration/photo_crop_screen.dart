import 'dart:typed_data';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

/// Full-screen circular crop UI. Pop returns the cropped JPEG/PNG bytes,
/// or null if the user backs out without cropping.
class PhotoCropScreen extends StatefulWidget {
  final Uint8List imageBytes;
  const PhotoCropScreen({super.key, required this.imageBytes});

  @override
  State<PhotoCropScreen> createState() => _PhotoCropScreenState();
}

class _PhotoCropScreenState extends State<PhotoCropScreen> {
  final _controller = CropController();
  bool _isCropping = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Crop Photo'),
        actions: [
          TextButton(
            onPressed: _isCropping
                ? null
                : () {
              setState(() => _isCropping = true);
              _controller.crop();
            },
            child: _isCropping
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
                : const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Crop(
        controller: _controller,
        image: widget.imageBytes,
        aspectRatio: 1,
        withCircleUi: true,
        baseColor: Colors.black,
        maskColor: Colors.black.withValues(alpha: 0.65),
        // NOTE: crop_your_image's callback shape changed between versions.
        // If pub.dev shows a newer major version installed, this may need
        // to be `onCropped: (CropResult result) { ... }` with a
        // CropSuccess/CropFailure switch instead — check the version you
        // actually resolve to in pubspec.lock.
        onCropped: (Uint8List croppedImage) {
          Navigator.of(context).pop(croppedImage);
        },
      ),
    );
  }
}