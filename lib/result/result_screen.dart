import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:meeras_fest_app/result/resultProvider.dart';
import 'package:provider/provider.dart';

import '../home/home_screen.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  @override
  void initState() {
    super.initState();
    final provider = context.read<ResultProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) provider.fetchResults();
    });
  }

  // ---------------------------------------------------------------------
  // Colorful gradient palette per category — each entry drives the pill
  // color AND the card's top accent bar, for a cohesive "3D" look.
  // ---------------------------------------------------------------------
  static const List<List<Color>> _palette = [
    [Color(0xFF6C63FF), Color(0xFF4834D4)], // violet
    [Color(0xFFFF9A56), Color(0xFFFF6B6B)], // sunset
    [Color(0xFFFF6BAA), Color(0xFFC44BC7)], // pink-magenta
    [Color(0xFF2ED9C3), Color(0xFF1B9E86)], // teal
    [Color(0xFF56CCF2), Color(0xFF2F80ED)], // sky blue
    [Color(0xFFFFC371), Color(0xFFFF5F6D)], // amber-coral
  ];

  List<Color> _gradientFor(String category) {
    if (category.isEmpty) return _palette[0];
    return _palette[category.hashCode.abs() % _palette.length];
  }

  // Medal styling: gold / silver / bronze get their own gradient + glow.
  List<Color> _medalGradient(int rank) {
    switch (rank) {
      case 1:
        return [const Color(0xFFFFE07A), const Color(0xFFFFA727)]; // gold
      case 2:
        return [const Color(0xFFEAEFF5), const Color(0xFFB6C0CC)]; // silver
      case 3:
        return [const Color(0xFFF6C199), const Color(0xFFCB7A3E)]; // bronze
      default:
        return [const Color(0xFFB9C2FF), const Color(0xFF7A86E8)]; // default
    }
  }

  String _medalGlyph(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '#$rank';
    }
  }

  String _formatPoints(num points) =>
      points % 1 == 0 ? points.toInt().toString() : points.toString();

  void _openPhoto(BuildContext context, String photoUrl, String studentName) {
    if (photoUrl.isEmpty) return;
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  photoUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    width: 200,
                    color: Colors.white,
                    child: const Icon(Icons.broken_image,
                        size: 48, color: Color(0xff9CA3AF)),
                  ),
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const SizedBox(
                      height: 200,
                      width: 200,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              studentName,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Soft, colorful backdrop gradient — sets the "not just white"
        // tone for the whole screen.
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF3F0FF),
              Color(0xFFFDF2FF),
              Color(0xFFF6FAFF),
            ],
            stops: [0.0, 0.35, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFFFF6BAA)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6C63FF).withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.emoji_events_rounded,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFF4834D4), Color(0xFFFF6B6B)],
                          ).createShader(bounds),
                          child: Text(
                            "Results",
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                            ),
                          ),
                        ),
                        Text(
                          "Check out the latest winners",
                          style: GoogleFonts.inter(
                            color: const Color(0xff6B7280),
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // ---------- Filter row ----------
              Consumer<ResultProvider>(
                builder: (context, resultPro, child) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _FilterPill(
                          label: 'Program',
                          value: resultPro.selectedProgramName,
                          options: resultPro.programNameOptions,
                          onChanged: resultPro.setProgramNameFilter,
                        ),
                        _FilterPill(
                          label: 'Category',
                          value: resultPro.selectedCategory,
                          options: resultPro.categoryOptions,
                          onChanged: resultPro.setCategoryFilter,
                        ),
                        _FilterPill(
                          label: 'Student Category',
                          value: resultPro.selectedStudentCategory,
                          options: resultPro.studentCategoryOptions,
                          onChanged: resultPro.setStudentCategoryFilter,
                        ),
                        _FilterPill(
                          label: 'Stage Type',
                          value: resultPro.selectedStageType,
                          options: resultPro.stageTypeOptions,
                          onChanged: resultPro.setStageTypeFilter,
                        ),
                        if (resultPro.hasActiveFilters)
                          InkWell(
                            onTap: resultPro.clearFilters,
                            borderRadius: BorderRadius.circular(9999),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                                ),
                                borderRadius: BorderRadius.circular(9999),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF6B6B)
                                        .withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Text(
                                'Clear',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),

              // ---------- Results list ----------
              Expanded(
                child: Consumer<ResultProvider>(
                  builder: (context, resultPro, child) {
                    if (resultPro.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
                        ),
                      );
                    }
                    if (resultPro.errorMessage != null) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: SelectableText(
                            resultPro.errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xff6B7280)),
                          ),
                        ),
                      );
                    }

                    final results = resultPro.results;
                    if (results.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text(
                            resultPro.hasActiveFilters
                                ? 'No results match these filters'
                                : 'No results published yet',
                            style: const TextStyle(color: Color(0xff6B7280)),
                          ),
                        ),
                      );
                    }

                    return RefreshIndicator(
                      color: const Color(0xFF6C63FF),
                      onRefresh: resultPro.fetchResults,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 4, bottom: 20),
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final program = results[index];
                          final gradient = _gradientFor(program.category);

                          return FadeSlideAnimation(
                            order: index,
                            from: SlideFrom.bottom,
                            child: _ResultCard(
                              program: program,
                              gradient: gradient,
                              medalGradient: _medalGradient,
                              medalGlyph: _medalGlyph,
                              formatPoints: _formatPoints,
                              onAvatarTap: (url, name) =>
                                  _openPhoto(context, url, name),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single program's result card — built with layered shadows (a soft
/// dark shadow below + a subtle white highlight above) to fake a raised,
/// "3D" surface, plus a colorful gradient accent bar tied to the category.
///
/// Initially shows only ranks 1-3 (program.topEntries), same as before.
/// If the program has more ranked entries than that (program.allEntries),
/// a "View more" pill appears at the bottom of the card — tapping it
/// expands the card in place to show every rank; tapping "View less"
/// collapses it back to the top 3.
class _ResultCard extends StatefulWidget {
  final dynamic program; // ProgramResult
  final List<Color> gradient;
  final List<Color> Function(int rank) medalGradient;
  final String Function(int rank) medalGlyph;
  final String Function(num points) formatPoints;
  final void Function(String url, String name) onAvatarTap;

  const _ResultCard({
    required this.program,
    required this.gradient,
    required this.medalGradient,
    required this.medalGlyph,
    required this.formatPoints,
    required this.onAvatarTap,
  });

  @override
  State<_ResultCard> createState() => _ResultCardState();
}

class _ResultCardState extends State<_ResultCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final program = widget.program;
    final gradient = widget.gradient;

    final List<dynamic> allEntries = program.allEntries;
    final List<dynamic> topEntries = program.topEntries;
    final bool hasMore = allEntries.length > topEntries.length;
    final List<dynamic> visibleEntries = _expanded ? allEntries : topEntries;

    return Container(
      margin: const EdgeInsets.only(right: 14, left: 14, bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          // Main "drop" shadow — gives the card lift off the page.
          BoxShadow(
            color: gradient.last.withValues(alpha: 0.18),
            blurRadius: 20,
            spreadRadius: -2,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient accent bar along the top — subtle 3D bevel via
          // a soft inner highlight.
          Container(
            height: 6,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  program.programName,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xff1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: gradient),
                      borderRadius: BorderRadius.circular(9999),
                      boxShadow: [
                        BoxShadow(
                          color: gradient.last.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4),
                      child: Text(
                        program.category.isEmpty ? '—' : program.category,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...List.generate(visibleEntries.length, (i) {
                        final entry = visibleEntries[i];
                        final medalColors = widget.medalGradient(entry.rank);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // ---- Avatar with glowing gradient ring + medal badge ----
                              GestureDetector(
                                onTap: () => widget.onAvatarTap(
                                    entry.photoUrl, entry.studentName),
                                child: SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient:
                                          LinearGradient(colors: medalColors),
                                          boxShadow: [
                                            BoxShadow(
                                              color: medalColors.last
                                                  .withValues(alpha: 0.45),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: ClipOval(
                                          child: Container(
                                            color: const Color(0xffF3F4F6),
                                            child: entry.photoUrl.isNotEmpty
                                                ? Image.network(
                                              entry.photoUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error,
                                                  stackTrace) =>
                                              const Icon(
                                                Icons.person,
                                                size: 18,
                                                color: Color(0xff9CA3AF),
                                              ),
                                              loadingBuilder: (context, child,
                                                  progress) {
                                                if (progress == null) {
                                                  return child;
                                                }
                                                return const Center(
                                                  child: SizedBox(
                                                    width: 14,
                                                    height: 14,
                                                    child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 1.5),
                                                  ),
                                                );
                                              },
                                            )
                                                : const Icon(
                                              Icons.person,
                                              size: 18,
                                              color: Color(0xff9CA3AF),
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Medal badge, pinned to bottom-right — its own
                                      // little gradient chip for a "3D sticker" feel.
                                      Positioned(
                                        bottom: -2,
                                        right: -4,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.12),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: LinearGradient(
                                                  colors: medalColors),
                                            ),
                                            child: Text(
                                              entry.rank <= 3
                                                  ? widget.medalGlyph(entry.rank)
                                                  : '${entry.rank}',
                                              style: GoogleFonts.inter(
                                                fontSize:
                                                entry.rank <= 3 ? 10 : 9,
                                                height: 1,
                                                fontWeight: FontWeight.w800,
                                                color: entry.rank <= 3
                                                    ? null
                                                    : Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      entry.studentName,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xff374151),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      entry.teamName,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w400,
                                        color: const Color(0xff9CA3AF),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFB9C2FF),
                                      Color(0xFF6C63FF)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(9999),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF6C63FF)
                                          .withValues(alpha: 0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 9, vertical: 5),
                                  child: Text(
                                    '${widget.formatPoints(entry.points)} Pts',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                if (hasMore)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Center(
                      child: InkWell(
                        onTap: () => setState(() => _expanded = !_expanded),
                        borderRadius: BorderRadius.circular(9999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: gradient.first.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _expanded
                                    ? 'View less'
                                    : 'View more (${allEntries.length - topEntries.length})',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: gradient.last,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                _expanded
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                size: 16,
                                color: gradient.last,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A frosted-glass, gradient-bordered dropdown pill used for each of the
/// independent result filters (Program / Category / Student Category /
/// Stage Type).
class _FilterPill extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  const _FilterPill({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = value != null;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9999),
        gradient: isActive
            ? const LinearGradient(
          colors: [Color(0xFFFF9A56), Color(0xFFFF6B6B)],
        )
            : null,
        color: isActive ? null : Colors.white,
        boxShadow: [
          BoxShadow(
            color: isActive
                ? const Color(0xFFFF6B6B).withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: isActive ? 10 : 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: isActive
            ? null
            : Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 16,
            color: isActive ? Colors.white : const Color(0xff4B5563),
          ),
          dropdownColor: Colors.white,
          hint: Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xff4B5563)),
          ),
          items: [
            DropdownMenuItem<String?>(value: null, child: Text('All $label')),
            ...options.map((o) => DropdownMenuItem<String?>(value: o, child: Text(o))),
          ],
          onChanged: onChanged,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isActive ? Colors.white : const Color(0xff4B5563),
          ),
        ),
      ),
    );
  }
}