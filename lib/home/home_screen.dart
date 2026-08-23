import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:meeras_fest_app/home/home_provider.dart';
import 'package:meeras_fest_app/profile/profileProvider.dart';
import 'package:provider/provider.dart';

import '../admin/providers/curosel_provider.dart';
import '../registration/register_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const List<String> _fallbackCarouselImages = [
    "https://images.unsplash.com/photo-1533174072545-7a4b6ad7a6c3?w=800&q=80",
    "https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=800&q=80",
    "https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?w=800&q=80",
  ];

  @override
  Widget build(BuildContext context) {
    List<Color> rankBgColors = [
      const Color(0xffFEF9C3), // 1
      const Color(0xffF3F4F6), // 2
      const Color(0xffFFEDD5), // 3
      const Color(0xffF8FAFC), // 4
    ];

    List<Color> rankTextColors = [
      const Color(0xffA16207),
      const Color(0xff374151),
      const Color(0xff9A3412),
      const Color(0xff64748B),
    ];

    List<Color> dotColors = [
      const Color(0xffEF4444),
      const Color(0xff3B82F6),
      const Color(0xff22C55E),
      const Color(0xffA855F7),
    ];

    List<String> teamNames = [
      "Phoenix",
      "Thunderbolts",
      "Spartans",
      "Titans",
    ];

    List<String> points = [
      "350",
      "450",
      "390",
      "310",
    ];

    return Scaffold(
      backgroundColor: const Color(0xffFFF9F5),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Column(
              children: [
                FadeSlideAnimation(
                  order: 1,
                  from: SlideFrom.top,
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFFFF6B6B).withValues(alpha: 0.08),
                          const Color(0xFF667EEA).withValues(alpha: 0.08),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Text(
                            "🎨 🎭 🎪 🎵",
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ShaderMask(
                            shaderCallback: (bounds) {
                              return const LinearGradient(
                                colors: [
                                  Color(0xFFFF6B6B), // stop 0%
                                  Color(0xFFFF8E53), // stop 50%
                                  Color(0xFF667EEA), // stop 100%
                                ],
                                stops: [0.0, 0.5, 1.0],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ).createShader(bounds);
                            },
                            child: Text(
                              "MEERAS FEST 2K27",
                              style: GoogleFonts.inter(
                                fontSize: 25,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
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
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }

                      final urls = carouselPro.images.isNotEmpty
                          ? carouselPro.images.map((e) => e.imageUrl).toList()
                          : _fallbackCarouselImages;

                      return _FestCarousel(imageUrls: urls);
                    },
                  ),
                ),

                const SizedBox(height: 18),

                Row(
                  children: [
                    Expanded(
                      child: FadeSlideAnimation(
                        order: 3,
                        from: SlideFrom.bottom,
                        child: Consumer<HomeProvider>(
                          builder: (context, homePro, child) {
                            return InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                homePro.changeBottomIndex(1);
                              },
                              child: Container(
                                height: 90,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 12,
                                      spreadRadius: 1,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: const Color(0xffFFEDD5),
                                      radius: 18,
                                      child: SvgPicture.asset(
                                        "assets/icons/resultIcon.svg",
                                        colorFilter: const ColorFilter.mode(
                                            Color(0xffFF8E53), BlendMode.srcIn),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "Result",
                                      style: GoogleFonts.inter(
                                        color: const Color(0xff1F2937),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FadeSlideAnimation(
                        order: 4,
                        from: SlideFrom.bottom,
                        child: Consumer<ProfileProvider>(
                          builder: (context, profilePro, child) {
                            return InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                profilePro.logout();
                                context
                                    .read<RegistrationProvider>()
                                    .clearRegistrationSelections();
                              },
                              child: Container(
                                height: 90,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 12,
                                      spreadRadius: 1,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: const Color(0xffF3E8FF),
                                      radius: 18,
                                      child: Icon(Icons.login_rounded,
                                          size: 18, color: const Color(0xff667EEA)),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "Logout",
                                      style: GoogleFonts.inter(
                                        color: const Color(0xff1F2937),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

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
                        onTap: () {
                          homePro.changeBottomIndex(1);
                        },
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
                  order: 5,
                  from: SlideFrom.right,
                  child: SizedBox(
                    height: 150,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
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
                                  Text("Song",
                                      style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xff6B7280))),
                                  const SizedBox(height: 6),
                                  Text("Classical Dance",
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
                                          Text("🥇", style: GoogleFonts.inter(fontSize: 18)),
                                          const SizedBox(width: 10),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text("Alice Johnson",
                                                  style: GoogleFonts.inter(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                      color: const Color(0xff374151))),
                                              Text("Phoenix",
                                                  style: GoogleFonts.inter(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w400,
                                                      color: const Color(0xff6B7280))),
                                            ],
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
                  ),
                ),

                FadeSlideAnimation(
                  order: 6,
                  from: SlideFrom.bottom,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
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
                                Text("Overall Standings",
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
                              itemCount: 4,
                              separatorBuilder: (context, index) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                return Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: const Color(0xffF9FAFB),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 12,
                                          backgroundColor: rankBgColors[index],
                                          child: Text(
                                            "${index + 1}",
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: rankTextColors[index],
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 9),
                                          child: CircleAvatar(
                                            radius: 3,
                                            backgroundColor: dotColors[index],
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            teamNames[index],
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xff1F2937),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(right: 6),
                                          child: Text(
                                            points[index],
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xff667EEA),
                                            ),
                                          ),
                                        ),
                                        Text(
                                          "Pts",
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w400,
                                            color: const Color(0xff9CA3AF),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),
              ],
            ),
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
                padding: EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: isActive ? 0 : 12,
                ),
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
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: const Color(0xffF3F4F6),
                          child: const Icon(Icons.image_not_supported_outlined,
                              color: Color(0xff9CA3AF)),
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
                              colors: [
                                Colors.black.withValues(alpha: 0.55),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Text(
                            "Meera's Fest 2K27",
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
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

    Future.delayed(
      Duration(milliseconds: widget.delayMs * widget.order),
          () {
        if (mounted) {
          setState(() {
            animate = true;
          });
        }
      },
    );
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