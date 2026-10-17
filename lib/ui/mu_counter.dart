import 'package:flutter/material.dart';

import '../theme/theme.dart';

enum MuCounterTone { alert, neutral, accent, muted }

/// Counter (components/Counter.md): a small count pill for pending items — 20 high, a circle
/// for one digit, « 99+ » above [max] — or a 10 px dot with a 2 px `surface` ring. At 0 it
/// renders nothing, never « 0 ».
class MuCounter extends StatelessWidget {
  const MuCounter({
    super.key,
    this.value = 0,
    this.max = 99,
    this.tone = MuCounterTone.alert,
    this.dot = false,
    this.semanticLabel,
  });

  final int value;
  final int max;
  final MuCounterTone tone;
  final bool dot;

  /// « 7 signalements ». Without it the pill is hidden from assistive tech: its parent says it.
  final String? semanticLabel;

  // Counter.md: pill 20 high, padding-inline 6; dot 10 with a 2 px ring.
  static const double _pill = 20;
  static const double _padding = 6;
  static const double _dot = 10;
  static const double _ring = 2;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final (Color fill, Color ink) = switch (tone) {
      MuCounterTone.alert => (c.destructive, c.onDestructive),
      MuCounterTone.neutral => (c.surfaceInverse, c.textInverse),
      MuCounterTone.accent => (c.accent, c.onAccent),
      MuCounterTone.muted => (c.surfaceMuted, c.textSecondary),
    };
    final Widget mark;
    if (dot) {
      mark = Container(
        width: _dot,
        height: _dot,
        decoration: BoxDecoration(
          color: fill,
          shape: BoxShape.circle,
          border: Border.all(color: c.surface, width: _ring),
        ),
      );
    } else {
      if (value <= 0) return const SizedBox.shrink();
      final pill = Badge(
        label: Text(value > max ? '$max+' : '$value', style: MuType.labelS),
        largeSize: _pill,
        smallSize: _dot,
        padding: const EdgeInsets.symmetric(horizontal: _padding),
        backgroundColor: fill,
        textColor: ink,
      );
      mark = tone == MuCounterTone.muted
          ? DecoratedBox(
              decoration: ShapeDecoration(
                shape: StadiumBorder(side: BorderSide(color: c.border)),
              ),
              child: pill,
            )
          : pill;
    }
    if (semanticLabel == null) return ExcludeSemantics(child: mark);
    return Semantics(
      container: true,
      label: semanticLabel,
      child: ExcludeSemantics(child: mark),
    );
  }
}
