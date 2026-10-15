import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/theme.dart';
import 'mu_spinner.dart';
import 'src/interaction.dart';

enum MuButtonVariant { primary, secondary, tertiary, destructive, destructiveOutline, link }

enum MuButtonSize { s, m, l, xl }

/// Button (components/Button.md): a verb that says what happens next.
///
/// [price] and [countdown] render inside the label in tabular digits (« Rejoindre et payer · 15 DT »).
/// [loading] swaps the label for a spinner at the same width; [success] shows the success fill and
/// a check — the caller turns it off after `MuMotion.success`.
class MuButton extends StatelessWidget {
  const MuButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = MuButtonVariant.primary,
    this.size = MuButtonSize.m,
    this.leading,
    this.trailing,
    this.price,
    this.countdown,
    this.loading = false,
    this.success = false,
    this.fullWidth = false,
  })  : inline = false,
        linkStyle = null;

  const MuButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = MuButtonSize.m,
    this.leading,
    this.trailing,
    this.price,
    this.countdown,
    this.loading = false,
    this.success = false,
    this.fullWidth = false,
  })  : variant = MuButtonVariant.primary,
        inline = false,
        linkStyle = null;

  const MuButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = MuButtonSize.m,
    this.leading,
    this.trailing,
    this.price,
    this.countdown,
    this.loading = false,
    this.success = false,
    this.fullWidth = false,
  })  : variant = MuButtonVariant.secondary,
        inline = false,
        linkStyle = null;

  const MuButton.tertiary({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = MuButtonSize.m,
    this.leading,
    this.trailing,
    this.price,
    this.countdown,
    this.loading = false,
    this.success = false,
    this.fullWidth = false,
  })  : variant = MuButtonVariant.tertiary,
        inline = false,
        linkStyle = null;

  /// A text link. [inline] links sit inside a sentence: no 44 px row, [linkStyle] matches the
  /// surrounding text (`label`, `label-l`…).
  const MuButton.link({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = MuButtonSize.m,
    this.inline = false,
    this.linkStyle,
    this.trailing,
  })  : variant = MuButtonVariant.link,
        leading = null,
        price = null,
        countdown = null,
        loading = false,
        success = false,
        fullWidth = false;

  final String label;
  final VoidCallback? onPressed;
  final MuButtonVariant variant;
  final MuButtonSize size;
  final IconData? leading;
  final IconData? trailing;

  /// Link only: sits inside running text.
  final bool inline;

  /// Link only: overrides the label style.
  final TextStyle? linkStyle;

  /// Price per person, e.g. '15 DT'.
  final String? price;

  /// Countdown digits, e.g. '14:59'.
  final String? countdown;
  final bool loading;
  final bool success;
  final bool fullWidth;

  double get _height => switch (size) {
        MuButtonSize.s => MuSize.controlS,
        MuButtonSize.m => MuSize.controlM,
        MuButtonSize.l => MuSize.controlL,
        MuButtonSize.xl => MuSize.controlXl,
      };

  double get _padding => switch (size) {
        MuButtonSize.s => MuSpace.s3,
        MuButtonSize.m => MuSpace.s4,
        MuButtonSize.l => MuSpace.s5,
        MuButtonSize.xl => MuSpace.s6,
      };

  double get _iconSize => switch (size) {
        MuButtonSize.s => MuSize.iconXs,
        MuButtonSize.m || MuButtonSize.l => MuSize.iconS,
        MuButtonSize.xl => MuSize.iconM,
      };

  BorderRadius get _radius =>
      size == MuButtonSize.s ? MuRadius.smAll : MuRadius.mdAll;

  bool get _large => size == MuButtonSize.l || size == MuButtonSize.xl;

  TextStyle get _labelStyle => _large ? MuType.labelL : MuType.label;

  TextStyle get _numStyle => _large ? MuType.numM : MuType.numS;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final enabled = onPressed != null && !loading;

    if (variant == MuButtonVariant.link) {
      return _LinkButton(
        label: label,
        onPressed: onPressed,
        style: linkStyle ?? _labelStyle,
        inline: inline,
        trailing: trailing,
      );
    }

    final style = _style(c);
    final content = _content(c, enabled);
    // Clicks are ignored while loading or showing success, but the button keeps its look.
    final VoidCallback? handler =
        onPressed == null ? null : (loading || success ? () {} : onPressed);

    final Widget button = switch (variant) {
      MuButtonVariant.primary || MuButtonVariant.destructive =>
        FilledButton(onPressed: handler, style: style, child: content),
      MuButtonVariant.secondary || MuButtonVariant.destructiveOutline =>
        OutlinedButton(onPressed: handler, style: style, child: content),
      _ => TextButton(onPressed: handler, style: style, child: content),
    };

    Widget result = MuFocusRing(
      borderRadius: _radius,
      child: MuPressScale(enabled: enabled, child: button),
    );
    if (fullWidth) result = SizedBox(width: double.infinity, child: result);
    return Semantics(
      button: true,
      enabled: enabled,
      label: loading ? 'Chargement' : (success ? 'Fait' : null),
      child: result,
    );
  }

  ButtonStyle _style(MuColors c) {
    final base = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(_height, _height)),
      fixedSize: WidgetStatePropertyAll(Size.fromHeight(_height)),
      padding: WidgetStatePropertyAll(EdgeInsetsDirectional.symmetric(horizontal: _padding)),
      iconSize: WidgetStatePropertyAll(_iconSize),
      textStyle: WidgetStatePropertyAll(_labelStyle),
      shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: _radius)),
      // S (32) grows its hit area to the touch target; M and up are already large enough.
      tapTargetSize: size == MuButtonSize.s
          ? MaterialTapTargetSize.padded
          : MaterialTapTargetSize.shrinkWrap,
    );
    if (success) {
      return base.copyWith(
        backgroundColor: WidgetStatePropertyAll(c.success),
        foregroundColor: WidgetStatePropertyAll(c.onDestructive),
        side: WidgetStatePropertyAll(BorderSide(color: c.success)),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      );
    }
    switch (variant) {
      case MuButtonVariant.destructive:
        return base.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.disabled) ? c.disabledFill : c.destructive),
          foregroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.disabled) ? c.textDisabled : c.onDestructive),
          overlayColor: _wash(c.onDestructive),
        );
      case MuButtonVariant.destructiveOutline:
        return base.copyWith(
          backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
          foregroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.disabled) ? c.textDisabled : c.errorText),
          overlayColor: _wash(c.errorText),
          side: WidgetStateProperty.resolveWith((s) => BorderSide(
              color: s.contains(WidgetState.disabled) ? c.border : c.error)),
        );
      default:
        return base;
    }
  }

  WidgetStateProperty<Color?> _wash(Color color) =>
      WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.pressed)) {
          return color.withValues(alpha: MuOpacity.pressed);
        }
        if (s.contains(WidgetState.hovered)) {
          return color.withValues(alpha: MuOpacity.hover);
        }
        return Colors.transparent;
      });

  Widget _content(MuColors c, bool enabled) {
    final children = <Widget>[
      if (leading != null) ...[
        Icon(leading, size: _iconSize),
        const SizedBox(width: MuSpace.s2),
      ],
      Flexible(child: Text(label, overflow: TextOverflow.ellipsis, maxLines: 1)),
      if (price != null) ...[
        const _Dot(),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text(price!, style: _numStyle),
        ),
      ],
      if (countdown != null) ...[
        const SizedBox(width: MuSpace.s2),
        Icon(PhosphorIcons.timer(), size: _iconSize),
        const SizedBox(width: MuSpace.s1),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text(countdown!, style: _numStyle),
        ),
      ],
      if (trailing != null) ...[
        const SizedBox(width: MuSpace.s2),
        MuDirectionalIcon(trailing!, size: _iconSize),
      ],
    ];
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: children,
    );
    if (success) {
      return Stack(alignment: Alignment.center, children: [
        Visibility.maintain(visible: false, child: row),
        Icon(PhosphorIcons.check(PhosphorIconsStyle.bold), size: _iconSize),
      ]);
    }
    if (loading) {
      return Stack(alignment: Alignment.center, children: [
        Visibility.maintain(visible: false, child: row),
        MuSpinner(size: _iconSize),
      ]);
    }
    return row;
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsetsDirectional.symmetric(horizontal: MuSpace.s2),
      child: Text('·'),
    );
  }
}

class _LinkButton extends StatelessWidget {
  const _LinkButton({
    required this.label,
    required this.onPressed,
    required this.style,
    required this.inline,
    this.trailing,
  });

  final String label;
  final VoidCallback? onPressed;
  final TextStyle style;
  final bool inline;
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final color = onPressed == null ? c.textDisabled : c.link;
    return MuFocusRing(
      borderRadius: MuRadius.xsAll,
      child: Semantics(
        link: true,
        child: InkWell(
          onTap: onPressed,
          borderRadius: MuRadius.xsAll,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: inline ? 0 : MuSize.touchTarget),
            child: Align(
              widthFactor: 1,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: style.copyWith(
                      color: color,
                      decoration: TextDecoration.underline,
                      decorationColor: color,
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: MuSpace.s1),
                    Icon(trailing, size: MuSize.iconXs, color: color),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
