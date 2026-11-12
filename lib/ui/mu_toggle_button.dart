import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/theme.dart';
import 'src/interaction.dart';

enum MuToggleSize { s, m, l }

/// ToggleButton (components/ToggleButton.md): one on/off action that stays in place —
/// « Suivre » ↔ « Suivi », « M’alerter » ↔ « Alerte activée ». Off: `surface` with a
/// `border-strong` outline; on: Volt (`accent`) fill with `on-accent` label and a check (or
/// [onIcon]). Flip the state at once and save in the background.
class MuToggleButton extends StatelessWidget {
  const MuToggleButton({
    super.key,
    required this.pressed,
    required this.onChanged,
    required this.label,
    this.onLabel,
    this.icon,
    this.onIcon,
    this.size = MuToggleSize.m,
  });

  final bool pressed;
  final ValueChanged<bool>? onChanged;

  /// Names the action (« Suivre »).
  final String label;

  /// Names the resulting state (« Suivi »); defaults to [label].
  final String? onLabel;
  final IconData? icon;

  /// Shown when on; a check by default.
  final IconData? onIcon;
  final MuToggleSize size;

  static const double _pressScale = 0.98;

  double get _height => switch (size) {
    MuToggleSize.s => MuSize.controlS,
    MuToggleSize.m => MuSize.controlM,
    MuToggleSize.l => MuSize.controlL,
  };

  double get _padding => switch (size) {
    MuToggleSize.s => MuSpace.s3,
    MuToggleSize.m => MuSpace.s4,
    MuToggleSize.l => MuSpace.s5,
  };

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final enabled = onChanged != null;
    final radius = size == MuToggleSize.s ? MuRadius.smAll : MuRadius.mdAll;
    final (Color fill, Color fg, Color border) = !enabled
        ? (c.surface, c.textDisabled, c.border)
        : pressed
        ? (c.accent, c.onAccent, c.accent)
        : (c.surface, c.text, c.borderStrong);
    final text = pressed ? (onLabel ?? label) : label;
    final glyph = pressed ? (onIcon ?? (icon != null ? PhosphorIcons.check(PhosphorIconsStyle.bold) : null)) : icon;
    final iconSize = size == MuToggleSize.s ? MuSize.iconXs : MuSize.iconS;
    final style = size == MuToggleSize.l ? MuType.labelL : MuType.label;
    final duration = MuMotion.durationOf(context, MuMotion.fast);

    final content = AnimatedSwitcher(
      duration: duration,
      child: Row(
        key: ValueKey(pressed),
        mainAxisSize: MainAxisSize.min,
        children: [
          if (glyph != null) ...[Icon(glyph, size: iconSize, color: fg), const SizedBox(width: MuSpace.s2)],
          Text(text, style: style.copyWith(color: fg)),
        ],
      ),
    );

    final button = AnimatedContainer(
      duration: duration,
      curve: MuMotion.enter,
      height: _height,
      padding: EdgeInsets.symmetric(horizontal: _padding),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: radius,
        border: Border.all(color: border),
      ),
      alignment: Alignment.center,
      child: content,
    );

    return Semantics(
      button: true,
      toggled: pressed,
      enabled: enabled,
      label: text,
      excludeSemantics: true,
      child: MuFocusRing(
        borderRadius: radius,
        child: MuPressScale(
          enabled: enabled,
          scale: _pressScale,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: radius,
              onTap: enabled ? () => onChanged!(!pressed) : null,
              // Invisible hit area up to the 44 px touch target.
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: _height < MuSize.touchTarget ? (MuSize.touchTarget - _height) / 2 : 0),
                child: button,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
