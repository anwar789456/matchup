import 'package:flutter/material.dart';

import '../../theme/theme.dart';

enum MuBadgeTone { warning, accent, neutral, info }

/// The small pills the cards carry next to a StatusBadge: « Plus que 1 place » (`warning-soft`,
/// `warning` icon), « Tu joues » (Volt), « Terminé » (neutral, flag). Same metrics as a StatusBadge
/// M: 24 high, `label-s`, 14 icon.
class MuToneBadge extends StatelessWidget {
  const MuToneBadge({super.key, required this.label, required this.tone, this.icon});

  final String label;
  final MuBadgeTone tone;
  final IconData? icon;

  static const double _height = 24;
  static const double _icon = 14;
  static const double _padStart = 6;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final (Color ground, Color ink, Color iconInk) = switch (tone) {
      MuBadgeTone.warning => (c.warningSoft, c.warningText, c.warning),
      MuBadgeTone.accent => (c.accent, c.onAccent, c.onAccent),
      MuBadgeTone.neutral => (c.surfaceMuted, c.textSecondary, c.textSecondary),
      MuBadgeTone.info => (c.infoSoft, c.infoText, c.infoText),
    };
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        height: _height,
        padding: EdgeInsetsDirectional.only(
          start: icon == null ? MuSpace.s2 : _padStart,
          end: MuSpace.s2,
        ),
        decoration: ShapeDecoration(
          color: ground,
          shape: StadiumBorder(
            side: tone == MuBadgeTone.neutral ? BorderSide(color: c.border) : BorderSide.none,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: _icon, color: iconInk),
              const SizedBox(width: MuSpace.s1),
            ],
            Text(label, style: MuType.labelS.copyWith(color: ink)),
          ],
        ),
      ),
    );
  }
}
