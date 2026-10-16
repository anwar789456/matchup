import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/clock.dart';
import '../../../core/format.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../home/controllers/home_providers.dart';
import '../controllers/explore_controller.dart';

/// EXP-04 · Filtres: the full-height sheet over Explorer. Changes stay in a draft until « Afficher
/// 12 parties », whose count follows the draft; « Réinitialiser » clears it; closing drops it.
Future<void> showExploreFilters(BuildContext context, WidgetRef ref) async {
  final draft = ValueNotifier(ref.read(exploreProvider).filters);
  await MuBottomSheet.show<void>(
    context,
    title: 'Filtres',
    height: MuSheetHeight.full,
    snapPoints: const [MuSheetHeight.full],
    child: _FiltersBody(draft: draft),
    footer: _FiltersFooter(draft: draft),
  );
  draft.dispose();
}

/// The number of results [filters] would give on the current segment.
int _resultCount(WidgetRef ref, ExploreFilters filters) {
  final state = ref.read(exploreProvider);
  final now = ref.read(clockProvider)();
  final venues = ref.read(exploreVenuesProvider).value?.data ?? const [];
  return switch (state.tab) {
    ExploreTab.games => filterGames(
      ref.read(exploreGamesProvider).value?.data ?? const [],
      venuesById(venues),
      filters,
      state.gameSort,
      now,
    ).length,
    ExploreTab.venues => filterVenues(venues, filters, state.venueSort).length,
    ExploreTab.tournaments =>
      (ref.read(exploreTournamentsProvider).value?.data ?? const [])
          .where(filters.matchesTournament)
          .length,
  };
}

class _FiltersFooter extends ConsumerWidget {
  const _FiltersFooter({required this.draft});

