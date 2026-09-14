import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../result/resultProvider.dart';
import 'providers/resultProvider.dart';

// ---------------------------------------------------------------------
// THEME — light background + card surfaces instead of the old dark
// gradient. Swap these constants if your brand colors differ.
// ---------------------------------------------------------------------
const _bgGradient = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF8F9FC), Color(0xFFEFF1FA)],
  ),
);
const _textDark = Color(0xFF1F2937);
const _textMuted = Color(0xFF6B7280);
const _accentPurple = Color(0xFF6C63FF);

// ---------------------------------------------------------------------
// ASSETS — update these to match what's bundled in pubspec.yaml.
// ---------------------------------------------------------------------
const List<String> _carouselAssetImages = [
  'assets/images/thoofan.PNG',
  'assets/logos/IMG_1299.PNG',
  'assets/images/WhatsApp Image 2026-08-27 at 11.09.12 PM.jpeg',
];
const String _confettiLottieAsset = 'assets/lottie/confetti.json';

enum _ViewMode { overall, programWise }

/// Full-screen, auto-rotating, realtime TV scoreboard.
///
/// Two view modes, switchable from the top toggle:
///  - Overall: one team-vs-program grid per STUDENT_CATEGORY (now ordered
///    Boys -> Girls -> Overall by the provider), followed by one totals
///    slide per gender ("Boys", "Girls" — plus "Overall" only if some
///    category didn't match either), looping.
///  - Program wise: one slide per program showing its rank 1/2/3 —
///    general (team) results show the team name + a group icon, and
///    individual results show the student's own name + photo.
///
/// Firestore .snapshots() listeners (via ResultProvider.startLiveResults)
/// mean an admin edit shows up here within moments. When a brand-new
/// result appears, a "Result published" banner fades in and a confetti
/// animation drops from the top of the screen.
class TvScoreboardPage extends StatelessWidget {
  const TvScoreboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ResultProvider()..startLiveResults(),
      child: const _TvScoreboardView(),
    );
  }
}

class _TvScoreboardView extends StatefulWidget {
  const _TvScoreboardView();

  @override
  State<_TvScoreboardView> createState() => _TvScoreboardViewState();
}

