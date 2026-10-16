import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/format.dart';
import '../theme/theme.dart';
import 'mu_avatar.dart';
import 'mu_avatar_stack.dart';
import 'mu_button.dart';
import 'mu_chip.dart';
import 'mu_court_art.dart';
import 'mu_match_fit_score.dart';
import 'mu_skeleton.dart';
import 'mu_sport_icon.dart';
import 'mu_status_badge.dart';
import 'src/card_surface.dart';
import 'src/price_tag.dart';
import 'src/scoreboard_strip.dart';
import 'src/tone_badge.dart';

/// Where the player stands with a game. Full and almost full are derived from the spots left.
enum MuGameStatus { open, joined, cancelled }

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
    this.id,
    this.venueId,
    this.court,
    this.gameType = 'Mixte',
    this.levelMin,
    this.levelMax,
    this.distanceKm,
    this.dateLabel,
    this.players = const [],
    this.organiser,
    this.organiserReliability,
    this.matchFit,
    this.matchFitReason,
    this.status = MuGameStatus.open,
    this.refund,
  });

  final String? id;
  final String? venueId;
  final MuSport sport;
  final String venue;
  final String? court;
  final String place;

  /// « Mixte », « Femmes », « Hommes ».
  final String gameType;
  final DateTime start;
  final int spotsTotal;
  final int spotsLeft;

  /// Always the share each player pays (court price ÷ players).
  final num pricePerPlayer;
  final double? levelMin;
  final double? levelMax;
  final double? distanceKm;

  /// « Ce soir », « Demain »; defaults to « sam. 18 oct. ».
  final String? dateLabel;
  final List<MuPerson> players;
  final String? organiser;

  /// Organiser reliability in %, shown as « Fiable 98 % ».
  final int? organiserReliability;

  /// AI compatibility in %, with the reason of its tooltip.
  final int? matchFit;
  final String? matchFitReason;
  final MuGameStatus status;

  /// Refunded to the balance when the game was cancelled (« Remboursé 15 DT sur ton solde »).
  final num? refund;

  String get title => court == null ? venue : '$venue · $court';
  bool get isFull => spotsLeft <= 0;
  bool get almostFull => spotsLeft == 1;

  /// « La Marsa · 1,4 km ».
  String get placeLabel =>
      distanceKm == null ? place : '$place · ${formatLevel(distanceKm!)} km';

  /// « 3,0–4,5 », or null without a level range.
  String? get levelLabel => levelMin != null && levelMax != null
      ? '${formatLevel(levelMin!)}–${formatLevel(levelMax!)}'
      : null;

  /// The AI pill shows only on games the player can still join.
  bool get showsFit => matchFit != null && status == MuGameStatus.open && !isFull;
}

enum MuGameCardVariant { standard, featured, compact }

/// GameCard (components/GameCard.md). Time, place, price per player and spots left are visible in
/// every variant.
///
/// `standard`: sport and type chips with the AI fit, identity, the scoreboard strip HEURE · PLACES
/// · PRIX, then who's in and « Rejoindre ». `featured`: CourtArt photo with the time on it, the
/// strip PLACES · PRIX · NIVEAU. `compact`: the dense row. Full, almost full, joined and cancelled
/// come from [MuGame]; [loading] draws the same layout in skeleton blocks.
class MuGameCard extends StatelessWidget {
  const MuGameCard({
    super.key,
    required MuGame this.game,
    this.variant = MuGameCardVariant.standard,
    this.onTap,
    this.onJoin,
    this.onWaitlist,
    this.onView,
    this.surfaceColor,
  }) : loading = false;

  /// The skeleton of a card in [variant] while games load.
  const MuGameCard.loading({super.key, this.variant = MuGameCardVariant.standard})
      : game = null,
        loading = true,
        onTap = null,
        onJoin = null,
        onWaitlist = null,
        onView = null,
        surfaceColor = null;

  final MuGame? game;
  final MuGameCardVariant variant;
  final VoidCallback? onTap;
  final VoidCallback? onJoin;
  final VoidCallback? onWaitlist;
  final VoidCallback? onView;
  final bool loading;

  /// Overrides `surface` (welcome illustrations sit on `surface-elevated`).
  final Color? surfaceColor;

