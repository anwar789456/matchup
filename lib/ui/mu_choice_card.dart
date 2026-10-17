import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/theme.dart';
import 'mu_text_field.dart';
import 'src/interaction.dart';

enum MuChoiceLayout { row, tile }

/// ChoiceCard (components/ChoiceCard.md): a large answer card for onboarding questions.
/// Selected = inset 2px `primary` ring + Volt badge with an `on-accent` check.
///
/// [background] fills the card behind the content (the CourtArt of the sports picker); text then
/// switches to white over it.
class MuChoiceCard extends StatefulWidget {
  const MuChoiceCard({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.description,
    this.leading,
    this.multi = false,
    this.layout = MuChoiceLayout.row,
    this.error = false,
    this.background,
    this.extra,
  });

  final String title;
  final String? description;
  final Widget? leading;
  final bool selected;
  final VoidCallback? onTap;
  final bool multi;
  final MuChoiceLayout layout;
  final bool error;
  final Widget? background;

  /// Under the description: a tag such as « Recommandé » (BKG-04).
  final Widget? extra;

  @override
  State<MuChoiceCard> createState() => _MuChoiceCardState();
}

class _MuChoiceCardState extends State<MuChoiceCard> {
  bool _hovered = false;

  // ChoiceCard.md: min-height 64; badge 24 with a 1.5 px edge; selected ring 2 px.
  static const double _minHeight = 64;
  static const double _badge = 24;
  static const double _badgeBorder = 1.5;
  static const double _ring = 2;

  bool get _enabled => widget.onTap != null;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final onArt = widget.background != null;
    final tile = widget.layout == MuChoiceLayout.tile;

    final Color ringColor;
    final double ringWidth;
    if (widget.error) {
      (ringColor, ringWidth) = (c.error, _badgeBorder);
    } else if (widget.selected) {
      (ringColor, ringWidth) = (c.primary, _ring);
    } else if (_hovered && _enabled) {
      (ringColor, ringWidth) = (c.borderStrong, 1);
    } else {
      (ringColor, ringWidth) = (c.border, 1);
    }

    // On art the ground is always the dark court, whatever the theme: text turns white.
    final titleColor = !_enabled ? c.textDisabled : (onArt ? MuPalette.white : c.text);
    final descColor = !_enabled ? c.textDisabled : (onArt ? MuPalette.white : c.textSecondary);

    final texts = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.title, style: MuType.labelL.copyWith(color: titleColor)),
        if (widget.description != null)
          Text(widget.description!, style: MuType.body.copyWith(color: descColor)),
        if (widget.extra != null) ...[const SizedBox(height: MuSpace.s2), widget.extra!],
      ],
    );

    final badge = _Badge(
      selected: widget.selected,
      multi: widget.multi,
      error: widget.error,
      onArt: onArt,
    );

    final leading = widget.leading == null
        ? null
        : Opacity(opacity: _enabled ? 1 : MuOpacity.disabled, child: widget.leading);

    final Widget content = tile
        ? Padding(
            padding: const EdgeInsets.all(MuSpace.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null) ...[leading, const SizedBox(height: MuSpace.s3)],
                texts,
              ],
            ),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4, vertical: MuSpace.s3),
            child: Row(
              children: [
                if (leading != null) ...[leading, const SizedBox(width: MuSpace.s3)],
                Expanded(child: texts),
                const SizedBox(width: MuSpace.s3),
                badge,
              ],
            ),
          );

    final card = AnimatedContainer(
      duration: MuMotion.durationOf(context, MuMotion.fast),
      curve: MuMotion.enter,
      constraints: const BoxConstraints(minHeight: _minHeight),
      decoration: BoxDecoration(
        color: _enabled ? c.surface : c.surfaceMuted,
        borderRadius: MuRadius.mdAll,
        boxShadow: _hovered && _enabled
            ? MuElevation.of(context).level2
            : MuElevation.of(context).level1,
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: MuRadius.mdAll,
        border: Border.all(color: ringColor, width: ringWidth),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (onArt) Positioned.fill(child: widget.background!),
          if (tile) ...[
            content,
            PositionedDirectional(top: MuSpace.s3, end: MuSpace.s3, child: badge),
          ] else
            content,
        ],
      ),
    );

    return MergeSemantics(
      child: Semantics(
        checked: widget.multi ? widget.selected : null,
        selected: widget.multi ? null : widget.selected,
        inMutuallyExclusiveGroup: !widget.multi,
        enabled: _enabled,
        child: MuFocusRing(
          borderRadius: MuRadius.mdAll,
          child: MuPressScale(
            enabled: _enabled,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: widget.onTap,
                onHover: (v) => setState(() => _hovered = v),
                borderRadius: MuRadius.mdAll,
                child: card,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.selected,
    required this.multi,
    required this.error,
    required this.onArt,
  });

  final bool selected;
  final bool multi;
  final bool error;
  final bool onArt;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final shape = multi ? BoxShape.rectangle : BoxShape.circle;
    final radius = multi ? MuRadius.xsAll : null;
    final edge = error ? c.error : (onArt ? MuPalette.white : c.borderControl);
    return AnimatedSwitcher(
      duration: MuMotion.durationOf(context, MuMotion.fast),
      switchInCurve: MuMotion.pop,
      transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
      child: selected
          ? Container(
              key: const ValueKey(true),
              width: _MuChoiceCardState._badge,
              height: _MuChoiceCardState._badge,
              decoration: BoxDecoration(color: c.accent, shape: shape, borderRadius: radius),
              child: Icon(PhosphorIcons.check(PhosphorIconsStyle.bold),
                  size: MuSize.iconXs, color: c.onAccent),
            )
          : Container(
              key: const ValueKey(false),
              width: _MuChoiceCardState._badge,
              height: _MuChoiceCardState._badge,
              decoration: BoxDecoration(
                shape: shape,
                borderRadius: radius,
                border: Border.all(color: edge, width: _MuChoiceCardState._badgeBorder),
              ),
            ),
    );
  }
}

/// A group of [MuChoiceCard]s named by the question; rows in a column, tiles in a grid.
class MuChoiceGroup extends StatelessWidget {
  const MuChoiceGroup({
    super.key,
    required this.label,
    required this.children,
    this.layout = MuChoiceLayout.row,
    this.columns = 2,
    this.error,
  });

  /// The question, read as the group's name.
  final String label;
  final List<Widget> children;
  final MuChoiceLayout layout;
  final int columns;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final Widget body;
    if (layout == MuChoiceLayout.tile) {
      body = LayoutBuilder(builder: (context, constraints) {
        final w = (constraints.maxWidth - MuSpace.s3 * (columns - 1)) / columns;
        return Wrap(
          spacing: MuSpace.s3,
          runSpacing: MuSpace.s3,
          children: [for (final child in children) SizedBox(width: w, child: child)],
        );
      });
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, child) in children.indexed) ...[
            if (i > 0) const SizedBox(height: MuSpace.s3),
            child,
          ],
        ],
      );
    }
    return Semantics(
      container: true,
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          body,
          if (error != null) ...[
            const SizedBox(height: MuSpace.s2),
            MuFieldMessage.error(error!),
          ],
        ],
      ),
    );
  }
}
