import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:meeras_fest_app/poster/student_poster_screen.dart';
import 'package:provider/provider.dart';

import '../home/home_screen.dart'; // FadeSlideAnimation / SlideFrom
import '../result/resultProvider.dart';

/// Public/Guest screen: pick a student, then view/generate their poster.
/// Reuses ResultProvider's already-fetched, already-joined data — no
/// separate Firestore reads.
class StudentPosterListScreen extends StatefulWidget {
  const StudentPosterListScreen({super.key});

  @override
  State<StudentPosterListScreen> createState() => _StudentPosterListScreenState();
}

class _StudentPosterListScreenState extends State<StudentPosterListScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    final provider = context.read<ResultProvider>();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) provider.fetchResultsPoster();
      });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Same medal palette language as ResultScreen — gold / silver / bronze
  // gradients + glow, so a student's poster-list card reads consistently
  // with how they already see their result on the Results tab.
  // ---------------------------------------------------------------------
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 18),

              // ---------- Header ----------
              FadeSlideAnimation(
                order: 1,
                from: SlideFrom.top,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xff4B5563)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6BAA), Color(0xFF6C63FF)],
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
                        child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Color(0xFFFF6B6B), Color(0xFF6C63FF)],
                            ).createShader(bounds),
                            child: Text(
                              "Get Your Poster",
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 21,
                              ),
                            ),
                          ),
                          Text(
                            "Pick a student to generate their poster",
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
              ),

              const SizedBox(height: 16),

              // ---------- Search ----------
              FadeSlideAnimation(
                order: 2,
                from: SlideFrom.bottom,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                      style: GoogleFonts.inter(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search by name or team',
                        hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xff9CA3AF)),
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xff9CA3AF)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ---------- List ----------
              Expanded(
                child: Consumer<ResultProvider>(
                  builder: (context, resultPro, child) {
                    if (resultPro.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
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

                    var students = resultPro.studentBestResults;
                    if (_query.isNotEmpty) {
                      students = students
                          .where((s) =>
                      s.studentName.toLowerCase().contains(_query) ||
                          s.teamName.toLowerCase().contains(_query))
                          .toList();
                    }

                    if (students.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text(
                            _query.isNotEmpty ? 'No students match "$_query"' : 'No results published yet',
                            style: const TextStyle(color: Color(0xff6B7280)),
                          ),
                        ),
                      );
                    }

                    return RefreshIndicator(
                      color: const Color(0xFF6C63FF),
                      onRefresh: resultPro.fetchResults,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          final s = students[index];
                          final medalColors = _medalGradient(s.bestRank);

                          return FadeSlideAnimation(
                            order: index,
                            from: SlideFrom.bottom,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: medalColors.last.withValues(alpha: 0.20),
                                    blurRadius: 18,
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
                              child: Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => StudentPosterScreen(student: s)),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        // ---- Avatar with glowing gradient ring + medal badge ----
                                        SizedBox(
                                          width: 52,
                                          height: 52,
                                          child: Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              Container(
                                                width: 48,
                                                height: 48,
                                                padding: const EdgeInsets.all(2),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  gradient: LinearGradient(colors: medalColors),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: medalColors.last.withValues(alpha: 0.45),
                                                      blurRadius: 8,
                                                      offset: const Offset(0, 3),
                                                    ),
                                                  ],
                                                ),
                                                child: ClipOval(
                                                  child: Container(
                                                    color: const Color(0xffF3F4F6),
                                                    child: s.photoUrl.isNotEmpty
                                                        ? Image.network(
                                                      s.photoUrl,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) =>
                                                      const Icon(Icons.person,
                                                          size: 20, color: Color(0xff9CA3AF)),
                                                      loadingBuilder: (context, child, progress) {
                                                        if (progress == null) return child;
                                                        return const Center(
                                                          child: SizedBox(
                                                            width: 14,
                                                            height: 14,
                                                            child: CircularProgressIndicator(strokeWidth: 1.5),
                                                          ),
                                                        );
                                                      },
                                                    )
                                                        : const Icon(Icons.person,
                                                        size: 20, color: Color(0xff9CA3AF)),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                bottom: -2,
                                                right: -4,
                                                child: Container(
                                                  padding: const EdgeInsets.all(2),
                                                  decoration: const BoxDecoration(
                                                    color: Colors.white,
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                                                    ],
                                                  ),
                                                  child: Container(
                                                    padding: const EdgeInsets.all(2),
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      gradient: LinearGradient(colors: medalColors),
                                                    ),
                                                    child: Text(
                                                      s.bestRank <= 3 ? _medalGlyph(s.bestRank) : '${s.bestRank}',
                                                      style: GoogleFonts.inter(
                                                        fontSize: s.bestRank <= 3 ? 10 : 9,
                                                        height: 1,
                                                        fontWeight: FontWeight.w800,
                                                        color: s.bestRank <= 3 ? null : Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 14),

                                        // ---- Name / team ----
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                s.studentName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.inter(
                                                    fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xff1F2937)),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                s.teamName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.inter(
                                                    fontSize: 11.5, fontWeight: FontWeight.w500, color: const Color(0xff9CA3AF)),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),

                                        // ---- CTA chip ----
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFFFF6BAA)]),
                                            borderRadius: BorderRadius.circular(9999),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF6C63FF).withValues(alpha: 0.35),
                                                blurRadius: 8,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text('View',
                                                  style: GoogleFonts.inter(
                                                      color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                                              const SizedBox(width: 3),
                                              const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Colors.white),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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
        ),
      ),
    );
  }
}