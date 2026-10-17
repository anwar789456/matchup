import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../player_onboarding/controllers/onboarding_controller.dart';
import '../../../l10n/l10n.dart';

/// ONB-01 · Splash: the logo and tagline on ink for 1,5 s, then the welcome slides — or, when a
/// player onboarding is in progress, the screen where it stopped (the Home once it is done).
/// Tapping anywhere continues at once. Always Night match.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  // SCREENS.md: the splash shows for 1,5 s.
  static const _hold = Duration(milliseconds: 1500);
  // ONB-01: logo 44 high; loading bar 80 × 4, 72 from the bottom, slider 40 % wide.
  static const double _logoHeight = 44;
  static const double _barWidth = 80;
  static const double _barHeight = 4;
  static const double _barBottom = 72;
  static const double _barFill = 0.4;
  static const double _trackAlpha = 0.12;

  late final AnimationController _bar = AnimationController(vsync: this, duration: MuMotion.shimmer);
  Timer? _timer;
  bool _left = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(_hold, _continue);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _bar.stop();
    } else if (!_bar.isAnimating) {
      _bar.repeat();
    }
  }

  Future<void> _continue() async {
    if (_left || !mounted) return;
    _left = true;
    final progress = await ref.read(onboardingProvider.future);
    if (!mounted) return;
    if (progress.completed) {
      context.go(Routes.home);
    } else if (progress.lastRoute != null) {
      context.go(progress.lastRoute!);
    } else {
      context.go(Routes.welcome1);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: MuTheme.dark(),
      child: Builder(builder: (context) {
        final c = context.mu;
        return Scaffold(
          backgroundColor: MuPalette.ink900,
          body: Semantics(
            button: true,
            label: l10n.ouvrirMatchup,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _continue,
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const MuLogo(tone: MuLogoTone.dark, height: _logoHeight),
                        const SizedBox(height: MuSpace.s4),
                        Text(
                          l10n.joueReserveProgresse,
                          style: MuType.bodyL.copyWith(color: MuPalette.ink300),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: _barBottom,
                    child: Center(
                      child: ExcludeSemantics(
                        child: ClipRRect(
                          borderRadius: MuRadius.fullAll,
                          child: Container(
                            width: _barWidth,
                            height: _barHeight,
                            color: MuPalette.white.withValues(alpha: _trackAlpha),
                            child: AnimatedBuilder(
                              animation: _bar,
                              builder: (context, _) {
                                // Slides from −100 % to +250 % of its own width (ease-move).
                                final t = MuMotion.move.transform(_bar.value);
                                final dx = (-1 + 3.5 * t) * _barWidth * _barFill;
                                return Transform.translate(
                                  offset: Offset(dx, 0),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: _barFill,
                                    child: ColoredBox(color: c.accent),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
