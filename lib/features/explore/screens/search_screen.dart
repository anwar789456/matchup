import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../core/search.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../controllers/explore_controller.dart';
import '../data/search_repository.dart';
import '../../../l10n/l10n.dart';

/// What a search row opens.
sealed class _Hit {
  const _Hit();
}

class _ZoneHit extends _Hit {
  const _ZoneHit(this.name);

  final String name;
}

class _VenueHit extends _Hit {
  const _VenueHit(this.id);

  final String id;
}

class _GameHit extends _Hit {
  const _GameHit(this.id);

  final String id;
}

class _PlayerHit extends _Hit {
  const _PlayerHit(this.name);

  final String name;
}

/// EXP-05 · Recherche: recent searches, then zones, venues, games and players matching the query
/// (two per group), with the matched letters marked.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  // EXP-05 shows two rows per group.
  static const int _perGroup = 2;
  static const double _tile = MuSize.controlM;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _matches(String? text) =>
      text != null && _query.isNotEmpty && foldAccents(text).contains(foldAccents(_query));

  void _open(_Hit hit) {
    ref.read(recentSearchesProvider.notifier).add(_query);
    switch (hit) {
      case _ZoneHit(:final name):
        ref.read(exploreProvider.notifier).setZone(name);
        context.pop();
      case _VenueHit(:final id):
        context.push(Routes.venue(id));
      case _GameHit(:final id):
        context.push(Routes.game(id));
      case _PlayerHit(:final name):
        context.push(Routes.player(name));
    }
  }

  /// « Foot 5v5 femmes · Arena Five », « Padel · Smash Padel Club ».
  static String _gameName(MuGame g) {
    final kind = switch (g.sport) {
      MuSport.football => l10n.foot5v5,
      MuSport.padel => l10n.padel,
      MuSport.basketball => l10n.basket,
    };
    final type = g.gameType == 'Mixte' ? '' : ' ${g.gameType.toLowerCase()}';
    return '$kind$type · ${g.venue}';
  }

  Widget _sportTile(MuSport sport) {
    final c = context.mu;
    return Container(
      width: _tile,
      height: _tile,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: sport.soft(c), borderRadius: MuRadius.smAll),
      child: MuSportIcon(sport, size: MuSize.iconS, color: sport.text(c)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final recent = ref.watch(recentSearchesProvider);
    final zones = ref.watch(searchZonesProvider).value ?? const [];
    final players = ref.watch(searchPlayersProvider).value ?? const [];
    final games = ref.watch(exploreGamesProvider).value?.data ?? const <MuGame>[];
    final venues = ref.watch(exploreVenuesProvider).value?.data ?? const <MuVenue>[];
    final zone = ref.watch(exploreProvider).zone;
    final radius = ref.watch(exploreProvider).filters.distanceKm;
    final recentKeys = {for (final r in recent) foldAccents(r)};
    bool fresh(String title) => !recentKeys.contains(foldAccents(title));

    final groups = _query.isEmpty
        ? const <MuSearchGroup<_Hit>>[]
        : [
            MuSearchGroup<_Hit>(
              label: l10n.zones,
              items: [
                for (final z in zones)
                  if (_matches(z.name))
                    () {
                      final inZone = z.venueIds == null
                          ? venues.where((v) => (v.distanceKm ?? 0) <= radius)
                          : venues.where((v) => z.venueIds!.contains(v.id));
                      final ids = {for (final v in inZone) v.id};
                      final nGames = games.where((g) => ids.contains(g.venueId)).length;
                      return MuSearchSuggestion<_Hit>(
                        value: _ZoneHit(z.name),
                        title: z.name,
                        subtitle:
                            '${countLabel(nGames, 'partie', 'parties')} · '
                            '${countLabel(ids.length, 'terrain', 'terrains')}',
                        leading: Container(
                          width: _tile,
                          height: _tile,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: c.surfaceMuted,
                            borderRadius: MuRadius.smAll,
                          ),
                          child: Icon(
                            PhosphorIcons.mapPin(),
                            size: MuSize.iconS,
                            color: c.textSecondary,
                          ),
                        ),
                      );
                    }(),
              ],
            ),
            MuSearchGroup<_Hit>(
              label: l10n.terrains,
              items: [
                for (final v in venues)
                  if (fresh(v.name) &&
                      (_matches(v.name) ||
                          _matches('${v.sport.label} · ${v.place}')))
                    MuSearchSuggestion<_Hit>(
                      value: _VenueHit(v.id),
                      title: v.name,
                      subtitle: '${v.sport.label} · ${v.place}',
                      leading: _sportTile(v.sport),
                    ),
              ],
            ),
            MuSearchGroup<_Hit>(
              label: l10n.parties,
              items: [
                for (final g in games)
                  if (_matches(_gameName(g)) || _matches(g.place))
                    MuSearchSuggestion<_Hit>(
                      value: _GameHit(g.id!),
                      title: _gameName(g),
                      subtitle:
                          l10n.pers(g.dateLabel?.toLowerCase() ?? formatDay(g.start), g.isFull ? 'complet' : countLabel(g.spotsLeft, 'place', 'places'), formatDT(g.pricePerPlayer)),
                      trailing: formatTime(g.start),
                      leading: _sportTile(g.sport),
                    ),
              ],
            ),
            MuSearchGroup<_Hit>(
              label: l10n.joueurs,
              items: [
                for (final p in players)
                  if (fresh(p.name) && (_matches(p.name) || _matches(p.place)))
                    MuSearchSuggestion<_Hit>(
                      value: _PlayerHit(p.name),
                      title: p.name,
                      subtitle: '${formatLevel(p.level)} · ${levelBand(p.level)} · ${p.place}',
                      leading: MuAvatar(name: p.name, size: MuAvatarSize.s),
                    ),
              ],
            ),
          ];

    return Scaffold(
      backgroundColor: c.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(
            MuSpace.s2,
            MuSpace.s2,
            MuSpace.s4,
            MuSpace.s8,
          ),
          children: [
            Row(
              children: [
                MuIconButton(
                  icon: PhosphorIcons.arrowLeft(),
                  label: l10n.retour,
                  size: MuIconButtonSize.l,
                  onPressed: () => context.canPop() ? context.pop() : context.go(Routes.explore),
                ),
                const SizedBox(width: MuSpace.s1),
                Expanded(
                  child: MuSearchField<void>(
                    label: l10n.rechercher,
                    placeholder: l10n.terrainPartieQuartier,
                    controller: _controller,
                    autofocus: true,
                    onChanged: (q) => setState(() => _query = q),
                    onSubmitted: (q) => ref.read(recentSearchesProvider.notifier).add(q),
                  ),
                ),
              ],
            ),
            const SizedBox(height: MuSpace.s2),
            MuSearchResults<_Hit>(
              query: _query,
              recent: recent,
              groups: groups,
              maxPerGroup: _perGroup,
              onSelected: _open,
              onRecent: (r) {
                _controller.text = r;
                _controller.selection = TextSelection.collapsed(offset: r.length);
              },
              onRemoveRecent: ref.read(recentSearchesProvider.notifier).remove,
              onClearRecent: ref.read(recentSearchesProvider.notifier).clear,
              emptyAction: MuButton.secondary(
                label: l10n.voirLesTerrainsPresDe,
                onPressed: () {
                  ref.read(exploreProvider.notifier).setTab(ExploreTab.venues);
                  context.canPop() ? context.pop() : context.go(Routes.explore);
                },
              ),
            ),
            if (_query.isEmpty && recent.isEmpty)
              Padding(
                padding: const EdgeInsets.all(MuSpace.s4),
                child: Text(
                  l10n.chercheUnQuartierCommeUn(zone),
                  style: MuType.body.copyWith(color: c.textSecondary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
