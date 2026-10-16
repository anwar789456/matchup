import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../../../core/format.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../explore/data/tournaments_repository.dart';
import '../../games/data/games_repository.dart';
import '../../home/controllers/home_providers.dart';
import '../../venue/data/venues_repository.dart';

/// Explorer's segments (« Parties · Terrains · Tournois ») and views (« Carte · Liste »).
enum ExploreTab { games, venues, tournaments }

enum ExploreView { list, map }

/// « Ce soir », « Ce week-end » or a chosen day.
enum ExploreWhen { any, tonight, weekend, day }

enum ExploreTime {
  morning('Matin'),
  afternoon('Après-midi'),
  evening('Soir · après 18h');

  const ExploreTime(this.label);

  final String label;

  bool matches(DateTime d) => switch (this) {
    ExploreTime.morning => d.hour < 12,
    ExploreTime.afternoon => d.hour >= 12 && d.hour < 18,
    ExploreTime.evening => d.hour >= 18,
  };
}

enum ExploreGameType {
  all('Toutes'),
  mixte('Mixte'),
  femmes('Femmes'),
  hommes('Hommes');

  const ExploreGameType(this.label);

  final String label;
}

enum ExploreSort {
  recommended('Recommandées'),
  closest('Plus proches'),
  soonest('Plus tôt'),
  cheapest('Moins chères');

  const ExploreSort(this.label);

  final String label;
}

/// Equipment filters of EXP-04, each standing for the venue amenities it needs.
enum ExploreAmenity {
  changing('Vestiaires et douches', [MuAmenity.changingRooms, MuAmenity.showers]),
  parking('Parking', [MuAmenity.parking]),
  cafe('Café', [MuAmenity.cafe]),
  bibs('Chasubles', [MuAmenity.bibs]);

  const ExploreAmenity(this.label, this.needs);

  final String label;
  final List<MuAmenity> needs;
}

/// The filters (EXP-04 and the quick chips). Price and level ranges are null when open.
@immutable
class ExploreFilters {
  const ExploreFilters({
    this.sports = const {},
    this.when = ExploreWhen.any,
    this.day,
    this.times = const {ExploreTime.evening},
    this.level,
    this.price,
    this.distanceMinKm = 0,
    this.distanceKm = defaultDistance,
    this.type = ExploreGameType.all,
    this.outdoor = false,
    this.indoor = false,
    this.lit = false,
    this.amenities = const {},
    this.freeTonight = true,
  });

  final Set<MuSport> sports;
  final ExploreWhen when;
  final DateTime? day;
  final Set<ExploreTime> times;

  /// Players' level range (« Mon niveau » sets it around the player's levels).
  final RangeValues? level;

  /// Price per person, never the court price.
  final RangeValues? price;
  final int distanceMinKm;
  final int distanceKm;
  final ExploreGameType type;
  final bool outdoor;
  final bool indoor;

  /// « Éclairé le soir ».
  final bool lit;
  final Set<ExploreAmenity> amenities;

  /// Terrains: « Libre ce soir ».
  final bool freeTonight;

  static const int defaultDistance = 10;
  static const double levelMin = 1;
  static const double levelMax = 7;
  static const double priceMax = 50;
  static const int distanceMax = 20;

  /// The filters counted on the « Filtres » chip (the zone's distance is on the zone chip).
  int get activeCount => [
    sports.isNotEmpty,
    when != ExploreWhen.any,
    times.isNotEmpty,
    level != null,
    price != null,
    type != ExploreGameType.all,
    outdoor || indoor,
    lit,
    amenities.isNotEmpty,
  ].where((on) => on).length;

