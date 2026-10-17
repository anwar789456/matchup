import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/clock.dart';
import '../../../core/format.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../booking/controllers/booking_controller.dart';
import '../data/venue_details.dart';

/// « Football · 5 contre 5 »: the sport chip with the venue's format.
class VenueSportChip extends StatelessWidget {
  const VenueSportChip({super.key, required this.details});

  final VenueDetails details;

  @override
  Widget build(BuildContext context) => MuChip(
    label: sportFormat(details),
    kind: MuChipKind.sport,
    sport: details.venue.sport,
    size: MuChipSize.s,
  );
}

/// The two-cell price box of VEN-01 and VEN-02: an `overline` label, a `num-l` value with its unit,
/// and an optional caption (with an icon).
class VenuePriceBox extends StatelessWidget {
  const VenuePriceBox({super.key, required this.cells, this.unit = 'DT'});

  /// (label, value, caption, caption icon).
  final List<(String, String, String?, Widget?)> cells;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Container(
      decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: MuRadius.mdAll),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, cell) in cells.indexed) ...[
              if (i > 0) VerticalDivider(width: 1, thickness: 1, color: c.border),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(MuSpace.s3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cell.$1.toUpperCase(),
                        style: MuType.overline.copyWith(color: c.textSecondary),
                      ),
                      const SizedBox(height: MuSpace.s1),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: cell.$2, style: MuType.numL),
                              TextSpan(text: ' $unit', style: MuType.numS),
                            ],
                          ),
                          style: TextStyle(color: c.text),
                        ),
                      ),
                      if (cell.$3 != null)
                        Row(
                          children: [
                            if (cell.$4 != null) ...[cell.$4!, const SizedBox(width: MuSpace.s1)],
                            Flexible(
                              child: Text(
                                cell.$3!,
                                style: MuType.caption.copyWith(color: c.textSecondary),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// « Mer. 21 oct. » — the weekday capitalised for a line start.
String capitalDay(DateTime d) {
  final s = formatDay(d);
  return '${s[0].toUpperCase()}${s.substring(1)}';
}

/// The day strip, the window line and the slot grid of a venue, bound to the booking draft
/// (VEN-01 with its header, legend and « Toute la journée »; VEN-02 compact).
class VenueSlotPicker extends ConsumerWidget {
  const VenueSlotPicker({
    super.key,
    required this.details,
    this.legend = false,
    this.compact = false,
    this.header,
    this.footer,
  });

  final VenueDetails details;
  final bool legend;

  /// VEN-02: the price note sits on the window line and the grid's corner says « Terrains ».
  final bool compact;
  final Widget? header;
  final Widget? footer;

  // The strip shows two weeks.
  static const int _days = 14;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final draft = ref.watch(bookingProvider);
    final booking = ref.read(bookingProvider.notifier);
    final now = ref.watch(clockProvider)();
    final today = DateTime(now.year, now.month, now.day);
    final repo = ref.read(venueDetailsRepositoryProvider);
    final schedule = ref.watch(dayScheduleProvider((details.venue.id, draft.day)));

    Future<void> pickDay() async {
      final day = await showDatePicker(
        context: context,
        initialDate: draft.day,
        firstDate: today,
        lastDate: today.add(const Duration(days: 60)),
        locale: const Locale('fr'),
      );
      if (day != null) booking.setDay(day);
    }

    final grid = schedule.value == null
        ? null
        : dayGrid(details, schedule.value!, fullDay: draft.fullDay);
    final windowEnd = grid == null || grid.times.isEmpty
        ? null
        : grid.times.last.add(Duration(minutes: details.slotMinutes));
    final window = grid == null || grid.times.isEmpty
        ? capitalDay(draft.day)
        : '${capitalDay(draft.day)} · ${formatTime(grid.times.first)} – '
              '${formatHour(windowEnd!.hour * 60 + windowEnd.minute)}';

    Widget gridArea;
    if (grid == null) {
      gridArea = schedule.hasError
          ? Padding(
              padding: const EdgeInsets.all(MuSpace.s4),
              child: Text(
                'Impossible de charger les créneaux.',
                style: MuType.body.copyWith(color: c.textSecondary),
              ),
            )
          : const MuSkeletonGroup(
              label: 'Chargement des créneaux',
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: MuSpace.s4),
                child: MuSkeleton.text(lines: 4),
              ),
            );
    } else if (grid.times.isEmpty || grid.courts.every((r) => r.slots.every((s) => !s.free))) {
      gridArea = Padding(
        padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
        child: MuEmptyState(
          compact: true,
          illustration: null,
          title: 'Aucun créneau ce jour-là',
          actions: [
            MuButton.secondary(
              label: 'Voir demain',
              onPressed: () => booking.setDay(draft.day.add(const Duration(days: 1))),
            ),
          ],
        ),
      );
    } else {
      gridArea = MuSlotGrid(
        key: ValueKey((draft.day, draft.fullDay)),
        courts: grid.courts,
        start: grid.start,
        step: details.slotMinutes,
        value: draft.selection,
        onChanged: booking.select,
        legend: legend,
        priceNote: compact ? 'Terrains' : 'Prix du terrain / ${_unit(details)}',
        label: 'Créneaux ${details.venue.name}, ${formatDay(draft.day)}',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (header != null) ...[
          Row(
            children: [
              Expanded(child: header!),
              Padding(
                padding: const EdgeInsetsDirectional.only(end: MuSpace.s4),
                child: MuIconButton(
                  icon: PhosphorIcons.calendarBlank(),
                  label: 'Ouvrir le calendrier',
                  variant: MuIconButtonVariant.secondary,
                  size: MuIconButtonSize.s,
                  onPressed: pickDay,
                ),
              ),
            ],
          ),
          const SizedBox(height: MuSpace.s3),
        ],
        MuDateStrip(
          start: today,
          today: today,
          value: draft.day,
          days: _days,
          label: 'Jour de réservation',
          availability: (d) => repo.availability(details.venue.id, d),
          onChanged: booking.setDay,
        ),
        const SizedBox(height: MuSpace.s3),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
          child: Row(
            children: [
              Expanded(
                child: Text(window, style: MuType.label.copyWith(color: c.text)),
              ),
              if (compact)
                Text(
                  'Prix du terrain / ${_unit(details)}',
                  style: MuType.caption.copyWith(color: c.textSecondary),
                )
              else
                MuButton.tertiary(
                  label: draft.fullDay ? 'Ce soir' : 'Toute la journée',
                  size: MuButtonSize.s,
                  onPressed: booking.toggleFullDay,
                ),
            ],
          ),
        ),
        const SizedBox(height: MuSpace.s3),
        gridArea,
        if (footer != null) ...[const SizedBox(height: MuSpace.s3), footer!],
      ],
    );
  }

  static String _unit(VenueDetails d) => d.slotMinutes == 60 ? 'h' : '${d.slotMinutes} min';
}

