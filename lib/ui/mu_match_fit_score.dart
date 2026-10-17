import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/theme.dart';

enum MuFitSize { s, m, l }

/// One reason behind the score: « Niveau dans la fourchette · Toi 3,0 · partie 3,0–4,5 ».
@immutable
class MuFitFactor {
  const MuFitFactor({required this.icon, required this.label, this.detail, this.against = false});

  final IconData icon;
  final String label;
  final String? detail;

  /// A factor against the fit: a hollow disc and wording that states the gap.
  final bool against;
}

/// MatchFitScore (components/MatchFitScore.md): the AI compatibility of a game for the player.
///
/// - `.pill`: « ✦ 92 % compatible » on `ai-soft` with a 1 px AI-gradient edge; [reason] is its
///   tooltip.
/// - `.ring`: a 64 (M) or 96 (L) ring stroked with the AI gradient, the value inside and
///   « compatible » under it, next to the why-list of [factors] and the provenance [note].
///
/// Under 60 the score goes quiet: neutral colours, no gradient.
class MuMatchFitScore extends StatelessWidget {
  const MuMatchFitScore.pill({super.key, required this.value, this.size = MuFitSize.s, this.reason})
    : ring = false,
      factors = const [],
      note = null;

  const MuMatchFitScore.ring({
    super.key,
    required this.value,
    this.size = MuFitSize.m,
    this.factors = const [],
    this.note,
  }) : ring = true,
       reason = null;

  final int value;
  final MuFitSize size;
  final String? reason;
  final bool ring;
  final List<MuFitFactor> factors;

  /// « Recommandé car … L’IA peut se tromper. »
  final String? note;

  // MatchFitScore.md: pill S 24 (6 / 10, sparkle 14), M 28 (8 / 12, sparkle 16); ring M 64 with a
  // 6 stroke, L 96 with 8; why-list discs 32; low under 60.
  static const double _heightS = 24;
  static const double _heightM = 28;
  static const double _sparkleS = 14;
  static const double _edge = 1;
  static const double _ringM = 64;
  static const double _ringL = 96;
  static const double _strokeM = 6;
  static const double _strokeL = 8;
  static const double _disc = 32;
  static const double _sparkleRing = 12;
  static const int lowThreshold = 60;

  bool get _low => value < lowThreshold;

  @override
  Widget build(BuildContext context) => ring ? _ring(context) : _pill(context);

  Widget _pill(BuildContext context) {
    final c = context.mu;
    final small = size != MuFitSize.m;
    final ink = _low ? c.text : c.aiText;
    final pill = Container(
      height: small ? _heightS : _heightM,
      padding: const EdgeInsets.all(_edge),
      decoration: _low
          ? ShapeDecoration(shape: const StadiumBorder(), color: c.borderStrong)
          : const ShapeDecoration(shape: StadiumBorder(), gradient: MuGradients.ai),
      child: Container(
        padding: EdgeInsetsDirectional.only(
          start: small ? 6 - _edge : MuSpace.s2 - _edge,
          end: small ? 10 - _edge : MuSpace.s3 - _edge,
        ),
        decoration: ShapeDecoration(
          shape: const StadiumBorder(),
          color: _low ? c.surfaceMuted : c.aiSoft,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIcons.sparkle(_low ? PhosphorIconsStyle.regular : PhosphorIconsStyle.fill),
              size: small ? _sparkleS : MuSize.iconXs,
              color: _low ? c.textSecondary : c.aiText,
            ),
            const SizedBox(width: MuSpace.s1),
            Text('$value %', style: (small ? MuType.numXs : MuType.numS).copyWith(color: ink)),
            Text(' compatible', style: MuType.labelS.copyWith(color: ink)),
          ],
        ),
      ),
    );
    final named = Semantics(label: 'IA : $value % compatible', excludeSemantics: true, child: pill);
    return reason == null ? named : Tooltip(message: 'Recommandé car $reason', child: named);
  }

  Widget _ring(BuildContext context) {
    final c = context.mu;
    final large = size == MuFitSize.l;
    final d = large ? _ringL : _ringM;
    final stroke = large ? _strokeL : _strokeM;
    final duration = MuMotion.durationOf(context, MuMotion.counter);

    final dial = Semantics(
      image: true,
      label: '$value % compatible',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: d,
            height: d,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value / 100),
              duration: duration,
              curve: MuMotion.move,
              builder: (context, t, _) => CustomPaint(
                painter: _RingPainter(
                  fraction: t,
                  stroke: stroke,
                  track: _low ? c.border : c.aiSoft,
                  solid: _low ? c.textSecondary : null,
                ),
                child: Center(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '$value',
                          style: (large ? MuType.numL : MuType.numM).copyWith(color: c.text),
                        ),
                        TextSpan(
                          text: '%',
                          style: (large ? MuType.numS : MuType.numXs).copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: MuSpace.s1),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                size: _sparkleRing,
                color: _low ? c.textSecondary : c.aiText,
              ),
              const SizedBox(width: MuSpace.s1),
              Text(
                'compatible',
                style: MuType.labelS.copyWith(color: _low ? c.textSecondary : c.aiText),
              ),
            ],
          ),
        ],
      ),
    );

    Widget factor(MuFitFactor f) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: _disc,
          height: _disc,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: f.against ? null : c.aiSoft,
            border: f.against ? Border.all(color: c.borderStrong, width: 1.5) : null,
          ),
          child: Icon(f.icon, size: MuSize.iconXs, color: f.against ? c.textSecondary : c.aiText),
        ),
        const SizedBox(width: MuSpace.s3),
        Expanded(
          child: Semantics(
            label:
                '${f.against ? 'En défaveur' : 'En faveur'} : ${f.label}'
                '${f.detail == null ? '' : ', ${f.detail}'}',
            excludeSemantics: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(f.label, style: MuType.label.copyWith(color: c.text)),
                if (f.detail != null)
                  Text(f.detail!, style: MuType.caption.copyWith(color: c.textSecondary)),
              ],
            ),
          ),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            dial,
            const SizedBox(width: MuSpace.s4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, f) in factors.indexed) ...[
                    if (i > 0) const SizedBox(height: MuSpace.s3),
                    factor(f),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (note != null) ...[
          const SizedBox(height: MuSpace.s3),
          Divider(height: 1, thickness: 1, color: c.border),
          const SizedBox(height: MuSpace.s3),
          Text(note!, style: MuType.caption.copyWith(color: c.textSecondary)),
        ],
      ],
    );
  }
}

/// The arc from 12 o'clock clockwise with round caps, AI gradient (or a solid colour when low).
class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.fraction,
    required this.stroke,
    required this.track,
    this.solid,
  });

  final double fraction;
  final double stroke;
  final Color track;
  final Color? solid;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawOval(rect, paint..color = track);
    if (fraction <= 0) return;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    if (solid != null) {
      arc.color = solid!;
    } else {
      arc.shader = MuGradients.ai.createShader(rect);
    }
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * fraction, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.track != track || old.solid != solid;
}