  ExploreFilters copyWith({
    Set<MuSport>? sports,
    ExploreWhen? when,
    DateTime? day,
    Set<ExploreTime>? times,
    RangeValues? Function()? level,
    RangeValues? Function()? price,
    int? distanceMinKm,
    int? distanceKm,
    ExploreGameType? type,
    bool? outdoor,
    bool? indoor,
    bool? lit,
    Set<ExploreAmenity>? amenities,
    bool? freeTonight,
  }) => ExploreFilters(
    sports: sports ?? this.sports,
    when: when ?? this.when,
    day: day ?? this.day,
    times: times ?? this.times,
    level: level == null ? this.level : level(),
    price: price == null ? this.price : price(),
    distanceMinKm: distanceMinKm ?? this.distanceMinKm,
    distanceKm: distanceKm ?? this.distanceKm,
    type: type ?? this.type,
    outdoor: outdoor ?? this.outdoor,
    indoor: indoor ?? this.indoor,
    lit: lit ?? this.lit,
    amenities: amenities ?? this.amenities,
    freeTonight: freeTonight ?? this.freeTonight,
  );

  @override
  bool operator ==(Object other) =>
      other is ExploreFilters &&
      _setEq(other.sports, sports) &&
      other.when == when &&
      other.day == day &&
      _setEq(other.times, times) &&
      other.level == level &&
      other.price == price &&
      other.distanceMinKm == distanceMinKm &&
      other.distanceKm == distanceKm &&
      other.type == type &&
      other.outdoor == outdoor &&
      other.indoor == indoor &&
      other.lit == lit &&
      _setEq(other.amenities, amenities) &&
      other.freeTonight == freeTonight;

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(sports),
    when,
    day,
    Object.hashAllUnordered(times),
    level,
    price,
    distanceMinKm,
    distanceKm,
    type,
    outdoor,
    indoor,
    lit,
    Object.hashAllUnordered(amenities),
    freeTonight,
  );

  static bool _setEq<T>(Set<T> a, Set<T> b) => a.length == b.length && a.containsAll(b);

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  bool _whenMatches(DateTime start, DateTime now) => switch (when) {
    ExploreWhen.any => true,
    ExploreWhen.tonight => _sameDay(start, now) && start.hour >= 18,
    ExploreWhen.weekend =>
      start.weekday >= DateTime.saturday &&
          start.difference(DateTime(now.year, now.month, now.day)).inDays < 7,
    ExploreWhen.day => day != null && _sameDay(start, day!),
  };

  bool _distanceMatches(double? km) => (km ?? 0) >= distanceMinKm && (km ?? 0) <= distanceKm;

  bool _venueMatches(MuVenue? v) {
    if (v == null) return true;
    final covered = v.amenities.contains(MuAmenity.covered);
    if (indoor && !outdoor && !covered) return false;
    if (outdoor && !indoor && covered && v.sports.contains(MuSport.basketball)) return false;
    if (lit && !v.amenities.contains(MuAmenity.lighting)) return false;
    for (final a in amenities) {
      if (!a.needs.every(v.amenities.contains)) return false;
    }
    return true;
  }

  /// Whether an open game passes every filter (its venue gives equipment and lighting).
  bool matchesGame(MuGame g, MuVenue? venue, DateTime now) {
    if (g.start.isBefore(now)) return false;
    if (sports.isNotEmpty && !sports.contains(g.sport)) return false;
    if (!_whenMatches(g.start, now)) return false;
    if (times.isNotEmpty && !times.any((t) => t.matches(g.start))) return false;
    final l = level;
    if (l != null && g.levelMin != null && g.levelMax != null) {
      if (g.levelMax! < l.start || g.levelMin! > l.end) return false;
    }
    final p = price;
    if (p != null && (g.pricePerPlayer < p.start || g.pricePerPlayer > p.end)) return false;
    if (!_distanceMatches(g.distanceKm)) return false;
    if (type != ExploreGameType.all && g.gameType != type.label) return false;
    return _venueMatches(venue);
  }

  /// Whether a venue passes the filters that apply to venues.
  bool matchesVenue(MuVenue v) {
    if (sports.isNotEmpty && !v.sports.any(sports.contains)) return false;
    final p = price;
    if (p != null && (v.pricePerPerson < p.start || v.pricePerPerson > p.end)) return false;
    if (!_distanceMatches(v.distanceKm)) return false;
    if (freeTonight && v.slots.isEmpty) return false;
    return _venueMatches(v);
  }

  bool matchesTournament(MuTournament t) => sports.isEmpty || sports.contains(t.sport);
}

