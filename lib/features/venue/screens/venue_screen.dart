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
              title: 'Terrain introuvable',
              description: 'Il n’existe plus ou le lien est incomplet.',
              actions: [
                MuButton.primary(
                  label: 'Voir les terrains',
                  onPressed: () => context.go(Routes.explore),
                ),
              ],
            ),
          ),
        ),
        _ => const MuSkeletonGroup(
          label: 'Chargement du terrain',
          child: Column(
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

    final hours = '${formatHour(details.opens)} – ${formatHour(details.closes)} tous les jours';

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // ── Photo ──
        SizedBox(
          height: _VenueScreenState._photo,
          child: Stack(
            fit: StackFit.expand,
            children: [
              MuCourtArt(sport: v.sport, semanticLabel: 'Photo de ${v.name}'),
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
                          label: 'Retour',
                          variant: MuIconButtonVariant.onMedia,
                          onPressed: () =>
                              context.canPop() ? context.pop() : context.go(Routes.explore),
                        ),
                        const Spacer(),
                        MuIconButton(
                          icon: PhosphorIcons.shareNetwork(),
                          label: 'Partager le terrain',
                          variant: MuIconButtonVariant.onMedia,
                          onPressed: () => SharePlus.instance.share(
                            ShareParams(
                              text: '${v.name} sur MatchUp : https://matchup.tn/t/${v.id}',
                            ),
                          ),
                        ),
                        const SizedBox(width: MuSpace.s2),
                        MuIconButton(
                          icon: PhosphorIcons.heart(),
                          selectedIcon: PhosphorIcons.heart(PhosphorIconsStyle.fill),
                          pressed: favourite,
                          label: 'Ajouter aux favoris',
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
                        semanticsLabel: 'Photo 1 sur ${details.photos}',
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
                const MuStatusBadge(status: MuStatus.verified, label: 'Terrain vérifié'),
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
                  '${details.street}${v.distanceKm == null ? '' : ' · ${formatLevel(v.distanceKm!)} km'}',
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
                        text: open ? 'Ouvert' : 'Fermé',
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
                'Par joueur',
                details.minShare == details.maxShare
                    ? formatAmount(details.minShare)
                    : '${formatAmount(details.minShare)}–${formatAmount(details.maxShare)}',
                null,
                null,
              ),
              (
                'Terrain · ${_slotLength(details)}',
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
              child: head('Choisis ton créneau'),
            ),
            footer: Padding(
              padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: 'À ${details.players} joueurs : '),
                    TextSpan(
                      text: '${formatDT(details.maxShare)} /pers.',
                      style: MuType.labelS.copyWith(color: c.text),
                    ),
                    if (details.peakPrice != details.offPeakPrice)
                      TextSpan(
                        text:
                            ' de ${details.peakFrom ~/ 60}h à ${details.peakTo ~/ 60}h · '
                            '${formatDT(details.minShare)} avant.',
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
          head('Équipements'),
          Semantics(
            container: true,
            label: 'Équipements',
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
            'Terrains',
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
              '+ ${details.courts.length - 3} autres terrains',
              style: MuType.caption.copyWith(color: c.textSecondary),
            ),
        ]),
        const SizedBox(height: MuSpace.s2),
        // ── Adresse ──
        section([
          head(
            'Adresse',
            trailing: v.distanceKm == null
                ? null
                : Text(
                    '${formatLevel(v.distanceKm!)} km de toi',
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
                      label: 'Itinéraire',
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
        section([head('Annulation et remboursement'), CancellationTiers(venueName: v.name)]),
        const SizedBox(height: MuSpace.s2),
        // ── Avis ──
        section(gap: MuSpace.s3, [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Semantics(
                header: true,
                child: Text('Avis', style: MuType.h3.copyWith(color: c.text)),
              ),
              if (v.rating != null) ...[
                const SizedBox(width: MuSpace.s2),
                Text(formatLevel(v.rating!), style: MuType.numM.copyWith(color: c.text)),
                const SizedBox(width: MuSpace.s1),
                Text('sur 5', style: MuType.caption.copyWith(color: c.textSecondary)),
              ],
              const Spacer(),
              if (v.reviews > 0)
                MuButton.tertiary(
                  label: 'Voir les ${v.reviews} avis',
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
                          text: 'dès ',
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
                      '$court DT le terrain · ${_Body._slotLength(d)} · à ${d.players}',
                      textAlign: TextAlign.end,
                      style: MuType.caption.copyWith(color: c.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MuSpace.s2),
              MuButton.primary(
                label: 'Réserver',
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
