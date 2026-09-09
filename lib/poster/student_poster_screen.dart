import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:meeras_fest_app/poster/poster_compositer.dart';
import 'package:meeras_fest_app/poster/poster_preview.dart';
import 'package:meeras_fest_app/poster/poster_template_model.dart';
import 'package:share_plus/share_plus.dart';

import '../home/home_screen.dart'; // FadeSlideAnimation / SlideFrom
import '../registration/photo_crop_screen.dart';
import '../result/resultProvider.dart';

class StudentPosterScreen extends StatefulWidget {
  final StudentBestResult student;
  const StudentPosterScreen({super.key, required this.student});

  @override
  State<StudentPosterScreen> createState() => _StudentPosterScreenState();
}

class _StudentPosterScreenState extends State<StudentPosterScreen> {
  PosterTemplateModel? _template;
  ui.Image? _bgImage;
  ui.Image? _studentImage;
  Future<ui.Image>? _previewFuture;

  bool _isLoading = true;
  bool _missingTemplate = false;
  bool _photoLoadFailed = false;
  bool _isGenerating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rankKey = PosterTemplateModel.rankKeyFor(widget.student.bestRank);
      final template = await PosterTemplateModel.fetchByRankKey(rankKey);
      if (template == null || !template.isConfigured) {
        setState(() {
          _missingTemplate = true;
          _isLoading = false;
        });
        return;
      }
      _template = template;

      try {
        final resp = await http.get(Uri.parse(template.backgroundImageUrl));
        if (resp.statusCode == 200) {
          _bgImage = await PosterCompositor.loadImage(resp.bodyBytes);
        }
      } catch (_) {
        // Background failing to load still lets the rest of the poster
        // (photo + text) render on the fallback dark backdrop.
      }