  // GameCard.md compact: min-height 88, 64 px date tile; the « 8 inscrits » caption hides when the
  // footer is ≤ 300; featured photo 16:9.
  static const double _minHeight = 88;
  static const double _tile = 64;
  static const double _captionMinFooter = 300;
  static const double _photoRatio = 16 / 9;

  // Skeleton block widths, matching the content they stand for (HOM-02).
  static const double _skelChip = 72;
  static const double _skelChipWide = 112;
  static const double _skelStack = 96;
  static const double _skelButton = 96;

  static String _spotsLabel(MuGame g) {
    final left = g.spotsLeft;
    return left <= 0 ? 'Complet' : '$left ${left == 1 ? 'place libre' : 'places libres'}';
  }

  static String _semantics(MuGame g) =>
      '${g.title}, ${g.sport.label}, ${formatDateTime(g.start)}, ${_spotsLabel(g)}, '
      '${formatDT(g.pricePerPlayer)} par joueur';

  @override
  Widget build(BuildContext context) {
    if (loading) return _Loading(variant: variant);
    return switch (variant) {
      MuGameCardVariant.compact => _compact(context, game!),
      MuGameCardVariant.featured => _featured(context, game!),
      MuGameCardVariant.standard => _standard(context, game!),
    };
  }

  bool _cancelled(MuGame g) => g.status == MuGameStatus.cancelled;

  /// Status flags at the end of the head: Complet, Plus que 1 place, Tu joues, Annulée.
  Widget? _flag(MuGame g) {
    if (g.status == MuGameStatus.cancelled) {
      return const MuStatusBadge(status: MuStatus.cancelled, label: 'Annulée', size: MuBadgeSize.s);
    }
    if (g.status == MuGameStatus.joined) {
      return const MuToneBadge(label: 'Tu joues', tone: MuBadgeTone.accent);
    }
    if (g.isFull) return const MuStatusBadge(status: MuStatus.full, size: MuBadgeSize.s);
    if (g.almostFull) {
      return MuToneBadge(
        label: 'Plus que 1 place',
        tone: MuBadgeTone.warning,
        icon: PhosphorIcons.warning(PhosphorIconsStyle.fill),
      );
    }
    return null;
  }

  Widget? _cta(MuGame g) {
    if (_cancelled(g)) return null;
    if (g.status == MuGameStatus.joined) {
      return MuButton.secondary(label: 'Voir la partie', onPressed: onView ?? onTap);
    }
    if (g.isFull) return MuButton.secondary(label: 'Liste d’attente', onPressed: onWaitlist);
    return MuButton.primary(label: 'Rejoindre', onPressed: onJoin);
  }

