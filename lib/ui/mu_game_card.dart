import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/format.dart';
import '../theme/theme.dart';
import 'mu_avatar.dart';
import 'mu_avatar_stack.dart';
import 'mu_button.dart';
import 'mu_chip.dart';
import 'mu_match_fit_score.dart';
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
    this.distanceKm,
    this.dateLabel,
    this.players = const [],
    this.organiser,
    this.organiserReliability,
    this.matchFit,
    this.matchFitReason,
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

  String get title => court == null ? venue : '$venue · $court';
}

enum MuGameCardVariant { standard, compact }

/// GameCard (components/GameCard.md). Time, place, price per player and spots left are visible in
/// every variant.
///
/// `standard`: sport and type chips with the AI fit, identity, the scoreboard strip HEURE · PLACES
/// · PRIX, then who's in and « Rejoindre ». `compact`: the dense row. The `featured` variant and
/// the full / joined / cancelled states come with the Player core milestone.
class MuGameCard extends StatelessWidget {
  const MuGameCard({
    super.key,
    required this.game,
    this.variant = MuGameCardVariant.standard,
    this.onTap,
    this.onJoin,
    this.surfaceColor,
  });

  final MuGame game;
  final MuGameCardVariant variant;
  final VoidCallback? onTap;
  final VoidCallback? onJoin;

  /// Overrides `surface` (welcome illustrations sit on `surface-elevated`).
  final Color? surfaceColor;

  // GameCard.md compact: min-height 88, 64 px date tile; standard: the « 8 inscrits » caption
  // hides when the footer is ≤ 300.
  static const double _minHeight = 88;
  static const double _tile = 64;
  static const double _captionMinFooter = 300;

  String get _spotsLabel {
    final left = game.spotsLeft;
    return left == 0 ? 'Complet' : '$left ${left == 1 ? 'place libre' : 'places libres'}';
  }

  String get _semantics =>
      '${game.title}, ${game.sport.label}, ${formatDateTime(game.start)}, $_spotsLabel, '
      '${formatDT(game.pricePerPlayer)} par joueur';

  @override
  Widget build(BuildContext context) =>
      variant == MuGameCardVariant.compact ? _compact(context) : _standard(context);

  Widget _standard(BuildContext context) {
    final c = context.mu;
    final g = game;
    final place = g.distanceKm == null
        ? g.place
        : '${g.place} · ${g.distanceKm!.toStringAsFixed(1).replaceAll('.', ',')} km';
    final level = g.levelMin != null && g.levelMax != null
        ? '${formatLevel(g.levelMin!)}–${formatLevel(g.levelMax!)}'
        : null;

    return MuCardSurface(
      onTap: onTap,
      color: surfaceColor,
      padding: EdgeInsets.zero,
      semanticLabel: _semantics,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s4, MuSpace.s4, MuSpace.s3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: MuSpace.s2,
                  runSpacing: MuSpace.s2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    MuChip.sport(g.sport, size: MuChipSize.s),
                    MuChip(label: g.gameType, kind: MuChipKind.input, size: MuChipSize.s),
                    if (g.matchFit != null)
                      MuMatchFitScore.pill(value: g.matchFit!, reason: g.matchFitReason),
                  ],
                ),
                const SizedBox(height: MuSpace.s3),
                Text(g.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MuType.labelL.copyWith(color: c.text)),
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
                        Text(place, style: MuType.body.copyWith(color: c.textSecondary)),
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
                  Text.rich(
                    TextSpan(children: [
                      const TextSpan(text: 'Par '),
                      TextSpan(text: g.organiser, style: MuType.labelS.copyWith(color: c.text)),
                      if (g.organiserReliability != null) ...[
                        const TextSpan(text: '  '),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Icon(PhosphorIcons.shieldCheck(PhosphorIconsStyle.fill),
                              size: MuSize.iconXs, color: c.successText),
                        ),
                        TextSpan(
                          text: ' Fiable ',
                          style: MuType.labelS.copyWith(color: c.successText),
                        ),
                        TextSpan(
                          text: '${g.organiserReliability} %',
                          style: MuType.numXs.copyWith(color: c.successText),
                        ),
                      ],
                    ]),
                    style: MuType.caption.copyWith(color: c.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          _Strip(game: g),
          Padding(
            padding: const EdgeInsets.all(MuSpace.s4),
            child: LayoutBuilder(builder: (context, constraints) {
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
                      Text('${g.players.length} inscrits',
                          style: MuType.caption.copyWith(color: c.textSecondary)),
                    ],
                  ],
                  const Spacer(),
                  MuButton.primary(label: 'Rejoindre', onPressed: onJoin),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _compact(BuildContext context) {
    final c = context.mu;
    final g = game;
    final sportText = g.sport.text(c);
    final left = g.spotsLeft;

    return MuCardSurface(
      onTap: onTap,
      color: surfaceColor,
      padding: const EdgeInsets.all(MuSpace.s3),
      semanticLabel: _semantics,
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
                            _spotsLabel,
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

/// The scoreboard strip: full-bleed `surface-muted` band, HEURE · PLACES · PRIX cells.
class _Strip extends StatelessWidget {
  const _Strip({required this.game});

  final MuGame game;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final g = game;
    final hairline = BorderSide(color: c.border);

    Widget cell(String label, Widget value, Widget sub, {required bool first, required bool last}) {
      return Expanded(
        child: Container(
          padding: EdgeInsetsDirectional.fromSTEB(
            first ? MuSpace.s4 : MuSpace.s3,
            MuSpace.s3,
            last ? MuSpace.s4 : MuSpace.s3,
            MuSpace.s3,
          ),
          decoration: BoxDecoration(
            border: last ? null : BorderDirectional(end: hairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(), style: MuType.overline.copyWith(color: c.textSecondary)),
              const SizedBox(height: MuSpace.s1),
              FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart, child: value),
              const SizedBox(height: MuSpace.s1),
              sub,
            ],
          ),
        ),
      );
    }

    Widget value(String main, [String? unit]) => Directionality(
          textDirection: TextDirection.ltr,
          child: Text.rich(
            TextSpan(children: [
              TextSpan(text: main, style: MuType.numL),
              if (unit != null) TextSpan(text: ' $unit', style: MuType.numM),
            ]),
            style: TextStyle(color: c.text),
          ),
        );

    Text sub(String text) => Text(text, style: MuType.caption.copyWith(color: c.textSecondary));

    return Semantics(
      label: 'Heure ${formatTime(g.start)}, ${g.spotsLeft} libres sur ${g.spotsTotal}, '
          '${formatDT(g.pricePerPlayer)} par joueur',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.surfaceMuted,
          border: Border.symmetric(horizontal: hairline),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              cell('Heure', value(formatTime(g.start)), sub(g.dateLabel ?? formatDay(g.start)),
                  first: true, last: false),
              cell(
                'Places',
                value('${g.spotsLeft}', g.spotsLeft == 1 ? 'libre' : 'libres'),
                g.spotsTotal <= _DotsMeter.maxDots
                    ? _DotsMeter(
                        total: g.spotsTotal,
                        taken: g.spotsTotal - g.spotsLeft,
                        color: g.sport.color(c),
                      )
                    : sub('sur ${g.spotsTotal}'),
                first: false,
                last: false,
              ),
              cell('Prix', value(formatAmount(g.pricePerPlayer), 'DT'), sub('par joueur'),
                  first: false, last: true),
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
