import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/clock.dart';
import '../../../core/connectivity.dart';
import '../../../core/format.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/coming_soon.dart';
import '../../home/controllers/home_providers.dart';
import '../controllers/explore_controller.dart';
import '../widgets/filters_sheet.dart';

/// EXP-01 to EXP-07 · Explorer: open games, venues and tournaments around the player's zone, as a
/// list or on the map (EXP-02), with the search (EXP-05), quick filters and the filters sheet
/// (EXP-04). « Aucun résultat » (EXP-06) and « Hors ligne » (EXP-07) are states of this screen.
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key, this.tab});

  /// The segment to open on (« Réserver un terrain » opens Terrains).
  final ExploreTab? tab;

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  // EXP-01: the list ends 180 above the screen bottom, under the floating Carte · Liste switch.
  static const double _listBottom = MuSpace.s16 + MuSpace.s10 + MuSpace.s4;
  static const int _skeletons = 3;

  @override
  void initState() {
    super.initState();
    _applyTab();
  }

  @override
  void didUpdateWidget(ExploreScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tab != widget.tab) _applyTab();
  }

  void _applyTab() {
    final tab = widget.tab;
    if (tab == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(exploreProvider.notifier).setTab(tab);
    });
  }

  ExploreController get _explore => ref.read(exploreProvider.notifier);

  void _retry() {
    ref
      ..invalidate(exploreGamesProvider)
      ..invalidate(exploreVenuesProvider)
      ..invalidate(exploreTournamentsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final state = ref.watch(exploreProvider);
    final games = ref.watch(exploreGamesProvider);
    final venues = ref.watch(exploreVenuesProvider);
    final tournaments = ref.watch(exploreTournamentsProvider);
    final now = ref.watch(clockProvider)();

    final AsyncValue<Fetched<Object>> current = switch (state.tab) {
      ExploreTab.games => games,
      ExploreTab.venues => venues,
      ExploreTab.tournaments => tournaments,
    };
    final offline = current.hasError && current.error is OfflineException;
    final venueMap = venuesById(venues.value?.data ?? const []);

    final gameList = filterGames(
      games.value?.data ?? const [],
      venueMap,
      state.filters,
      state.gameSort,
      now,
    );
    final venueList = filterVenues(venues.value?.data ?? const [], state.filters, state.venueSort);
    final tournamentList = (tournaments.value?.data ?? const <MuTournament>[])
        .where(state.filters.matchesTournament)
        .toList();

    final count = switch (state.tab) {
      ExploreTab.games => gameList.length,
      ExploreTab.venues => venueList.length,
      ExploreTab.tournaments => tournamentList.length,
    };
    final canMap = state.tab != ExploreTab.tournaments;
    final showMap = canMap && state.view == ExploreView.map;

    Widget body;
    if (!current.hasValue) {
      body = current.hasError
          ? _LoadError(onRetry: _retry, offline: offline)
          : _LoadingList(tab: state.tab, count: _skeletons);
    } else if (count == 0) {
      body = _NoResults(state: state, onCreate: () => _explore.setTab(ExploreTab.venues));
    } else if (showMap) {
      body = _ExploreMap(state: state, games: gameList, venues: venueList, venueMap: venueMap);
    } else {
      body = ListView(
        padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s3, MuSpace.s4, _listBottom),
        children: [
          _CountRow(
            state: state,
            count: count,
            savedAt: offline ? current.value!.at : null,
            onSort: _explore.cycleSort,
          ),
          const SizedBox(height: MuSpace.s3),
          ...switch (state.tab) {
            ExploreTab.games => [
              for (final g in gameList)
                MuGameCard(
                  game: g,
                  onTap: () => context.push(Routes.game(g.id!)),
                  onJoin: () => context.push(Routes.game(g.id!)),
                  onWaitlist: () => context.push(Routes.game(g.id!)),
                ),
            ],
            ExploreTab.venues => [
              for (final v in venueList)
                MuVenueCard(
                  venue: v,
                  variant: MuVenueCardVariant.compact,
                  favourite: ref.watch(favouriteVenuesProvider).contains(v.id),
                  onFavouriteChanged: (_) =>
                      ref.read(favouriteVenuesProvider.notifier).toggle(v.id),
                  onTap: () => context.push(Routes.venue(v.id)),
                ),
            ],
            ExploreTab.tournaments => [
              for (final t in tournamentList)
                MuTournamentCard(
                  tournament: t,
                  onTap: () => showComingSoon(context),
                  onRegister: () => showComingSoon(context),
                  onWaitlist: () => showComingSoon(context),
                ),
            ],
          }.expand((card) => [card, const SizedBox(height: MuSpace.s3)]),
        ],
      );
    }

    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(state: state, offline: offline),
              if (offline)
                MuBanner(
                  title: 'Hors ligne',
                  detail: 'Reconnecte-toi pour réserver.',
                  tone: MuBannerTone.warning,
                  variant: MuBannerVariant.strip,
                  icon: PhosphorIcons.wifiSlash(),
                  action: MuAction('Réessayer', _retry),
                ),
              Expanded(child: body),
            ],
          ),
          if (canMap && current.hasValue && count > 0)
            Positioned(
              left: 0,
              right: 0,
              bottom: MuSpace.s4,
              child: Center(
                child: _ViewSwitch(view: state.view, onChanged: _explore.setView),
              ),
            ),
        ],
      ),
    );
  }
}

