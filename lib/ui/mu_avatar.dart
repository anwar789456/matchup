import 'package:flutter/material.dart';

import '../core/format.dart';
import '../theme/theme.dart';

enum MuAvatarSize { xs, s, m, l, xl }

/// Avatar (components/Avatar.md): a photo or initials, with an optional Volt level badge
/// (not shown at XS) and an online dot.
class MuAvatar extends StatelessWidget {
  const MuAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.image,
    this.size = MuAvatarSize.m,
    this.level,
    this.online = false,
    this.ring = false,
    this.short = false,
  });

  final String name;
  final String? imageUrl;

  /// A local photo (picked from the gallery); used before [imageUrl].
  final ImageProvider? image;
  final MuAvatarSize size;
  final double? level;
  final bool online;
  final bool ring;
  final bool short;

  // Avatar.md: 2px surface ring; badge offsets end −6 / bottom −4 (XL −4 / 2);
  // online dot 25 % of the diameter, clamped 8–16.
  static const double _ring = 2;
  static const double _dotRatio = 0.25;
  static const double _dotMin = 8;
  static const double _dotMax = 16;

  double get _diameter => switch (size) {
        MuAvatarSize.xs => MuSize.avatarXs,
        MuAvatarSize.s => MuSize.avatarS,
        MuAvatarSize.m => MuSize.avatarM,
        MuAvatarSize.l => MuSize.avatarL,
        MuAvatarSize.xl => MuSize.avatarXl,
      };

  TextStyle get _initialsStyle => switch (size) {
        MuAvatarSize.xs || MuAvatarSize.s => MuType.labelS,
        MuAvatarSize.m => MuType.label,
        MuAvatarSize.l => MuType.h3,
        MuAvatarSize.xl => MuType.h1,
      };

  String get _semantics {
    final parts = [name];
    if (level != null) parts.add('niveau ${formatLevel(level!)}');
    if (online) parts.add('en ligne');
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final d = _diameter;
    final initials = Text(
      initialsOf(name, short: short || size == MuAvatarSize.xs),
      style: _initialsStyle.copyWith(color: c.avatarText),
    );

    Widget circle = CircleAvatar(
      radius: d / 2,
      backgroundColor: c.avatarBg,
      foregroundImage: image ?? (imageUrl != null ? NetworkImage(imageUrl!) : null),
      onForegroundImageError: image != null || imageUrl != null ? (_, _) {} : null,
      child: initials,
    );
    if (ring) {
      circle = Container(
        padding: const EdgeInsets.all(_ring),
        decoration: BoxDecoration(color: c.surface, shape: BoxShape.circle),
        child: circle,
      );
    }

    final showLevel = level != null && size != MuAvatarSize.xs;
    final dot = (d * _dotRatio).clamp(_dotMin, _dotMax);
    final xl = size == MuAvatarSize.xl;

    return Semantics(
      image: true,
      label: _semantics,
      excludeSemantics: true,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          circle,
          if (showLevel)
            // The ring sits outside the badge (a box-shadow in the spec), so it does not count
            // in the offsets: end −6 / bottom −4 (XL −4 / 2).
            PositionedDirectional(
              end: (xl ? -MuSpace.s1 : -(MuSpace.s1 + _ring)) - _ring,
              bottom: (xl ? _ring : -MuSpace.s1) - _ring,
              child: _LevelBadge(level: level!, size: size),
            ),
          if (online)
            PositionedDirectional(
              end: 0,
              top: 0,
              child: Container(
                width: dot,
                height: dot,
                decoration: BoxDecoration(
                  color: c.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.surface, width: _ring),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level, required this.size});

  final double level;
  final MuAvatarSize size;

  // Avatar.md: min 24×18 (S, M), 26×18 (L), 40×24 (XL); padding-inline 4; 2px surface ring.
  static const double _ring = 2;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final (double w, double h) = switch (size) {
      MuAvatarSize.xl => (40.0, 24.0),
      MuAvatarSize.l => (26.0, 18.0),
      _ => (24.0, 18.0),
    };
    final style = size == MuAvatarSize.l || size == MuAvatarSize.xl ? MuType.numS : MuType.numXs;
    return Container(
      constraints: BoxConstraints(minWidth: w + _ring * 2, minHeight: h + _ring * 2),
      padding: const EdgeInsets.symmetric(horizontal: MuSpace.s1),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.accent,
        borderRadius: MuRadius.fullAll,
        border: Border.all(color: c.surface, width: _ring),
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Text(formatLevel(level), style: style.copyWith(color: c.onAccent)),
      ),
    );
  }
}