  final ValueNotifier<ExploreFilters> draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(exploreProvider).tab;
    return ValueListenableBuilder(
      valueListenable: draft,
      builder: (context, filters, _) {
        final n = _resultCount(ref, filters);
        final label = switch (tab) {
          ExploreTab.games => countLabel(n, 'partie', 'parties'),
          ExploreTab.venues => countLabel(n, 'terrain', 'terrains'),
          ExploreTab.tournaments => countLabel(n, 'tournoi', 'tournois'),
        };
        return Row(
          children: [
            MuButton.secondary(
              label: 'Réinitialiser',
              size: MuButtonSize.xl,
              onPressed: () => draft.value = ref.read(exploreProvider.notifier).cleared,
            ),
            const SizedBox(width: MuSpace.s3),
            Expanded(
              child: MuButton.primary(
                label: 'Afficher $label',
                size: MuButtonSize.xl,
                fullWidth: true,
                onPressed: () {
                  ref.read(exploreProvider.notifier).setFilters(draft.value);
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FiltersBody extends ConsumerWidget {
  const _FiltersBody({required this.draft});

  final ValueNotifier<ExploreFilters> draft;

  static const _levelBands = [
    MuRangeBand(1, 2.5, 'Débutant'),
    MuRangeBand(2.5, 4, 'Intermédiaire'),
    MuRangeBand(4, 5.5, 'Avancé'),
    MuRangeBand(5.5, 7, 'Expert'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final levels = ref.watch(meProvider).value?.levels ?? const {};

    return ValueListenableBuilder(
      valueListenable: draft,
      builder: (context, f, _) {
        void set(ExploreFilters next) => draft.value = next;

        Widget group(String? title, List<Widget> children, {bool last = false}) => Container(
          padding: const EdgeInsets.symmetric(vertical: MuSpace.s4),
          decoration: BoxDecoration(
            border: last ? null : Border(bottom: BorderSide(color: c.border)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title != null) ...[
                Semantics(
                  header: true,
                  child: Text(title, style: MuType.label.copyWith(color: c.text)),
                ),
                const SizedBox(height: MuSpace.s3),
              ],
              for (final (i, child) in children.indexed) ...[
                if (i > 0) const SizedBox(height: MuSpace.s3),
                child,
              ],
            ],
          ),
        );

        Widget wrap(List<Widget> chips) =>
            Wrap(spacing: MuSpace.s2, runSpacing: MuSpace.s2, children: chips);

        Future<void> pickDay() async {
          final now = ref.read(clockProvider)();
          final day = await showDatePicker(
            context: context,
            initialDate: f.day ?? now,
            firstDate: DateTime(now.year, now.month, now.day),
            lastDate: now.add(const Duration(days: 60)),
            locale: const Locale('fr'),
          );
          if (day != null) set(f.copyWith(when: ExploreWhen.day, day: day));
        }

        final levelText = [
          for (final e in levels.entries) '${formatLevel(e.value)} en ${e.key.label.toLowerCase()}',
        ].join(', ');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            group('Sport', [
              wrap([
                for (final s in MuSport.values)
                  MuChip.sport(
                    s,
                    selected: f.sports.contains(s),
                    onSelected: (_) {
                      final sports = {...f.sports};
                      if (!sports.remove(s)) sports.add(s);
                      set(f.copyWith(sports: sports));
                    },
                  ),
              ]),
            ]),
            group('Date et heure', [
              Semantics(
                container: true,
                label: 'Date',
                child: wrap([
                  MuChip(
                    label: 'Ce soir',
                    kind: MuChipKind.choice,
                    selected: f.when == ExploreWhen.tonight,
                    onSelected: (_) => set(
                      f.copyWith(
                        when: f.when == ExploreWhen.tonight ? ExploreWhen.any : ExploreWhen.tonight,
                      ),
                    ),
                  ),
                  MuChip(
                    label: 'Ce week-end',
                    kind: MuChipKind.choice,
                    selected: f.when == ExploreWhen.weekend,
                    onSelected: (_) => set(
                      f.copyWith(
                        when: f.when == ExploreWhen.weekend ? ExploreWhen.any : ExploreWhen.weekend,
                      ),
                    ),
                  ),
                  MuChip(
                    label: f.when == ExploreWhen.day && f.day != null
                        ? formatDay(f.day!)
                        : 'Choisir',
                    icon: PhosphorIcons.calendarBlank(),
                    selected: f.when == ExploreWhen.day,
                    onSelected: (_) => f.when == ExploreWhen.day
                        ? set(f.copyWith(when: ExploreWhen.any))
                        : pickDay(),
                  ),
                ]),
              ),
              wrap([
                for (final t in ExploreTime.values)
                  MuChip(
                    label: t.label,
                    selected: f.times.contains(t),
                    onSelected: (_) {
                      final times = {...f.times};
                      if (!times.remove(t)) times.add(t);
                      set(f.copyWith(times: times));
                    },
                  ),
              ]),
            ]),
            group(null, [
              MuRangeSlider(
                label: 'Niveau des joueurs',
                values:
                    f.level ?? const RangeValues(ExploreFilters.levelMin, ExploreFilters.levelMax),
                min: ExploreFilters.levelMin,
                max: ExploreFilters.levelMax,
                step: 0.5,
                format: formatLevel,
                bands: _levelBands,
                minLabel: 'Niveau minimum',
                maxLabel: 'Niveau maximum',
                onChanged: (r) => set(
                  f.copyWith(
                    level: () =>
                        r.start == ExploreFilters.levelMin && r.end == ExploreFilters.levelMax
                        ? null
                        : r,
                  ),
                ),
              ),
              if (levelText.isNotEmpty)
                Text(
                  'Autour de ton niveau : $levelText.',
                  style: MuType.caption.copyWith(color: c.textSecondary),
                ),
            ]),
            group(null, [
              MuRangeSlider(
                label: 'Prix par personne',
                values: f.price ?? const RangeValues(0, ExploreFilters.priceMax),
                min: 0,
                max: ExploreFilters.priceMax,
                format: (v) => formatDT(v.round()),
                minLabel: 'Prix minimum',
                maxLabel: 'Prix maximum',
                onChanged: (r) => set(
                  f.copyWith(
                    price: () => r.start == 0 && r.end == ExploreFilters.priceMax ? null : r,
                  ),
                ),
              ),
            ]),
            group(null, [
              MuRangeSlider(
                label: 'Distance',
                values: RangeValues(f.distanceMinKm.toDouble(), f.distanceKm.toDouble()),
                min: 0,
                max: ExploreFilters.distanceMax.toDouble(),
                format: (v) => '${v.round()} km',
                formatRange: (lo, hi) =>
                    lo == 0 ? 'Jusqu’à ${hi.round()} km' : '${lo.round()} – ${hi.round()} km',
                minLabel: 'Distance minimum',
                maxLabel: 'Distance maximum',
                onChanged: (r) =>
                    set(f.copyWith(distanceMinKm: r.start.round(), distanceKm: r.end.round())),
              ),
            ]),
            group('Type de partie', [
              MuSegmentedControl<ExploreGameType>(
                semanticLabel: 'Type de partie',
                expand: true,
                value: f.type,
                segments: [
                  for (final t in ExploreGameType.values) MuSegment(value: t, label: t.label),
                ],
                onChanged: (t) => set(f.copyWith(type: t)),
              ),
            ]),
            group('Terrain', [
              wrap([
                MuChip(
                  label: 'Extérieur',
                  icon: PhosphorIcons.sun(),
                  selected: f.outdoor,
                  onSelected: (v) => set(f.copyWith(outdoor: v)),
                ),
                MuChip(
                  label: 'Intérieur',
                  icon: PhosphorIcons.umbrella(),
                  selected: f.indoor,
                  onSelected: (v) => set(f.copyWith(indoor: v)),
                ),
              ]),
              MuSwitch(
                value: f.lit,
                label: 'Éclairé le soir',
                icon: PhosphorIcons.lightbulb(),
                labelAtStart: true,
                onChanged: (v) => set(f.copyWith(lit: v)),
              ),
            ]),
            group('Équipements', last: true, [
              wrap([
                for (final a in ExploreAmenity.values)
                  MuChip(
                    label: a.label,
                    icon: switch (a) {
                      ExploreAmenity.changing => PhosphorIcons.shower(),
                      ExploreAmenity.parking => PhosphorIcons.carSimple(),
                      ExploreAmenity.cafe => PhosphorIcons.coffee(),
                      ExploreAmenity.bibs => PhosphorIcons.tShirt(),
                    },
                    selected: f.amenities.contains(a),
                    onSelected: (_) {
                      final amenities = {...f.amenities};
                      if (!amenities.remove(a)) amenities.add(a);
                      set(f.copyWith(amenities: amenities));
                    },
                  ),
              ]),
            ]),
          ],
        );
      },
    );
  }
}