/// « Explorer », the zone chip, the search field, the segments and the quick filters.
class _Header extends ConsumerWidget {
  const _Header({required this.state, required this.offline});

  final ExploreState state;
  final bool offline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final explore = ref.read(exploreProvider.notifier);
    final f = state.filters;
    final active = f.activeCount;

    final filtersChip = Semantics(
      label: active == 0 ? 'Filtres' : 'Filtres, $active actifs',
      excludeSemantics: true,
      button: true,
      child: MuChip(
        label: 'Filtres',
        icon: PhosphorIcons.slidersHorizontal(),
        count: active == 0 ? null : active,
        onSelected: (_) => showExploreFilters(context, ref),
      ),
    );
    final sportChips = [
      for (final s in MuSport.values)
        MuChip.sport(s, selected: f.sports.contains(s), onSelected: (_) => explore.toggleSport(s)),
    ];
    final List<Widget> quick = switch (state.tab) {
      ExploreTab.games => [
        filtersChip,
        MuChip(
          label: 'Mon niveau',
          selected: explore.myLevelOn,
          onSelected: (_) => explore.toggleMyLevel(),
        ),
        MuChip(
          label: 'Ce soir',
          selected: f.when == ExploreWhen.tonight,
          onSelected: (_) => explore.toggleWhen(ExploreWhen.tonight),
        ),
        MuChip(
          label: 'Ce week-end',
          selected: f.when == ExploreWhen.weekend,
          onSelected: (_) => explore.toggleWhen(ExploreWhen.weekend),
        ),
        ...sportChips,
      ],
      ExploreTab.venues => [
        filtersChip,
        MuChip(
          label: 'Libre ce soir',
          selected: f.freeTonight,
          onSelected: (_) => explore.toggleFreeTonight(),
        ),
        MuChip(
          label: 'Éclairé',
          icon: PhosphorIcons.lightbulb(),
          selected: f.lit,
          onSelected: (_) => explore.toggleLit(),
        ),
        ...sportChips,
      ],
      ExploreTab.tournaments => [filtersChip, ...sportChips],
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(top: MuSpace.s2, bottom: MuSpace.s3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: MuSize.controlM),
                  child: Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text('Explorer', style: MuType.h2.copyWith(color: c.text)),
                        ),
                      ),
                      Semantics(
                        label: 'Zone : ${state.zone}, ${f.distanceKm} km. Changer',
                        excludeSemantics: true,
                        button: true,
                        child: MuChip(
                          label: '${state.zone} · ${f.distanceKm} km',
                          icon: PhosphorIcons.mapPin(),
                          trailingIcon: PhosphorIcons.caretDown(),
                          onSelected: (_) => showExploreFilters(context, ref),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: MuSpace.s3),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
                child: MuSearchField<void>(
                  label: 'Rechercher un terrain, une partie, un quartier',
                  placeholder: offline
                      ? 'Recherche indisponible hors ligne'
                      : 'Terrain, partie, quartier…',
                  enabled: !offline,
                  onTap: () => context.push(Routes.exploreSearch),
                ),
              ),
              const SizedBox(height: MuSpace.s3),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
                child: MuSegmentedControl<ExploreTab>(
                  semanticLabel: 'Explorer',
                  expand: true,
                  value: state.tab,
                  segments: const [
                    MuSegment(value: ExploreTab.games, label: 'Parties'),
                    MuSegment(value: ExploreTab.venues, label: 'Terrains'),
                    MuSegment(value: ExploreTab.tournaments, label: 'Tournois'),
                  ],
                  onChanged: explore.setTab,
                ),
              ),
              const SizedBox(height: MuSpace.s3),
              Semantics(
                container: true,
                label: 'Filtres rapides',
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
                  child: Row(
                    children: [
                      for (final (i, chip) in quick.indexed) ...[
                        if (i > 0) const SizedBox(width: MuSpace.s2),
                        chip,
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// « 12 parties · près de La Marsa » with the sort, or « Enregistrées à 17h42 » offline.
class _CountRow extends StatelessWidget {
  const _CountRow({
    required this.state,
    required this.count,
    required this.savedAt,
    required this.onSort,
  });

  final ExploreState state;
  final int count;
  final DateTime? savedAt;
  final VoidCallback onSort;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final (one, many, where) = switch (state.tab) {
      ExploreTab.games => ('partie', 'parties', 'près de ${state.zone}'),
      ExploreTab.venues => (
        'terrain',
        'terrains',
        state.filters.freeTonight ? 'libres ce soir' : 'près de ${state.zone}',
      ),
      ExploreTab.tournaments => ('tournoi', 'tournois', 'près de ${state.zone}'),
    };
    return Row(
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '$count', style: MuType.numS),
                TextSpan(text: ' ${count == 1 ? one : many} '),
                TextSpan(
                  text: '· $where',
                  style: TextStyle(color: c.textSecondary),
                ),
              ],
            ),
            style: MuType.label.copyWith(color: c.text),
          ),
        ),
        if (savedAt != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: MuSpace.s3, vertical: MuSpace.s1),
            decoration: ShapeDecoration(color: c.surfaceMuted, shape: const StadiumBorder()),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  PhosphorIcons.clockCounterClockwise(),
                  size: MuSize.iconXs,
                  color: c.textSecondary,
                ),
                const SizedBox(width: MuSpace.s1),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'Enregistrées à '),
                      TextSpan(
                        text: formatTime(savedAt!),
                        style: MuType.numXs.copyWith(color: c.text),
                      ),
                    ],
                  ),
                  style: MuType.caption.copyWith(color: c.textSecondary),
                ),
              ],
            ),
          )
        else if (state.tab != ExploreTab.tournaments)
          Semantics(
            label: 'Trier par : ${state.sort.label.toLowerCase()}',
            excludeSemantics: true,
            button: true,
            child: MuButton.tertiary(
              label: state.sort.label,
              leading: PhosphorIcons.arrowsDownUp(),
              size: MuButtonSize.s,
              onPressed: onSort,
            ),
          ),
      ],
    );
  }
}

