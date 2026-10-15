import 'package:flutter/material.dart';

import '../core/format.dart';
import '../theme/theme.dart';

enum MuLevelVariant { inline, bar }

enum MuLevelSize { s, m }

/// The four bands of the 1,0–7,0 scale, each 1,5 points wide.
const muLevelBands = ['Débutant', 'Intermédiaire', 'Avancé', 'Expert'];

/// LevelIndicator (components/LevelIndicator.md): a level and its band — inline « 3,5
/// Intermédiaire », or a 6-segment bar with a marker on the exact level and the bands under it.
/// Bands are never coloured.
///
/// The badge variant, trend and AI confidence row come with the profile milestone.
class MuLevelIndicator extends StatelessWidget {
  const MuLevelIndicator({
    super.key,
    required this.level,
    this.variant = MuLevelVariant.inline,
    this.size = MuLevelSize.m,
    this.label,
  });

  final double level;
  final MuLevelVariant variant;
  final MuLevelSize size;

  /// Accessible name of the bar (« Niveau padel estimé »).
  final String? label;

  // LevelIndicator.md: track 8 high, 2 px gaps; marker 4 × 20 with a 2 px surface ring;
  // band ticks 1 × 6.
  static const double _track = 8;
  static const double _gap = 2;
  static const double _markerW = 4;
  static const double _markerH = 20;
  static const double _ring = 2;
  static const double _tick = 6;

  String get _spoken => '${formatLevel(level)} sur 7, ${levelBand(level)}';

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    if (variant == MuLevelVariant.inline) {
      final small = size == MuLevelSize.s;
      return Semantics(
        label: 'Niveau $_spoken',
        excludeSemantics: true,
        child: Text.rich(
          TextSpan(children: [
            TextSpan(
              text: formatLevel(level),
              style: (small ? MuType.numXs : MuType.numS).copyWith(color: c.text),
            ),
            TextSpan(text: small ? ' ' : '  '),
            TextSpan(text: levelBand(level)),
          ]),
          style: (small ? MuType.caption : MuType.body).copyWith(color: c.textSecondary),
        ),
      );
    }

    final band = levelBand(level);
    final fraction = ((level - 1) / 6).clamp(0.0, 1.0);
    final duration = MuMotion.durationOf(context, MuMotion.counter);

    return Semantics(
      label: label,
      value: _spoken,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: _markerH,
            child: LayoutBuilder(builder: (context, constraints) {
              final width = constraints.maxWidth;
              return Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.centerLeft,
                children: [
                  // Six segments, one per point, filled up to the level.
                  Row(
                    children: [
                      for (var i = 0; i < 6; i++) ...[
                        if (i > 0) const SizedBox(width: _gap),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: MuRadius.xsAll,
                            child: Container(
                              height: _track,
                              color: c.border,
                              alignment: AlignmentDirectional.centerStart,
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(end: (level - 1 - i).clamp(0.0, 1.0)),
                                duration: duration,
                                curve: MuMotion.move,
                                builder: (context, f, _) => FractionallySizedBox(
                                  widthFactor: f,
                                  heightFactor: 1,
                                  child: ColoredBox(color: c.primary),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: fraction),
                    duration: duration,
                    curve: MuMotion.move,
                    builder: (context, f, child) => PositionedDirectional(
                      start: f * width - _markerW / 2 - _ring,
                      child: child!,
                    ),
                    child: Container(
                      width: _markerW + _ring * 2,
                      height: _markerH,
                      decoration: BoxDecoration(
                        color: c.primary,
                        borderRadius: MuRadius.fullAll,
                        border: Border.all(color: c.surface, width: _ring),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
          // Ticks at the band limits 2,5 · 4,0 · 5,5 (25 %, 50 %, 75 %).
          SizedBox(
            height: _tick + MuSpace.s1,
            child: Row(
              children: [
                for (var i = 0; i < 4; i++) ...[
                  if (i > 0)
                    Container(
                      width: 1,
                      height: _tick,
                      margin: const EdgeInsets.only(top: MuSpace.s1),
                      color: c.borderStrong,
                    ),
                  const Expanded(child: SizedBox()),
                ],
              ],
            ),
          ),
          const SizedBox(height: MuSpace.s1),
          Row(
            children: [
              for (final name in muLevelBands)
                Expanded(
                  child: Text(
                    name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    softWrap: false,
                    style: name == band
                        ? MuType.labelS.copyWith(color: c.text)
                        : MuType.caption.copyWith(color: c.textSecondary),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
