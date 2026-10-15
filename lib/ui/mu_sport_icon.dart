import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/theme.dart';

/// One of the custom sport SVGs, repainted in [color] (default: the sport's `-text` colour).
class MuSportIcon extends StatelessWidget {
  const MuSportIcon(this.sport, {super.key, this.size = MuSize.iconM, this.color});

  final MuSport sport;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      sport.asset,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color ?? sport.text(context.mu), BlendMode.srcIn),
      excludeFromSemantics: true,
    );
  }
}

/// The custom MatchUp glyphs drawn to sit next to Phosphor Regular (Iconography).
abstract final class MuGlyph {
  static const whistle = 'assets/icons/sport/whistle.svg';
  static const trophy = 'assets/icons/sport/trophy.svg';
  static const court = 'assets/icons/sport/court.svg';
}

enum MuMediaTileSize { row, tile }

/// The media square of a ChoiceCard: `<sport>-soft` + sport icon, or `surface-muted` + a
/// Phosphor icon (components/ChoiceCard.md: 40 / radius-sm / icon 24 in rows, 48 / radius-md /
/// icon 28 in tiles).
class MuSportTile extends StatelessWidget {
  const MuSportTile(this.sport, {super.key, this.size = MuMediaTileSize.row})
      : icon = null,
        asset = null;

  const MuSportTile.icon(IconData this.icon, {super.key, this.size = MuMediaTileSize.row})
      : sport = null,
        asset = null;

  /// One of the custom MatchUp glyphs (`whistle`, `trophy`, `court`), e.g. [MuGlyph.whistle].
  const MuSportTile.asset(String this.asset, {super.key, this.size = MuMediaTileSize.row})
      : sport = null,
        icon = null;

  final MuSport? sport;
  final IconData? icon;
  final String? asset;
  final MuMediaTileSize size;

  // ChoiceCard.md: tile icon 28.
  static const double _tileIcon = 28;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final row = size == MuMediaTileSize.row;
    final box = row ? MuSize.controlM : MuSize.controlL;
    final iconSize = row ? MuSize.iconM : _tileIcon;
    return Container(
      width: box,
      height: box,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: sport != null ? sport!.soft(c) : c.surfaceMuted,
        borderRadius: row ? MuRadius.smAll : MuRadius.mdAll,
      ),
      child: sport != null
          ? MuSportIcon(sport!, size: iconSize)
          : asset != null
              ? SvgPicture.asset(
                  asset!,
                  width: iconSize,
                  height: iconSize,
                  colorFilter: ColorFilter.mode(c.text, BlendMode.srcIn),
                  excludeFromSemantics: true,
                )
              : Icon(icon, size: iconSize, color: c.text),
    );
  }
}
