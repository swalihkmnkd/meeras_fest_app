import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:meeras_fest_app/poster/poster_compositer.dart';


/// Renders a [ui.Image] (already produced by [PosterCompositor]) inside a
/// fixed-aspect 1080:1920 box. The caller controls exactly when the image
/// is (re)computed — this widget just displays it.
class PosterPreview extends StatelessWidget {
  final Future<ui.Image>? future;
  final BorderRadius borderRadius;

  const PosterPreview({super.key, required this.future, this.borderRadius = const BorderRadius.all(Radius.circular(16))});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: PosterCompositor.canvasWidth / PosterCompositor.canvasHeight,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Container(
          color: const Color(0xffF3F4F6),
          child: future == null
              ? const Center(child: Icon(Icons.image_outlined, color: Color(0xff9CA3AF), size: 40))
              : FutureBuilder<ui.Image>(
            future: future,
            builder: (context, snap) {
              if (snap.hasError) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Failed to render poster', style: TextStyle(color: Color(0xff6B7280))),
                  ),
                );
              }
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator(strokeWidth: 2));
              }
              return FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: PosterCompositor.canvasWidth,
                  height: PosterCompositor.canvasHeight,
                  child: RawImage(image: snap.data, fit: BoxFit.fill),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}