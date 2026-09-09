import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:meeras_fest_app/poster/poster_template_model.dart';
import 'package:meeras_fest_app/poster/poster_template_provider.dart';
import 'package:provider/provider.dart';

import '../admin/adminWidgets.dart';


const _rankTabLabels = {'rank_1': 'Rank 1', 'rank_2': 'Rank 2', 'rank_3': 'Rank 3', 'default': 'Default'};

/// Preset swatches offered for every color picker on this page, plus a
/// "custom" entry (last one) that opens an RGB dialog for anything else.
const _presetColors = <int>[
  0xFFFFFFFF, // white
  0xFF000000, // black
  0xFFFFD700, // gold
  0xFFC0C0C0, // silver
  0xFFCD7F32, // bronze
  0xFFEF4444, // red
  0xFF3B82F6, // blue
  0xFF10B981, // green
  0xFFF59E0B, // amber
  0xFF8B5CF6, // purple
];

class PosterTemplateEditorPage extends StatefulWidget {
  const PosterTemplateEditorPage({super.key});

  @override
  State<PosterTemplateEditorPage> createState() => _PosterTemplateEditorPageState();
}

class _PosterTemplateEditorPageState extends State<PosterTemplateEditorPage> {
  static const double _canvasW = 1080;
  static const double _canvasH = 1920;

  Future<void> _save(BuildContext context) async {
    final provider = context.read<PosterTemplateProvider>();
    final error = await provider.saveCurrent();
    if (!context.mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      showAdminSuccessDialog(context, message: '${_rankTabLabels[provider.currentRankKey]} template saved');
    }
  }

