import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/format.dart';
import '../theme/theme.dart';
import 'mu_sport_icon.dart';
import 'src/interaction.dart';

enum MuChipKind { filter, choice, sport, level, input }

enum MuChipSize { m, s }

/// Chip (components/Chip.md): filter, choice, sport, level and removable input chips.
/// Selected = Volt fill with `on-accent` text and a leading check.
class MuChip extends StatelessWidget {
  const MuChip({
    super.key,
    this.label,
    this.kind = MuChipKind.filter,
    this.selected = false,
    this.onSelected,
    this.sport,
    this.level,
    this.icon,
    this.trailingIcon,
    this.count,
    this.onRemove,
    this.removeLabel,
    this.size = MuChipSize.m,
  });

  /// Sport tag (or sport filter when [onSelected] is set). Label defaults to the sport name.
  const MuChip.sport(
    MuSport this.sport, {
    super.key,
    this.selected = false,
    this.onSelected,
    this.size = MuChipSize.m,
  })  : kind = MuChipKind.sport,
        label = null,
        level = null,
        icon = null,
        trailingIcon = null,
        count = null,
        onRemove = null,
        removeLabel = null;

  /// « 3,5 · Intermédiaire ».
  const MuChip.level(
    double this.level, {
    super.key,
    this.size = MuChipSize.m,
  })  : kind = MuChipKind.level,
        label = null,
        selected = false,
        onSelected = null,
        sport = null,
        icon = null,
        trailingIcon = null,
        count = null,
        onRemove = null,
        removeLabel = null;

  final String? label;
  final MuChipKind kind;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final MuSport? sport;
  final double? level;
  final IconData? icon;
  final IconData? trailingIcon;
  final int? count;
  final VoidCallback? onRemove;
  final String? removeLabel;
  final MuChipSize size;

  // Chip.md: S chip is 24 high; icons 18 (M) / 16 (S); count 18 high; pressed scale 0.96;
  // remove button 24 with a 14 px x.
  static const double _heightS = 24;
  static const double _iconM = 18;
  static const double _countSize = 18;
  static const double _pressScale = 0.96;
  static const double _removeSize = 24;
  static const double _removeIcon = 14;

  bool get _interactive =>
      onSelected != null && (kind == MuChipKind.filter || kind == MuChipKind.choice ||
          kind == MuChipKind.sport);

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final small = size == MuChipSize.s;
    final height = small ? _heightS : MuSize.controlS;
    final iconSize = small ? MuSize.iconXs : _iconM;
    final textStyle = small ? MuType.labelS : MuType.label;
    final disabled = (kind == MuChipKind.filter || kind == MuChipKind.choice) && onSelected == null;

    // Colours per kind.
    Color fill;
    Color fg;
    BorderSide side;
    if (selected) {
      (fill, fg, side) = (c.accent, c.onAccent, BorderSide(color: c.accent));
    } else {
      switch (kind) {
        case MuChipKind.sport:
          (fill, fg, side) = (sport!.soft(c), sport!.text(c), BorderSide.none);
        case MuChipKind.level || MuChipKind.input:
          (fill, fg, side) = (c.surfaceMuted, c.text, BorderSide(color: c.border));
        case MuChipKind.filter || MuChipKind.choice:
          (fill, fg, side) = disabled
              ? (c.surface, c.textDisabled, BorderSide(color: c.border))
              : (c.surface, c.text, BorderSide(color: c.borderStrong));
      }
    }

    final children = <Widget>[];
    if (kind == MuChipKind.sport) {
      children.add(MuSportIcon(sport!, size: iconSize, color: fg));
      children.add(const SizedBox(width: MuSpace.s1));
      children.add(Text(label ?? sport!.label, style: textStyle.copyWith(color: fg)));
    } else if (kind == MuChipKind.level) {
      children.addAll([
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text(formatLevel(level!), style: MuType.numS.copyWith(color: fg)),
        ),
        Container(
          width: 1,
          height: iconSize,
          margin: const EdgeInsets.symmetric(horizontal: MuSpace.s2),
          color: c.borderStrong,
        ),
        Text(levelBand(level!), style: textStyle.copyWith(color: fg)),
      ]);
    } else {
      if (selected && icon == null) {
        children.add(Icon(PhosphorIcons.check(PhosphorIconsStyle.bold), size: iconSize, color: fg));
        children.add(const SizedBox(width: MuSpace.s1));
      } else if (icon != null) {
        children.add(Icon(icon, size: iconSize, color: fg));
        children.add(const SizedBox(width: MuSpace.s1));
      }
      children.add(Text(label ?? '', style: textStyle.copyWith(color: fg)));
      if (count != null) {
        children.add(const SizedBox(width: MuSpace.s1));
        children.add(_Count(count: count!, selected: selected));
      }
      if (trailingIcon != null) {
        children.add(const SizedBox(width: MuSpace.s1));
        children.add(Icon(trailingIcon, size: MuSize.iconXs, color: fg));
      }
      if (kind == MuChipKind.input && onRemove != null) {
        children.add(const SizedBox(width: MuSpace.s1));
        children.add(_RemoveButton(
          label: removeLabel ?? 'Retirer ${label ?? ''}',
          onPressed: onRemove!,
        ));
      }
    }

    final hasRemove = kind == MuChipKind.input && onRemove != null;
    final chip = AnimatedContainer(
      duration: MuMotion.durationOf(context, MuMotion.fast),
      curve: MuMotion.enter,
      height: height,
      padding: EdgeInsetsDirectional.only(
        start: small ? MuSpace.s2 : MuSpace.s3,
        end: hasRemove ? MuSpace.s1 : (small ? MuSpace.s2 : MuSpace.s3),
      ),
      decoration: ShapeDecoration(color: fill, shape: StadiumBorder(side: side)),
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );

    if (!_interactive) {
      return Semantics(
        label: kind == MuChipKind.level
            ? 'Niveau ${formatLevel(level!)}, ${levelBand(level!)}'
            : null,
        excludeSemantics: kind == MuChipKind.level,
        child: chip,
      );
    }

    return Semantics(
      button: true,
      toggled: kind == MuChipKind.choice ? null : selected,
      checked: kind == MuChipKind.choice ? selected : null,
      inMutuallyExclusiveGroup: kind == MuChipKind.choice,
      child: MuFocusRing(
        borderRadius: MuRadius.fullAll,
        child: MuPressScale(
          scale: _pressScale,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () => onSelected!(!selected),
              // Invisible hit area up to the 44 px touch target.
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: (MuSize.touchTarget - height) / 2),
                child: chip,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.count, required this.selected});

  final int count;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Container(
      constraints: const BoxConstraints(minWidth: MuChip._countSize),
      height: MuChip._countSize,
      padding: const EdgeInsets.symmetric(horizontal: MuSpace.s1),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? c.onAccent : c.surfaceInverse,
        borderRadius: MuRadius.fullAll,
      ),
      child: Text(
        '$count',
        style: MuType.labelS.copyWith(color: selected ? c.accent : c.textInverse),
      ),
    );
  }
}

class _RemoveButton extends StatelessWidget {
  const _RemoveButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: InkResponse(
          onTap: onPressed,
          radius: MuSize.touchTarget / 2,
          hoverColor: c.border,
          child: SizedBox.square(
            dimension: MuChip._removeSize,
            child: Icon(PhosphorIcons.x(), size: MuChip._removeIcon, color: c.textSecondary),
          ),
        ),
      ),
    );
  }
}
