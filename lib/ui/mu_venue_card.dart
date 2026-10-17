import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../core/format.dart';
import '../theme/theme.dart';
import 'mu_chip.dart';
import 'mu_court_art.dart';
import 'mu_icon_button.dart';
import 'mu_map_view.dart';
import 'mu_skeleton.dart';
import 'mu_sport_icon.dart';
import 'mu_status_badge.dart';
import 'src/card_surface.dart';
import 'src/scoreboard_strip.dart';
import '../l10n/l10n.dart';

/// Venue amenities, with their icon and name (VenueCard « Tags »).
enum MuAmenity {
  lighting,
  changingRooms,
  showers,
  parking,
  covered,
  cafe,
  bibs;

  String get label => switch (this) {
    MuAmenity.lighting => l10n.eclairage,
    MuAmenity.changingRooms => l10n.vestiaires,
    MuAmenity.showers => l10n.douches,
    MuAmenity.parking => l10n.parking,
    MuAmenity.covered => l10n.couvert,
    MuAmenity.cafe => l10n.cafe,
    MuAmenity.bibs => l10n.chasubles,
  };

  IconData get icon => switch (this) {
    MuAmenity.lighting => PhosphorIcons.lightbulb(),
    MuAmenity.changingRooms => PhosphorIcons.coatHanger(),
    MuAmenity.showers => PhosphorIcons.shower(),
    MuAmenity.parking => PhosphorIcons.carSimple(),
    MuAmenity.covered => PhosphorIcons.umbrella(),
    MuAmenity.cafe => PhosphorIcons.coffee(),
    MuAmenity.bibs => PhosphorIcons.tShirt(),
  };
}

/// Open now, closed (opens later) or fully booked today.
enum MuVenueStatus { open, closed, fullToday }

/// A venue as the Terrains lists, the map and the Home show it.
@immutable
class MuVenue {
  const MuVenue({
    required this.id,
    required this.name,
    required this.sports,
    required this.place,
    required this.pricePerPerson,
    this.distanceKm,
    this.rating,
    this.reviews = 0,
    this.verified = false,
    this.amenities = const [],
    this.slots = const [],
    this.slotsDay,
    this.courtPrice,
    this.courtPriceUnit = '/h',
    this.status = MuVenueStatus.open,
    this.opensAt,
    this.position,
  });

  final String id;
  final String name;
  final List<MuSport> sports;
  final String place;
  final double? distanceKm;
  final double? rating;
  final int reviews;
  final bool verified;
  final List<MuAmenity> amenities;

  /// Next free start times, « 19h00 ».
  final List<String> slots;

  /// « Demain » when today is closed or full.
  final String? slotsDay;

  /// The lowest price per player, « dès 12 DT ».
  final num pricePerPerson;

  /// The court price, secondary (« 60 DT/h »).
  final num? courtPrice;
  final String courtPriceUnit;
  final MuVenueStatus status;

  /// « 8h00 », shown when closed.
  final String? opensAt;
  final MuLatLng? position;

  MuSport get sport => sports.first;

  /// « La Marsa · 1,4 km ».
  String get placeLabel => distanceKm == null ? place : l10n.km(place, formatLevel(distanceKm!));
}

enum MuVenueCardVariant { standard, compact }

/// VenueCard (components/VenueCard.md): photo with « Vérifié » and a heart, rating and prices on the
/// scoreboard strip, amenities and the next free slots; `compact` is the 96-high row of the Home,
/// favourites and map sheets. The price per player comes first; the court price supports it.
class MuVenueCard extends StatelessWidget {
  const MuVenueCard({
    super.key,
    required MuVenue this.venue,
    this.variant = MuVenueCardVariant.standard,
    this.favourite = false,
    this.onFavouriteChanged,
    this.onSlotTap,
    this.onTap,
  }) : loading = false;

  /// The skeleton of a card in [variant] while venues load.
  const MuVenueCard.loading({super.key, this.variant = MuVenueCardVariant.standard})
    : venue = null,
      loading = true,
      favourite = false,
      onFavouriteChanged = null,
      onSlotTap = null,
      onTap = null;

  final MuVenue? venue;
  final MuVenueCardVariant variant;
  final bool favourite;
  final ValueChanged<bool>? onFavouriteChanged;
  final ValueChanged<String>? onSlotTap;
  final VoidCallback? onTap;
  final bool loading;

  // VenueCard.md: photo 16:10; compact thumb 72, 96 high; the Vérifié seal next to the name.
  static const double _photoRatio = 16 / 10;
  static const double _thumb = 72;
  static const double _sealSize = 22;
  static const double _sealIcon = 14;
  static const double _amenityGap = MuSpace.s3;

  // Skeleton block widths (HOM-02).
  static const double _skelPrice = 72;
  static const double _skelMeta = 40;

  String _semantics(MuVenue v) =>
      l10n.desParPersonne(v.name, v.verified ? l10n.verifie2 : '', v.sports.map((s) => s.label).join(', '), v.placeLabel, v.rating == null ? '' : l10n.noteSurAvis(formatLevel(v.rating!), v.reviews), formatDT(v.pricePerPerson));

