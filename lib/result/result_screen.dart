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
    // fetchResults() is async, so this is safe to call directly here —
    // the widget will already be built by the time it resolves and calls
    // notifyListeners().
    final provider = context.read<ResultProvider>();
    if (provider.results.isEmpty) {
      provider.fetchResults();
    }
  }

  // Deterministic color pair per category so any category (not just a
  // hardcoded few) gets a consistent, distinct badge color.
  static const List<Map<String, Color>> _palette = [
    {"text": Color(0xFF1D4ED8), "bg": Color(0xFFDBEAFE), "border": Color(0xFFBFDBFE)},
    {"text": Color(0xFFC2410C), "bg": Color(0xFFFFEDD5), "border": Color(0xFFFED7AA)},
    {"text": Color(0xFFBE185D), "bg": Color(0xFFFCE7F3), "border": Color(0xFFFBCFE8)},
    {"text": Color(0xFF15803D), "bg": Color(0xFFDCFCE7), "border": Color(0xFFBBF7D0)},
    {"text": Color(0xFF6D28D9), "bg": Color(0xFFEDE9FE), "border": Color(0xFFDDD6FE)},
  ];

  Map<String, Color> _colorsFor(String category) {
    if (category.isEmpty) return _palette[0];
    return _palette[category.hashCode.abs() % _palette.length];
  }

  String _medalFor(int rank) {
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
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                photoUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  width: 200,
                  color: Colors.white,
                  child: const Icon(Icons.broken_image, size: 48, color: Color(0xff9CA3AF)),
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
            const SizedBox(height: 8),
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30),
          const Padding(
            padding: EdgeInsets.only(left: 12.0),
            child: Text(
              "Result",
              style: TextStyle(color: Color(0xff1F2937), fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 12.0),
            child: Text(
              "Check out the latest winners",
              style: TextStyle(color: Color(0xff6B7280), fontWeight: FontWeight.w400, fontSize: 12),
            ),
          ),
          const SizedBox(height: 18),

          // ---------- Filter row: Program Name / Category / Student Category / Stage Type ----------
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
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          child: Text(
                            'Clear',
                            style: TextStyle(
                              color: Color(0xFFEF4444),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // ---------- Results list ----------
          Expanded(
            child: Consumer<ResultProvider>(
              builder: (context, resultPro, child) {
                if (resultPro.isLoading) {
                  return const Center(child: CircularProgressIndicator());
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
                  onRefresh: resultPro.fetchResults,
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final program = results[index];
                      final colors = _colorsFor(program.category);

                      return FadeSlideAnimation(
                        order: index,
                        from: SlideFrom.bottom,
                        child: Container(
                          margin: const EdgeInsets.only(right: 13, left: 13, bottom: 13),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.2),
                                blurRadius: 8,
                                spreadRadius: 1,
                                offset: const Offset(0, 3),
                              ),
                            ],
                            color: Colors.white,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  program.programName,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xff1F2937),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: colors["bg"],
                                      border: Border.all(color: colors["border"]!, width: 1),
                                      borderRadius: BorderRadius.circular(9999),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3),
                                      child: Text(
                                        program.category.isEmpty ? '—' : program.category,
                                        style: TextStyle(
                                          color: colors["text"],
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ...program.topEntries.map(
                                      (entry) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // ---- Student photo avatar with rank medal stacked bottom-right ----
                                        GestureDetector(
                                          onTap: () => _openPhoto(context, entry.photoUrl, entry.studentName),
                                          child: SizedBox(
                                            width: 36,
                                            height: 36,
                                            child: Stack(
                                              clipBehavior: Clip.none,
                                              children: [
                                                CircleAvatar(
                                                  radius: 16,
                                                  backgroundColor: const Color(0xffF3F4F6),
                                                  child: ClipOval(
                                                    child: entry.photoUrl.isNotEmpty
                                                        ? Image.network(
                                                      entry.photoUrl,
                                                      width: 32,
                                                      height: 32,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) => const Icon(
                                                        Icons.person,
                                                        size: 16,
                                                        color: Color(0xff9CA3AF),
                                                      ),
                                                      loadingBuilder: (context, child, progress) {
                                                        if (progress == null) return child;
                                                        return const SizedBox(
                                                          width: 16,
                                                          height: 16,
                                                          child: CircularProgressIndicator(strokeWidth: 1.5),
                                                        );
                                                      },
                                                    )
                                                        : const Icon(
                                                      Icons.person,
                                                      size: 16,
                                                      color: Color(0xff9CA3AF),
                                                    ),
                                                  ),
                                                ),
                                                // Rank medal badge, pinned to bottom-right corner
                                                Positioned(
                                                  top: 2,
                                                  right: 0,
                                                  child: Text(
                                                    _medalFor(entry.rank),
                                                    style: GoogleFonts.inter(fontSize: 14, height: 1),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              entry.studentName,
                                              style: GoogleFonts.inter(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xff6B7280),
                                              ),
                                            ),
                                            Text(
                                              entry.teamName,
                                              style: GoogleFonts.inter(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w400,
                                                color: const Color(0xff6B7280),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Spacer(),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: const Color(0xffFAF5FF),
                                            borderRadius: BorderRadius.circular(9999),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(5.0),
                                            child: Text(
                                              '${_formatPoints(entry.points)} Pts',
                                              style: GoogleFonts.inter(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xff667EEA),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
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
    );
  }
}

/// A dropdown styled as a rounded pill, used for each of the independent
/// result filters (Program / Category / Student Category / Stage Type).
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
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFFFF1EE) : Colors.white,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: isActive ? const Color(0xFFFF8E53) : const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
          hint: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xff4B5563))),
          items: [
            DropdownMenuItem<String?>(value: null, child: Text('All $label')),
            ...options.map((o) => DropdownMenuItem<String?>(value: o, child: Text(o))),
          ],
          onChanged: onChanged,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? const Color(0xFFFF6B6B) : const Color(0xff4B5563),
          ),
        ),
      ),
    );
  }
}