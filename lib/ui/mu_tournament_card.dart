import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/format.dart';
import '../theme/theme.dart';
import 'mu_button.dart';
import 'mu_chip.dart';
import 'mu_court_art.dart';
import 'mu_skeleton.dart';
import 'mu_sport_icon.dart';
import 'mu_status_badge.dart';
import 'src/card_surface.dart';
import 'src/price_tag.dart';
import 'src/scoreboard_strip.dart';
import 'src/tone_badge.dart';

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
    this.id,
    this.prize,
    this.levelMin,
    this.levelMax,
  });

  final String? id;
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

enum MuTournamentCardVariant { standard, compact }

/// TournamentCard (components/TournamentCard.md): poster with its dates, registration status, venue
/// and level, then entry fee, prize money and teams left on the scoreboard strip, and
/// « S’inscrire ».
///
/// `standard` (poster on the left) is the mobile list card; `compact` the dense row of search
/// results and venue pages. Almost full (≤ 25 % of the teams left) and full come from the counts.
/// The `vertical` grid variant and the live state come with the Tournaments milestone.
class MuTournamentCard extends StatelessWidget {
  const MuTournamentCard({
    super.key,
    required MuTournament this.tournament,
    this.variant = MuTournamentCardVariant.standard,
    this.onTap,
    this.onRegister,
    this.onWaitlist,
    this.surfaceColor,
  }) : loading = false;

  /// The skeleton of a card in [variant] while tournaments load.
  const MuTournamentCard.loading({super.key, this.variant = MuTournamentCardVariant.standard})
      : tournament = null,
        loading = true,
        onTap = null,
        onRegister = null,
        onWaitlist = null,
        surfaceColor = null;

  final MuTournament? tournament;
  final MuTournamentCardVariant variant;
  final VoidCallback? onTap;
  final VoidCallback? onRegister;
  final VoidCallback? onWaitlist;
  final Color? surfaceColor;
  final bool loading;

  // TournamentCard.md compact: min-height 88, poster thumb 54 × 72, mini fill bar 64 × 6;
  // standard: poster 96 wide at 3:4, fill bar 6 high.
  static const double _minHeight = 88;
  static const double _posterW = 54;
  static const double _posterH = 72;
  static const double _bar = 64;
  static const double _barH = 6;
  static const double _poster = 96;
  static const double _posterRatio = 3 / 4;

  // Skeleton block widths (HOM-02).
  static const double _skelCount = 120;
  static const double _skelButton = 104;

  @override
  Widget build(BuildContext context) {
    if (loading) return _Loading(compact: variant == MuTournamentCardVariant.compact);
    final t = tournament!;
    return variant == MuTournamentCardVariant.compact
        ? _buildCompact(context, t)
        : _buildStandard(context, t);
  }

  Widget _fillBar(BuildContext context, MuTournament t, {double? width}) {
    final c = context.mu;
    return ClipRRect(
      borderRadius: MuRadius.xsAll,
      child: Container(
        width: width,
        height: _barH,
        color: c.surfaceMuted,
        alignment: AlignmentDirectional.centerStart,
        child: FractionallySizedBox(
          widthFactor: t.teamsTotal == 0 ? 0 : t.teamsRegistered / t.teamsTotal,
          heightFactor: 1,
          child: ColoredBox(color: t.sport.color(c)),
        ),
      ),
    );
  }