/// Data with the time it was fetched (« Enregistrées à 17h42 » when offline).
@immutable
class Fetched<T> {
  const Fetched(this.data, this.at);

  final T data;
  final DateTime at;
}

final exploreGamesProvider = FutureProvider<Fetched<List<MuGame>>>((ref) async {
  final games = await ref.watch(gamesRepositoryProvider).openGames();
  return Fetched(games, ref.read(clockProvider)());
});

final exploreVenuesProvider = FutureProvider<Fetched<List<MuVenue>>>((ref) async {
  final venues = await ref.watch(venuesRepositoryProvider).venues();
  return Fetched(venues, ref.read(clockProvider)());
});

final exploreTournamentsProvider = FutureProvider<Fetched<List<MuTournament>>>((ref) async {
  final tournaments = await ref.watch(tournamentsRepositoryProvider).nearby();
  return Fetched(tournaments, ref.read(clockProvider)());
});

/// What Explorer shows: segment, view, zone, filters, sort and the selected map pin.
@immutable
class ExploreState {
  const ExploreState({
    this.tab = ExploreTab.games,
    this.view = ExploreView.list,
    this.zone = 'La Marsa',
    this.filters = const ExploreFilters(),
    this.gameSort = ExploreSort.recommended,
    this.venueSort = ExploreSort.closest,
    this.selectedPin,
    this.alertTypes = const {},
  });

  final ExploreTab tab;
  final ExploreView view;
  final String zone;
  final ExploreFilters filters;
  final ExploreSort gameSort;
  final ExploreSort venueSort;
  final String? selectedPin;

  /// « Préviens-moi » alerts switched on, per sport.
  final Set<MuSport> alertTypes;

  ExploreSort get sort => tab == ExploreTab.venues ? venueSort : gameSort;

  ExploreState copyWith({
    ExploreTab? tab,
    ExploreView? view,
    String? zone,
    ExploreFilters? filters,
    ExploreSort? gameSort,
    ExploreSort? venueSort,
    String? Function()? selectedPin,
    Set<MuSport>? alertTypes,
  }) => ExploreState(
    tab: tab ?? this.tab,
    view: view ?? this.view,
    zone: zone ?? this.zone,
    filters: filters ?? this.filters,
    gameSort: gameSort ?? this.gameSort,
    venueSort: venueSort ?? this.venueSort,
    selectedPin: selectedPin == null ? this.selectedPin : selectedPin(),
    alertTypes: alertTypes ?? this.alertTypes,
  );
}

class ExploreController extends Notifier<ExploreState> {
  @override
  ExploreState build() {
    final me = ref.read(meProvider).value;
    return ExploreState(
      zone: me?.zone ?? 'La Marsa',
      filters: ExploreFilters(level: myLevelRange(me?.levels.values)),
    );
  }

  /// « Mon niveau »: from the lowest of the player's levels to one point above the highest
  /// (3,0 in football and 3,5 in padel give 3,0–4,5).
  static RangeValues myLevelRange(Iterable<double>? levels) {
    final l = (levels == null || levels.isEmpty) ? const [3.0, 3.5] : levels.toList();
    final lo = l.reduce((a, b) => a < b ? a : b);
    final hi = l.reduce((a, b) => a > b ? a : b) + 1;
    return RangeValues(
      lo.clamp(ExploreFilters.levelMin, ExploreFilters.levelMax),
      hi.clamp(ExploreFilters.levelMin, ExploreFilters.levelMax),
    );
  }

  RangeValues get _myLevel => myLevelRange(ref.read(meProvider).value?.levels.values);

  void setTab(ExploreTab tab) => state = state.copyWith(tab: tab, selectedPin: () => null);

  void setView(ExploreView view) => state = state.copyWith(view: view, selectedPin: () => null);