  Widget _organiser(BuildContext context, MuGame g) {
    final c = context.mu;
    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(text: 'Par '),
          TextSpan(text: g.organiser, style: MuType.labelS.copyWith(color: c.text)),
          if (g.organiserReliability != null) ...[
            const TextSpan(text: '  '),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Icon(
                PhosphorIcons.shieldCheck(PhosphorIconsStyle.fill),
                size: MuSize.iconXs,
                color: c.successText,
              ),
            ),
            TextSpan(text: ' Fiable ', style: MuType.labelS.copyWith(color: c.successText)),
            TextSpan(
              text: '${g.organiserReliability} %',
              style: MuType.numXs.copyWith(color: c.successText),
            ),
          ],
        ],
      ),
      style: MuType.caption.copyWith(color: c.textSecondary),
    );
  }

  Widget _footer(BuildContext context, MuGame g) {
    final c = context.mu;
    final cta = _cta(g);
    if (_cancelled(g)) {
      return Padding(
        padding: const EdgeInsets.all(MuSpace.s4),
        child: Row(
          children: [
            Icon(PhosphorIcons.arrowUUpLeft(), size: MuSize.iconXs, color: c.infoText),
            const SizedBox(width: MuSpace.s1),
            Expanded(
              child: Text(
                g.refund == null
                    ? 'Partie annulée'
                    : 'Remboursé ${formatDT(g.refund!)} sur ton solde',
                style: MuType.caption.copyWith(color: c.infoText),
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(MuSpace.s4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showCaption = constraints.maxWidth > _captionMinFooter;
          return Row(
            children: [
              if (g.players.isNotEmpty) ...[
                MuAvatarStack(
                  people: g.players,
                  size: MuAvatarSize.xs,
                  semanticLabel: '${g.players.length} inscrits',
                ),
                if (showCaption) ...[
                  const SizedBox(width: MuSpace.s2),
                  Flexible(
                    child: Text(
                      '${g.players.length} inscrits',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MuType.caption.copyWith(color: c.textSecondary),
                    ),
                  ),
                ],
              ],
              const Spacer(),
              ?cta,
            ],
          );
        },
      ),
    );
  }

  /// PLACES « 2 libres » over the dots meter.
  MuStripCell _placesCell(BuildContext context, MuGame g) {
    final c = context.mu;
    final muted = _cancelled(g);
    return MuStripCell(
      label: 'Places',
      value: MuScoreboardStrip.value(
        context,
        '${g.spotsLeft < 0 ? 0 : g.spotsLeft}',
        g.spotsLeft == 1 || g.spotsLeft == 0 ? 'libre' : 'libres',
        muted ? c.textSecondary : null,
      ),
      sub: g.spotsTotal <= _DotsMeter.maxDots
          ? _DotsMeter(
              total: g.spotsTotal,
              taken: g.spotsTotal - g.spotsLeft,
              color: muted ? c.textDisabled : g.sport.color(c),
            )
          : MuScoreboardStrip.sub(context, 'sur ${g.spotsTotal}'),
    );
  }

  MuStripCell _priceCell(BuildContext context, MuGame g) {
    final c = context.mu;
    return MuStripCell(
      label: 'Prix',
      value: _struck(
        g,
        MuScoreboardStrip.value(
          context,
          formatAmount(g.pricePerPlayer),
          'DT',
          _cancelled(g) ? c.textSecondary : null,
        ),
      ),
      sub: MuScoreboardStrip.sub(context, 'par joueur'),
    );
  }

  /// Cancelled values are struck through.
  Widget _struck(MuGame g, Widget value) => _cancelled(g)
      ? DefaultTextStyle.merge(
          style: const TextStyle(decoration: TextDecoration.lineThrough),
          child: value,
        )
      : value;

  String _stripSemantics(MuGame g) =>
      'Heure ${formatTime(g.start)}, ${g.spotsLeft} libres sur ${g.spotsTotal}, '
      '${formatDT(g.pricePerPlayer)} par joueur';

  Widget _standard(BuildContext context, MuGame g) {
    final c = context.mu;
    final level = g.levelLabel;
    final flag = _flag(g);

    return MuCardSurface(
      onTap: onTap,
      color: surfaceColor,
      padding: EdgeInsets.zero,
      semanticLabel: _semantics(g),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s4, MuSpace.s4, MuSpace.s3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: MuSpace.s2,
                        runSpacing: MuSpace.s2,
                        children: [
                          MuChip.sport(g.sport, size: MuChipSize.s),
                          MuChip(label: g.gameType, kind: MuChipKind.input, size: MuChipSize.s),
                        ],
                      ),
                    ),
                    if (g.showsFit) ...[
                      const SizedBox(width: MuSpace.s2),
                      MuMatchFitScore.pill(value: g.matchFit!, reason: g.matchFitReason),
                    ] else if (flag != null) ...[
                      const SizedBox(width: MuSpace.s2),
                      flag,
                    ],
                  ],
                ),
                const SizedBox(height: MuSpace.s3),
                Text(
                  g.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MuType.labelL.copyWith(color: c.text),
                ),
                const SizedBox(height: MuSpace.s1),
                Wrap(
                  spacing: MuSpace.s2,
                  runSpacing: MuSpace.s1,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(PhosphorIcons.mapPin(), size: MuSize.iconXs, color: c.textSecondary),
                        const SizedBox(width: MuSpace.s1),
                        Text(g.placeLabel, style: MuType.body.copyWith(color: c.textSecondary)),
                      ],
                    ),
                    if (level != null)
                      MuChip(
                        label: 'Niveau $level',
                        icon: PhosphorIcons.gauge(),
                        kind: MuChipKind.input,
                        size: MuChipSize.s,
                      ),
                  ],
                ),
                if (g.organiser != null) ...[
                  const SizedBox(height: MuSpace.s1),
                  _organiser(context, g),
                ],
              ],
            ),
          ),
          MuScoreboardStrip(
            semanticLabel: _stripSemantics(g),
            cells: [
              MuStripCell(
                label: 'Heure',
                value: _struck(
                  g,
                  MuScoreboardStrip.value(
                    context,
                    formatTime(g.start),
                    null,
                    _cancelled(g) ? c.textSecondary : null,
                  ),
                ),
                sub: MuScoreboardStrip.sub(context, g.dateLabel ?? formatDay(g.start)),
              ),
              _placesCell(context, g),
              _priceCell(context, g),
            ],
          ),
          _footer(context, g),
        ],
      ),
    );
  }

  Widget _featured(BuildContext context, MuGame g) {
    final c = context.mu;
    final level = g.levelLabel;
    final flag = _flag(g);
    const onMedia = MuPalette.white;

    return MuCardSurface(
      onTap: onTap,
      color: surfaceColor,
      padding: EdgeInsets.zero,
      semanticLabel: _semantics(g),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(MuRadius.md)),
            child: AspectRatio(
              aspectRatio: _photoRatio,
              child: MuCourtArt(
                sport: g.sport,
                child: DecoratedBox(
                  decoration: const BoxDecoration(gradient: MuGradients.photoScrim),
                  child: Padding(
                    padding: const EdgeInsets.all(MuSpace.s4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            MuChip.sport(g.sport, size: MuChipSize.s),
                            const SizedBox(width: MuSpace.s3),
                            Flexible(
                              child: Text(
                                'PARTIES POUR TOI',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: MuType.overline.copyWith(color: onMedia),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: Text(
                                formatTime(g.start),
                                style: MuType.numXl.copyWith(color: onMedia),
                              ),
                            ),
                            const SizedBox(width: MuSpace.s2),
                            Flexible(
                              child: Text(
                                g.dateLabel ?? formatDay(g.start),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: MuType.label.copyWith(color: onMedia),
                              ),
                            ),
                            if (flag != null) ...[const SizedBox(width: MuSpace.s2), flag],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s4, MuSpace.s4, MuSpace.s3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  g.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MuType.h3.copyWith(color: c.text),
                ),
                const SizedBox(height: MuSpace.s1),
                Row(
                  children: [
                    Icon(PhosphorIcons.mapPin(), size: MuSize.iconXs, color: c.textSecondary),
                    const SizedBox(width: MuSpace.s1),
                    Expanded(
                      child: Text(
                        '${g.placeLabel} · ${g.gameType}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: MuType.body.copyWith(color: c.textSecondary),
                      ),
                    ),
                  ],
                ),
                if (g.organiser != null) ...[
                  const SizedBox(height: MuSpace.s1),
                  _organiser(context, g),
                ],
                if (g.showsFit) ...[
                  const SizedBox(height: MuSpace.s3),
                  MuMatchFitScore.pill(value: g.matchFit!, reason: g.matchFitReason),
                  if (g.matchFitReason != null) ...[
                    const SizedBox(height: MuSpace.s1),
                    Text(
                      g.matchFitReason!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MuType.caption.copyWith(color: c.textSecondary),
                    ),
                  ],
                ],
              ],
            ),
          ),
          MuScoreboardStrip(
            semanticLabel: '${g.spotsLeft} libres sur ${g.spotsTotal}, '
                '${formatDT(g.pricePerPlayer)} par joueur'
                '${level == null ? '' : ', niveau $level'}',
            cells: [
              _placesCell(context, g),
              _priceCell(context, g),
              MuStripCell(
                label: 'Niveau',
                value: MuScoreboardStrip.value(context, level ?? '—'),
                sub: g.levelMin != null && g.levelMax != null
                    ? MuScoreboardStrip.sub(context, levelBand((g.levelMin! + g.levelMax!) / 2))
                    : null,
              ),
            ],
          ),
          _footer(context, g),
        ],
      ),
    );
  }

  Widget _compact(BuildContext context, MuGame g) {
    final c = context.mu;
    final sportText = g.sport.text(c);
    final left = g.spotsLeft;

    return MuCardSurface(
      onTap: onTap,
      color: surfaceColor,
      padding: const EdgeInsets.all(MuSpace.s3),
      semanticLabel: _semantics(g),
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
                padding: const EdgeInsets.all(MuSpace.s1),
                // Large text sizes shrink the tile content instead of overflowing it.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${formatWeekday(g.start)} ${g.start.day}'
                            .replaceAll('.', '')
                            .toUpperCase(),
                        style: MuType.overline.copyWith(color: sportText),
                      ),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          formatTime(g.start),
                          style: MuType.numM.copyWith(color: c.text),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: MuSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      g.title,
                      style: MuType.label.copyWith(color: c.text),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
                          child: Text(
                            _spotsLabel(g),
                            style: MuType.labelS.copyWith(color: c.text),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
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

/// The card in skeleton blocks (HOM-02): photo, chips, title lines, the strip and the footer.
class _Loading extends StatelessWidget {
  const _Loading({required this.variant});

  final MuGameCardVariant variant;

  @override
  Widget build(BuildContext context) {
    if (variant == MuGameCardVariant.compact) {
      return const MuCardSurface(
        padding: EdgeInsets.all(MuSpace.s3),
        child: Row(
          children: [
            MuSkeleton(width: MuGameCard._tile, height: MuGameCard._tile),
            SizedBox(width: MuSpace.s3),
            Expanded(child: MuSkeleton.text(lines: 3)),
          ],
        ),
      );
    }
    final featured = variant == MuGameCardVariant.featured;
    return MuCardSurface(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (featured)
            const AspectRatio(
              aspectRatio: MuGameCard._photoRatio,
              child: MuSkeleton(
                radius: BorderRadius.vertical(top: Radius.circular(MuRadius.md)),
              ),
            ),
          const Padding(
            padding: EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s4, MuSpace.s4, MuSpace.s3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    MuSkeleton.pill(width: MuGameCard._skelChip, height: MuSize.iconM),
                    SizedBox(width: MuSpace.s2),
                    MuSkeleton.pill(width: MuGameCard._skelChip * 0.7, height: MuSize.iconM),
                    Spacer(),
                    MuSkeleton.pill(width: MuGameCard._skelChipWide, height: MuSize.iconM),
                  ],
                ),
                SizedBox(height: MuSpace.s3),
                FractionallySizedBox(widthFactor: 0.6, child: MuSkeleton.text()),
                SizedBox(height: MuSpace.s2),
                FractionallySizedBox(widthFactor: 0.4, child: MuSkeleton.text()),
                SizedBox(height: MuSpace.s2),
                FractionallySizedBox(widthFactor: 0.5, child: MuSkeleton.text()),
              ],
            ),
          ),
          MuScoreboardStrip(
            loading: true,
            cells: [
              for (final label in ['', '', ''])
                MuStripCell(label: label, value: const SizedBox.shrink()),
            ],
          ),
          const Padding(
            padding: EdgeInsets.all(MuSpace.s4),
            child: Row(
              children: [
                MuSkeleton.pill(width: MuGameCard._skelStack, height: MuSize.iconM),
                Spacer(),
                MuSkeleton.pill(width: MuGameCard._skelButton, height: MuSize.controlL),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One dot per player: taken in the sport colour, free hollow with a `border-strong` ring.
/// Dots shrink from 7 to 4 px (gaps from 3 to 2) to fit a narrow cell.
class _DotsMeter extends StatelessWidget {
  const _DotsMeter({required this.total, required this.taken, required this.color});

  final int total;
  final int taken;
  final Color color;

  // GameCard.md: ≤ 12 dots, 7 px (shrinks to 4 px), 3 px gap, 1.5 px ring.
  static const int maxDots = 12;
  static const double _dot = 7;
  static const double _dotMin = 4;
  static const double _gap = 3;
  static const double _gapMin = 2;
  static const double _ring = 1.5;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return LayoutBuilder(
      builder: (context, constraints) {
        var dot = _dot;
        var gap = _gap;
        final available = constraints.maxWidth;
        if (available.isFinite && total > 1) {
          final needed = total * _dot + (total - 1) * _gap;
          if (needed > available) {
            gap = _gapMin;
            dot = ((available - (total - 1) * gap) / total).clamp(_dotMin, _dot);
          }
        }
        final ring = dot < _dot ? _ring * dot / _dot : _ring;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < total; i++) ...[
              if (i > 0) SizedBox(width: gap),
              Container(
                width: dot,
                height: dot,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < taken ? color : null,
                  border: i < taken ? null : Border.all(color: c.borderStrong, width: ring),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