  Future<void> _pickColor(BuildContext context, int current, ValueChanged<int> onPicked) async {
    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) => _ColorPickerDialog(initial: current),
    );
    if (picked != null) onPicked(picked);
  }

  /// Everything that isn't the live drag-canvas now lives in this single
  /// bottom sheet — background upload, photo shape/border, AND the
  /// per-text font-size/color controls (previously a fixed strip under
  /// the canvas). Moving all of that off-screen by default is what frees
  /// up nearly the entire screen height for the poster preview itself.
  void _openCustomizeSheet(BuildContext context, PosterTemplateProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      // showModalBottomSheet inserts its content as a new route in the
      // Navigator's Overlay — a SIBLING of this page's route, not a
      // descendant of it. So if PosterTemplateProvider is only provided
      // above this page (not above the whole Navigator/MaterialApp), the
      // sheet's subtree can't see it via a plain Consumer, and throws
      // ProviderNotFoundException. Fix: re-inject the *same* provider
      // instance (captured from the calling context, which does have
      // access to it) into the sheet's own route with `.value`.
      builder: (sheetContext) {
        return ChangeNotifierProvider<PosterTemplateProvider>.value(
          value: provider,
          child: Consumer<PosterTemplateProvider>(
            builder: (context, provider, child) {
              return DraggableScrollableSheet(
                initialChildSize: 0.6,
                minChildSize: 0.3,
                maxChildSize: 0.92,
                expand: false,
                builder: (context, scrollController) {
                  return SingleChildScrollView(
                    controller: scrollController,
                    padding: EdgeInsets.only(
                      left: 16, right: 16, top: 16,
                      bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Text Styles',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xff1F2937))),
                        const SizedBox(height: 10),
                        _TextStyleSheetRow(
                          label: 'Program Name',
                          config: provider.current.programName,
                          onSizeChanged: (v) => provider.updateCurrent(
                                  (t) => t.copyWith(programName: t.programName.copyWith(fontSize: v))),
                          onColorTap: () => _pickColor(
                            context,
                            provider.current.programName.colorValue,
                                (c) => provider.updateCurrent(
                                    (t) => t.copyWith(programName: t.programName.copyWith(colorValue: c))),
                          ),
                        ),
                        _TextStyleSheetRow(
                          label: 'Student Name',
                          config: provider.current.studentName,
                          onSizeChanged: (v) => provider.updateCurrent(
                                  (t) => t.copyWith(studentName: t.studentName.copyWith(fontSize: v))),
                          onColorTap: () => _pickColor(
                            context,
                            provider.current.studentName.colorValue,
                                (c) => provider.updateCurrent(
                                    (t) => t.copyWith(studentName: t.studentName.copyWith(colorValue: c))),
                          ),
                        ),
                        _TextStyleSheetRow(
                          label: 'Team Name',
                          config: provider.current.teamName,
                          onSizeChanged: (v) => provider.updateCurrent(
                                  (t) => t.copyWith(teamName: t.teamName.copyWith(fontSize: v))),
                          onColorTap: () => _pickColor(
                            context,
                            provider.current.teamName.colorValue,
                                (c) => provider.updateCurrent(
                                    (t) => t.copyWith(teamName: t.teamName.copyWith(colorValue: c))),
                          ),
                        ),
                        const Divider(height: 28),
                        const Text('Background & Photo',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xff1F2937))),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: provider.isUploadingBackground
                                ? null
                                : () async {
                              final error = await provider.pickAndUploadBackground();
                              if (error != null && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                              }
                            },
                            icon: provider.isUploadingBackground
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.image_outlined),
                            label: Text(provider.current.backgroundImageUrl.isEmpty
                                ? 'Upload Background'
                                : 'Change Background'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _ImageShapeControls(
                          config: provider.current.studentImage,
                          onCircularChanged: (v) => provider
                              .updateCurrent((t) => t.copyWith(studentImage: t.studentImage.copyWith(circular: v))),
                          onRadiusChanged: (v) => provider
                              .updateCurrent((t) => t.copyWith(studentImage: t.studentImage.copyWith(borderRadius: v))),
                          onBorderWidthChanged: (v) => provider
                              .updateCurrent((t) => t.copyWith(studentImage: t.studentImage.copyWith(borderWidth: v))),
                          onBorderColorTap: () => _pickColor(
                            context,
                            provider.current.studentImage.borderColorValue,
                                (c) => provider.updateCurrent(
                                    (t) => t.copyWith(studentImage: t.studentImage.copyWith(borderColorValue: c))),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Poster Templates'),
        backgroundColor: const Color(0xFFEC4899),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Consumer<PosterTemplateProvider>(
            builder: (context, provider, child) => IconButton(
              tooltip: 'Text, background & photo settings',
              icon: const Icon(Icons.tune),
              onPressed: () => _openCustomizeSheet(context, provider),
            ),
          ),
        ],
      ),
      body: Consumer<PosterTemplateProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) return const Center(child: CircularProgressIndicator());

          return Column(
            children: [
              // ---- Rank tabs (compact single row) ----
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 2),
                child: Wrap(
                  spacing: 8,
                  children: PosterTemplateProvider.rankKeys.map((key) {
                    final selected = provider.currentRankKey == key;
                    return ChoiceChip(
                      label: Text(_rankTabLabels[key]!),
                      selected: selected,
                      onSelected: (_) => provider.selectRankKey(key),
                      selectedColor: const Color(0xFFEC4899),
                      labelStyle: TextStyle(color: selected ? Colors.white : const Color(0xff374151)),
                    );
                  }).toList(),
                ),
              ),

              if (provider.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(provider.errorMessage!, style: const TextStyle(color: Color(0xffEF4444))),
                ),

              if (provider.current.backgroundImageUrl.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  child: Text(
                    'Tip: tap the ⚙ icon above to upload a background',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ),

              // ---- Drag canvas — this now owns essentially the entire
              // remaining screen. Score/Rank handles were removed from
              // the editor entirely, and font-size/color + background/
              // photo controls moved into the "tune" bottom sheet, so
              // there's no other chrome competing with the canvas for space.
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: _canvasW / _canvasH,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final scale = constraints.maxWidth / _canvasW;
                          return Container(
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                              // Background image is drawn with fit: cover and no
                              // color/opacity overlay — it renders exactly as
                              // uploaded, fully visible. The dark fill below is
                              // only a placeholder shown before any image is set.
                              image: provider.current.backgroundImageUrl.isNotEmpty
                                  ? DecorationImage(
                                  image: NetworkImage(provider.current.backgroundImageUrl), fit: BoxFit.cover)
                                  : null,
                              color: provider.current.backgroundImageUrl.isEmpty ? const Color(0xFF1F2937) : null,
                            ),
                            child: Stack(
                              children: [
                                _DraggableImageBox(scale: scale, provider: provider),
                                _DraggableTextHandle(
                                  scale: scale,
                                  sampleText: 'Program Name',
                                  config: provider.current.programName,
                                  onMoved: (x, y) => provider.updateCurrent(
                                          (t) => t.copyWith(programName: t.programName.copyWith(x: x, y: y))),
                                ),
                                _DraggableTextHandle(
                                  scale: scale,
                                  sampleText: 'Student Name',
                                  config: provider.current.studentName,
                                  onMoved: (x, y) => provider.updateCurrent(
                                          (t) => t.copyWith(studentName: t.studentName.copyWith(x: x, y: y))),
                                ),
                                _DraggableTextHandle(
                                  scale: scale,
                                  sampleText: 'Team Name',
                                  config: provider.current.teamName,
                                  onMoved: (x, y) => provider.updateCurrent(
                                          (t) => t.copyWith(teamName: t.teamName.copyWith(x: x, y: y))),
                                ),
                                // Score and Rank handles intentionally removed
                                // from the editor per request — their data
                                // fields still exist on the model (untouched,
                                // default position) in case another part of
                                // the app still renders them from saved data.
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),

              // ---- Save ----
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                child: AdminSubmitButton(
                  label: 'Save ${_rankTabLabels[provider.currentRankKey]} Template',
                  loading: provider.isSaving,
                  onPressed: () => _save(context),
                  color: const Color(0xFFEC4899),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The student photo box — drag to move, drag the corner handle to resize.
/// Shape (circle vs rounded-rect radius) and border (width + color) all
/// come from [PosterImageConfig] so the preview matches what actually
/// renders on the final poster. Screen-pixel deltas are divided by [scale]
/// to convert into the fixed 1080x1920 logical coordinate system before
/// being stored.
///
/// NOTE: `clipBehavior: Clip.antiAlias` is set below so that once a real
/// photo is drawn inside this box (e.g. on the actual generated poster,
/// not just this placeholder), it gets clipped to the circle / rounded-rect
/// shape instead of just having a border/radius drawn on top of a square
/// image. If your final poster-rendering screen builds this box
/// separately, make sure it also uses ClipRRect/ClipOval (or
/// clipBehavior: Clip.antiAlias) matching `cfg.circular` / `cfg.borderRadius`
/// — otherwise the border radius will look right here but the real photo
/// won't actually be cropped.
class _DraggableImageBox extends StatelessWidget {
  final double scale;
  final PosterTemplateProvider provider;
  const _DraggableImageBox({required this.scale, required this.provider});

  @override
  Widget build(BuildContext context) {
    final cfg = provider.current.studentImage;
    return Positioned(
      left: cfg.x * scale,
      top: cfg.y * scale,
      width: cfg.width * scale,
      height: cfg.height * scale,
      child: GestureDetector(
        onPanUpdate: (details) {
          provider.updateCurrent((t) => t.copyWith(
            studentImage: t.studentImage.copyWith(
              x: t.studentImage.x + details.delta.dx / scale,
              y: t.studentImage.y + details.delta.dy / scale,
            ),
          ));
        },
        child: Stack(
          children: [
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                shape: cfg.circular ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: cfg.circular ? null : BorderRadius.circular(cfg.borderRadius * scale),
                border: cfg.borderWidth > 0
                    ? Border.all(color: cfg.borderColor, width: cfg.borderWidth * scale)
                    : null,
                color: const Color(0x336366F1),
              ),
              child: const Center(child: Icon(Icons.person, color: Color(0xFF6366F1))),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onPanUpdate: (details) {
                  provider.updateCurrent((t) => t.copyWith(
                    studentImage: t.studentImage.copyWith(
                      width: (t.studentImage.width + details.delta.dx / scale).clamp(60.0, 1080.0).toDouble(),
                      height: (t.studentImage.height + details.delta.dy / scale).clamp(60.0, 1920.0).toDouble(),
                    ),
                  ));
                },
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(color: Color(0xFF6366F1), shape: BoxShape.circle),
                  child: const Icon(Icons.open_in_full, size: 12, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A draggable text element. Renders the *actual* sample copy ("Team Name",
/// "Student Name", etc.) in the field's real font size/weight/color so the
/// handle previews exactly what will appear on the finished poster — a
/// small grab icon sits above it so it stays easy to pick up on a busy
/// background. Text visibly grows/shrinks and re-colors live as the font
/// size / color controls in the "tune" sheet are changed.
class _DraggableTextHandle extends StatelessWidget {
  final double scale;
  final String sampleText;
  final PosterTextStyleConfig config;
  final void Function(double x, double y) onMoved;

  const _DraggableTextHandle({
    required this.scale,
    required this.sampleText,
    required this.config,
    required this.onMoved,
  });

  @override
  Widget build(BuildContext context) {
    // Reflects the real scale factor directly — no artificial cap. With the
    // canvas now filling almost the whole screen, scale is large enough
    // that font-size changes are clearly visible. Bounds are explicit
    // doubles and `.toDouble()`'d to avoid `num` vs `double` ambiguity
    // from clamp(), which is what could make size changes look like
    // they "don't take effect" on some Dart/analyzer versions.
    final previewFontSize = (config.fontSize * scale).clamp(6.0, 400.0).toDouble();

    final textStyle = GoogleFonts.inter(
      fontSize: previewFontSize,
      fontWeight: config.flutterWeight,
      color: config.color,
      shadows: const [
        Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 1)),
      ],
    );

    // Measure the text exactly as PosterCompositor does, so the horizontal
    // anchor here matches its alignment math pixel-for-pixel:
    // dx = cfg.x for 'left', cfg.x - width/2 for 'center', cfg.x - width
    // for 'right'. Previously this used a Column with
    // crossAxisAlignment.center, which just centers the text under the
    // 16px grab icon's own width — it ignored `alignment` entirely and
    // never matched where the compositor actually draws the text.
    final painter = TextPainter(
      text: TextSpan(text: sampleText, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    double dxOffset = 0;
    if (config.alignment == 'center') dxOffset = -painter.width / 2;
    if (config.alignment == 'right') dxOffset = -painter.width;

    return Positioned(
      // top is exactly config.y * scale — no extra offset — because
      // PosterCompositor paints the text's top-left starting exactly at
      // (x, y). The old Column (icon, then SizedBox(height: 2), then
      // text) pushed the *visible* text down by (16 + 2) screen px from
      // this point, so a position that looked right in the editor was
      // always rendered noticeably higher on the real poster.
      left: config.x * scale + dxOffset,
      top: config.y * scale,
      child: GestureDetector(
        onPanUpdate: (details) {
          onMoved(config.x + details.delta.dx / scale, config.y + details.delta.dy / scale);
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Grab icon now sits as a pure visual overlay ABOVE the text
            // (negative top) instead of a layout sibling that shifts the
            // text's position — it no longer affects where sampleText is
            // anchored.
            Positioned(
              left: (painter.width / 2) - 8,
              top: -20,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.open_with, size: 10, color: Colors.white),
              ),
            ),
            Text(
              sampleText,
              textAlign: config.flutterAlign,
              style: textStyle,
            ),
          ],
        ),
      ),
    );
  }
}

/// Font-size slider + color swatch for one text field, laid out as a full
/// width row for use inside the "tune" bottom sheet (replaces the old
/// fixed-height horizontal strip that used to sit under the canvas).
class _TextStyleSheetRow extends StatelessWidget {
  final String label;
  final PosterTextStyleConfig config;
  final ValueChanged<double> onSizeChanged;
  final VoidCallback onColorTap;

  const _TextStyleSheetRow({
    required this.label,
    required this.config,
    required this.onSizeChanged,
    required this.onColorTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xff374151))),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.remove_circle_outline, size: 20),
            onPressed: () => onSizeChanged((config.fontSize - 2).clamp(10.0, 200.0).toDouble()),
          ),
          SizedBox(
            width: 32,
            child: Text('${config.fontSize.toInt()}',
                textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.add_circle_outline, size: 20),
            onPressed: () => onSizeChanged((config.fontSize + 2).clamp(10.0, 200.0).toDouble()),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onColorTap,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: config.color,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD1D5DB)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Circle/rect toggle + radius slider (rect only) + border width slider +
/// border color swatch, for the student photo box.
class _ImageShapeControls extends StatelessWidget {
  final PosterImageConfig config;
  final ValueChanged<bool> onCircularChanged;
  final ValueChanged<double> onRadiusChanged;
  final ValueChanged<double> onBorderWidthChanged;
  final VoidCallback onBorderColorTap;

  const _ImageShapeControls({
    required this.config,
    required this.onCircularChanged,
    required this.onRadiusChanged,
    required this.onBorderWidthChanged,
    required this.onBorderColorTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Photo Shape', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xff374151))),
          Row(
            children: [
              const Text('Circle', style: TextStyle(fontSize: 12, color: Color(0xff6B7280))),
              Switch(
                value: config.circular,
                activeColor: const Color(0xFFEC4899),
                onChanged: onCircularChanged,
              ),
              const Text('Rectangle', style: TextStyle(fontSize: 12, color: Color(0xff6B7280))),
            ],
          ),
          if (!config.circular)
            Row(
              children: [
                const SizedBox(width: 60, child: Text('Radius', style: TextStyle(fontSize: 12, color: Color(0xff6B7280)))),
                Expanded(
                  child: Slider(
                    value: config.borderRadius.clamp(0.0, 200.0).toDouble(),
                    min: 0,
                    max: 200,
                    activeColor: const Color(0xFFEC4899),
                    onChanged: onRadiusChanged,
                  ),
                ),
                SizedBox(width: 32, child: Text('${config.borderRadius.toInt()}', style: const TextStyle(fontSize: 12))),
              ],
            ),
          Row(
            children: [
              const SizedBox(width: 60, child: Text('Border', style: TextStyle(fontSize: 12, color: Color(0xff6B7280)))),
              Expanded(
                child: Slider(
                  value: config.borderWidth.clamp(0.0, 20.0).toDouble(),
                  min: 0,
                  max: 20,
                  activeColor: const Color(0xFFEC4899),
                  onChanged: onBorderWidthChanged,
                ),
              ),
              SizedBox(width: 32, child: Text('${config.borderWidth.toInt()}', style: const TextStyle(fontSize: 12))),
              GestureDetector(
                onTap: onBorderColorTap,
                child: Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    color: config.borderColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFD1D5DB)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Simple color picker: a grid of presets plus an RGB-slider "custom" tab
/// — kept dependency-free rather than pulling in a color-picker package.
class _ColorPickerDialog extends StatefulWidget {
  final int initial;
  const _ColorPickerDialog({required this.initial});

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late Color _custom = Color(widget.initial);
  bool _showCustom = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choose Color'),
      content: SizedBox(
        width: 280,
        child: _showCustom
            ? _buildCustomSliders()
            : Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final c in _presetColors)
              GestureDetector(
                onTap: () => Navigator.pop(context, c),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Color(c),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: c == widget.initial ? const Color(0xFFEC4899) : const Color(0xFFD1D5DB),
                      width: c == widget.initial ? 3 : 1,
                    ),
                  ),
                ),
              ),
            GestureDetector(
              onTap: () => setState(() => _showCustom = true),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFD1D5DB)),
                  gradient: const SweepGradient(colors: [
                    Colors.red, Colors.yellow, Colors.green, Colors.cyan, Colors.blue, Colors.purple, Colors.red,
                  ]),
                ),
                child: const Icon(Icons.edit, size: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        if (_showCustom)
          TextButton(
            onPressed: () => Navigator.pop(context, _custom.value),
            child: const Text('Use Color'),
          ),
      ],
    );
  }

  Widget _buildCustomSliders() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          height: 40,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(color: _custom, borderRadius: BorderRadius.circular(8)),
        ),
        _rgbSlider('R', _custom.red, (v) => setState(() => _custom = _custom.withRed(v.toInt()))),
        _rgbSlider('G', _custom.green, (v) => setState(() => _custom = _custom.withGreen(v.toInt()))),
        _rgbSlider('B', _custom.blue, (v) => setState(() => _custom = _custom.withBlue(v.toInt()))),
      ],
    );
  }

  Widget _rgbSlider(String label, int value, ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(width: 16, child: Text(label, style: const TextStyle(fontSize: 12))),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: 0,
            max: 255,
            activeColor: const Color(0xFFEC4899),
            onChanged: onChanged,
          ),
        ),
        SizedBox(width: 30, child: Text('$value', style: const TextStyle(fontSize: 12))),
      ],
    );
  }
}