  @override
  Widget build(BuildContext context) {
    if (loading) return _Loading(compact: variant == MuVenueCardVariant.compact);
    final v = venue!;
    return variant == MuVenueCardVariant.compact
        ? _buildCompact(context, v)
        : _buildStandard(context, v);
  }

  Widget _heart(MuVenue v, {required bool onMedia}) => MuIconButton(
    icon: PhosphorIcons.heart(),
    selectedIcon: PhosphorIcons.heart(PhosphorIconsStyle.fill),
    pressed: favourite,
    label: l10n.mettreEnFavori(v.name),
    size: onMedia ? MuIconButtonSize.m : MuIconButtonSize.s,
    variant: onMedia ? MuIconButtonVariant.onMedia : MuIconButtonVariant.ghost,
    onPressed: onFavouriteChanged == null ? null : () => onFavouriteChanged!(!favourite),
  );

  Widget _rating(BuildContext context, MuVenue v) {
    final c = context.mu;
    return Text.rich(
      TextSpan(
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Icon(
              PhosphorIcons.star(PhosphorIconsStyle.fill),
              size: MuSize.iconXs,
              color: c.text,
            ),
          ),
          const TextSpan(text: ' '),
          if (v.rating != null) ...[
            TextSpan(
              text: formatLevel(v.rating!),
              style: MuType.numXs.copyWith(color: c.text),
            ),
            TextSpan(text: ' (${v.reviews})'),
          ],
          TextSpan(text: ' · ${v.placeLabel}'),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: MuType.caption.copyWith(color: c.textSecondary),
    );
  }

