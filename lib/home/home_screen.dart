import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:meeras_fest_app/home/home_provider.dart';
import 'package:meeras_fest_app/profile/profileProvider.dart';
import 'package:provider/provider.dart';

import '../admin/animated_graph.dart';
import '../admin/providers/curosel_provider.dart';
import '../poster/student_poster_list_screen.dart';
import '../registration/register_provider.dart';
import 'home_stats_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const List<String> _fallbackCarouselImages = [
    "https://images.unsplash.com/photo-1533174072545-7a4b6ad7a6c3?w=800&q=80",
    "https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=800&q=80",
    "https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?w=800&q=80",
  ];

  // Loading animation shown full-screen while HomeStatsProvider is fetching.
  static const String loadingGifUrl =
      "https://cdn.dribbble.com/userupload/22768141/file/original-9c15931c5055bdee54affd7e98717036.gif";

  static const List<Color> _rankBgPalette = [
    Color(0xffFEF9C3),
    Color(0xffF3F4F6),
    Color(0xffFFEDD5),
    Color(0xffF8FAFC),
    Color(0xffE0E7FF),
  ];
  static const List<Color> _rankTextPalette = [
    Color(0xffA16207),
    Color(0xff374151),
    Color(0xff9A3412),
    Color(0xff64748B),
    Color(0xff4338CA),
  ];
  static const List<Color> _dotPalette = [
    Color(0xffEF4444),
    Color(0xff3B82F6),
    Color(0xff22C55E),
    Color(0xffA855F7),
    Color(0xffF97316),
  ];

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Log out?"),
        content: const Text("You'll need to sign in again to access your account."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xffEF4444)),
            child: const Text("Log Out"),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<ProfileProvider>().logout();
      if (context.mounted) {
        context.read<RegistrationProvider>().clearRegistrationSelections();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final carouselHeight = isLandscape ? 140.0 : 170.0;

    return ChangeNotifierProvider(
      create: (_) => HomeStatsProvider()..fetchAll(),
      child: Scaffold(
        // Background is painted by the gradient Container below,
        // so keep the scaffold itself transparent.
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
              ),
              child: SafeArea(
                child: Consumer<HomeStatsProvider>(
                  builder: (context, stats, child) {
                    // Full-screen animated loader while the initial data fetch
                    // is in flight — swaps in the real content once it's ready.
                    if (stats.isLoading) {
                      return const _HomeLoadingView();
                    }
                    return child!;
                  },
                  child: SingleChildScrollView(
                    child: Center(
                      // NEW — caps the content column on wide/landscape
                      // screens instead of stretching edge-to-edge.
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: isLandscape ? 700 : double.infinity),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Column(
                            children: [
                              /// ================= GLASS HEADER =================
                              FadeSlideAnimation(
                                order: 1,
                                from: SlideFrom.top,
                                child: Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  width: double.infinity,
                                  clipBehavior: Clip.antiAlias,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.5),
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                      decoration: BoxDecoration(
                                        // frosted glass tint
                                        color: Colors.white.withValues(alpha: 0.50),
                                      ),
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const SizedBox(width: 40),
                                                Image.asset(
                                                  "assets/logos/IMG_1299.PNG",
                                                  height: 80,
                                                  width: 80,
                                                ),
                                                Consumer<ProfileProvider>(
                                                    builder: (context,profilePro,child) {
                                                      if(profilePro.loggedRole=='Guest'){
                                                        return SizedBox(width: 40,);
                                                      }
                                                      return Align(
                                                        alignment: Alignment.topRight,
                                                        child: InkWell(
                                                          borderRadius: BorderRadius.circular(16),
                                                          onTap: () => _confirmLogout(context),
                                                          child: CircleAvatar(
                                                            backgroundColor:
                                                            Colors.white.withValues(alpha: 0.7),
                                                            radius: 15,
                                                            child: const Icon(Icons.login_rounded,
                                                                size: 18, color: Color(0xff667EEA)),
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                ),
                                              ],
                                            ),
                                            Image.asset("assets/images/thoofan.PNG",height: 80,),
                                            Text(
                                              textAlign: TextAlign.center,
                                              "Meerasul Ambiya Higher secondary Madrassa\nOravampuram",
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: const Color(0xff6B7280),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 18),
                              FadeSlideAnimation(
                                order: 3,
                                from: SlideFrom.bottom,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const StudentPosterListScreen()),
                                  ),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 18),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFFFF6BAA), Color(0xFF6C63FF)],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(color: const Color(0xFF6C63FF).withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 6)),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.auto_awesome_rounded, color: Colors.white),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Get Your Poster', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                                              Text('Generate & share your result poster', style: GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              /// ================= CAROUSEL =================
                              FadeSlideAnimation(
                                order: 2,
                                from: SlideFrom.bottom,
                                child: Consumer<CarouselProvider>(
                                  builder: (context, carouselPro, child) {
                                    if (carouselPro.isLoading) {
                                      return Container(
                                        height: carouselHeight,
                                        decoration: BoxDecoration(
                                          color: const Color(0xffF3F4F6),
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                      );
                                    }
                                    final urls = carouselPro.images.isNotEmpty
                                        ? carouselPro.images.map((e) => e.imageUrl).toList()
                                        : _fallbackCarouselImages;
                                    return _FestCarousel(imageUrls: urls, height: carouselHeight);
                                  },
                                ),
                              ),

                              const SizedBox(height: 20),

                              /// ================= LIVE NOW =================
                              /// Programs whose registrations currently have
                              /// STATUS == 'Assigned' — i.e. on stage / being judged
                              /// right now. Hidden entirely when nothing is live.
                              Consumer<HomeStatsProvider>(
                                builder: (context, stats, child) {
                                  if (stats.isLoading || stats.livePrograms.isEmpty) {
                                    return const SizedBox.shrink();
                                  }
                                  return FadeSlideAnimation(
                                    order: 5,
                                    from: SlideFrom.left,
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 24),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const _PulsingDot(),
                                              const SizedBox(width: 8),
                                              Text(
                                                "Live Now",
                                                style: GoogleFonts.inter(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xff1F2937),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xffFEE2E2),
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  "${stats.livePrograms.length}",
                                                  style: GoogleFonts.inter(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    color: const Color(0xffDC2626),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          SizedBox(
                                            height: 60,
                                            child: ListView.builder(
                                              scrollDirection: Axis.horizontal,
                                              itemCount: stats.livePrograms.length,
                                              itemBuilder: (context, index) {
                                                final program = stats.livePrograms[index];
                                                return Padding(
                                                  padding: const EdgeInsets.only(right: 10),
                                                  child: _LiveProgramCard(program: program),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),

                              /// ================= LATEST WINNERS =================
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Latest Winners",
                                    style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xff1F2937)),
                                  ),
                                  Consumer<HomeProvider>(builder: (context, homePro, child) {
                                    return InkWell(
                                      onTap: () => homePro.changeBottomIndex(1),
                                      child: Row(
                                        children: [
                                          Text(
                                            "View All",
                                            style: GoogleFonts.inter(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: const Color(0xff667EEA)),
                                          ),
                                          const Icon(Icons.arrow_forward_outlined,
                                              color: Color(0xff667EEA), size: 13)
                                        ],
                                      ),
                                    );
                                  })
                                ],
                              ),
                              const SizedBox(height: 12),

                              FadeSlideAnimation(
                                order: 6,
                                from: SlideFrom.right,
                                child: Consumer<HomeStatsProvider>(
                                  builder: (context, stats, child) {
                                    if (stats.isLoading) {
                                      return const SizedBox(
                                        height: 150,
                                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                      );
                                    }
                                    if (stats.latestWinners.isEmpty) {
                                      return Container(
                                        height: 100,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: const Text(
                                          "No published results yet",
                                          style: TextStyle(color: Colors.grey, fontSize: 12),
                                        ),
                                      );
                                    }
                                    return SizedBox(
                                      height: 150,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: stats.latestWinners.length,
                                        itemBuilder: (context, index) {
                                          final w = stats.latestWinners[index];
                                          // ⬅️ NEW: General programs are a
                                          // team result — show the team
                                          // name (not one representative
                                          // student) and a groups icon
                                          // instead of a specific photo.
                                          final title = w.isGeneral ? w.teamName : w.studentName;
                                          final subtitle = w.isGeneral ? 'General Program' : w.teamName;
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8),
                                            child: Container(
                                              width: 240,
                                              height: 140,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(16),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.grey.withValues(alpha: 0.18),
                                                    blurRadius: 10,
                                                    spreadRadius: 1,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ],
                                                color: Colors.white,
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(14.0),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text("Program",
                                                        style: GoogleFonts.inter(
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.w500,
                                                            color: const Color(0xff6B7280))),
                                                    const SizedBox(height: 6),
                                                    Text(w.programName,
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: GoogleFonts.inter(
                                                            fontSize: 13,
                                                            fontWeight: FontWeight.bold,
                                                            color: const Color(0xff1F2937))),
                                                    const SizedBox(height: 10),
                                                    Container(
                                                      decoration: BoxDecoration(
                                                        borderRadius: BorderRadius.circular(12),
                                                        color: const Color(0xffF9FAFB),
                                                      ),
                                                      child: Padding(
                                                        padding: const EdgeInsets.all(10.0),
                                                        child: Row(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            // ---- Avatar with 🥇 medal stacked bottom-right ----
                                                            SizedBox(
                                                              width: 36,
                                                              height: 36,
                                                              child: Stack(
                                                                clipBehavior: Clip.none,
                                                                children: [
                                                                  CircleAvatar(
                                                                    radius: 16,
                                                                    backgroundColor: const Color(0xffF3F4F6),
                                                                    child: w.isGeneral
                                                                        ? const Icon(
                                                                      Icons.groups_rounded,
                                                                      size: 16,
                                                                      color: Color(0xff9CA3AF),
                                                                    )
                                                                        : ClipOval(
                                                                      child: (w.photoUrl != null &&
                                                                          w.photoUrl!.isNotEmpty)
                                                                          ? Image.network(
                                                                        w.photoUrl!,
                                                                        width: 32,
                                                                        height: 32,
                                                                        fit: BoxFit.cover,
                                                                        errorBuilder:
                                                                            (context, error, stackTrace) =>
                                                                        const Icon(
                                                                          Icons.person,
                                                                          size: 16,
                                                                          color: Color(0xff9CA3AF),
                                                                        ),
                                                                        loadingBuilder:
                                                                            (context, child, progress) {
                                                                          if (progress == null) return child;
                                                                          return const SizedBox(
                                                                            width: 16,
                                                                            height: 16,
                                                                            child: CircularProgressIndicator(
                                                                                strokeWidth: 1.5),
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
                                                                  Positioned(
                                                                    bottom: 0,
                                                                    right: 0,
                                                                    child: Text("🥇",
                                                                        style:
                                                                        GoogleFonts.inter(fontSize: 14, height: 1)),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            const SizedBox(width: 12),
                                                            Expanded(
                                                              child: Column(
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                  Text(title,
                                                                      maxLines: 1,
                                                                      overflow: TextOverflow.ellipsis,
                                                                      style: GoogleFonts.inter(
                                                                          fontSize: 11,
                                                                          fontWeight: FontWeight.w600,
                                                                          color: const Color(0xff374151))),
                                                                  Text(subtitle,
                                                                      maxLines: 1,
                                                                      overflow: TextOverflow.ellipsis,
                                                                      style: GoogleFonts.inter(
                                                                          fontSize: 10,
                                                                          fontWeight: FontWeight.w400,
                                                                          color: const Color(0xff6B7280))),
                                                                ],
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

                              /// ================= OVERALL STANDINGS (per category) =================
                              FadeSlideAnimation(
                                order: 7,
                                from: SlideFrom.bottom,
                                child: Consumer<HomeStatsProvider>(
                                  builder: (context, stats, child) {
                                    if (stats.isLoading) {
                                      return const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 24),
                                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                      );
                                    }
                                    if (stats.standingsByCategory.isEmpty) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        child: Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: const Center(
                                            child: Text("No published standings yet",
                                                style: TextStyle(color: Colors.grey, fontSize: 12)),
                                          ),
                                        ),
                                      );
                                    }

                                    final categories = stats.standingsByCategory.keys.toList()..sort();

                                    // ⬅️ NEW: on wide screens (landscape/tablet)
                                    // each category's standings card sits side
                                    // by side instead of stacked full-width.
                                    return LayoutBuilder(
                                      builder: (context, constraints) {
                                        final isWide = constraints.maxWidth >= 560;
                                        final cards = categories.map((category) {
                                          final teams = stats.standingsByCategory[category]!;
                                          final maxPoints = teams.fold<num>(
                                              0, (prev, t) => t.totalPoints > prev ? t.totalPoints : prev);
                                          return _StandingsCategoryCard(
                                            category: category,
                                            teams: teams,
                                            maxPoints: maxPoints,
                                          );
                                        }).toList();

                                        if (!isWide) {
                                          return Column(
                                            children: cards
                                                .map((c) => Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                              child: c,
                                            ))
                                                .toList(),
                                          );
                                        }

                                        final cardWidth = (constraints.maxWidth - 12) / 2;
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          child: Wrap(
                                            spacing: 12,
                                            runSpacing: 12,
                                            children: cards
                                                .map((c) => SizedBox(width: cardWidth, child: c))
                                                .toList(),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 14),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ================= REWARD / TROPHY POPUP =================
            // Always shown as a small floating bubble once the top
            // teams are known — no auto full-screen popup on open.
            // Tapping the bubble expands it into a centered card with
            // the top team from the Girls standings and the top team
            // from the Boys standings side by side (whichever category
            // names exist). If a category has no scores yet, its top
            // team still shows — any one team rather than nothing.
            // Tapping the dimmed backdrop, the close icon, or "Got it!"
            // shrinks the card back down into the bubble.
            Consumer<HomeStatsProvider>(
              builder: (context, stats, child) {
                if (stats.isLoading) return const SizedBox.shrink();

                // Finds the top-scoring team in a category whose name
                // contains [genderKeyword] ("girl" / "boy"), case
                // insensitive. Ties (including all-zero) just pick one.
                LeaderEntry? topTeamFor(String label, String genderKeyword) {
                  for (final entry in stats.standingsByCategory.entries) {
                    if (entry.key.toLowerCase().contains(genderKeyword)) {
                      if (entry.value.isEmpty) return null;
                      final top = entry.value.reduce(
                            (a, b) => a.totalPoints >= b.totalPoints ? a : b,
                      );
                      return LeaderEntry(
                        label: label,
                        teamName: top.teamName,
                        points: top.totalPoints,
                      );
                    }
                  }
                  return null;
                }

                final girlsLeader = topTeamFor('Girls', 'girl');
                final boysLeader = topTeamFor('Boys', 'boy');
                final entries = <LeaderEntry>[
                  if (girlsLeader != null) girlsLeader,
                  if (boysLeader != null) boysLeader,
                ];

                if (entries.isEmpty) return const SizedBox.shrink();

                return RewardGifOverlay(entries: entries);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// One category's standings card (icon + "<Category> Standings" header +
/// the bar graph). Extracted so the parent can arrange these either
/// stacked (narrow) or side by side (wide) without duplicating the card
/// body for each layout.
class _StandingsCategoryCard extends StatelessWidget {
  final String category;
  final List<TeamStanding> teams;
  final num maxPoints;

  const _StandingsCategoryCard({
    required this.category,
    required this.teams,
    required this.maxPoints,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.18),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
        color: Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xffFFEDD5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SvgPicture.asset(
                    "assets/icons/resultIcon.svg",
                    height: 14,
                    width: 14,
                    colorFilter: const ColorFilter.mode(Color(0xffFF8E53), BlendMode.srcIn),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text("$category Standings",
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xff1F2937))),
                ),
              ],
            ),
            const SizedBox(height: 14),
            AnimatedBarGraph(
              maxValue: maxPoints > 0 ? maxPoints.toDouble() : 1,
              entries: teams
                  .map((team) => BarGraphEntry(
                teamName: team.teamName,
                leaderName: team.leaderName,
                points: team.totalPoints.toDouble(),
                color: team.color,
              ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen "reward" popup built around a gif (default: the Trophy
/// gif). Animates between two states using a single AnimationController:
///  - t == 1 (open):   a centered card with a dark backdrop behind it.
///  - t == 0 (bubble): a small floating circle in the corner.
/// The gif itself just grows/shrinks to fill whichever shape it's in;
/// the surrounding chrome (labels, buttons, close icon) fades in only
/// once the card is mostly expanded, so the bubble stays clean.
///
/// Starts as the small bubble (t == 0) as soon as it mounts. Tapping the
/// bubble expands it into the full card; dismissing the card (backdrop
/// tap, close icon, or the button) animates it back down into the
/// bubble.
///
/// [entries] holds one leader per standings category (e.g. Girls, Boys)
/// — each with its own label, team name, and score, shown side by side.
class LeaderEntry {
  final String label;
  final String teamName;
  final num points;
  const LeaderEntry({required this.label, required this.teamName, required this.points});
}

class RewardGifOverlay extends StatefulWidget {
  final String gifAssetPath;
  final String eyebrow;
  final List<LeaderEntry> entries;
  final String buttonLabel;

  const RewardGifOverlay({
    super.key,
    required this.entries,
    this.gifAssetPath = 'assets/gif/Trophy.gif',
    this.eyebrow = 'Congratulations!',
    this.buttonLabel = 'Got it!',
  });

  @override
  State<RewardGifOverlay> createState() => _RewardGifOverlayState();
}

class _RewardGifOverlayState extends State<RewardGifOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Always true — the overlay is shown as soon as it mounts (as the
  // expanded card the very first time, then the bubble after it's been
  // dismissed once — see [_hasEverBeenDismissed] below).
  bool _everOpened = false;

  static bool _hasEverBeenDismissed = false;

  static const double _bubbleSize = 64;
  static const double _bubbleMargin = 18;
  static const double _bubbleBottomOffset = 60;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _everOpened = true;
    _controller.value = _hasEverBeenDismissed ? 0.0 : 1.0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _minimize() {
    _hasEverBeenDismissed = true;
    _controller.reverse();
  }

  void _expand() => _controller.forward();

  @override
  Widget build(BuildContext context) {
    if (!_everOpened) return const SizedBox.shrink();

    final mq = MediaQuery.of(context);
    final screenSize = mq.size;

    // ⬅️ CHANGED: modalWidth/modalHeight are now both capped relative to
    // the actual screen size instead of a hardcoded 420 — critical on
    // short landscape phones where height might only be ~360px, where
    // the old fixed 420 height didn't fit and got clipped.
    final modalWidth = math.min(screenSize.width - 48, 420.0);
    final modalHeight = math.min(screenSize.height * 0.86, 420.0).clamp(240.0, 420.0);

    final modalRect = Rect.fromLTWH(
      (screenSize.width - modalWidth) / 2,
      (screenSize.height - modalHeight) / 2,
      modalWidth,
      modalHeight,
    );
    final bubbleRect = Rect.fromLTWH(
      screenSize.width - _bubbleSize - _bubbleMargin,
      math.max(
        0,
        screenSize.height - _bubbleSize - _bubbleMargin - mq.padding.bottom - _bubbleBottomOffset,
      ),
      _bubbleSize,
      _bubbleSize,
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOutCubic.transform(_controller.value);
        final rect = Rect.lerp(bubbleRect, modalRect, t)!;
        final radius = lerpDouble(_bubbleSize / 2, 28, t)!;
        // Chrome (text/buttons/close icon) only fades in during the
        // last 45% of the expansion so the bubble shape stays clean.
        final chromeOpacity = ((t - 0.55) / 0.45).clamp(0.0, 1.0);
        final backdropOpacity = t * 0.55;

        return Stack(
          children: [
            // ---- Backdrop: tapping outside the card minimizes it ----
            if (t > 0.02)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _minimize,
                  child: Container(color: Colors.black.withValues(alpha: backdropOpacity)),
                ),
              ),

            // ---- The card / bubble itself ----
            Positioned(
              left: rect.left,
              top: rect.top,
              width: rect.width,
              height: rect.height,
              child: GestureDetector(
                // While mostly a bubble, tapping it reopens the card.
                onTap: t < 0.5 ? _expand : null,
                child: Material(
                  elevation: lerpDouble(6, 20, t)!,
                  shadowColor: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(radius),
                  clipBehavior: Clip.antiAlias,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xff1e1b3a), Color(0xffb968e8)],
                      ),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // The gif always fills the container — this is
                        // what visually grows/shrinks between states.
                        Padding(
                          padding: EdgeInsets.all(lerpDouble(4, 24, t)!),
                          child: Image.asset(
                            widget.gifAssetPath,
                            fit: BoxFit.contain,
                            gaplessPlayback: true,
                            errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.emoji_events, color: Colors.white, size: 32),
                          ),
                        ),

                        if (chromeOpacity > 0)
                          Opacity(
                            opacity: chromeOpacity,
                            child: IgnorePointer(
                              ignoring: chromeOpacity < 0.9,
                              child: Column(
                                children: [
                                  // ---- Close button, top-right ----
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        InkWell(
                                          borderRadius: BorderRadius.circular(20),
                                          onTap: _minimize,
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(alpha: 0.35),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.close, size: 16, color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // ⬅️ CHANGED: Expanded + SingleChildScrollView
                                  // instead of Spacer() + a fixed-size Column —
                                  // on a short landscape screen the capped
                                  // modalHeight leaves little vertical room,
                                  // so this content now scrolls instead of
                                  // overflowing/clipping off the bottom.
                                  Spacer(),
                                  SingleChildScrollView(
                                    padding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          widget.eyebrow,
                                          style: GoogleFonts.inter(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height:100),
                                        // One card per standings category
                                        // (e.g. Girls, Boys), side by side
                                        // when there's more than one.
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            for (int i = 0; i < widget.entries.length; i++) ...[
                                              if (i > 0) const SizedBox(width: 10),
                                              Expanded(child: _LeaderBlock(entry: widget.entries[i])),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 18),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed: _minimize,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              foregroundColor: const Color(0xff1F2937),
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(30),
                                              ),
                                              elevation: 0,
                                            ),
                                            child: Text(
                                              widget.buttonLabel,
                                              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                                            ),
                                          ),
                                        ),
                                      ],
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
              ),
            ),
          ],
        );
      },
    );
  }
}

/// One category's leader — label (e.g. "GIRLS"), team name, and score —
/// rendered as a small translucent card. Used side by side inside
/// [RewardGifOverlay] when there's a team for each standings category.
class _LeaderBlock extends StatelessWidget {
  final LeaderEntry entry;
  const _LeaderBlock({required this.entry});

  /// Pink for "Girls", blue for "Boys", white as a neutral fallback for
  /// any other category label.
  Color get _accent {
    final key = entry.label.toLowerCase();
    if (key.contains('girl')) return const Color(0xffFF6FA5);
    if (key.contains('boy')) return const Color(0xff5FA8FF);
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accent.withValues(alpha: 0.5), width: 1.2),
      ),
      child: Column(
        children: [
          Text(
            entry.label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: _accent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "${entry.points}",
            style: GoogleFonts.inter(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              height: 1,
              color: Colors.white,
            ),
          ),
          Text(
            "points",
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            entry.teamName,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeLoadingView extends StatelessWidget {
  const _HomeLoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.network(
          HomeScreen.loadingGifUrl,
          width: 180,
          height: 180,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) => const SizedBox(
            width: 180,
            height: 180,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        ),
      ),
    );
  }
}

/// A festival-highlight image carousel. Auto-plays every 4s, shows a
/// "peek" effect on neighbouring pages, and renders animated dot indicators.
class _FestCarousel extends StatefulWidget {
  final List<String> imageUrls;
  final double height;
  const _FestCarousel({required this.imageUrls, this.height = 170});

  @override
  State<_FestCarousel> createState() => _FestCarouselState();
}

class _FestCarouselState extends State<_FestCarousel> {
  late final PageController _controller;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.92);
    if (widget.imageUrls.length > 1) _startAutoPlay();
  }

  void _startAutoPlay() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!_controller.hasClients || widget.imageUrls.isEmpty) return;
      _currentPage = (_currentPage + 1) % widget.imageUrls.length;
      _controller.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final isActive = index == _currentPage;
              return AnimatedPadding(
                duration: const Duration(milliseconds: 250),
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: isActive ? 0 : 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        widget.imageUrls[index],
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: const Color(0xffF3F4F6),
                            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: const Color(0xffF3F4F6),
                          child: const Icon(Icons.image_not_supported_outlined, color: Color(0xff9CA3AF)),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Colors.black.withValues(alpha: 0.55), Colors.transparent],
                            ),
                          ),
                          child: Text(
                            "Meem Meeras Fest Season 5",
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.imageUrls.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.imageUrls.length, (index) {
              final isActive = index == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                height: 6,
                width: isActive ? 18 : 6,
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xff667EEA) : const Color(0xffE5E7EB),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

/// A single "on stage now" card, used in the horizontal Live Now list.
class _LiveProgramCard extends StatelessWidget {
  final LiveProgramInfo program;
  const _LiveProgramCard({required this.program});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xffFF6B6B), Color(0xffFF8E53)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffFF6B6B).withValues(alpha: 0.25),
            blurRadius: 14,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _PulsingDot(color: Colors.white, size: 7),
              const SizedBox(width: 6),
              Text(
                "LIVE",
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          Text(
            program.programName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// A small looping "radar" pulse dot used to signal live/on-air content.
class _PulsingDot extends StatefulWidget {
  final double size;
  final Color color;
  const _PulsingDot({this.size = 8, this.color = const Color(0xffEF4444)});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value; // 0 -> 1
        return SizedBox(
          width: widget.size * 2.6,
          height: widget.size * 2.6,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: (1 - t) * 0.5,
                child: Container(
                  width: widget.size * (1 + t * 1.6),
                  height: widget.size * (1 + t * 1.6),
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

enum SlideFrom { top, bottom, left, right }

class FadeSlideAnimation extends StatefulWidget {
  final Widget child;
  final SlideFrom from;
  final int delayMs;
  final int durationMs;
  final double distance;
  final int order;

  const FadeSlideAnimation({
    super.key,
    required this.child,
    this.from = SlideFrom.bottom,
    this.delayMs = 300,
    this.durationMs = 300,
    this.distance = 0.2,
    this.order = 1,
  });

  @override
  State<FadeSlideAnimation> createState() => _FadeSlideAnimationState();
}

class _FadeSlideAnimationState extends State<FadeSlideAnimation> {
  bool animate = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delayMs * widget.order), () {
      if (mounted) setState(() => animate = true);
    });
  }

  Offset getOffset() {
    switch (widget.from) {
      case SlideFrom.top:
        return Offset(0, -widget.distance);
      case SlideFrom.bottom:
        return Offset(0, widget.distance);
      case SlideFrom.left:
        return Offset(-widget.distance, 0);
      case SlideFrom.right:
        return Offset(widget.distance, 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: animate ? 1 : 0,
      duration: Duration(milliseconds: widget.durationMs),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: animate ? Offset.zero : getOffset(),
        duration: Duration(milliseconds: widget.durationMs),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}