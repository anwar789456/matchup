import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../data/welcome_samples.dart';

/// The decorative cards of the three welcome slides (hidden from screen readers: the title and
/// text below say the same thing).

/// ONB-02: « À ton niveau » with four players around 3,5, then an open game.
class LevelMatchIllustration extends StatelessWidget {
  const LevelMatchIllustration({super.key});

  // ONB-02: the card is 300 wide.
  static const double _cardWidth = 300;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: _CappedWidth(
            width: _cardWidth,
            child: _IllustrationCard(
              padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s3, MuSpace.s4, MuSpace.s4),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'À TON NIVEAU',
                        style: MuType.overline.copyWith(color: c.textSecondary),
                      ),
                    ),
                    const MuChip.level(WelcomeSamples.myLevel, size: MuChipSize.s),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (final (name, level) in WelcomeSamples.levelPeers)
                      SizedBox(
                        width: MuSize.avatarL,
                        child: Column(
                          children: [
                            MuAvatar(name: name, level: level),
                            const SizedBox(height: MuSpace.s2),
                            Text(
                              name.split(' ').first,
                              style: MuType.caption.copyWith(color: c.textSecondary),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: MuSpace.s3),
        MuGameCard(game: WelcomeSamples.game, surfaceColor: c.surfaceElevated),
      ],
    );
  }
}

/// ONB-03: the padel booking split four ways, and the « Ta part est payée » toast.
class SplitPaymentIllustration extends StatelessWidget {
  const SplitPaymentIllustration({super.key});

  // ONB-03: card 326 wide; toast 300 wide, overlapping the card by 28; the card's footer keeps
  // 36 under the avatars for that overlap.
  static const double _cardWidth = 326;
  static const double _toastWidth = 300;
  static const double _toastOverlap = 28;
  static const double _footerBottom = 36;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final b = WelcomeSamples.booking;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: _CappedWidth(
            width: _cardWidth,
            child: _IllustrationCard(
              padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s4, MuSpace.s4, 0),
              gap: MuSpace.s4,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b.venue, style: MuType.labelL.copyWith(color: c.text)),
                          Text(
                            '${b.court} · ${formatDateTime(b.start)}',
                            style: MuType.caption.copyWith(color: c.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: MuSpace.s3),
                    MuChip.sport(b.sport, size: MuChipSize.s),
                  ],
                ),
                // Full-bleed « Ta part » band.
                _Bleed(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: MuSpace.s4,
                      vertical: MuSpace.s3,
                    ),
                    decoration: BoxDecoration(
                      color: c.surfaceMuted,
                      border: Border.symmetric(horizontal: BorderSide(color: c.border)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TA PART',
                              style: MuType.overline.copyWith(color: c.textSecondary),
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  formatDT(b.share),
                                  style: MuType.numXl.copyWith(color: c.text),
                                ),
                                const SizedBox(width: MuSpace.s1),
                                Text(
                                  '/pers.',
                                  style: MuType.label.copyWith(color: c.textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(width: MuSpace.s3),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: MuSpace.s2),
                            child: Text.rich(
                              textAlign: TextAlign.end,
                              TextSpan(
                                children: [
                                  const TextSpan(text: 'Terrain '),
                                  TextSpan(
                                    text: formatDT(b.courtPrice),
                                    style: MuType.numXs.copyWith(color: c.text),
                                  ),
                                  TextSpan(text: ' ÷ ${b.players} joueurs'),
                                ],
                              ),
                              style: MuType.caption.copyWith(color: c.textSecondary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: _footerBottom),
                  child: Row(
                    children: [
                      MuAvatarStack(people: b.people),
                      const SizedBox(width: MuSpace.s3),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${b.paid} sur ${b.players}',
                                style: MuType.labelS.copyWith(color: c.text),
                              ),
                              const TextSpan(text: ' ont payé leur part'),
                            ],
                          ),
                          style: MuType.caption.copyWith(color: c.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -_toastOverlap),
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: _CappedWidth(
              width: _toastWidth,
              child: MuToast(
                tone: MuToastTone.success,
                title: 'Ta part est payée',
                description: '${formatDT(b.share)} · ${b.venue}',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// ONB-04: the AI basketball level card and a tournament to aim for.
class ProgressIllustration extends StatelessWidget {
  const ProgressIllustration({super.key});

  // ONB-04: the card is 318 wide; trend icon 16.
  static const double _cardWidth = 318;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: _CappedWidth(
            width: _cardWidth,
            child: _IllustrationCard(
              padding: const EdgeInsets.all(MuSpace.s4),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'NIVEAU BASKET',
                        style: MuType.overline.copyWith(color: c.textSecondary),
                      ),
                    ),
                    const MuAiLabel(size: MuAiLabelSize.s),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      formatLevel(WelcomeSamples.basketLevel),
                      style: MuType.numXl.copyWith(color: c.text),
                    ),
                    const SizedBox(width: MuSpace.s2),
                    Text(
                      levelBand(WelcomeSamples.basketLevel),
                      style: MuType.label.copyWith(color: c.text),
                    ),
                    const SizedBox(width: MuSpace.s2),
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Icon(
                                PhosphorIcons.trendUp(),
                                size: MuSize.iconXs,
                                color: c.successText,
                              ),
                              const SizedBox(width: MuSpace.s1),
                              Text(
                                '+${formatLevel(WelcomeSamples.basketTrend)}',
                                style: MuType.numXs.copyWith(color: c.successText),
                              ),
                              Text(
                                ' sur 30 jours',
                                style: MuType.caption.copyWith(color: c.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                MuProgressBar(
                  value: WelcomeSamples.towardsNextBand,
                  size: MuProgressSize.s,
                  label: 'Vers Avancé',
                  valueLabel: formatLevel(4.0),
                ),
                Text(
                  'Estimé d’après tes 12 derniers matchs.',
                  style: MuType.caption.copyWith(color: c.textSecondary),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: MuSpace.s3),
        MuTournamentCard(tournament: WelcomeSamples.tournament, surfaceColor: c.surfaceElevated),
      ],
    );
  }
}

/// `mu-card` on `surface-elevated`, children [gap] apart. Each child gets the side padding,
/// except [_Bleed] children, which run edge to edge.
class _IllustrationCard extends StatelessWidget {
  const _IllustrationCard({required this.children, required this.padding, this.gap = MuSpace.s3});

  final List<Widget> children;
  final EdgeInsets padding;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Container(
      padding: EdgeInsets.only(top: padding.top, bottom: padding.bottom),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.surfaceElevated,
        borderRadius: MuRadius.mdAll,
        boxShadow: MuElevation.of(context).level1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, child) in children.indexed) ...[
            if (i > 0) SizedBox(height: gap),
            if (child is _Bleed)
              child
            else
              Padding(
                padding: EdgeInsets.only(left: padding.left, right: padding.right),
                child: child,
              ),
          ],
        ],
      ),
    );
  }
}

/// Marks a child of [_IllustrationCard] that runs to the card edges.
class _Bleed extends StatelessWidget {
  const _Bleed({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

/// The design's fixed card width, never wider than the space available.
class _CappedWidth extends StatelessWidget {
  const _CappedWidth({required this.width, required this.child});

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) =>
          SizedBox(width: math.min(width, constraints.maxWidth), child: child),
    );
  }
}