  Widget _fromPrice(BuildContext context, MuVenue v) {
    final c = context.mu;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: l10n.des,
              style: MuType.caption.copyWith(color: c.textSecondary),
            ),
            TextSpan(text: formatAmount(v.pricePerPerson), style: MuType.numM),
            TextSpan(text: ' DT', style: MuType.numS),
            TextSpan(
              text: ' /pers.',
              style: MuType.caption.copyWith(color: c.textSecondary),
            ),
          ],
        ),
        style: TextStyle(color: c.text),
      ),
    );
  }

  Widget _verifiedSeal(BuildContext context) {
    final c = context.mu;
    return Semantics(
      label: l10n.verifie,
      child: Container(
        width: _sealSize,
        height: _sealSize,
        decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Icon(
          PhosphorIcons.sealCheck(PhosphorIconsStyle.fill),
          size: _sealIcon,
          color: c.onAccent,
        ),
      ),
    );
  }

  Widget _buildCompact(BuildContext context, MuVenue v) {
    final c = context.mu;
    return MuCardSurface(
      onTap: onTap,
      padding: const EdgeInsets.all(MuSpace.s3),
      semanticLabel: _semantics(v),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Thumb(venue: v, size: _thumb),
          const SizedBox(width: MuSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              v.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: MuType.labelL.copyWith(color: c.text),
                            ),
                          ),
                          if (v.verified) ...[
                            const SizedBox(width: MuSpace.s2),
                            _verifiedSeal(context),
                          ],
                        ],
                      ),
                    ),
                    _heart(v, onMedia: false),
                  ],
                ),
                _rating(context, v),
                const SizedBox(height: MuSpace.s2),
                Row(
                  children: [
                    for (final s in v.sports) ...[
                      MuSportIcon(s, size: MuSize.iconS, color: s.text(c)),
                      const SizedBox(width: MuSpace.s1),
                    ],
                    const Spacer(),
                    _fromPrice(context, v),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandard(BuildContext context, MuVenue v) {
    final c = context.mu;
    final closed = v.status == MuVenueStatus.closed;
    final String? photoBadge = switch (v.status) {
      MuVenueStatus.closed => v.opensAt == null ? l10n.ferme2 : l10n.fermeOuvreA('${v.opensAt}'),
      MuVenueStatus.fullToday => l10n.completAujourdHui,
      MuVenueStatus.open => null,
    };
    final slotsTitle = v.slotsDay == null
        ? l10n.prochainsCreneaux
        : l10n.prochainsCreneaux2('${v.slotsDay}');

    return MuCardSurface(
      onTap: onTap,
      padding: EdgeInsets.zero,
      semanticLabel: _semantics(v),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(MuRadius.md)),
            child: AspectRatio(
              aspectRatio: _photoRatio,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (closed)
                    ColorFiltered(
                      colorFilter: const ColorFilter.matrix(_greyscale),
                      child: MuCourtArt(sport: v.sport, semanticLabel: l10n.photoDe(v.name)),
                    )
                  else
                    MuCourtArt(sport: v.sport, semanticLabel: l10n.photoDe(v.name)),
                  if (closed) ColoredBox(color: c.scrim),
                  PositionedDirectional(
                    top: MuSpace.s3,
                    start: MuSpace.s3,
                    end: MuSpace.s3,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (v.verified) const MuStatusBadge(status: MuStatus.verified),
                        if (photoBadge != null) ...[
                          if (v.verified) const SizedBox(width: MuSpace.s2),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: MuSpace.s2,
                                vertical: MuSpace.s1,
                              ),
                              decoration: ShapeDecoration(
                                color: c.surfaceInverse,
                                shape: const StadiumBorder(),
                              ),
                              child: Text(
                                photoBadge,
                                style: MuType.labelS.copyWith(color: c.textInverse),
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        _heart(v, onMedia: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s4, MuSpace.s4, MuSpace.s3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  v.name,
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
                        v.placeLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: MuType.body.copyWith(color: c.textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: MuSpace.s3),
                Wrap(
                  spacing: MuSpace.s2,
                  runSpacing: MuSpace.s2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (final s in v.sports) MuChip.sport(s, size: MuChipSize.s),
                    if (v.amenities.isNotEmpty)
                      Semantics(
                        container: true,
                        label: l10n.equipements,
                        child: Wrap(
                          spacing: _amenityGap,
                          children: [
                            for (final a in v.amenities)
                              Tooltip(
                                message: a.label,
                                child: Icon(
                                  a.icon,
                                  size: MuSize.iconS,
                                  color: c.textSecondary,
                                  semanticLabel: a.label,
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          MuScoreboardStrip(
            semanticLabel:
                l10n.desParJoueur(v.rating == null ? '' : l10n.note2(formatLevel(v.rating!)), formatDT(v.pricePerPerson), v.courtPrice == null ? '' : l10n.terrain5(formatDT(v.courtPrice!))),
            cells: [
              if (v.rating != null)
                MuStripCell(
                  label: l10n.note,
                  labelIcon: PhosphorIcons.star(PhosphorIconsStyle.fill),
                  value: MuScoreboardStrip.value(context, formatLevel(v.rating!)),
                  sub: MuScoreboardStrip.sub(context, '${v.reviews} avis'),
                ),
              MuStripCell(
                label: l10n.parJoueur,
                value: MuScoreboardStrip.value(context, formatAmount(v.pricePerPerson), dtUnit),
                sub: MuScoreboardStrip.sub(context, l10n.des2),
              ),
              if (v.courtPrice != null)
                MuStripCell(
                  label: l10n.terrain2,
                  value: MuScoreboardStrip.value(
                    context,
                    formatAmount(v.courtPrice!),
                    'DT${v.courtPriceUnit}',
                  ),
                ),
            ],
          ),
          if (v.slots.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(MuSpace.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    slotsTitle.toUpperCase(),
                    style: MuType.overline.copyWith(color: c.textSecondary),
                  ),
                  const SizedBox(height: MuSpace.s2),
                  Wrap(
                    spacing: MuSpace.s2,
                    runSpacing: MuSpace.s2,
                    children: [
                      for (final slot in v.slots)
                        Semantics(
                          button: true,
                          label: v.slotsDay == null
                              ? l10n.reserverA(slot)
                              : l10n.reserverA2(v.slotsDay!.toLowerCase(), slot),
                          excludeSemantics: true,
                          child: MuChip(
                            label: slot,
                            onSelected: onSlotTap == null ? null : (_) => onSlotTap!(slot),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Luminance-preserving greyscale for the closed photo.
  static const List<double> _greyscale = [
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 1, 0,
  ];
}

/// The 72 px CourtArt thumbnail with a hairline ring.
class _Thumb extends StatelessWidget {
  const _Thumb({required this.venue, required this.size});

  final MuVenue venue;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Container(
      width: size,
      height: size,
      foregroundDecoration: BoxDecoration(
        borderRadius: MuRadius.smAll,
        border: Border.all(color: c.border),
      ),
      child: ClipRRect(
        borderRadius: MuRadius.smAll,
        child: MuCourtArt(sport: venue.sport),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MuSkeleton(width: MuVenueCard._thumb, height: MuVenueCard._thumb),
            SizedBox(width: MuSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FractionallySizedBox(widthFactor: 0.55, child: MuSkeleton.text()),
                  SizedBox(height: MuSpace.s2),
                  MuSkeleton.text(),
                  SizedBox(height: MuSpace.s4),
                  Row(
                    children: [
                      MuSkeleton(width: MuVenueCard._skelMeta, height: MuSkeleton.textHeight),
                      Spacer(),
                      MuSkeleton(width: MuVenueCard._skelPrice, height: MuSkeleton.textHeight),
                    ],
                  ),
                ],
              ),
            ),
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
          AspectRatio(
            aspectRatio: MuVenueCard._photoRatio,
            child: MuSkeleton(radius: BorderRadius.vertical(top: Radius.circular(MuRadius.md))),
          ),
          Padding(padding: EdgeInsets.all(MuSpace.s4), child: MuSkeleton.text(lines: 3)),
          MuScoreboardStrip(
            loading: true,
            cells: [
              MuStripCell(label: '', value: SizedBox.shrink()),
              MuStripCell(label: '', value: SizedBox.shrink()),
              MuStripCell(label: '', value: SizedBox.shrink()),
            ],
          ),
        ],
      ),
    );
  }
}