/// The floating « Carte · Liste » switch.
class _ViewSwitch extends StatelessWidget {
  const _ViewSwitch({required this.view, required this.onChanged});

  final ExploreView view;
  final ValueChanged<ExploreView> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: MuRadius.mdAll,
        boxShadow: MuElevation.of(context).level2,
      ),
      child: MuSegmentedControl<ExploreView>(
        semanticLabel: 'Affichage',
        size: MuSegmentedSize.s,
        value: view,
        segments: [
          MuSegment(value: ExploreView.map, label: 'Carte', icon: PhosphorIcons.mapTrifold()),
          MuSegment(value: ExploreView.list, label: 'Liste', icon: PhosphorIcons.list()),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

/// EXP-02: the games (or venues) on the map; a pin is a venue, its card the next game there.
class _ExploreMap extends ConsumerWidget {
  const _ExploreMap({
    required this.state,
    required this.games,
    required this.venues,
    required this.venueMap,
  });

  final ExploreState state;
  final List<MuGame> games;
  final List<MuVenue> venues;
  final Map<String, MuVenue> venueMap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider).value;
    final explore = ref.read(exploreProvider.notifier);
    final List<MuMapVenue> pins;
    if (state.tab == ExploreTab.games) {
      final byVenue = <String, List<MuGame>>{};
      for (final g in games) {
        if (g.venueId != null) (byVenue[g.venueId!] ??= []).add(g);
      }
      pins = [
        for (final e in byVenue.entries)
          if (venueMap[e.key]?.position != null)
            () {
              final v = venueMap[e.key]!;
              final first = e.value.first;
              return MuMapVenue(
                id: v.id,
                name: first.title,
                sport: first.sport,
                position: v.position!,
                area: v.place,
                subtitle: first.dateLabel ?? formatDay(first.start),
                rating: v.rating,
                reviews: v.reviews,
                priceFrom: first.pricePerPlayer,
                // The card is about the next game there: its time is the one slot.
                slots: [formatTime(first.start)],
              );
            }(),
      ];
    } else {
      pins = [
        for (final v in venues)
          if (v.position != null)
            MuMapVenue(
              id: v.id,
              name: v.name,
              sport: v.sport,
              position: v.position!,
              area: v.place,
              subtitle: v.placeLabel,
              rating: v.rating,
              reviews: v.reviews,
              priceFrom: v.pricePerPerson,
              slots: v.slots,
            ),
      ];
    }

    return MuMapView.explore(
      center: me?.position ?? pins.first.position,
      user: me?.position,
      venues: pins,
      label: state.tab == ExploreTab.games
          ? 'Carte des parties autour de ${state.zone}'
          : 'Carte des terrains autour de ${state.zone}',
      selectedId: state.selectedPin,
      onSelect: explore.select,
      onSearchArea: (_) => ref
        ..invalidate(exploreGamesProvider)
        ..invalidate(exploreVenuesProvider),
      onOpen: (pin, slot) {
        if (state.tab == ExploreTab.venues) {
          context.push(Routes.venue(pin.id));
          return;
        }
        final atVenue = games.where((g) => g.venueId == pin.id);
        final game = slot == null
            ? atVenue.first
            : atVenue.firstWhere((g) => formatTime(g.start) == slot, orElse: () => atVenue.first);
        context.push(Routes.game(game.id!));
      },
    );
  }
}

