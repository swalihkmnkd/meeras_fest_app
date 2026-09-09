import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:meeras_fest_app/poster/poster_template_model.dart';

class PosterComposeData {
  final PosterTemplateModel template;
  final ui.Image? background;
  final ui.Image? studentImage;
  final String studentName;
  final String teamName;
  // ⬅️ NEW: actual text for the "Program Name" element. The template
  // only ever stored *style/position* for this field (PosterTemplateModel
  // .programName is a PosterTextStyleConfig, not a string) — there was no
  // real text being fed in anywhere, which is why it never appeared on
  // the generated poster even though it was fully editable in the admin
  // UI. This is the student's specific program/item name.
  final String programName;
  final num points;
  final int rank;

  const PosterComposeData({
    required this.template,
    required this.background,
    required this.studentImage,
    required this.studentName,
    required this.teamName,
    required this.programName,
    required this.points,
    required this.rank,
  });
}

/// Single source of truth for poster composition — used by the admin
/// preview, the student preview, and PNG export, so all three always
/// match exactly (spec §9/§17). Draws directly onto a Canvas via
/// PictureRecorder at logical 1080x1920; never captures a rendered widget.
class PosterCompositor {
  static const double canvasWidth = 1080;
  static const double canvasHeight = 1920;

  static Future<ui.Image> loadImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  static void paint(Canvas canvas, PosterComposeData data) {
    final t = data.template;

    if (data.background != null) {
      _drawImageRect(canvas, data.background!, const Rect.fromLTWH(0, 0, canvasWidth, canvasHeight), BoxFit.cover);
    } else {
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, canvasWidth, canvasHeight),
        Paint()..color = const Color(0xFF1F2937),
      );
    }

    if (data.studentImage != null) {
      final rect = Rect.fromLTWH(
          t.studentImage.x, t.studentImage.y, t.studentImage.width, t.studentImage.height);
      canvas.save();
      if (t.studentImage.circular) {
        canvas.clipPath(Path()..addOval(rect));
      } else if (t.studentImage.borderRadius > 0) {
        canvas.clipRRect(RRect.fromRectAndRadius(rect, Radius.circular(t.studentImage.borderRadius)));
      } else {
        canvas.clipRect(rect);
      }
      _drawImageRect(canvas, data.studentImage!, rect, BoxFit.cover);
      canvas.restore();

      // Stroke the frame around the photo. This must happen in a separate,
      // un-clipped pass — drawing it *inside* the clip above would cut the
      // outer half of the stroke off.
      //
      // ⬅️ FIX: previously this block didn't exist at all. borderWidth /
      // borderColorValue were fully configurable in the admin editor and
      // stored on the model, but nothing here ever painted them — so the
      // frame was invisible on the actual generated/shared poster even
      // though the photo's shape (circle / rounded-rect) was clipped
      // correctly. The editor's own preview only *looked* right because
      // it draws a separate Border.all() on its placeholder Container,
      // which this compositor has no equivalent of.
      if (t.studentImage.borderWidth > 0) {
        final borderPaint = Paint()
          ..color = t.studentImage.borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = t.studentImage.borderWidth;
        // Inset by half the stroke width so the line is centered on the
        // photo's edge (matching how BoxDecoration/Border.all renders it
        // in the editor preview) instead of being drawn entirely outside
        // the photo's bounding rect.
        final strokeRect = rect.deflate(t.studentImage.borderWidth / 2);
        if (t.studentImage.circular) {
          canvas.drawOval(strokeRect, borderPaint);
        } else if (t.studentImage.borderRadius > 0) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(strokeRect, Radius.circular(t.studentImage.borderRadius)),
            borderPaint,
          );
        } else {
          canvas.drawRect(strokeRect, borderPaint);
        }
      }
    }

    _drawText(canvas, data.studentName, t.studentName);
    // ⬅️ NEW: was completely missing before — the model/editor had a full
    // programName style config with a drag handle and font/color
    // controls, but nothing ever painted it onto the actual canvas.
    _drawText(canvas, data.programName, t.programName);
    _drawText(canvas, data.teamName, t.teamName);
    // ⬅️ REMOVED: score ("X Pts") and rankLabel ("1st Place" / "#4") used
    // to be drawn here using t.score / t.rankLabel's *default*, non-editable
    // positions (their drag handles were removed from the admin editor
    // earlier), which is why they showed up on the real poster in
    // positions the admin had no control over. Per request, the poster no
    // longer shows either. t.score / t.rankLabel remain on the model
    // (unused) in case a future design wants them back with proper
    // editor controls.
  }

  static void _drawImageRect(Canvas canvas, ui.Image image, Rect dst, BoxFit fit) {
    final srcSize = Size(image.width.toDouble(), image.height.toDouble());
    final fitted = applyBoxFit(fit, srcSize, dst.size);
    final srcRect = Alignment.center.inscribe(fitted.source, Offset.zero & srcSize);
    final dstRect = Alignment.center.inscribe(fitted.destination, dst);
    canvas.drawImageRect(image, srcRect, dstRect, Paint()..filterQuality = FilterQuality.high);
  }

  static void _drawText(Canvas canvas, String text, PosterTextStyleConfig cfg) {
    if (text.isEmpty) return;
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: GoogleFonts.inter(fontSize: cfg.fontSize, fontWeight: cfg.flutterWeight, color: cfg.color),
      ),
      textAlign: cfg.flutterAlign,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: canvasWidth);

    double dx = cfg.x;
    if (cfg.alignment == 'center') dx -= painter.width / 2;
    if (cfg.alignment == 'right') dx -= painter.width;
    painter.paint(canvas, Offset(dx, cfg.y));
  }

  static Future<ui.Image> composeToImage(PosterComposeData data) async {
    // Ensure Inter is actually loaded before drawing — otherwise the very
    // first poster generated in a session can silently fall back to the
    // system font for a frame.
    await GoogleFonts.pendingFonts();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, canvasWidth, canvasHeight));
    paint(canvas, data);
    final picture = recorder.endRecording();
    return picture.toImage(canvasWidth.toInt(), canvasHeight.toInt());
  }

  static Future<Uint8List> composeToPngBytes(PosterComposeData data) async {
    final image = await composeToImage(data);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}