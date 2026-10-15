import 'package:flutter/material.dart';

import '../core/format.dart';
import '../theme/theme.dart';
import 'mu_sport_icon.dart';
import 'src/card_surface.dart';
import 'src/price_tag.dart';

/// The data an open game card shows.
@immutable
class MuGame {
  const MuGame({
    required this.sport,
    required this.venue,
    required this.place,
    required this.start,
    required this.spotsTotal,
    required this.spotsLeft,
    required this.pricePerPlayer,
    this.court,
    this.gameType = 'Mixte',
    this.levelMin,
    this.levelMax,
  });

  final MuSport sport;
  final String venue;
  final String? court;
  final String place;
  final String gameType;
  final DateTime start;
  final int spotsTotal;
  final int spotsLeft;

  /// Always the share each player pays (court price ÷ players).
  final num pricePerPlayer;
  final double? levelMin;
  final double? levelMax;

  String get title => court == null ? venue : '$venue · $court';
}

enum MuGameCardVariant { compact }

/// GameCard (components/GameCard.md). Time, place, price per player and spots left are visible in
/// every variant.
///
/// Only the `compact` variant is built so far (dense lists, the welcome slide); `standard` and
/// `featured` come with the Player core milestone.
class MuGameCard extends StatelessWidget {
  const MuGameCard({
    super.key,
    required this.game,
    this.variant = MuGameCardVariant.compact,
    this.onTap,
    this.surfaceColor,
  });

  final MuGame game;
  final MuGameCardVariant variant;
  final VoidCallback? onTap;

  /// Overrides `surface` (welcome illustrations sit on `surface-elevated`).
  final Color? surfaceColor;

  // GameCard.md compact: min-height 88, 64 px date tile.
  static const double _minHeight = 88;
  static const double _tile = 64;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final g = game;
    final sportText = g.sport.text(c);
    final left = g.spotsLeft;
    final spotsLabel = left == 0
        ? 'Complet'
        : '$left ${left == 1 ? 'place libre' : 'places libres'}';

    return MuCardSurface(
      onTap: onTap,
      color: surfaceColor,
      padding: const EdgeInsets.all(MuSpace.s3),
      semanticLabel:
          '${g.title}, ${g.sport.label}, ${formatDateTime(g.start)}, $spotsLabel, ${formatDT(g.pricePerPlayer)} par joueur',
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _minHeight - MuSpace.s3 * 2),
          child: Row(
            children: [
              Container(
                width: _tile,
                height: _tile,
                decoration: BoxDecoration(color: g.sport.soft(c), borderRadius: MuRadius.smAll),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${formatWeekday(g.start)} ${g.start.day}'.replaceAll('.', '').toUpperCase(),
                      style: MuType.overline.copyWith(color: sportText),
                    ),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(formatTime(g.start), style: MuType.numM.copyWith(color: c.text)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: MuSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(g.title,
                        style: MuType.label.copyWith(color: c.text),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: MuSpace.s1),
                    Row(
                      children: [
                        MuSportIcon(g.sport, size: MuSize.iconXs),
                        const SizedBox(width: MuSpace.s1),
                        Expanded(
                          child: Text(
                            '${g.sport.label} · ${g.gameType} · ${g.place}',
                            style: MuType.caption.copyWith(color: c.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: MuSpace.s2),
                    Row(
                      children: [
                        if (g.spotsTotal <= _DotsMeter.maxDots) ...[
                          _DotsMeter(
                            total: g.spotsTotal,
                            taken: g.spotsTotal - left,
                            color: g.sport.color(c),
                          ),
                          const SizedBox(width: MuSpace.s2),
                        ],
                        Flexible(
                          child: Text(spotsLabel,
                              style: MuType.labelS.copyWith(color: c.text),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: MuSpace.s3),
              MuPriceTag(amount: g.pricePerPlayer, unit: '/joueur'),
            ],
          ),
        ),
      ),
    );
  }
}

/// One dot per player: taken in the sport colour, free hollow with a `border-strong` ring.
class _DotsMeter extends StatelessWidget {
  const _DotsMeter({required this.total, required this.taken, required this.color});

  final int total;
  final int taken;
  final Color color;

  // GameCard.md: ≤ 12 dots, 7 px, 3 px gap, 1.5 px ring.
  static const int maxDots = 12;
  static const double _dot = 7;
  static const double _gap = 3;
  static const double _ring = 1.5;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: _gap),
          Container(
            width: _dot,
            height: _dot,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < taken ? color : null,
              border: i < taken ? null : Border.all(color: c.borderStrong, width: _ring),
            ),
          ),
        ],
      ],
    );
  }
}
