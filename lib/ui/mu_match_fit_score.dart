import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/theme.dart';

enum MuFitSize { s, m }

/// MatchFitScore (components/MatchFitScore.md), pill form: « ✦ 92 % compatible » on `ai-soft`
/// with a 1 px AI-gradient edge. Read « IA : 92 % compatible »; [reason] is its tooltip.
///
/// The ring form and the « Pourquoi 92 % ? » popover come with the game detail milestone.
class MuMatchFitScore extends StatelessWidget {
  const MuMatchFitScore.pill({
    super.key,
    required this.value,
    this.size = MuFitSize.s,
    this.reason,
  });

  final int value;
  final MuFitSize size;
  final String? reason;

  // MatchFitScore.md: pill S 24 high, padding 6 / 10, sparkle 14; M 28, 8 / 12, sparkle 16.
  static const double _heightS = 24;
  static const double _heightM = 28;
  static const double _sparkleS = 14;
  static const double _edge = 1;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final small = size == MuFitSize.s;
    final pill = Container(
      height: small ? _heightS : _heightM,
      padding: const EdgeInsets.all(_edge),
      decoration: const ShapeDecoration(shape: StadiumBorder(), gradient: MuGradients.ai),
      child: Container(
        padding: EdgeInsetsDirectional.only(
          start: small ? 6 - _edge : MuSpace.s2 - _edge,
          end: small ? 10 - _edge : MuSpace.s3 - _edge,
        ),
        decoration: ShapeDecoration(shape: const StadiumBorder(), color: c.aiSoft),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                size: small ? _sparkleS : MuSize.iconXs, color: c.aiText),
            const SizedBox(width: MuSpace.s1),
            Text('$value %', style: (small ? MuType.numXs : MuType.numS).copyWith(color: c.aiText)),
            Text(' compatible', style: MuType.labelS.copyWith(color: c.aiText)),
          ],
        ),
      ),
    );
    final named = Semantics(
      label: 'IA : $value % compatible',
      excludeSemantics: true,
      child: pill,
    );
    return reason == null ? named : Tooltip(message: 'Recommandé car $reason', child: named);
  }
}
