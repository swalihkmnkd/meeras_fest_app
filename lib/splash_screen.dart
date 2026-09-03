import 'package:flutter/material.dart';
import 'package:meeras_fest_app/home/bottom_bar.dart';
// TODO: import whichever providers/services actually need pre-fetching, e.g:
// import 'package:provider/provider.dart';
// import 'package:meeras_fest_app/home/home_stats_provider.dart';
// import 'package:meeras_fest_app/admin/providers/curosel_provider.dart';

/// Splash flow:
/// 1. Logo (asset image) fades + scales in on a plain background.
/// 2. After a short hold, it crossfades into a fullscreen asset image.
/// 3. While the fullscreen image holds, initial app data is fetched
///    in the background — the hold time is reused as fetch time
///    instead of being a pure delay.
/// 4. The fullscreen image fades OUT once both the hold time AND the
///    data fetch are done (whichever takes longer).
/// 5. Navigates to [BottomBar].
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  static const String _logoUrl = 'assets/logos/IMG_1299.PNG';
  static const String _fullScreenImageUrl = 'assets/images/WhatsApp Image 2026-08-27 at 11.09.12 PM.jpeg';

  // ---- Timings — tweak freely ----
  static const _logoAnimDuration = Duration(milliseconds: 900);
  static const _logoHoldDuration = Duration(milliseconds: 700);
  static const _crossfadeDuration = Duration(milliseconds: 600); // logo -> fullscreen fade in
  // Minimum time the fullscreen image stays visible, even if data
  // fetching finishes earlier (keeps the animation from feeling rushed).
  static const _fullScreenMinHoldDuration = Duration(milliseconds: 1500);
  // Safety cap so a slow/failed network call can never hang the splash forever.
  static const _fullScreenMaxHoldDuration = Duration(milliseconds: 6000);
  static const _fullScreenFadeOutDuration = Duration(milliseconds: 600);

  late final AnimationController _logoController;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;

  bool _showFullScreen = false;
  double _fullScreenOpacity = 0.0; // used for the final fade-out

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(vsync: this, duration: _logoAnimDuration);
    _logoFade = CurvedAnimation(parent: _logoController, curve: Curves.easeOut);
    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    _runSequence();
  }

  /// Kick off whatever initial data the app needs before it's usable.
  /// Runs concurrently with the fullscreen-image hold, so the wait time
  /// isn't wasted on a bare delay. Errors are swallowed here — a failed
  /// prefetch shouldn't block the user from reaching the app; the relevant
  /// screen can retry/show its own error state.
  Future<void> _fetchInitialData() async {
    try {
      // Example (uncomment / adapt to your real providers):
      // final homeStats = context.read<HomeStatsProvider>();
      // final carousel = context.read<CarouselProvider>();
      // await Future.wait([
      //   homeStats.fetchAll(),
      //   carousel.fetchImages(),
      // ]);
    } catch (_) {
      // Swallow — don't let a prefetch failure block navigation.
    }
  }

  Future<void> _runSequence() async {
    // 1. Animate the logo in.
    await _logoController.forward();
    if (!mounted) return;

    // 2. Hold on the logo briefly.
    await Future.delayed(_logoHoldDuration);
    if (!mounted) return;

    // 3. Crossfade to the fullscreen image (fade in) and, at the same
    //    time, start fetching data. The image's hold period is reused
    //    as fetch time instead of being pure dead time.
    setState(() {
      _showFullScreen = true;
      _fullScreenOpacity = 1.0;
    });

    final fetchFuture = _fetchInitialData();
    final minHoldFuture = Future.delayed(_crossfadeDuration + _fullScreenMinHoldDuration);
    final maxHoldFuture = Future.delayed(_crossfadeDuration + _fullScreenMaxHoldDuration);

    // Wait for the minimum hold time AND the fetch to complete (so the
    // animation never feels rushed), but never wait longer than the max cap.
    await Future.any([
      Future.wait([minHoldFuture, fetchFuture]),
      maxHoldFuture,
    ]);
    if (!mounted) return;

    // 4. Fade the fullscreen image back out.
    setState(() => _fullScreenOpacity = 0.0);
    await Future.delayed(_fullScreenFadeOutDuration);
    if (!mounted) return;

    // 5. Navigate to the app.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const BottomBar()),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedSwitcher(
        duration: _crossfadeDuration,
        switchInCurve: Curves.easeIn,
        switchOutCurve: Curves.easeOut,
        child: _showFullScreen ? _buildFullScreenImage() : _buildLogo(),
      ),
    );
  }

  Widget _buildLogo() {
    return Center(
      key: const ValueKey('logo'),
      child: FadeTransition(
        opacity: _logoFade,
        child: ScaleTransition(
          scale: _logoScale,
          child: Image.asset(
            _logoUrl,
            width: 140,
            height: 140,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.image_not_supported_outlined,
              size: 60,
              color: Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFullScreenImage() {
    return SizedBox.expand(
      key: const ValueKey('fullscreen'),
      child: AnimatedOpacity(
        opacity: _fullScreenOpacity,
        duration: _fullScreenFadeOutDuration,
        curve: Curves.easeInOut,
        child: Container(
          height: double.infinity,
          color: Colors.black,
          child: Image.asset(
            _fullScreenImageUrl,
            fit: BoxFit.fitWidth,
            errorBuilder: (context, error, stackTrace) => Container(color: Colors.white),
          ),
        ),
      ),
    );
  }
}