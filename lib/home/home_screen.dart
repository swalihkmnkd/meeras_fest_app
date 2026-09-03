import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:meeras_fest_app/home/home_provider.dart';
import 'package:meeras_fest_app/profile/profileProvider.dart';
import 'package:provider/provider.dart';

import '../admin/animated_graph.dart';
import '../admin/providers/curosel_provider.dart';
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
    return ChangeNotifierProvider(
      create: (_) => HomeStatsProvider()..fetchAll(),
      child: Scaffold(
        // Background is painted by the gradient Container below,
        // so keep the scaffold itself transparent.
        backgroundColor: Colors.transparent,
        body: Container(
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
                                                  radius: 18,
                                                  child: const Icon(Icons.login_rounded,
                                                      size: 18, color: Color(0xff667EEA)),
                                                ),
                                              ),
                                            );
                                          }
                                        ),
                                      ],
                                    ),
                                    // Text(
                                    //   "🎨 🎭 🎪 🎵",
                                    //   style: GoogleFonts.inter(
                                    //       fontSize: 10, fontWeight: FontWeight.bold),
                                    // ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        ShaderMask(
                                          shaderCallback: (bounds) {
                                            return const LinearGradient(
                                              colors: [
                                                Color(0xFFFF6B6B),
                                                Color(0xFFFF8E53),
                                                Color(0xFF667EEA),
                                              ],
                                              stops: [0.0, 0.5, 1.0],
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                            ).createShader(bounds);
                                          },
                                          child: Text(
                                            "മീറാസ് ഫെസ്റ്റ്",
                                            style: GoogleFonts.notoSansMalayalam(
                                              fontSize: 25,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.5,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          " SEASON 5",
                                          style: GoogleFonts.inter(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
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

                      /// ================= CAROUSEL =================
                      FadeSlideAnimation(
                        order: 2,
                        from: SlideFrom.bottom,
                        child: Consumer<CarouselProvider>(
                          builder: (context, carouselPro, child) {
                            if (carouselPro.isLoading) {
                              return Container(
                                height: 170,
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
                            return _FestCarousel(imageUrls: urls);
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
                                                    // ---- Student photo avatar with 🥇 medal stacked bottom-right ----
                                                    SizedBox(
                                                      width: 36,
                                                      height: 36,
                                                      child: Stack(
                                                        clipBehavior: Clip.none,
                                                        children: [
                                                          CircleAvatar(
                                                            radius: 16,
                                                            backgroundColor: const Color(0xffF3F4F6),
                                                            child: ClipOval(
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
                                                          Text(w.studentName,
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                              style: GoogleFonts.inter(
                                                                  fontSize: 11,
                                                                  fontWeight: FontWeight.w600,
                                                                  color: const Color(0xff374151))),
                                                          Text(w.teamName,
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

                            return Column(
                              children: categories.map((category) {
                                final teams = stats.standingsByCategory[category]!;
                                final maxPoints = teams.fold<num>(
                                    0, (prev, t) => t.totalPoints > prev ? t.totalPoints : prev);
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Container(
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
                                                  colorFilter: const ColorFilter.mode(
                                                      Color(0xffFF8E53), BlendMode.srcIn),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Text("$category Standings",
                                                  style: GoogleFonts.inter(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w700,
                                                      color: const Color(0xff1F2937))),
                                            ],
                                          ),
                                          const SizedBox(height: 14),
                                          ListView.separated(
                                            shrinkWrap: true,
                                            physics: const NeverScrollableScrollPhysics(),
                                            itemCount: 1,
                                            separatorBuilder: (context, index) => const SizedBox(height: 10),
                                            itemBuilder: (context, index) {
                                              final team = teams[index];
                                              final paletteIndex = index % _rankBgPalette.length;
                                              final fraction = maxPoints > 0
                                                  ? (team.totalPoints / maxPoints).toDouble()
                                                  : 0.0;
                                              return AnimatedBarGraph(
                                                maxValue: maxPoints > 0 ? maxPoints.toDouble() : 1,
                                                entries: teams
                                                    .map((team) => BarGraphEntry(
                                                  teamName: team.teamName,
                                                  leaderName: team.leaderName,
                                                  points: team.totalPoints.toDouble(),
                                                  color: team.color,
                                                ))
                                                    .toList(),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
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
    );
  }
}

/// Full-screen loading state shown while [HomeStatsProvider] fetches its
/// initial data. Uses the same gradient the rest of the screen sits on
/// so it doesn't flash a different background before the content pops in.
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
  const _FestCarousel({required this.imageUrls});

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
          height: 170,
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
      width: 190,
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
            maxLines: 2,
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