/// A court of the « Terrains » section: its CourtArt pattern, name (umbrella when covered) and
/// « Extérieur · éclairé ».
class VenueCourtTile extends StatelessWidget {
  const VenueCourtTile({super.key, required this.sport, required this.court});

  final MuSport sport;
  final VenueCourt court;

  // VEN-01: tiles 3:2.
  static const double _ratio = 3 / 2;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: _ratio,
          child: ClipRRect(
            borderRadius: MuRadius.smAll,
            child: MuCourtArt(sport: sport, variant: MuCourtArtVariant.pattern),
          ),
        ),
        const SizedBox(height: MuSpace.s2),
        Row(
          children: [
            Flexible(
              child: Text(
                court.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: MuType.label.copyWith(color: c.text),
              ),
            ),
            if (court.indoor) ...[
              const SizedBox(width: MuSpace.s1),
              Icon(
                PhosphorIcons.umbrella(),
                size: MuSize.iconXs,
                color: c.text,
                semanticLabel: 'Couvert',
              ),
            ],
          ],
        ),
        Text(court.description, style: MuType.caption.copyWith(color: c.textSecondary)),
      ],
    );
  }
}

/// The three cancellation tiers. With [start] the lines carry the slot's dates (BKG-04).
class CancellationTiers extends StatelessWidget {
  const CancellationTiers({super.key, required this.venueName, this.start, this.small = false});

  final String venueName;
  final DateTime? start;

  /// 16 icons in 28 discs (BKG-04) rather than 20 in 36 (VEN-01).
  final bool small;

  // VEN-01: 36 discs with 20 icons; BKG-04: 28 with 16.
  static const double _disc = 36;
  static const double _discS = 28;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final s = start;
    final policy = s == null ? null : policyFor(s);
    final tiers = [
      (
        PhosphorIcons.checkCircle(),
        c.successSoft,
        c.successText,
        policy == null
            ? 'Gratuite jusqu’à 24 h avant'
            : 'Gratuit jusqu’au ${formatDateTime(policy.freeUntil)}',
        '100 % remboursé sur ton solde MatchUp',
      ),
      (
        PhosphorIcons.circleHalf(),
        c.warningSoft,
        c.warningText,
        policy == null
            ? '50 % remboursés entre 24 h et 6 h avant'
            : '50 % jusqu’au ${formatDateTime(policy.halfUntil)}',
        policy == null ? 'La moitié de ta part te revient' : 'Entre 24 h et 6 h avant le match',
      ),
      (
        PhosphorIcons.prohibit(),
        c.errorSoft,
        c.errorText,
        policy == null ? 'Non remboursable moins de 6 h avant' : 'Non remboursable ensuite',
        'Sauf si $venueName annule : tout est remboursé',
      ),
    ];
    final disc = small ? _discS : _disc;
    return Column(
      children: [
        for (final (i, t) in tiers.indexed) ...[
          if (i > 0) const SizedBox(height: MuSpace.s3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: disc,
                height: disc,
                decoration: BoxDecoration(color: t.$2, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Icon(t.$1, size: small ? MuSize.iconXs : MuSize.iconS, color: t.$3),
              ),
              const SizedBox(width: MuSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.$4, style: MuType.label.copyWith(color: c.text)),
                    Text(t.$5, style: MuType.caption.copyWith(color: c.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// A review: avatar, author, when and court, the stars, the text.
class VenueReviewTile extends StatelessWidget {
  const VenueReviewTile({super.key, required this.review});

  final VenueReview review;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            MuAvatar(name: review.author, size: MuAvatarSize.s),
            const SizedBox(width: MuSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(review.author, style: MuType.label.copyWith(color: c.text)),
                  Text(
                    '${review.when} · ${review.court}',
                    style: MuType.caption.copyWith(color: c.textSecondary),
                  ),
                ],
              ),
            ),
            MuStarRating.display(value: review.rating.toDouble(), size: 16, showValue: false),
          ],
        ),
        const SizedBox(height: MuSpace.s2),
        Text(review.text, style: MuType.body.copyWith(color: c.text)),
      ],
    );
  }
}
