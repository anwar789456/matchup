import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/format.dart';
import '../theme/theme.dart';
import '../l10n/l10n.dart';

enum MuLevelVariant { inline, bar }

enum MuLevelSize { s, m }

/// How sure the AI is of an estimated level: 1, 2 or 3 dots.
enum MuConfidence { low, medium, high }

/// The four bands of the 1,0–7,0 scale, each 1,5 points wide.
final muLevelBands = [l10n.debutant, l10n.intermediaire, l10n.avance, l10n.expert];

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
    this.trend,
    this.trendLabel,
    this.ai = false,
    this.confidence,
    this.reason,
    this.showValue = false,
  });

  final double level;
  final MuLevelVariant variant;
  final MuLevelSize size;

  /// Accessible name of the bar (« Niveau padel estimé »).
  final String? label;

  /// Bar only: the change over [trendLabel] (« +0,2 sur 30 jours »); 0 reads « Stable ».
  final double? trend;
  final String? trendLabel;

  /// Bar only: « Estimation IA » pill, the confidence dots and the [reason] under a rule.
  final bool ai;
  final MuConfidence? confidence;
  final String? reason;

  /// Bar only: « 3,5 Intermédiaire » (+ the AI pill) above the track (PRF-01 level cards).
  final bool showValue;

  // LevelIndicator.md: track 8 high, 2 px gaps; marker 4 × 20 with a 2 px surface ring;
  // band ticks 1 × 6.
  static const double _track = 8;
  static const double _gap = 2;
  static const double _markerW = 4;
  static const double _markerH = 20;
  static const double _ring = 2;
  static const double _tick = 6;
  static const double _dotSize = 6;
  static const double _sparkle = 14;

  String get _spoken => l10n.sur3(formatLevel(level), levelBand(level));

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    if (variant == MuLevelVariant.inline) {
      final small = size == MuLevelSize.s;
      return Semantics(
        label: l10n.niveau2(_spoken),
        excludeSemantics: true,
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: formatLevel(level),
                style: (small ? MuType.numXs : MuType.numS).copyWith(color: c.text),
              ),
              TextSpan(text: small ? ' ' : '  '),
              TextSpan(text: levelBand(level)),
            ],
          ),
          style: (small ? MuType.caption : MuType.body).copyWith(color: c.textSecondary),
        ),
      );
    }

    final band = levelBand(level);
    final fraction = ((level - 1) / 6).clamp(0.0, 1.0);
    final duration = MuMotion.durationOf(context, MuMotion.counter);

    final trendRow = trend == null && confidence == null
        ? null
        : Row(
            children: [
              if (confidence != null) ...[
                for (var i = 0; i < 3; i++)
                  Container(
                    width: _dotSize,
                    height: _dotSize,
                    margin: EdgeInsetsDirectional.only(end: i < 2 ? _gap : MuSpace.s2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i <= confidence!.index ? c.text : c.borderStrong,
                    ),
                  ),
                Text(switch (confidence!) {
                  MuConfidence.low => l10n.confianceFaible,
                  MuConfidence.medium => l10n.confianceMoyenne,
                  MuConfidence.high => l10n.confianceElevee,
                }, style: MuType.caption.copyWith(color: c.textSecondary)),
              ],
              const Spacer(),
              if (trend != null) ...[
                Icon(
                  trend! > 0
                      ? PhosphorIcons.trendUp()
                      : trend! < 0
                      ? PhosphorIcons.trendDown()
                      : PhosphorIcons.minus(),
                  size: MuSize.iconXs,
                  color: trend! > 0
                      ? c.successText
                      : trend! < 0
                      ? c.errorText
                      : c.textSecondary,
                ),
                const SizedBox(width: MuSpace.s1),
                Text(
                  trend == 0 ? l10n.stable : '${trend! > 0 ? '+' : '−'}${formatLevel(trend!.abs())}',
                  style: (trend == 0 ? MuType.labelS : MuType.numXs).copyWith(
                    color: trend! > 0
                        ? c.successText
                        : trend! < 0
                        ? c.errorText
                        : c.textSecondary,
                  ),
                ),
                if (trendLabel != null) ...[
                  const SizedBox(width: MuSpace.s1),
                  Text(trendLabel!, style: MuType.caption.copyWith(color: c.textSecondary)),
                ],
              ],
            ],
          );

    return Semantics(
      label: label,
      value:
          '$_spoken'
          '${trend == null
              ? ''
              : trend == 0
              ? l10n.stable2
              : ', ${trend! > 0 ? 'plus' : 'moins'} ${formatLevel(trend!.abs())} ${trendLabel ?? ''}'}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showValue) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(formatLevel(level), style: MuType.numL.copyWith(color: c.text)),
                const SizedBox(width: MuSpace.s2),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: MuSpace.s1),
                    child: Text(band, style: MuType.labelL.copyWith(color: c.text)),
                  ),
                ),
                if (ai)
                  Container(
                    height: MuSize.controlS - MuSpace.s2,
                    padding: const EdgeInsets.symmetric(horizontal: MuSpace.s2),
                    decoration: BoxDecoration(color: c.aiSoft, borderRadius: MuRadius.fullAll),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                          size: _sparkle,
                          color: c.aiText,
                        ),
                        const SizedBox(width: MuSpace.s1),
                        Text(l10n.estimationIa, style: MuType.labelS.copyWith(color: c.aiText)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: MuSpace.s3),
          ],
          SizedBox(
            height: _markerH,
            child: LayoutBuilder(
              builder: (context, constraints) {
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
              },
            ),
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
          if (trendRow != null) ...[const SizedBox(height: MuSpace.s3), trendRow],
          if (reason != null) ...[
            const SizedBox(height: MuSpace.s2),
            Text(reason!, style: MuType.caption.copyWith(color: c.textSecondary)),
          ],
        ],
      ),
    );
  }
}