/// Three skeleton cards while the list loads.
class _LoadingList extends StatelessWidget {
  const _LoadingList({required this.tab, required this.count});

  final ExploreTab tab;
  final int count;

  @override
  Widget build(BuildContext context) {
    final Widget card = switch (tab) {
      ExploreTab.games => const MuGameCard.loading(),
      ExploreTab.venues => const MuVenueCard.loading(variant: MuVenueCardVariant.compact),
      ExploreTab.tournaments => const MuTournamentCard.loading(),
    };
    return MuSkeletonGroup(
      label: switch (tab) {
        ExploreTab.games => 'Chargement des parties',
        ExploreTab.venues => 'Chargement des terrains',
        ExploreTab.tournaments => 'Chargement des tournois',
      },
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(MuSpace.s4),
        children: [
          for (var i = 0; i < count; i++) ...[if (i > 0) const SizedBox(height: MuSpace.s3), card],
        ],
      ),
    );
  }
}

/// Nothing saved to show: what to do about it.
class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry, required this.offline});

  final VoidCallback onRetry;
  final bool offline;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(MuSpace.s4),
        child: MuEmptyState(
          title: offline ? 'Pas de connexion' : 'Impossible de charger',
          description: offline
              ? 'Reconnecte-toi pour voir les parties et les terrains près de toi.'
              : 'Un souci de notre côté. Réessaie dans un instant.',
          actions: [MuButton.primary(label: 'Réessayer', onPressed: onRetry)],
        ),
      ),
    );
  }
}

