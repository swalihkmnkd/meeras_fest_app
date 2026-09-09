import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'home_stats_provider.dart';

/// Shows the Trophy.gif with an entrance animation, then the current
/// top Girls team and top Boys team scores beneath it.
///
/// If no scores exist yet (fresh fest / all zero), swaps in a pulsing
/// placeholder animation that grows continuously and shrinks briefly
/// on tap.
class TrophyScoreSection extends StatefulWidget {
  const TrophyScoreSection({super.key});

  @override
  State<TrophyScoreSection> createState() => _TrophyScoreSectionState();
}

class _TrophyScoreSectionState extends State<TrophyScoreSection>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _entranceScale;
  late final Animation<double> _entranceFade;

  @override
  void initState() {
    super.initState();
    // Trophy pop-in animation, played once when the screen/app opens.
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _entranceScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.elasticOut),
    );
    _entranceFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    // Slight delay so it feels intentional rather than instant.
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _entranceController.forward();
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  /// Finds the top-scoring team in [stats.standingsByCategory] whose
  /// category key matches [genderKeyword] ("girl" / "boy"), case-insensitive.
  /// TODO: adjust the matching if your category names differ
  /// (e.g. exactly "Girls" / "Boys" / "Mixed").
  _TeamScoreDisplay? _topTeamFor(HomeStatsProvider stats, String genderKeyword) {
    for (final entry in stats.standingsByCategory.entries) {
      if (entry.key.toLowerCase().contains(genderKeyword)) {
        if (entry.value.isEmpty) return null;
        final top = entry.value.reduce(
              (a, b) => a.totalPoints >= b.totalPoints ? a : b,
        );
        return _TeamScoreDisplay(
          teamName: top.teamName,
          points: top.totalPoints,
          color: top.color,
        );
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<HomeStatsProvider>();

    final girlsTop = _topTeamFor(stats, 'girl');
    final boysTop = _topTeamFor(stats, 'boy');

    final totalScore = (girlsTop?.points ?? 0) + (boysTop?.points ?? 0);

    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 6),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.15),
            blurRadius: 14,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ---- Trophy entrance animation ----
          FadeTransition(
            opacity: _entranceFade,
            child: ScaleTransition(
              scale: _entranceScale,
              child: Image.asset(
                'assets/gif/Trophy.gif',
                height: 120,
                width: 120,
                fit: BoxFit.contain,
                gaplessPlayback: true,
              ),
            ),
          ),
          const SizedBox(height: 14),

          if (totalScore <= 0)
            const _ZeroScorePlaceholder()
          else
            Row(
              children: [
                Expanded(
                  child: _TeamScoreCard(
                    label: 'Girls',
                    team: girlsTop,
                    accent: const Color(0xffEC4899),
                    bg: const Color(0xffFCE7F3),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TeamScoreCard(
                    label: 'Boys',
                    team: boysTop,
                    accent: const Color(0xff3B82F6),
                    bg: const Color(0xffDBEAFE),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TeamScoreDisplay {
  final String teamName;
  final num points;
  final Color color;
  const _TeamScoreDisplay({
    required this.teamName,
    required this.points,
    required this.color,
  });
}

class _TeamScoreCard extends StatelessWidget {
  final String label;
  final _TeamScoreDisplay? team;
  final Color accent;
  final Color bg;

  const _TeamScoreCard({
    required this.label,
    required this.team,
    required this.accent,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: accent,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            team?.teamName ?? '—',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: const Color(0xff1F2937),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${team?.points ?? 0} pts',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown when there are no scores yet. Continuously grows/shrinks on a
/// gentle loop; tapping anywhere in this area shrinks it briefly before
/// it resumes the idle pulse.
class _ZeroScorePlaceholder extends StatefulWidget {
  const _ZeroScorePlaceholder();

  @override
  State<_ZeroScorePlaceholder> createState() => _ZeroScorePlaceholderState();
}

class _ZeroScorePlaceholderState extends State<_ZeroScorePlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              // Idle pulse: scales gently between 1.0 and 1.12.
              final idleScale = 1.0 + (_pulseController.value * 0.12);
              return AnimatedScale(
                // On tap: shrink to 0.82; released: springs back to idle pulse.
                scale: _isPressed ? 0.82 : idleScale,
                duration: Duration(milliseconds: _isPressed ? 150 : 250),
                curve: _isPressed ? Curves.easeOut : Curves.easeOutBack,
                child: child,
              );
            },
            // TODO: swap this for a dedicated "waiting for results" gif
            // if you have one — reusing Trophy.gif here as the "any one
            // animation" placeholder per your request.
            child: Image.asset(
              'assets/gif/Trophy.gif',
              height: 90,
              width: 90,
              fit: BoxFit.contain,
              gaplessPlayback: true,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Scores will appear here once results are published',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xff9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}