class _TvScoreboardViewState extends State<_TvScoreboardView>
    with SingleTickerProviderStateMixin {
  static const _slideDuration = Duration(seconds: 6);

  final PageController _controller = PageController();
  Timer? _timer;
  int _slideCount = 0;
  double _page = 0;

  _ViewMode _mode = _ViewMode.overall;
  // Auto-flips between Overall and Program-wise every 5 minutes so the TV
  // doesn't get stuck on one mode unattended. Manual taps on the toggle
  // still work in between — this timer just fires on its own schedule.
  // The toggle button's highlighted side is driven purely by `_mode`
  // (see _ModeToggle below), so whichever path changes `_mode` — this
  // timer or a manual tap — the button updates identically, with the
  // same 200ms color animation.
  late final Timer _autoModeTimer;

  // ---- New-result detection -> toast + confetti ----
  ResultProvider? _providerRef;
  Set<String> _seenResultKeys = {};
  bool _seenKeysInitialized = false;
  String? _publishedBannerText;
  bool _showPublishedBanner = false;
  Timer? _bannerTimer;

  late final AnimationController _confettiController;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (!mounted) return;
      setState(() => _page = _controller.page ?? 0);
    });

    _confettiController = AnimationController(vsync: this);

    _autoModeTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (!mounted) return;
      setState(() {
        _mode = _mode == _ViewMode.overall
            ? _ViewMode.programWise
            : _ViewMode.overall;
        _slideCount = 0;
        if (_controller.hasClients) _controller.jumpToPage(0);
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ResultProvider>();
      _providerRef = provider;
      provider.addListener(_onProviderChanged);
      // Prime the "seen" set on first data so we don't fire the toast
      // for results that were already published before this screen opened.
      _onProviderChanged();
    });
  }

  void _onProviderChanged() {
    final provider = _providerRef;
    if (provider == null || provider.isLoading) return;

    final currentKeys = <String>{};
    String? latestProgramName;
    for (final program in provider.results) {
      for (final entry in program.topEntries) {
        final key =
            '${program.programId}|${entry.rank}|${entry.teamName}|${entry.studentId}';
        currentKeys.add(key);
        if (!_seenResultKeys.contains(key)) {
          latestProgramName = program.programName;
        }
      }
    }

    if (!_seenKeysInitialized) {
      // First snapshot after opening the screen — just record it, no toast.
      _seenKeysInitialized = true;
      _seenResultKeys = currentKeys;
      return;
    }

    final hasNew = currentKeys.difference(_seenResultKeys).isNotEmpty;
    _seenResultKeys = currentKeys;

    if (hasNew && latestProgramName != null) {
      _announcePublished(latestProgramName);
    }
  }

  void _announcePublished(String programName) {
    _bannerTimer?.cancel();
    setState(() {
      _publishedBannerText = 'Result published: $programName';
      _showPublishedBanner = true;
      _showConfetti = true;
    });
    _confettiController.forward(from: 0);
    _bannerTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() => _showPublishedBanner = false);
    });
  }

  void _ensureTimer(int count) {
    if (count == _slideCount) return;
    _slideCount = count;
    _timer?.cancel();
    if (count <= 1) return;
    _timer = Timer.periodic(_slideDuration, (_) {
      if (!_controller.hasClients) return;
      final next = ((_controller.page ?? 0).round() + 1) % count;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bannerTimer?.cancel();
    _autoModeTimer.cancel();
    _controller.dispose();
    _confettiController.dispose();
    _providerRef?.removeListener(_onProviderChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ResultProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading &&
              provider.categoryGrids.isEmpty &&
              provider.results.isEmpty) {
            return Container(
              decoration: _bgGradient,
              child: const Center(
                child: CircularProgressIndicator(color: _accentPurple),
              ),
            );
          }
          if (provider.errorMessage != null && provider.categoryGrids.isEmpty) {
            return Container(
              decoration: _bgGradient,
              child: Center(
                child: Text(
                  provider.errorMessage!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 22),
                ),
              ),
            );
          }

          final teamColors = provider.teamColors;

          final baseSlides = _mode == _ViewMode.overall
              ? <Widget>[
            for (final grid in provider.categoryGrids)
              _CategoryGridSlide(grid: grid, teamColors: teamColors),
            for (final gt in provider.genderTotals)
              _GenderTotalSlide(genderTotal: gt, teamColors: teamColors),
          ]
              : <Widget>[
            for (final program in provider.results)
              _ProgramRankSlide(program: program),
          ];

          // Carousel images ride the same rotation as the score slides —
          // no separate carousel widget, they just take their turn in the
          // PageView alongside the grids/program cards.
          final slides = <Widget>[
            ...baseSlides,
            for (final path in _carouselAssetImages)
              _CarouselSlide(imagePath: path),
          ];

          WidgetsBinding.instance.addPostFrameCallback(
                (_) => _ensureTimer(slides.length),
          );

          return Container(
            decoration: _bgGradient,
            child: SafeArea(
              child: Stack(
                children: [
                  if (slides.isEmpty)
                    const Center(
                      child: Text(
                        'No published results yet',
                        style: TextStyle(color: _textMuted, fontSize: 24),
                      ),
                    )
                  else
                    PageView.builder(
                      controller: _controller,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: slides.length,
                      itemBuilder: (context, index) {
                        final delta = (index - _page).clamp(-1.0, 1.0);
                        final angle = delta * (math.pi / 2.4);
                        return Transform(
                          alignment: delta <= 0
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.0016)
                            ..rotateY(angle),
                          child: Opacity(
                            opacity: (1 - delta.abs()).clamp(0.0, 1.0),
                            child: slides[index],
                          ),
                        );
                      },
                    ),

                  // ---- Mode toggle pinned to a fixed corner over the
                  // animation. It sits on its own solid white pill (see
                  // _ModeToggle) so it never blends into whatever slide —
                  // grid, program card, or carousel photo — is behind it.
                  // It always shows the CURRENT _mode, whether that was
                  // set by a manual tap or by the 5-minute auto-timer.
                  // ---- Overall score ticker pinned to the bottom ----
                  // The ticker uses the same live genderTotals data as the
                  // Overall score slides and continuously scrolls right-to-left.
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _OverallScoreTicker(
                      genderTotals: provider.genderTotals,
                      teamColors: teamColors,
                    ),
                  ),

                  Positioned(
                    top: 10,
                    left: 12,
                    child: _ModeToggle(
                      mode: _mode,
                      onChanged: (m) => setState(() {
                        _mode = m;
                        _slideCount = 0;
                        if (_controller.hasClients) _controller.jumpToPage(0);
                      }),
                    ),
                  ),

                  const Positioned(top: 14, right: 12, child: _LiveBadge()),

                  // ---- Result-published banner, fades in/out ----
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      child: AnimatedOpacity(
                        opacity: _showPublishedBanner ? 1 : 0,
                        duration: const Duration(milliseconds: 400),
                        child: Center(
                          child: Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              _publishedBannerText ?? '',
                              style: const TextStyle(
                                color: _accentPurple,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ---- Confetti — plays once top to bottom, then hides ----
                  if (_showConfetti)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Lottie.asset(
                          _confettiLottieAsset,
                          controller: _confettiController,
                          fit: BoxFit.cover,
                          onLoaded: (composition) {
                            _confettiController.duration = composition.duration;
                            _confettiController.forward(from: 0);
                          },
                          errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Bottom running ticker showing all team overall scores.
///
/// The content is duplicated and the scroll loops at the exact half-way
/// point, so the movement is continuous without a visible jump.
class _OverallScoreTicker extends StatefulWidget {
  final List<GenderTotal> genderTotals;
  final Map<String, Color> teamColors;

  const _OverallScoreTicker({
    required this.genderTotals,
    required this.teamColors,
  });

  @override
  State<_OverallScoreTicker> createState() => _OverallScoreTickerState();
}

class _OverallScoreTickerState extends State<_OverallScoreTicker> {
  final ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;
  double _offset = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startTicker());
  }

  @override
  void didUpdateWidget(covariant _OverallScoreTicker oldWidget) {
    super.didUpdateWidget(oldWidget);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startTicker();
    });
  }

  void _startTicker() {
    _scrollTimer?.cancel();
    _offset = 0;

    if (!_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _startTicker();
      });
      return;
    }

    _scrollController.jumpTo(0);

    _scrollTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!mounted || !_scrollController.hasClients) return;

      final position = _scrollController.position;
      final maxScroll = position.maxScrollExtent;

      if (maxScroll <= 0) return;

      // With two identical copies:
      // maxScroll = (2 * contentWidth) - viewportWidth.
      // Therefore this gives exactly contentWidth.
      final loopPoint = (maxScroll + position.viewportDimension) / 2;

      _offset += 1.6; // smooth TV-style speed

      if (_offset >= loopPoint) {
        _offset -= loopPoint;
      }

      _scrollController.jumpTo(_offset.clamp(0.0, maxScroll));
    });
  }

  List<_TickerTeam> _buildTeams() {
    // Add totals from all genders together so the ticker represents the
    // actual overall score of each team.
    final totals = <String, _TickerTeam>{};

    for (final gender in widget.genderTotals) {
      for (final team in gender.teamTotals) {
        final key = team.teamName.trim().toLowerCase();
        if (key.isEmpty) continue;

        final existing = totals[key];

        if (existing == null) {
          totals[key] = _TickerTeam(
            teamName: team.teamName.trim(),
            total: team.totalPoints,
            color: widget.teamColors[team.teamName] ?? _accentPurple,
          );
        } else {
          totals[key] = _TickerTeam(
            teamName: existing.teamName,
            total: existing.total + team.totalPoints,
            color: existing.color,
          );
        }
      }
    }

    final teams = totals.values.toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    return teams;
  }

  Widget _tickerContent(List<_TickerTeam> teams) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.only(right: 30),
          child: _TickerLabel(),
        ),
        for (var i = 0; i < teams.length; i++) ...[
          _TickerScoreItem(
            rank: i + 1,
            teamName: teams[i].teamName,
            total: teams[i].total,
            color: teams[i].color,
          ),
          const SizedBox(width: 34),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final teams = _buildTeams();

    if (teams.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 68,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF111827), Color(0xFF312E81), Color(0xFF111827)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.20),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRect(
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [_tickerContent(teams), _tickerContent(teams)],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }
}