  void select(String? pin) => state = state.copyWith(selectedPin: () => pin);

  void setZone(String zone) => state = state.copyWith(zone: zone);

  void setFilters(ExploreFilters filters) => state = state.copyWith(filters: filters);

  /// The next sort order (games: recommended → closest → soonest → cheapest; venues: closest →
  /// cheapest).
  void cycleSort() {
    if (state.tab == ExploreTab.venues) {
      state = state.copyWith(
        venueSort: state.venueSort == ExploreSort.closest
            ? ExploreSort.cheapest
            : ExploreSort.closest,
      );
    } else {
      const order = ExploreSort.values;
      state = state.copyWith(gameSort: order[(order.indexOf(state.gameSort) + 1) % order.length]);
    }
  }

  bool get myLevelOn => state.filters.level == _myLevel;

  void toggleMyLevel() => state = state.copyWith(
    filters: state.filters.copyWith(level: () => myLevelOn ? null : _myLevel),
  );

  void toggleWhen(ExploreWhen when) => state = state.copyWith(
    filters: state.filters.copyWith(when: state.filters.when == when ? ExploreWhen.any : when),
  );

  void toggleSport(MuSport sport) {
    final sports = {...state.filters.sports};
    if (!sports.remove(sport)) sports.add(sport);
    state = state.copyWith(filters: state.filters.copyWith(sports: sports));
  }

  void toggleLit() =>
      state = state.copyWith(filters: state.filters.copyWith(lit: !state.filters.lit));

  void toggleFreeTonight() => state = state.copyWith(
    filters: state.filters.copyWith(freeTonight: !state.filters.freeTonight),
  );

  void toggleAlert(MuSport sport) {
    final alerts = {...state.alertTypes};
    if (!alerts.remove(sport)) alerts.add(sport);
    state = state.copyWith(alertTypes: alerts);
  }

  /// « Réinitialiser »: no filter at all (not even « Mon niveau »).
  ExploreFilters get cleared => const ExploreFilters(times: {}, freeTonight: false);
}

final exploreProvider = NotifierProvider<ExploreController, ExploreState>(ExploreController.new);

/// The venues by id, for the games' equipment and positions.
Map<String, MuVenue> venuesById(Iterable<MuVenue> venues) => {for (final v in venues) v.id: v};

/// The open games passing [filters], in [sort] order.
List<MuGame> filterGames(
  List<MuGame> games,
  Map<String, MuVenue> venues,
  ExploreFilters filters,
  ExploreSort sort,
  DateTime now,
) {
  final out = [
    for (final g in games)
      if (filters.matchesGame(g, venues[g.venueId], now)) g,
  ];
  switch (sort) {
    case ExploreSort.recommended:
      break;
    case ExploreSort.closest:
      out.sort((a, b) => (a.distanceKm ?? 0).compareTo(b.distanceKm ?? 0));
    case ExploreSort.soonest:
      out.sort((a, b) => a.start.compareTo(b.start));
    case ExploreSort.cheapest:
      out.sort((a, b) => a.pricePerPlayer.compareTo(b.pricePerPlayer));
  }
  return out;
}

/// The venues passing [filters], in [sort] order.
List<MuVenue> filterVenues(List<MuVenue> venues, ExploreFilters filters, ExploreSort sort) {
  final out = [
    for (final v in venues)
      if (filters.matchesVenue(v)) v,
  ];
  if (sort == ExploreSort.cheapest) {
    out.sort((a, b) => a.pricePerPerson.compareTo(b.pricePerPerson));
  } else {
    out.sort((a, b) => (a.distanceKm ?? 0).compareTo(b.distanceKm ?? 0));
  }
  return out;
}

/// « 12 parties », « 1 partie ».
String countLabel(int n, String one, String many) => '$n ${n == 1 ? one : many}';

/// « 3,0 - 4,5 », « 10 DT - 25 DT », « Jusqu’à 10 km ».
String levelRangeLabel(RangeValues r) => '${formatLevel(r.start)} - ${formatLevel(r.end)}';
