import 'package:flutter/material.dart';

import '../core/format.dart';
import '../theme/theme.dart';
import 'mu_court_art.dart';
import 'mu_sport_icon.dart';
import 'src/card_surface.dart';
import 'src/price_tag.dart';

/// The data a tournament card shows.
@immutable
class MuTournament {
  const MuTournament({
    required this.sport,
    required this.name,
    required this.start,
    required this.end,
    required this.venue,
    required this.place,
    required this.feePerTeam,
    required this.teamsTotal,
    required this.teamsRegistered,
    this.prize,
    this.levelMin,
    this.levelMax,
  });

  final MuSport sport;
  final String name;
  final DateTime start;
  final DateTime end;
  final String venue;
  final String place;
  final num feePerTeam;
  final num? prize;
  final int teamsTotal;
  final int teamsRegistered;
  final double? levelMin;
  final double? levelMax;

  int get teamsLeft => teamsTotal - teamsRegistered;

  /// ≤ 25 % of the teams left.
  bool get almostFull => teamsLeft > 0 && teamsLeft * 4 <= teamsTotal;
}

enum MuTournamentCardVariant { compact }

/// TournamentCard (components/TournamentCard.md).
///
/// Only `compact` is built so far (search results, the welcome slide); `standard` and `vertical`
/// come with the Tournaments milestone.
class MuTournamentCard extends StatelessWidget {
  const MuTournamentCard({
    super.key,
    required this.tournament,
    this.variant = MuTournamentCardVariant.compact,
    this.onTap,
    this.surfaceColor,
  });

  final MuTournament tournament;
  final MuTournamentCardVariant variant;
  final VoidCallback? onTap;
  final Color? surfaceColor;

  // TournamentCard.md compact: min-height 88, poster thumb 54 × 72, mini fill bar 64 × 6.
  static const double _minHeight = 88;
  static const double _posterW = 54;
  static const double _posterH = 72;
  static const double _bar = 64;
  static const double _barH = 6;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final t = tournament;
    final left = t.teamsLeft;
    final placesLabel = left == 0 ? 'Complet' : '$left ${left == 1 ? 'place' : 'places'}';
    final placesColor = t.almostFull ? c.warningText : c.text;
    final dates = formatDateRange(t.start, t.end);

    return MuCardSurface(
      onTap: onTap,
      color: surfaceColor,
      padding: const EdgeInsets.all(MuSpace.s3),
      semanticLabel:
          '${t.name}, $dates, ${t.venue}, $placesLabel, ${formatDT(t.feePerTeam)} par équipe',
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _minHeight - MuSpace.s3 * 2),
          child: Row(
            children: [
              Container(
                width: _posterW,
                height: _posterH,
                foregroundDecoration: BoxDecoration(
                  borderRadius: MuRadius.smAll,
                  border: Border.all(color: c.border),
                ),
                child: ClipRRect(
                  borderRadius: MuRadius.smAll,
                  child: MuCourtArt(sport: t.sport),
                ),
              ),
              const SizedBox(width: MuSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(t.name,
                        style: MuType.label.copyWith(color: c.text),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: MuSpace.s1),
                    Row(
                      children: [
                        MuSportIcon(t.sport, size: MuSize.iconXs),
                        const SizedBox(width: MuSpace.s1),
                        Expanded(
                          child: Text(
                            '$dates · ${t.venue}',
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
                        ClipRRect(
                          borderRadius: MuRadius.xsAll,
                          child: Container(
                            width: _bar,
                            height: _barH,
                            color: c.surfaceMuted,
                            alignment: AlignmentDirectional.centerStart,
                            child: FractionallySizedBox(
                              widthFactor: t.teamsTotal == 0 ? 0 : t.teamsRegistered / t.teamsTotal,
                              heightFactor: 1,
                              child: ColoredBox(color: t.sport.color(c)),
                            ),
                          ),
                        ),
                        const SizedBox(width: MuSpace.s2),
                        Text(placesLabel, style: MuType.labelS.copyWith(color: placesColor)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: MuSpace.s3),
              MuPriceTag(amount: t.feePerTeam, unit: '/équipe'),
            ],
          ),
        ),
      ),
    );
  }
}
