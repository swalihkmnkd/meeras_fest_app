import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BarGraphEntry {
  final String teamName;
  final String leaderName;
  final double points;
  final Color color;

  const BarGraphEntry({
    required this.teamName,
    required this.leaderName,
    required this.points,
    required this.color,
  });
}

class AnimatedBarGraph extends StatelessWidget {
  final List<BarGraphEntry> entries;
  final double maxValue;
  final double barWidth;
  final double maxBarHeight;

  const AnimatedBarGraph({
    super.key,
    required this.entries,
    required this.maxValue,
    this.barWidth = 40,
    this.maxBarHeight = 150,
  });

  @override
  Widget build(BuildContext context) {
    final safeMax = maxValue <= 0 ? 1.0 : maxValue;

    return SizedBox(
      height: maxBarHeight + 80,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: entries.map((entry) {
            final targetHeight =
                (entry.points / safeMax).clamp(0.0, 1.0) * maxBarHeight;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: SizedBox(
                width: barWidth + 30,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Points
                    Text(
                      "${entry.points.toInt()}",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xff1F2937),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // FIXED HEIGHT BAR AREA
                    SizedBox(
                      height: maxBarHeight,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(
                            begin: 0.0,
                            end: targetHeight,
                          ),
                          duration: const Duration(milliseconds: 1200),
                          curve: Curves.easeOutCubic,
                          builder: (context, animatedHeight, child) {
                            return Container(
                              width: barWidth,
                              height: animatedHeight,
                              decoration: BoxDecoration(
                                color: entry.color,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(8),
                                  bottom: Radius.circular(3),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Team name
                    Text(
                      entry.teamName,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xff1F2937),
                      ),
                    ),

                    // Leader name
                    Text(
                      entry.leaderName,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xff6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