      await _loadInitialPhoto();
      _rebuildPreview();
    } catch (e) {
      _errorMessage = 'Failed to load poster: $e';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadInitialPhoto() async {
    if (widget.student.photoUrl.isEmpty) return;
    try {
      final resp = await http.get(Uri.parse(widget.student.photoUrl));
      if (resp.statusCode == 200) {
        _studentImage = await PosterCompositor.loadImage(resp.bodyBytes);
      } else {
        _photoLoadFailed = true;
      }
    } catch (_) {
      _photoLoadFailed = true;
    }
  }

  void _rebuildPreview() {
    if (_template == null) return;
    setState(() {
      _previewFuture = PosterCompositor.composeToImage(PosterComposeData(
        template: _template!,
        background: _bgImage,
        studentImage: _studentImage,
        studentName: widget.student.studentName,
        teamName: widget.student.teamName,
        // ⬅️ NEW: this is what actually makes "Program Name" show up on
        // the poster now — the field existed on StudentBestResult all
        // along, it just wasn't being passed into the compose data.
        programName: widget.student.programName,
        points: widget.student.points,
        rank: widget.student.bestRank,
      ));
    });
  }
  bool _isProcessingImage = false;

  /// Runs on a background isolate via compute() — decodes the picked image
  /// and downscales it if it's larger than 2000px on the long edge, so the
  /// crop screen never has to process a full-resolution gallery photo.
  Uint8List _resizeForCrop(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;
    if (decoded.width <= 2000 && decoded.height <= 2000) return bytes;

    final resized = img.copyResize(
      decoded,
      width: decoded.width >= decoded.height ? 2000 : null,
      height: decoded.height > decoded.width ? 2000 : null,
    );
    return Uint8List.fromList(img.encodeJpg(resized, quality: 90));
  }

  Future<void> _changeImage() async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
      );
      if (file == null) return;

      final rawBytes = await file.readAsBytes();
      if (!mounted) return;

      // Downscale off the main isolate before handing to the crop screen.
      final resizedBytes = await compute(_resizeForCrop, rawBytes);
      if (!mounted) return;

      final Uint8List? cropped = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute(builder: (_) => PhotoCropScreen(imageBytes: resizedBytes)),
      );
      final bytes = cropped ?? resizedBytes;

      // Show a spinner while the (potentially heavy) load/compose work runs.
      setState(() => _isProcessingImage = true);

      final image = await PosterCompositor.loadImage(bytes);
      if (!mounted) return;

      setState(() {
        _studentImage = image;
        _photoLoadFailed = false;
        _isProcessingImage = false;
      });
      _rebuildPreview();
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update image: $e')),
        );
      }
    }
  }

  Future<void> _generateAndShare() async {
    if (_template == null) return;
    setState(() => _isGenerating = true);
    try {
      final bytes = await PosterCompositor.composeToPngBytes(PosterComposeData(
        template: _template!,
        background: _bgImage,
        studentImage: _studentImage,
        studentName: widget.student.studentName,
        teamName: widget.student.teamName,
        // ⬅️ NEW: same as above — keeps the shared/downloaded PNG in sync
        // with the live preview instead of silently dropping this field.
        programName: widget.student.programName,
        points: widget.student.points,
        rank: widget.student.bestRank,
      ));
      final safeName = widget.student.studentName.replaceAll(RegExp(r'\s+'), '_');
      final file = XFile.fromData(bytes, name: '${safeName}_poster.png', mimeType: 'image/png');
      await SharePlus.instance.share(ShareParams(
        files: [file],
        text: 'ലഹരിക്കെതിരെ സർഗ പ്രതിരോധം\nTOOFAN\nThe Art Hunt\nമീം മീറാസ് ഫെസ്റ്റ്\nSEASON 5\nMEERASUL AMBIYA HIGHER SECONDARY MADRASA,Oravampuram',
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to generate poster: $e')));
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  // ---- Medal palette, same language as the result/poster-list screens ----
  List<Color> get _medalColors {
    switch (widget.student.bestRank) {
      case 1:
        return [const Color(0xFFFFE07A), const Color(0xFFFFA727)];
      case 2:
        return [const Color(0xFFEAEFF5), const Color(0xFFB6C0CC)];
      case 3:
        return [const Color(0xFFF6C199), const Color(0xFFCB7A3E)];
      default:
        return [const Color(0xFFB9C2FF), const Color(0xFF7A86E8)];
    }
  }

  String get _medalGlyph {
    switch (widget.student.bestRank) {
      case 1:
        return '🥇 1st Place';
      case 2:
        return '🥈 2nd Place';
      case 3:
        return '🥉 3rd Place';
      default:
        return 'Rank #${widget.student.bestRank}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasUsableImage = _studentImage != null;
    final medalColors = _medalColors;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: Colors.white),
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFFFF6BAA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(widget.student.studentName, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF3F0FF), Color(0xFFFDF2FF), Color(0xFFF6FAFF)],
            stops: [0.0, 0.35, 1.0],
          ),
        ),
        child: SafeArea(
          top: false,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
              : _errorMessage != null
              ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(_errorMessage!, textAlign: TextAlign.center),
            ),
          )
              : _missingTemplate
              ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: const Icon(Icons.image_not_supported_outlined, size: 36, color: Color(0xff9CA3AF)),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'The poster design for this rank hasn\'t been set up yet.\nPlease check back later.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xff6B7280)),
                  ),
                ],
              ),
            ),
          )
              : SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 100, 18, 24),
            child: Column(
              children: [
                // ---- Rank badge pill ----
                FadeSlideAnimation(
                  order: 1,
                  from: SlideFrom.top,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: medalColors),
                      borderRadius: BorderRadius.circular(9999),
                      boxShadow: [
                        BoxShadow(color: medalColors.last.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 5)),
                      ],
                    ),
                    child: Text(
                      _medalGlyph,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: widget.student.bestRank == 2 ? const Color(0xff374151) : Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // ---- Poster preview — glowing 3D card ----
                FadeSlideAnimation(
                  order: 2,
                  from: SlideFrom.bottom,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: medalColors.last.withValues(alpha: 0.30),
                          blurRadius: 30,
                          spreadRadius: -4,
                          offset: const Offset(0, 16),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: PosterPreview(
                      future: _previewFuture,
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                if (_photoLoadFailed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      'Your saved photo couldn\'t be loaded — pick one below.',
                      style: GoogleFonts.inter(color: const Color(0xffEF4444), fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),

                // ---- Change / Add Image — glassy gradient-bordered pill ----
                FadeSlideAnimation(
                  order: 3,
                  from: SlideFrom.bottom,
                  child: SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.35), width: 1.4),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _changeImage,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  hasUsableImage ? Icons.edit_rounded : Icons.add_a_photo_outlined,
                                  size: 18,
                                  color: const Color(0xFF6C63FF),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  hasUsableImage ? 'Change Image' : 'Add Image',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                    color: const Color(0xFF6C63FF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ---- Generate & Share — full gradient CTA ----
                FadeSlideAnimation(
                  order: 4,
                  from: SlideFrom.bottom,
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFFFF6BAA)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _isGenerating ? null : _generateAndShare,
                          child: Center(
                            child: _isGenerating
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                            )
                                : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.share_rounded, color: Colors.white, size: 19),
                                const SizedBox(width: 8),
                                Text(
                                  'Generate & Share',
                                  style: GoogleFonts.inter(
                                      color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}