import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/clock.dart';
import '../../../core/directions.dart';
import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../booking/controllers/booking_controller.dart';
import '../../common/widgets/coming_soon.dart';
import '../../home/controllers/home_providers.dart';
import '../data/venue_details.dart';
import '../widgets/venue_widgets.dart';
import '../../../l10n/l10n.dart';

/// VEN-01 · Fiche du terrain: the photo, « Vérifié », rating, opening hours and prices, the slot
/// grid of the chosen day, equipment, courts, the map, the cancellation policy and a review; the
/// sticky bar shows the price per person and « Réserver ».
class VenueScreen extends ConsumerStatefulWidget {
  const VenueScreen({super.key, required this.venueId});

  final String venueId;

  @override
  ConsumerState<VenueScreen> createState() => _VenueScreenState();
}

class _VenueScreenState extends ConsumerState<VenueScreen> {
  // VEN-01: photo 252 high; the map 176; court tiles 3:2.
  static const double _photo = 252;
  static const double _map = 176;
  static const double _mapZoom = 1.6;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(bookingProvider.notifier).openVenue(widget.venueId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final details = ref.watch(venueDetailsProvider(widget.venueId));
    return Scaffold(
      backgroundColor: c.bg,
      body: switch (details) {
        AsyncData(:final value) => _Body(details: value),
        AsyncError() => Center(
          child: Padding(
            padding: const EdgeInsets.all(MuSpace.s4),
            child: MuEmptyState(
              title: l10n.terrainIntrouvable,
              description: l10n.ilNExistePlusOu,
              actions: [
                MuButton.primary(
                  label: l10n.voirLesTerrains,
                  onPressed: () => context.go(Routes.explore),
                ),
              ],
            ),
          ),
        ),
        _ => MuSkeletonGroup(
          label: l10n.chargementDuTerrain,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MuSkeleton(height: _photo, radius: BorderRadius.zero),
              Padding(padding: EdgeInsets.all(MuSpace.s4), child: MuSkeleton.text(lines: 4)),
            ],
          ),
        ),
      },
      bottomNavigationBar: details.value == null ? null : _Bar(details: details.value!),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.details});

  final VenueDetails details;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final v = details.venue;
    final now = ref.watch(clockProvider)();
    final minute = now.hour * 60 + now.minute;
    final open = minute >= details.opens && minute < details.closes;
    final favourite = ref.watch(favouriteVenuesProvider).contains(v.id);

    Widget section(
      List<Widget> children, {
      EdgeInsetsGeometry? padding,
      double gap = MuSpace.s4,
    }) => Container(
      color: c.surface,
      padding: padding ?? const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s5, MuSpace.s4, MuSpace.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, child) in children.indexed) ...[if (i > 0) SizedBox(height: gap), child],
        ],
      ),
    );

    Widget head(String title, {Widget? trailing}) => Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(title, style: MuType.h3.copyWith(color: c.text)),
          ),
        ),
        ?trailing,
      ],
    );

    Widget line(IconData icon, Widget text) => Row(
      children: [
        Icon(icon, size: MuSize.iconXs, color: c.textSecondary),
        const SizedBox(width: MuSpace.s2),
        Expanded(child: text),
      ],
    );

    final hours = l10n.tousLesJours(formatHour(details.opens), formatHour(details.closes));

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // ── Photo ──
        SizedBox(
          height: _VenueScreenState._photo,
          child: Stack(
            fit: StackFit.expand,
            children: [
              MuCourtArt(sport: v.sport, semanticLabel: l10n.photoDe(v.name)),
              const DecoratedBox(decoration: BoxDecoration(gradient: MuGradients.photoScrim)),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(MuSpace.s2),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Row(
                      children: [
                        MuIconButton(
                          icon: PhosphorIcons.arrowLeft(),
                          label: l10n.retour,
                          variant: MuIconButtonVariant.onMedia,
                          onPressed: () =>
                              context.canPop() ? context.pop() : context.go(Routes.explore),
                        ),
                        const Spacer(),
                        MuIconButton(
                          icon: PhosphorIcons.shareNetwork(),
                          label: l10n.partagerLeTerrain,
                          variant: MuIconButtonVariant.onMedia,
                          onPressed: () => SharePlus.instance.share(
                            ShareParams(
                              text: l10n.surMatchupHttpsMatchupTn(v.name, v.id),
                            ),
                          ),
                        ),
                        const SizedBox(width: MuSpace.s2),
                        MuIconButton(
                          icon: PhosphorIcons.heart(),
                          selectedIcon: PhosphorIcons.heart(PhosphorIconsStyle.fill),
                          pressed: favourite,
                          label: l10n.ajouterAuxFavoris,
                          variant: MuIconButtonVariant.onMedia,
                          onPressed: () => ref.read(favouriteVenuesProvider.notifier).toggle(v.id),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              PositionedDirectional(
                end: MuSpace.s4,
                bottom: MuSpace.s4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: MuSpace.s2, vertical: MuSpace.s1),
                  decoration: BoxDecoration(color: c.scrim, borderRadius: MuRadius.fullAll),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(PhosphorIcons.images(), size: MuSize.iconXs, color: MuPalette.white),
                      const SizedBox(width: MuSpace.s1),
                      Text(
                        '1/${details.photos}',
                        semanticsLabel: l10n.photoSur(details.photos),
                        style: MuType.numXs.copyWith(color: MuPalette.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // ── Identity ──
        section(gap: MuSpace.s3, [
          Wrap(
            spacing: MuSpace.s2,
            runSpacing: MuSpace.s2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              VenueSportChip(details: details),
              if (v.verified)
                MuStatusBadge(status: MuStatus.verified, label: l10n.terrainVerifie),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(v.name, style: MuType.h1.copyWith(color: c.text)),
              ),
              if (v.rating != null) ...[
                const SizedBox(height: MuSpace.s1),
                MuStarRating.display(value: v.rating!, count: v.reviews, size: 16),
              ],
            ],
          ),
          Column(
            children: [
              line(
                PhosphorIcons.mapPin(),
                Text(
                  '${details.street}${v.distanceKm == null ? '' : l10n.km3(formatLevel(v.distanceKm!))}',
                  style: MuType.body.copyWith(color: c.textSecondary),
                ),
              ),
              const SizedBox(height: MuSpace.s1),
              line(
                PhosphorIcons.clock(),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: open ? l10n.ouvert : l10n.ferme2,
                        style: MuType.label.copyWith(color: open ? c.successText : c.errorText),
                      ),
                      TextSpan(text: ' · $hours'),
                    ],
                  ),
                  style: MuType.body.copyWith(color: c.textSecondary),
                ),
              ),
            ],
          ),
          VenuePriceBox(
            cells: [
              (
                l10n.parJoueur,
                details.minShare == details.maxShare
                    ? formatAmount(details.minShare)
                    : '${formatAmount(details.minShare)}–${formatAmount(details.maxShare)}',
                null,
                null,
              ),
              (
                l10n.terrain(_slotLength(details)),
                details.offPeakPrice == details.peakPrice
                    ? formatAmount(details.peakPrice)
                    : '${formatAmount(details.offPeakPrice)}–${formatAmount(details.peakPrice)}',
                null,
                null,
              ),
            ],
          ),
        ]),
        const SizedBox(height: MuSpace.s2),
        // ── Slots ──
        Container(
          color: c.surface,
          padding: const EdgeInsets.only(top: MuSpace.s5, bottom: MuSpace.s5),
          child: VenueSlotPicker(
            details: details,
            legend: true,
            header: Padding(
              padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
              child: head(l10n.choisisTonCreneau),
            ),
            footer: Padding(
              padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: l10n.aJoueurs2(details.players)),
                    TextSpan(
                      text: '${formatDT(details.maxShare)} /pers.',
                      style: MuType.labelS.copyWith(color: c.text),
                    ),
                    if (details.peakPrice != details.offPeakPrice)
                      TextSpan(
                        text:
                            l10n.deHAHAvant(details.peakFrom ~/ 60, details.peakTo ~/ 60, formatDT(details.minShare)),
                      ),
                  ],
                ),
                style: MuType.caption.copyWith(color: c.textSecondary),
              ),
            ),
          ),
        ),
        const SizedBox(height: MuSpace.s2),
        // ── Équipements ──
        section([
          head(l10n.equipements),
          Semantics(
            container: true,
            label: l10n.equipements,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = (constraints.maxWidth - MuSpace.s3 * 2) / 3;
                return Wrap(
                  spacing: MuSpace.s3,
                  runSpacing: MuSpace.s4,
                  children: [
                    for (final a in v.amenities)
                      SizedBox(
                        width: w,
                        child: Row(
                          children: [
                            Icon(a.icon, size: MuSize.iconS, color: c.text),
                            const SizedBox(width: MuSpace.s2),
                            Flexible(
                              child: Text(a.label, style: MuType.body.copyWith(color: c.text)),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ]),
        const SizedBox(height: MuSpace.s2),
        // ── Terrains ──
        section([
          head(
            l10n.terrains,
            trailing: Text(
              '${details.format} · ${details.surface}',
              style: MuType.caption.copyWith(color: c.textSecondary),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, court) in details.courts.take(3).indexed) ...[
                if (i > 0) const SizedBox(width: MuSpace.s3),
                Expanded(
                  child: VenueCourtTile(sport: v.sport, court: court),
                ),
              ],
              for (var i = details.courts.length; i < 3; i++) ...[
                const SizedBox(width: MuSpace.s3),
                const Expanded(child: SizedBox.shrink()),
              ],
            ],
          ),
          if (details.courts.length > 3)
            Text(
              l10n.autresTerrains(details.courts.length - 3),
              style: MuType.caption.copyWith(color: c.textSecondary),
            ),
        ]),
        const SizedBox(height: MuSpace.s2),
        // ── Adresse ──
        section([
          head(
            l10n.adresse,
            trailing: v.distanceKm == null
                ? null
                : Text(
                    l10n.kmDeToi(formatLevel(v.distanceKm!)),
                    style: MuType.caption.copyWith(color: c.textSecondary),
                  ),
          ),
          SizedBox(
            height: _VenueScreenState._map,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (v.position != null)
                  MuMapView(
                    center: v.position!,
                    zoom: _VenueScreenState._mapZoom,
                    label: '${v.name}, ${v.place}',
                    district: v.place.toUpperCase(),
                    venues: [
                      MuMapVenue(id: v.id, name: v.name, sport: v.sport, position: v.position!),
                    ],
                  ),
                PositionedDirectional(
                  end: MuSpace.s3,
                  bottom: MuSpace.s3,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: MuRadius.smAll,
                      boxShadow: MuElevation.of(context).level2,
                    ),
                    child: MuButton.secondary(
                      label: l10n.itineraire,
                      leading: PhosphorIcons.navigationArrow(),
                      size: MuButtonSize.s,
                      onPressed: v.position == null ? null : () => openDirections(v.position!),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(details.postalAddress, style: MuType.body.copyWith(color: c.text)),
        ]),
        const SizedBox(height: MuSpace.s2),
        // ── Annulation ──
        section([head(l10n.annulationEtRemboursement), CancellationTiers(venueName: v.name)]),
        const SizedBox(height: MuSpace.s2),
        // ── Avis ──
        section(gap: MuSpace.s3, [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Semantics(
                header: true,
                child: Text(l10n.avis, style: MuType.h3.copyWith(color: c.text)),
              ),
              if (v.rating != null) ...[
                const SizedBox(width: MuSpace.s2),
                Text(formatLevel(v.rating!), style: MuType.numM.copyWith(color: c.text)),
                const SizedBox(width: MuSpace.s1),
                Text(l10n.sur2, style: MuType.caption.copyWith(color: c.textSecondary)),
              ],
              const Spacer(),
              if (v.reviews > 0)
                MuButton.tertiary(
                  label: l10n.voirLesAvis(v.reviews),
                  size: MuButtonSize.s,
                  onPressed: () => showComingSoon(context),
                ),
            ],
          ),
          if (details.review != null) VenueReviewTile(review: details.review!),
        ]),
        const SizedBox(height: MuSpace.s4),
      ],
    );
  }

  static String _slotLength(VenueDetails d) => d.slotMinutes % 60 == 0
      ? '${d.slotMinutes ~/ 60} h'
      : '${d.slotMinutes ~/ 60} h ${d.slotMinutes % 60}';
}

/// « dès 12 DT /pers. · 120–150 DT le terrain · 1 h · à 10 » and « Réserver ».
class _Bar extends ConsumerWidget {
  const _Bar({required this.details});

  final VenueDetails details;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final d = details;
    final court = d.offPeakPrice == d.peakPrice
        ? formatAmount(d.peakPrice)
        : '${formatAmount(d.offPeakPrice)}–${formatAmount(d.peakPrice)}';
    return DecoratedBox(
      decoration: BoxDecoration(color: c.surface, boxShadow: MuElevation.of(context).level2Up),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s3, MuSpace.s4, MuSpace.s3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: l10n.des,
                          style: MuType.caption.copyWith(color: c.textSecondary),
                        ),
                        TextSpan(
                          text: formatDT(d.minShare),
                          style: MuType.numL.copyWith(color: c.text),
                        ),
                        TextSpan(
                          text: ' /pers.',
                          style: MuType.caption.copyWith(color: c.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: MuSpace.s3),
                  Expanded(
                    child: Text(
                      l10n.dtLeTerrainA(court, _Body._slotLength(d), d.players),
                      textAlign: TextAlign.end,
                      style: MuType.caption.copyWith(color: c.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MuSpace.s2),
              MuButton.primary(
                label: l10n.reserver,
                size: MuButtonSize.xl,
                fullWidth: true,
                onPressed: () => context.push(Routes.venueSlots(d.venue.id)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
