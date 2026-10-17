import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/data/story_data.dart';
import 'owner_drafts.dart';

/// A group of courts sharing one price (OWN-16 « Terrains 1 et 2 », « Terrain 3 »).
@immutable
class CourtPrice {
  const CourtPrice({
    required this.id,
    required this.courts,
    required this.offPeak,
    required this.peak,
    this.indoor = false,
  });

  final String id;

  /// Court numbers (1, 2 → « Terrains 1 et 2 »).
  final List<int> courts;
  final bool indoor;

  /// Price of the court for one hour, off-peak and at peak hours.
  final num offPeak;
  final num peak;

  CourtPrice copyWith({num? offPeak, num? peak}) => CourtPrice(
    id: id,
    courts: courts,
    indoor: indoor,
    offPeak: offPeak ?? this.offPeak,
    peak: peak ?? this.peak,
  );
}

/// A day with its own rule (« Fête de la Révolution »: peak all day).
@immutable
class SpecialDate {
  const SpecialDate({
    required this.id,
    required this.day,
    required this.name,
    this.allDayPeak = false,
    this.fromHour,
    this.toHour,
    this.tentative = false,
  });

  final String id;
  final DateTime day;
  final String name;
  final bool allDayPeak;

  /// Peak only between these hours (« Pointe 20h00 – 00h00 »).
  final int? fromHour;
  final int? toHour;

  /// « dates à confirmer ».
  final bool tentative;
}

/// A promotion the owner published (from the AI suggestion, OWN-10 → OWN-16).
@immutable
class OwnerPromo {
  const OwnerPromo({required this.draft, required this.firstDay, required this.weekly});

  final PromoDraft draft;

  /// The first day it applies (« jeu. 22 oct. »).
  final DateTime firstDay;

  /// « Tous les jeudis » rather than once.
  final bool weekly;
}

/// Arena Five's price list (OWN-16, OWN-17, OWN-15 « 120 – 150 DT /h »).
@immutable
class Tariffs {
  const Tariffs({
    required this.prices,
    required this.peakFrom,
    required this.peakTo,
    required this.weekendPeak,
    required this.specialDates,
    this.promos = const [],
  });

  final List<CourtPrice> prices;

  /// Weekday peak hours (18h – 23h).
  final int peakFrom;
  final int peakTo;

  /// Saturday and Sunday are peak all day.
  final bool weekendPeak;
  final List<SpecialDate> specialDates;
  final List<OwnerPromo> promos;

  num get minPrice => prices.map((p) => p.offPeak).reduce((a, b) => a < b ? a : b);
  num get maxPrice => prices.map((p) => p.peak).reduce((a, b) => a > b ? a : b);

  /// The price group of court [number].
  CourtPrice priceOf(int number) =>
      prices.firstWhere((p) => p.courts.contains(number), orElse: () => prices.first);

  Tariffs copyWith({List<CourtPrice>? prices, bool? weekendPeak, List<OwnerPromo>? promos}) =>
      Tariffs(
        prices: prices ?? this.prices,
        peakFrom: peakFrom,
        peakTo: peakTo,
        weekendPeak: weekendPeak ?? this.weekendPeak,
        specialDates: specialDates,
        promos: promos ?? this.promos,
      );
}

/// The venue's prices. Until a backend exists [FakeTariffsRepository] keeps them in memory.
abstract interface class TariffsRepository {
  Future<Tariffs> load();

  /// Saves the whole price list (OWN-16 « Enregistrer les tarifs »).
  Future<Tariffs> save(Tariffs tariffs);

  /// Publishes one promotion (OWN-16 « Publier la promo »).
  Future<Tariffs> publishPromo(OwnerPromo promo);
}

class FakeTariffsRepository implements TariffsRepository {
  FakeTariffsRepository({this.latency = const Duration(milliseconds: 300)});

  final Duration latency;

  Tariffs _tariffs = Tariffs(
    prices: const [
      CourtPrice(id: 'outdoor', courts: [1, 2], offPeak: 120, peak: 150),
      CourtPrice(id: 'indoor', courts: [3], offPeak: 120, peak: 150, indoor: true),
    ],
    peakFrom: 18,
    peakTo: 23,
    weekendPeak: true,
    specialDates: [
      SpecialDate(
        id: 'revolution',
        day: DateTime(2026, 12, 17),
        name: 'Fête de la Révolution',
        allDayPeak: true,
      ),
      SpecialDate(
        id: 'ramadan',
        day: DateTime(2027, 2, 8),
        name: 'Ramadan 2027',
        fromHour: 20,
        toHour: 24,
        tentative: true,
      ),
    ],
  );

  /// How many times something was written (tests check nothing is saved before the owner asks).
  int saves = 0;

  Future<void> _wait() => Future<void>.delayed(latency);

  @override
  Future<Tariffs> load() async {
    await _wait();
    return _tariffs;
  }

  @override
  Future<Tariffs> save(Tariffs tariffs) async {
    await _wait();
    saves++;
    return _tariffs = tariffs;
  }

  @override
  Future<Tariffs> publishPromo(OwnerPromo promo) async {
    await _wait();
    saves++;
    return _tariffs = _tariffs.copyWith(promos: [..._tariffs.promos, promo]);
  }
}

final tariffsRepositoryProvider = Provider<TariffsRepository>((ref) => FakeTariffsRepository());

final tariffsProvider = FutureProvider<Tariffs>(
  (ref) => ref.watch(tariffsRepositoryProvider).load(),
);

/// The next [weekday] after [from] (« jeu. 22 oct. » from ven. 16 oct.).
DateTime nextWeekday(DateTime from, int weekday) {
  final day = DateTime(from.year, from.month, from.day);
  var d = day.add(Duration(days: (weekday - day.weekday) % 7));
  if (!d.isAfter(day)) d = d.add(const Duration(days: 7));
  return d;
}

/// Seven-day occupancy of each court (OWN-17 « Occupé · 7 j »), until the backend computes it.
const courtOccupancy = <int, int>{1: 84, 2: 79, 3: 71};

/// Scheduled works shown on a court card (OWN-17, Terrain 2: « Entretien du gazon · jeu. 22 oct.
/// · 8h–12h »).
final courtWorks = <int, ({String what, DateTime day, int from, int to})>{
  2: (what: 'Entretien du gazon', day: Story.at(22, 8), from: 8, to: 12),
};