/// EXP-06 · Aucun résultat: the empty state and four leads — an alert, a wider radius, one filter
/// less, or creating the game.
class _NoResults extends ConsumerWidget {
  const _NoResults({required this.state, required this.onCreate});

  final ExploreState state;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final explore = ref.read(exploreProvider.notifier);
    final f = state.filters;
    final now = ref.read(clockProvider)();
    final allGames = ref.watch(exploreGamesProvider).value?.data ?? const <MuGame>[];
    final allVenues = ref.watch(exploreVenuesProvider).value?.data ?? const <MuVenue>[];
    final venueMap = venuesById(allVenues);
    final sport = f.sports.length == 1 ? f.sports.first : null;
    final sportName = sport?.label.toLowerCase();
    final what = switch (state.tab) {
      ExploreTab.games => sport == null ? 'partie' : 'partie de $sportName',
      ExploreTab.venues => sport == null ? 'terrain' : 'terrain de $sportName',
      ExploreTab.tournaments => sport == null ? 'tournoi' : 'tournoi de $sportName',
    };
    final feminine = state.tab == ExploreTab.games;
    final noun = feminine ? 'Aucune' : 'Aucun';
    final article = feminine ? 'une' : 'un';
    final when = switch (f.when) {
      ExploreWhen.tonight => ' ce soir',
      ExploreWhen.weekend => ' ce week-end',
      ExploreWhen.day => f.day == null ? '' : ' le ${formatDay(f.day!)}',
      ExploreWhen.any => '',
    };

    List<MuGame> gamesWith(ExploreFilters filters) =>
        filterGames(allGames, venueMap, filters, ExploreSort.soonest, now);

    // « Élargir à N km »: the closest venue of the sport beyond the radius.
    final beyond =
        allVenues
            .where(
              (v) =>
                  (sport == null || v.sports.contains(sport)) && (v.distanceKm ?? 0) > f.distanceKm,
            )
            .toList()
          ..sort((a, b) => (a.distanceKm ?? 0).compareTo(b.distanceKm ?? 0));
    final widen = beyond.firstOrNull;
    final widenTo = widen == null
        ? null
        : ((widen.distanceKm! / 5).ceil() * 5).clamp(0, ExploreFilters.distanceMax);

    // « Retirer « Ce soir » »: the date filter off (and the radius wide enough if it must be).
    ExploreFilters? relaxed;
    List<MuGame> relaxedGames = const [];
    if (state.tab == ExploreTab.games && f.when != ExploreWhen.any) {
      relaxed = f.copyWith(when: ExploreWhen.any);
      relaxedGames = gamesWith(relaxed);
      if (relaxedGames.isEmpty) {
        relaxed = relaxed.copyWith(distanceMinKm: 0, distanceKm: ExploreFilters.distanceMax);
        relaxedGames = gamesWith(relaxed);
      }
    }
    final whenLabel = switch (f.when) {
      ExploreWhen.tonight => 'Ce soir',
      ExploreWhen.weekend => 'Ce week-end',
      _ => f.day == null ? 'la date' : formatDay(f.day!),
    };

    String gameLine(List<MuGame> games) {
      final n = games.length;
      final kind = sport == null ? 'partie' : 'partie de $sportName';
      if (n == 1) {
        final g = games.first;
        return '1 $kind ${formatDateTime(g.start)}';
      }
      return '$n ${sport == null ? 'parties' : 'parties de $sportName'}';
    }

