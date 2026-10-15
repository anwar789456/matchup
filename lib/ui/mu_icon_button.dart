import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'src/interaction.dart';

enum MuIconButtonSize { s, m, l }

enum MuIconButtonVariant { ghost, secondary, primary, inverse, onMedia }

/// IconButton (components/IconButton.md): an icon-only action with a required [label], used as
/// tooltip and screen-reader name. [badge] shows a count (« 99+ » cap); [dot] a 10 px dot.
/// Pass [pressed] to make it a toggle (accent fill + [selectedIcon]).
class MuIconButton extends StatelessWidget {
  const MuIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.size = MuIconButtonSize.m,
    this.variant = MuIconButtonVariant.ghost,
    this.badge,
    this.dot = false,
    this.pressed,
    this.selectedIcon,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final MuIconButtonSize size;
  final MuIconButtonVariant variant;
  final int? badge;
  final bool dot;
  final bool? pressed;
  final IconData? selectedIcon;

  /// Overrides the icon colour (e.g. `text-secondary` for a field's clear button).
  final Color? color;

  // IconButton.md: icon 18 / 20 / 24 for S / M / L; pressed scale 0.94.
  static const double _iconSmall = 18;
  static const double _pressScale = 0.94;

  double get _visual => switch (size) {
        MuIconButtonSize.s => MuSize.controlS,
        MuIconButtonSize.m => MuSize.controlM,
        MuIconButtonSize.l => MuSize.controlL,
      };

  double get _iconSize => switch (size) {
        MuIconButtonSize.s => _iconSmall,
        MuIconButtonSize.m => MuSize.iconS,
        MuIconButtonSize.l => MuSize.iconM,
      };

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final on = pressed ?? false;
    final enabled = onPressed != null;

    final (Color fill, Color fg, BorderSide side) = on
        ? (c.accent, c.onAccent, BorderSide.none)
        : switch (variant) {
            MuIconButtonVariant.ghost => (Colors.transparent, c.text, BorderSide.none),
            MuIconButtonVariant.secondary =>
              (c.surface, c.text, BorderSide(color: c.borderStrong)),
            MuIconButtonVariant.primary => (c.primary, c.onPrimary, BorderSide.none),
            MuIconButtonVariant.inverse =>
              (c.surfaceInverse, c.textInverse, BorderSide.none),
            MuIconButtonVariant.onMedia => (c.surface, c.text, BorderSide.none),
          };
    final iconColor = enabled ? (color ?? fg) : c.textDisabled;

    Widget glyph = Icon(on ? (selectedIcon ?? icon) : icon, size: _iconSize, color: iconColor);
    if (badge != null && badge! > 0 || dot) {
      glyph = _Badged(count: dot ? null : badge, child: glyph);
    }

    final button = IconButton(
      onPressed: onPressed,
      tooltip: label,
      isSelected: pressed,
      icon: glyph,
      style: IconButton.styleFrom(
        fixedSize: Size.square(_visual),
        minimumSize: Size.square(_visual),
        padding: EdgeInsets.zero,
        shape: CircleBorder(side: side),
        backgroundColor: fill,
        disabledBackgroundColor:
            variant == MuIconButtonVariant.ghost ? Colors.transparent : c.disabledFill,
        foregroundColor: iconColor,
        hoverColor: fg.withValues(alpha: MuOpacity.hover),
        highlightColor: fg.withValues(alpha: MuOpacity.pressed),
        // Hit area: 44 for S and M without changing the visual size.
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
    );

    Widget result = MuFocusRing(
      shape: BoxShape.circle,
      borderRadius: MuRadius.fullAll,
      child: MuPressScale(enabled: enabled, scale: _pressScale, child: button),
    );
    if (variant == MuIconButtonVariant.onMedia) {
      result = DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: MuElevation.of(context).level2,
        ),
        child: result,
      );
    }
    return Semantics(
      button: true,
      toggled: pressed,
      label: badge != null && badge! > 0 ? '$label, $badge' : label,
      excludeSemantics: true,
      child: result,
    );
  }
}

class _Badged extends StatelessWidget {
  const _Badged({required this.count, required this.child});

  final int? count;
  final Widget child;

  // IconButton.md: badge 18 high, min-width 18, padding-inline 5, 2px surface ring,
  // top −2 / inline-end −4; the dot is 10 px inset 6 from the top-end.
  static const double _height = 18;
  static const double _padding = 5;
  static const double _ring = 2;
  static const double _dot = 10;
  static const int _cap = 99;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final Widget mark;
    if (count == null) {
      mark = Container(
        width: _dot,
        height: _dot,
        decoration: BoxDecoration(
          color: c.destructive,
          shape: BoxShape.circle,
          border: Border.all(color: c.surface, width: _ring),
        ),
      );
    } else {
      mark = Container(
        constraints: const BoxConstraints(minWidth: _height + _ring * 2),
        height: _height + _ring * 2,
        padding: const EdgeInsets.symmetric(horizontal: _padding),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.destructive,
          borderRadius: MuRadius.fullAll,
          border: Border.all(color: c.surface, width: _ring),
        ),
        child: Text(
          count! > _cap ? '$_cap+' : '$count',
          style: MuType.labelS.copyWith(color: c.onDestructive),
        ),
      );
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        PositionedDirectional(
          top: count == null ? -MuSpace.s1 : -MuSpace.s2,
          end: count == null ? -MuSpace.s1 : -MuSpace.s3,
          child: mark,
        ),
      ],
    );
  }
}