  Widget _buildStandard(BuildContext context, MuTournament t) {
    final c = context.mu;
    final left = t.teamsLeft;
    final full = left <= 0;
    final dates = formatDateRange(t.start, t.end);
    final level = t.levelMin != null && t.levelMax != null
        ? '${formatLevel(t.levelMin!)}–${formatLevel(t.levelMax!)}'
        : null;
    final Widget badge = full
        ? const MuStatusBadge(status: MuStatus.full)
        : t.almostFull
            ? MuToneBadge(
                label: 'Plus que $left ${left == 1 ? 'place' : 'places'}',
                tone: MuBadgeTone.warning,
                icon: PhosphorIcons.warning(PhosphorIconsStyle.fill),
              )
            : const MuStatusBadge(status: MuStatus.confirmed, label: 'Inscriptions ouvertes');
    final spots = full ? 'complet' : '$left libres sur ${t.teamsTotal} équipes';

    Widget line(IconData icon, String text) => Row(
          children: [
            Icon(icon, size: MuSize.iconXs, color: c.textSecondary),
            const SizedBox(width: MuSpace.s1),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: MuType.body.copyWith(color: c.textSecondary),
              ),
            ),
          ],
        );

    return MuCardSurface(
      onTap: onTap,
      color: surfaceColor,
      padding: EdgeInsets.zero,
      semanticLabel: '${t.name}, $dates, ${t.venue} · ${t.place}, $spots, '
          '${formatDT(t.feePerTeam)} par équipe',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(MuSpace.s4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: _poster,
                  child: AspectRatio(
                    aspectRatio: _posterRatio,
                    child: ClipRRect(
                      borderRadius: MuRadius.smAll,
                      child: MuCourtArt(
                        sport: t.sport,
                        variant: MuCourtArtVariant.poster,
                        semanticLabel: 'Affiche du tournoi ${t.name}',
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.all(MuSpace.s2),
                            // The dates printed on the poster are read with the card.
                            child: ExcludeSemantics(
                              child: Directionality(
                                textDirection: TextDirection.ltr,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      t.start.month == t.end.month
                                          ? '${t.start.day}–${t.end.day}'
                                          : '${t.start.day}',
                                      style: MuType.numL.copyWith(color: MuPalette.white),
                                    ),
                                    Text(
                                      formatMonth(t.end).toUpperCase(),
                                      style: MuType.overline.copyWith(color: MuPalette.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: MuSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      badge,
                      const SizedBox(height: MuSpace.s2),
                      Text(
                        t.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: MuType.labelL.copyWith(color: c.text),
                      ),
                      const SizedBox(height: MuSpace.s1),
                      line(PhosphorIcons.calendarBlank(), dates),
                      line(PhosphorIcons.mapPin(), '${t.venue} · ${t.place}'),
                      const SizedBox(height: MuSpace.s2),
                      Wrap(
                        spacing: MuSpace.s2,
                        runSpacing: MuSpace.s2,
                        children: [
                          MuChip.sport(t.sport, size: MuChipSize.s),
                          if (level != null)
                            MuChip(
                              label: 'Niveau $level',
                              icon: PhosphorIcons.gauge(),
                              kind: MuChipKind.input,
                              size: MuChipSize.s,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          MuScoreboardStrip(
            semanticLabel: 'Inscription ${formatDT(t.feePerTeam)} par équipe'
                '${t.prize == null ? '' : ', dotation ${formatDT(t.prize!)}'}, $spots',
            cells: [
              MuStripCell(
                label: 'Inscription',
                value: MuScoreboardStrip.value(context, formatAmount(t.feePerTeam), 'DT'),
                sub: MuScoreboardStrip.sub(context, 'par équipe'),
              ),
              if (t.prize != null)
                MuStripCell(
                  label: 'Dotation',
                  labelIcon: PhosphorIcons.trophy(),
                  value: MuScoreboardStrip.value(context, formatAmount(t.prize!), 'DT'),
                ),
              MuStripCell(
                label: 'Places',
                value: MuScoreboardStrip.value(
                  context,
                  '${full ? 0 : left}',
                  left == 1 || full ? 'libre' : 'libres',
                ),
                sub: _fillBar(context, t),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(MuSpace.s4),
            child: Row(
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${t.teamsRegistered}/${t.teamsTotal}',
                          style: MuType.numXs.copyWith(color: c.text),
                        ),
                        const TextSpan(text: ' équipes inscrites'),
                      ],
                    ),
                    style: MuType.caption.copyWith(color: c.textSecondary),
                  ),
                ),
                if (full)
                  MuButton.secondary(label: 'Liste d’attente', onPressed: onWaitlist)
                else
                  MuButton.primary(label: 'S’inscrire', onPressed: onRegister),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompact(BuildContext context, MuTournament t) {
    final c = context.mu;
    final left = t.teamsLeft;
    final placesLabel = left <= 0 ? 'Complet' : '$left ${left == 1 ? 'place' : 'places'}';
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
                  child: MuCourtArt(sport: t.sport, variant: MuCourtArtVariant.poster),
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
                        _fillBar(context, t, width: _bar),
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

class _Loading extends StatelessWidget {
  const _Loading({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return const MuCardSurface(
        padding: EdgeInsets.all(MuSpace.s3),
        child: Row(
          children: [
            MuSkeleton(width: MuTournamentCard._posterW, height: MuTournamentCard._posterH),
            SizedBox(width: MuSpace.s3),
            Expanded(child: MuSkeleton.text(lines: 3)),
          ],
        ),
      );
    }
    return const MuCardSurface(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.all(MuSpace.s4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: MuTournamentCard._poster,
                  child: AspectRatio(
                    aspectRatio: MuTournamentCard._posterRatio,
                    child: MuSkeleton(),
                  ),
                ),
                SizedBox(width: MuSpace.s3),
                Expanded(child: MuSkeleton.text(lines: 3)),
              ],
            ),
          ),
          MuScoreboardStrip(
            loading: true,
            cells: [
              MuStripCell(label: '', value: SizedBox.shrink()),
              MuStripCell(label: '', value: SizedBox.shrink()),
              MuStripCell(label: '', value: SizedBox.shrink()),
            ],
          ),
          Padding(
            padding: EdgeInsets.all(MuSpace.s4),
            child: Row(
              children: [
                MuSkeleton(width: MuTournamentCard._skelCount, height: MuSkeleton.textHeight),
                Spacer(),
                MuSkeleton.pill(width: MuTournamentCard._skelButton, height: MuSize.controlL),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