    final alertOn = sport != null && state.alertTypes.contains(sport);
    final rows = <Widget>[
      _LeadRow(
        icon: PhosphorIcons.bellRinging(),
        accent: true,
        title: 'Préviens-moi',
        detail: 'Dès qu’$article $what s’ouvre',
        trailing: MuSwitch(
          value: alertOn,
          semanticLabel: 'Préviens-moi dès qu’$article $what s’ouvre près de ${state.zone}',
          onChanged: sport == null
              ? (_) => showComingSoon(context)
              : (_) => explore.toggleAlert(sport),
        ),
      ),
      if (widen != null && widenTo != null)
        _LeadRow(
          icon: PhosphorIcons.mapPinArea(),
          title: 'Élargir à $widenTo km',
          detail:
              '${widen.name}, ${elideA(widen.place)}, est à ${formatLevel(widen.distanceKm!)} km',
          semanticLabel: 'Élargir la distance à $widenTo km',
          onTap: () => explore.setFilters(f.copyWith(distanceKm: widenTo)),
        ),
      if (relaxed != null && relaxedGames.isNotEmpty)
        _LeadRow(
          icon: PhosphorIcons.calendarBlank(),
          title: 'Retirer « $whenLabel »',
          detail: gameLine(relaxedGames),
          semanticLabel: 'Retirer le filtre $whenLabel',
          onTap: () => explore.setFilters(relaxed!),
        ),
      if (state.tab == ExploreTab.games)
        _LeadRow(
          icon: PhosphorIcons.plus(),
          title: sport == null ? 'Créer une partie' : 'Créer une partie de $sportName',
          detail: 'Réserve un terrain, on complète l’équipe',
          onTap: onCreate,
        ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s2, MuSpace.s4, MuSpace.s16 * 2),
      children: [
        MuEmptyState(
          compact: true,
          illustration: MuEmptyIllustration.results,
          title: '$noun $what$when',
          description:
              'Rien à moins de ${f.distanceKm} km de ${state.zone} pour l’instant. Essaie une de '
              'ces pistes :',
        ),
        const SizedBox(height: MuSpace.s4),
        MuCardSurface(
          padding: const EdgeInsets.symmetric(vertical: MuSpace.s1 / 2),
          child: Column(
            children: [
              for (final (i, row) in rows.indexed) ...[
                if (i > 0) Divider(height: 1, thickness: 1, indent: MuSpace.s4, color: c.border),
                row,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// « à Ennasr », « au Lac 2 »… kept simple: « à » before a place name.
String elideA(String place) => 'à $place';

/// One lead of EXP-06: a 40 tile, title and detail, then a switch or a chevron.
class _LeadRow extends StatelessWidget {
  const _LeadRow({
    required this.icon,
    required this.title,
    required this.detail,
    this.accent = false,
    this.trailing,
    this.onTap,
    this.semanticLabel,
  });

  final IconData icon;
  final String title;
  final String detail;
  final bool accent;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4, vertical: MuSpace.s3),
      child: Row(
        children: [
          Container(
            width: MuSize.controlM,
            height: MuSize.controlM,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent ? c.accent : c.surfaceMuted,
              borderRadius: MuRadius.smAll,
            ),
            child: Icon(icon, size: MuSize.iconS, color: accent ? c.onAccent : c.text),
          ),
          const SizedBox(width: MuSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: MuType.label.copyWith(color: c.text)),
                const SizedBox(height: MuSpace.s1 / 2),
                Text(detail, style: MuType.caption.copyWith(color: c.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: MuSpace.s3),
          trailing ??
              MuDirectionalIcon(
                PhosphorIcons.caretRight(),
                size: MuSize.iconS,
                color: c.textSecondary,
              ),
        ],
      ),
    );
    if (onTap == null) return content;
    return Semantics(
      button: true,
      label: semanticLabel ?? title,
      excludeSemantics: true,
      child: InkWell(onTap: onTap, child: content),
    );
  }
}
