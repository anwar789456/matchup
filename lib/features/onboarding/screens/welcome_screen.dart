import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/balanced_text.dart';
import '../widgets/welcome_illustrations.dart';
import '../../../l10n/l10n.dart';

/// ONB-02 · ONB-03 · ONB-04 — the three welcome slides, swipeable, always in Night match.
/// Each slide keeps its own route; buttons and swipes keep the URL in sync.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, this.initialPage = 0});

  final int initialPage;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _Slide {
  const _Slide({
    required this.sport,
    required this.title,
    required this.text,
    required this.illustration,
    this.artTop = _artTopDefault,
    this.fade = const [0, 0.22, 0.6, 1],
  });

  final MuSport sport;
  final String title;
  final String text;
  final Widget illustration;
  final double artTop;
  final List<double> fade;

  // ONB-02/03: the art starts 96 from the top and is 500 high (ONB-04: from the top).
  static const double _artTopDefault = 96;
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late final PageController _pages = PageController(initialPage: widget.initialPage);
  late int _page = widget.initialPage;

  static const double _artHeight = 500;

  static final _slides = [
    _Slide(
      sport: MuSport.football,
      title: l10n.trouveDesJoueursATon,
      text: l10n.rejoinsDesPartiesPresDe,
      illustration: const LevelMatchIllustration(),
    ),
    _Slide(
      sport: MuSport.padel,
      title: l10n.reserveEtPaieEnQuelques,
      text: l10n.choisisTonCreneauEtPaie,
      illustration: const SplitPaymentIllustration(),
    ),
    _Slide(
      sport: MuSport.basketball,
      title: l10n.progresseEtAffronteLesMeilleurs,
      text: l10n.tonNiveauEvolueAChaque,
      illustration: const ProgressIllustration(),
      artTop: 0,
      fade: [0, 0.24, 0.52, 0.92],
    ),
  ];

  bool get _last => _page == _slides.length - 1;

  @override
  void didUpdateWidget(WelcomeScreen old) {
    super.didUpdateWidget(old);
    // A route change (button, back, deep link) moves the carousel.
    if (widget.initialPage != _page) _animateTo(widget.initialPage);
  }

  void _animateTo(int page) {
    setState(() => _page = page);
    if (!_pages.hasClients) return;
    final duration = MuMotion.durationOf(context, MuMotion.slow);
    if (duration == Duration.zero) {
      _pages.jumpToPage(page);
    } else {
      _pages.animateToPage(page, duration: duration, curve: MuMotion.move);
    }
  }

  void _goTo(int page) => context.go(Routes.welcome[page]);

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: MuTheme.dark(),
      child: Builder(builder: (context) {
        final c = context.mu;
        final bottomInset = MediaQuery.paddingOf(context).bottom;
        return Scaffold(
          backgroundColor: c.bg,
          body: Stack(
            children: [
              PageView.builder(
                controller: _pages,
                itemCount: _slides.length,
                onPageChanged: (i) {
                  if (i == _page) return;
                  setState(() => _page = i);
                  _goTo(i);
                },
                itemBuilder: (context, i) => _SlidePage(
                  slide: _slides[i],
                  artHeight: _artHeight,
                  // Room for the dots and the buttons, which stay fixed below the slides.
                  bottomSpace: _controlsHeight(i) + math.max(bottomInset, MuSpace.s8),
                ),
              ),
              _topBar(context),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _controls(context),
              ),
            ],
          ),
        );
      }),
    );
  }

  /// Dots (24 above) + buttons (24 above, XL, 12 apart); the bottom margin is added by the caller.
  double _controlsHeight(int page) {
    const dots = MuSpace.s6 + MuSpace.s2;
    final buttons = page == _slides.length - 1
        ? MuSize.controlXl * 2 + MuSpace.s3
        : MuSize.controlXl;
    return dots + MuSpace.s6 + buttons;
  }

  Widget _topBar(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(MuSpace.s2, MuSpace.s2, MuSpace.s2, 0),
        child: SizedBox(
          height: MuSize.controlL,
          child: Row(
            children: [
              if (_page > 0)
                MuIconButton(
                  icon: PhosphorIcons.arrowLeft(),
                  label: l10n.retour,
                  size: MuIconButtonSize.l,
                  onPressed: () => _goTo(_page - 1),
                ),
              const Spacer(),
              if (!_last)
                MuButton.tertiary(
                  label: l10n.passer,
                  onPressed: () => _goTo(_slides.length - 1),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _controls(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: MuSpace.s8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s6, MuSpace.s4, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: MuStepIndicator(
                step: _page + 1,
                total: _slides.length,
                variant: MuStepVariant.dots,
              ),
            ),
            const SizedBox(height: MuSpace.s6),
            if (_last) ...[
              MuButton.primary(
                label: l10n.commencer,
                size: MuButtonSize.xl,
                fullWidth: true,
                onPressed: () => context.push(Routes.signup),
              ),
              const SizedBox(height: MuSpace.s3),
              MuButton.secondary(
                label: l10n.jAiDejaUnCompte,
                size: MuButtonSize.xl,
                fullWidth: true,
                onPressed: () => context.push(Routes.login),
              ),
            ] else
              MuButton.primary(
                label: l10n.suivant,
                trailing: PhosphorIcons.arrowRight(),
                size: MuButtonSize.xl,
                fullWidth: true,
                onPressed: () => _goTo(_page + 1),
              ),
          ],
        ),
      ),
    );
  }
}

class _SlidePage extends StatelessWidget {
  const _SlidePage({required this.slide, required this.artHeight, required this.bottomSpace});

  final _Slide slide;
  final double artHeight;
  final double bottomSpace;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final topInset = MediaQuery.paddingOf(context).top;
    return Stack(
      children: [
        Positioned(
          top: slide.artTop,
          left: 0,
          right: 0,
          height: artHeight,
          child: MuCourtArt(
            sport: slide.sport,
            variant: MuCourtArtVariant.poster,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [c.bg, c.bg.withValues(alpha: 0), c.bg.withValues(alpha: 0), c.bg],
                  stops: slide.fade,
                ),
              ),
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: topInset + MuSpace.s2 + MuSize.controlL),
            // The illustration sits at the bottom of the free space; on short screens its top is
            // clipped rather than squeezing the title.
            Expanded(
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.bottomCenter,
                  minHeight: 0,
                  maxHeight: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
                    child: ExcludeSemantics(child: slide.illustration),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(MuSpace.s6, MuSpace.s6, MuSpace.s6, 0),
              child: Column(
                children: [
                  Semantics(
                    header: true,
                    child: BalancedText(
                      slide.title,
                      textAlign: TextAlign.center,
                      style: MuType.h1.copyWith(color: c.text),
                    ),
                  ),
                  const SizedBox(height: MuSpace.s3),
                  BalancedText(
                    slide.text,
                    textAlign: TextAlign.center,
                    style: MuType.bodyL.copyWith(color: c.textSecondary),
                  ),
                ],
              ),
            ),
            SizedBox(height: bottomSpace),
          ],
        ),
      ],
    );
  }
}
