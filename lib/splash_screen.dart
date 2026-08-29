import 'package:flutter/material.dart';
import 'package:meeras_fest_app/home/bottom_bar.dart';

/// Splash flow:
/// 1. Logo (asset image) fades + scales in on a plain background.
/// 2. After a short hold, it crossfades into a fullscreen asset image.
/// 3. The fullscreen image holds, then fades OUT.
/// 4. Navigates to [BottomBar].
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
  static const _fullScreenHoldDuration = Duration(milliseconds: 1500);
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

  Future<void> _runSequence() async {
    // 1. Animate the logo in.
    await _logoController.forward();
    if (!mounted) return;

    // 2. Hold on the logo briefly.
    await Future.delayed(_logoHoldDuration);
    if (!mounted) return;

    // 3. Crossfade to the fullscreen image (fade in).
    setState(() {
      _showFullScreen = true;
      _fullScreenOpacity = 1.0;
    });
    await Future.delayed(_crossfadeDuration + _fullScreenHoldDuration);
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