class _TickerTeam {
  final String teamName;
  final num total;
  final Color color;

  const _TickerTeam({
    required this.teamName,
    required this.total,
    required this.color,
  });
}

class _TickerLabel extends StatelessWidget {
  const _TickerLabel();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 28),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.20)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events_rounded, color: Color(0xFFFACC15), size: 23),
          SizedBox(width: 9),
          Text(
            'OVERALL SCORES',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _TickerScoreItem extends StatelessWidget {
  final int rank;
  final String teamName;
  final num total;
  final Color color;

  const _TickerScoreItem({
    required this.rank,
    required this.teamName,
    required this.total,
    required this.color,
  });

  Color get _rankColor {
    switch (rank) {
      case 1:
        return const Color(0xFFFACC15);
      case 2:
        return const Color(0xFFE5E7EB);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Team color indicator
        Container(
          width: 7,
          height: 38,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 11),

        // Rank
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _rankColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 5),
            ],
          ),
          child: Text(
            '$rank',
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),

        const SizedBox(width: 12),

        Text(
          teamName.toUpperCase(),
          style: TextStyle(
            color: color.computeLuminance() > 0.45
                ? Colors.white
                : Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),

        const SizedBox(width: 12),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.30), blurRadius: 8),
            ],
          ),
          child: Text(
            '$total PTS',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

/// Two-option pill toggle: Overall / Program wise.
class _ModeToggle extends StatelessWidget {
  final _ViewMode mode;
  final ValueChanged<_ViewMode> onChanged;
  const _ModeToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModeButton(
            label: 'Overall',
            selected: mode == _ViewMode.overall,
            onTap: () => onChanged(_ViewMode.overall),
          ),
          _ModeButton(
            label: 'Program wise',
            selected: mode == _ViewMode.programWise,
            onTap: () => onChanged(_ViewMode.programWise),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _accentPurple : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : _textMuted,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

/// A carousel image taking its own turn in the main slide rotation — same
/// panel treatment as the score slides, so it reads as part of the same
/// animation rather than a bolted-on strip.
class _CarouselSlide extends StatelessWidget {
  final String imagePath;
  const _CarouselSlide({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 60, 40, 24),
      child: _LightPanel(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              imagePath,
              fit: BoxFit.fitHeight,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFFF3F4F6),
                child: const Icon(
                  Icons.image_not_supported_outlined,
                  color: _textMuted,
                  size: 40,
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.45),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: const Text(
                  'Meem Meeras Fest Season 5',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveBadge extends StatefulWidget {
  const _LiveBadge();
  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FadeTransition(
          opacity: Tween<double>(begin: 0.3, end: 1.0).animate(_controller),
          child: Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Colors.redAccent,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'LIVE',
          style: TextStyle(
            color: _textMuted,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }
}

/// One category's team-vs-program score grid — light theme.
class _CategoryGridSlide extends StatelessWidget {
  final CategoryGrid grid;
  final Map<String, Color> teamColors;
  const _CategoryGridSlide({required this.grid, required this.teamColors});

  @override
  Widget build(BuildContext context) {
    final columnWidths = <int, TableColumnWidth>{
      0: const FixedColumnWidth(220),
    };
    for (var i = 0; i < grid.programNames.length; i++) {
      columnWidths[i + 1] = const FixedColumnWidth(110);
    }
    columnWidths[grid.programNames.length + 1] = const FixedColumnWidth(130);

    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 10, 40, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 40),
          _SectionTitle(text: grid.category.toUpperCase()),
          const SizedBox(height: 16),
          Expanded(
            child: _LightPanel(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: MediaQuery.of(context).size.width - 120,
                  ),
                  child: Table(
                    border: TableBorder.symmetric(
                      inside: BorderSide(color: Colors.grey.shade200),
                    ),
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    columnWidths: columnWidths,
                    children: [
                      TableRow(
                        decoration: const BoxDecoration(
                          color: Color(0xFFF3F0FF),
                        ),
                        children: [
                          const _HeaderCell('TEAM'),
                          for (final p in grid.programNames)
                            _VerticalHeaderCell(p),
                          const _HeaderCell('TOTAL'),
                        ],
                      ),
                      for (final row in grid.teamRows)
                        TableRow(
                          children: [
                            _TeamNameCell(
                              name: row.teamName,
                              color: teamColors[row.teamName] ?? _textDark,
                            ),
                            for (final p in grid.programNames)
                              _ScoreStackCell(
                                points: row.pointsByProgram[p] ?? const [],
                              ),
                            _TotalCell(total: row.total),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Overall gender totals slide — one bar per team, sorted by score, with
/// tie-aware ranking (equal totals share the same rank).
class _GenderTotalSlide extends StatelessWidget {
  final GenderTotal genderTotal;
  final Map<String, Color> teamColors;
  const _GenderTotalSlide({
    required this.genderTotal,
    required this.teamColors,
  });

  @override
  Widget build(BuildContext context) {
    final maxScore = genderTotal.teamTotals.isEmpty
        ? 1
        : genderTotal.teamTotals
        .map((t) => t.totalPoints)
        .reduce((a, b) => a > b ? a : b);

    // Tie-aware ranking: teams with equal totals share the same rank,
    // and the next distinct total resumes at its 1-based position
    // (1, 1, 3, ...). Requires genderTotal.teamTotals to already be
    // sorted descending by totalPoints (the provider guarantees this).
    final ranks = <int>[];
    int currentRank = 0;
    num? previousTotal;
    for (var i = 0; i < genderTotal.teamTotals.length; i++) {
      final total = genderTotal.teamTotals[i].totalPoints;
      if (previousTotal == null || total != previousTotal) {
        currentRank = i + 1;
      }
      previousTotal = total;
      ranks.add(currentRank);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(90, 20, 90, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Center(
            child: _SectionTitle(
              text: genderTotal.gender.toUpperCase(),
              fontSize: 46,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              itemCount: genderTotal.teamTotals.length,
              separatorBuilder: (_, __) => const SizedBox(height: 22),
              itemBuilder: (context, i) {
                final t = genderTotal.teamTotals[i];
                final color = teamColors[t.teamName] ?? _accentPurple;
                final fraction = maxScore == 0
                    ? 0.0
                    : (t.totalPoints / maxScore).clamp(0.0, 1.0).toDouble();
                // Center each bar as a fixed-width block instead of
                // letting it stretch to the full slide width.
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: _TeamTotalBar(
                      rank: ranks[i],
                      teamName: t.teamName,
                      total: t.totalPoints,
                      color: color,
                      fraction: fraction,
                    ),
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

/// PROGRAM-WISE — one program per slide, showing rank 1/2/3. General
/// programs show the team name + a group icon; individual programs show
/// the student's own name + photo.
class _ProgramRankSlide extends StatelessWidget {
  final ProgramResult program;
  const _ProgramRankSlide({required this.program});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 10, 40, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 25),

          _SectionTitle(text: program.programName.toUpperCase(), fontSize: 42),

          if (program.category.isNotEmpty || program.stageType.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                [
                  program.category,
                  program.stageType,
                ].where((s) => s.isNotEmpty).join(' • '),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _textMuted,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

          const SizedBox(height: 18),

          Expanded(
            child: _LightPanel(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 35,
                    vertical: 18,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      for (final entry in program.topEntries)
                        Expanded(
                          child: Center(child: _RankCard(entry: entry)),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankCard extends StatelessWidget {
  final RankedEntry entry;
  const _RankCard({required this.entry});

  static const _medalColors = {
    1: Color(0xFFFACC15),
    2: Color(0xFFD1D5DB),
    3: Color(0xFFCD7F32),
  };

  @override
  Widget build(BuildContext context) {
    final medalColor = _medalColors[entry.rank] ?? Colors.grey.shade300;

    final title = entry.isGeneral ? entry.teamName : entry.studentName;

    final subtitle = entry.isGeneral ? 'GENERAL PROGRAM' : entry.teamName;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Larger result image / group icon
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 145,
                height: 145,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                  border: Border.all(color: medalColor, width: 5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 18,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: entry.isGeneral
                      ? const Icon(
                    Icons.groups_rounded,
                    size: 78,
                    color: _textMuted,
                  )
                      : entry.photoUrl.isNotEmpty
                      ? Image.network(
                    entry.photoUrl,
                    width: 145,
                    height: 145,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(
                      Icons.person,
                      size: 75,
                      color: _textMuted,
                    ),
                  )
                      : const Icon(Icons.person, size: 75, color: _textMuted),
                ),
              ),

              // Larger rank badge
              Positioned(
                bottom: -10,
                right: -10,
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: medalColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.16),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${entry.rank}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                      fontSize: 26,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 25),

          // Larger name
          Text(
            title.isEmpty ? '-' : title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _textDark,
              fontWeight: FontWeight.w900,
              fontSize: 26,
              height: 1.15,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _textMuted,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 12),

          // Larger points
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
            decoration: BoxDecoration(
              color: _accentPurple.withOpacity(0.10),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Text(
              '${entry.points} PTS',
              style: const TextStyle(
                color: _accentPurple,
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamTotalBar extends StatelessWidget {
  final int rank;
  final String teamName;
  final num total;
  final Color color;
  final double fraction;

  const _TeamTotalBar({
    required this.rank,
    required this.teamName,
    required this.total,
    required this.color,
    required this.fraction,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = constraints.maxWidth * fraction;
        const scoreBoxWidth = 85.0;

        return SizedBox(
          height: 72,
          child: Stack(
            children: [
              // Background
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(18),
                ),
              ),

              // Animated colored bar
              AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                width: barWidth,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.95),
                      color.withOpacity(0.65),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
              ),

              // Rank + Team Name
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      _RankMedal(rank: rank),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Text(
                          teamName.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
// Score chip — pinned to the end of the whole bar (outside the
// colored fill, at the right edge of the track), regardless of
// how far the colored fill extends.
              Positioned(
                right: 12,
                top: 12,
                bottom: 12,
                child: Container(
                  width: scoreBoxWidth,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '$total',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RankMedal extends StatelessWidget {
  final int rank;
  const _RankMedal({required this.rank});
  static const _medalColors = {
    1: Color(0xFFFACC15),
    2: Color(0xFFD1D5DB),
    3: Color(0xFFCD7F32),
  };

  @override
  Widget build(BuildContext context) {
    final color = _medalColors[rank] ?? Colors.white54;
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        '$rank',
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 17,
        ),
      ),
    );
  }
}

class _LightPanel extends StatelessWidget {
  final Widget child;
  const _LightPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: ClipRRect(borderRadius: BorderRadius.circular(16), child: child),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final double fontSize;
  const _SectionTitle({required this.text, this.fontSize = 34});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: _accentPurple,
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: _textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}

class _VerticalHeaderCell extends StatelessWidget {
  final String text;
  const _VerticalHeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Center(
        child: RotatedBox(
          quarterTurns: 3,
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _textDark,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _TeamNameCell extends StatelessWidget {
  final String name;
  final Color color;
  const _TeamNameCell({required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 6,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              name.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _textDark,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalCell extends StatelessWidget {
  final num total;
  const _TotalCell({required this.total});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$total',
        style: const TextStyle(
          color: _accentPurple,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      ),
    );
  }
}

class _ScoreStackCell extends StatelessWidget {
  final List<num> points;
  const _ScoreStackCell({required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Center(
          child: Text(
            '—',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 18),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [for (final p in points) _PointPill(p)],
      ),
    );
  }
}

class _PointPill extends StatelessWidget {
  final num points;
  const _PointPill(this.points);

  Color get _bg {
    if (points >= 10) return const Color(0xFFD1FAE5);
    if (points >= 6) return const Color(0xFFFEE2E2);
    if (points >= 1) return const Color(0xFFFEF3C7);
    return const Color(0xFFF3F4F6);
  }

  Color get _fg {
    if (points >= 10) return const Color(0xFF065F46);
    if (points >= 6) return const Color(0xFF991B1B);
    if (points >= 1) return const Color(0xFF92400E);
    return Colors.grey.shade400;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$points',
        style: TextStyle(color: _fg, fontWeight: FontWeight.bold, fontSize: 15),
      ),
    );
  }
}