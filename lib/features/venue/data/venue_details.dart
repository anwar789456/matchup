import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/ui.dart';
import '../../common/data/story_data.dart';
import '../../matches/data/bookings_repository.dart';

/// One court of a venue.
@immutable
class VenueCourt {
  const VenueCourt({required this.id, required this.name, required this.indoor, this.lit = true});

  final String id;

  /// « Terrain 1 », « Court 3 ».
  final String name;
  final bool indoor;
  final bool lit;

  /// The slot grid's line: « Éclairé », « Indoor ».
  String get gridDetail => indoor ? 'Indoor' : (lit ? 'Éclairé' : 'Extérieur');

  /// The courts section's line: « Extérieur · éclairé », « Indoor · couvert ».
  String get description => indoor ? 'Indoor · couvert' : 'Extérieur${lit ? ' · éclairé' : ''}';
}

/// A player's review of the venue.
@immutable
class VenueReview {
  const VenueReview({
    required this.author,
    required this.when,
    required this.court,
    required this.rating,
    required this.text,
  });

  final String author;
  final String when;
  final String court;
  final int rating;
  final String text;
}

/// Everything VEN-01 shows about a venue, and how it sells its courts.
@immutable
class VenueDetails {
  const VenueDetails({
    required this.venue,
    required this.street,
    required this.postalAddress,
    required this.format,
    required this.surface,
    required this.courts,
    required this.opens,
    required this.closes,
    required this.slotMinutes,
    required this.players,
    required this.offPeakPrice,
    required this.peakPrice,
    this.peakFrom = 18 * 60,
    this.peakTo = 23 * 60,
    this.eveningFrom = 20 * 60,
    this.photos = 1,
    this.review,
    this.soldOutDays = const {},
  });

  final MuVenue venue;

  /// « Route de la Corniche, La Marsa ».
  final String street;

  /// « Route de la Corniche, 2070 La Marsa ».
  final String postalAddress;

  /// « 5 contre 5 », « Double ».
  final String format;

  /// « gazon synthétique ».
  final String surface;
  final List<VenueCourt> courts;

  /// Opening hours, in minutes after midnight (24 × 60 = midnight).
  final int opens;
  final int closes;

  /// The length of one slot (60 for football, 90 for padel).
  final int slotMinutes;

  /// Players a court is priced for (« à 10 »).
  final int players;
  final num offPeakPrice;
  final num peakPrice;
  final int peakFrom;
  final int peakTo;

  /// Where « ce soir » starts on the slot grid.
  final int eveningFrom;
  final int photos;
  final VenueReview? review;

  /// Days of the month with no free slot (the strip dims them).
  final Set<int> soldOutDays;

  /// Cancellation, applied to each player: free until 24 h before, half until 6 h before.
  static const freeUntil = Duration(hours: 24);
  static const halfUntil = Duration(hours: 6);

  /// Every share must be paid 3 h before the game, or the booking is cancelled and refunded.
  static const payBefore = Duration(hours: 3);

  num priceAt(int minute) => minute >= peakFrom && minute < peakTo ? peakPrice : offPeakPrice;
  bool peakAt(int minute) => minute >= peakFrom && minute < peakTo && peakPrice != offPeakPrice;

  /// « 12–15 » DT per player, « 120–150 » DT the court.
  num get minShare => offPeakPrice / players;
  num get maxShare => peakPrice / players;
}

/// A slot of one court on one day.
@immutable
class CourtSlot {
  const CourtSlot({
    required this.start,
    required this.status,
    required this.price,
    required this.peak,
  });

  final DateTime start;
  final MuSlotStatus status;
  final num price;
  final bool peak;
}

/// A day of a venue: every court's slots from opening to closing.
@immutable
class DaySchedule {
  const DaySchedule({required this.day, required this.slots});

  final DateTime day;
  final Map<String, List<CourtSlot>> slots;
}

abstract interface class VenueDetailsRepository {
  Future<VenueDetails> details(String venueId);

  /// The courts' slots on [day]; past slots are left out.
  Future<DaySchedule> schedule(String venueId, DateTime day, {required DateTime now});

  /// Free slots, sold out or closed — for the date strip.
  MuDayAvailability availability(String venueId, DateTime day);
}

/// The story's venues and their days. Arena Five's mer. 21 oct. is the one of the designs
/// (VEN-01): Terrain 2 taken 20h–22h, Terrain 3 at 20h and 23h; the other days are taken in a fixed
/// pattern; sam. 17 and sam. 24 oct. are sold out. The player's own bookings show as theirs.
class FakeVenueDetailsRepository implements VenueDetailsRepository {
  FakeVenueDetailsRepository({required this.bookings, this.latency = Duration.zero});

  /// The player's bookings, shown as « Ta réservation ».
  final BookingsRepository bookings;
  final Duration latency;

  static const _review = VenueReview(
    author: 'Skander T.',
    when: 'il y a 3 jours',
    court: 'Terrain 2',
    rating: 5,
    text:
        'Gazon impeccable et l’éclairage est top le soir. Vestiaires propres, on revient chaque '
        'dimanche.',
  );

  static final _all = <String, VenueDetails>{
    Story.arenaFive.id: const VenueDetails(
      venue: Story.arenaFive,
      street: 'Route de la Corniche, La Marsa',
      postalAddress: 'Route de la Corniche, 2070 La Marsa',
      format: '5 contre 5',
      surface: 'gazon synthétique',
      courts: [
        VenueCourt(id: 't1', name: 'Terrain 1', indoor: false),
        VenueCourt(id: 't2', name: 'Terrain 2', indoor: false),
        VenueCourt(id: 't3', name: 'Terrain 3', indoor: true),
      ],
      opens: 8 * 60,
      closes: 24 * 60,
      slotMinutes: 60,
      players: 10,
      offPeakPrice: 120,
      peakPrice: 150,
      photos: 8,
      review: _review,
      soldOutDays: {17, 24},
    ),
    Story.smashPadel.id: const VenueDetails(
      venue: Story.smashPadel,
      street: 'Rue du Lac Biwa, Lac 2',
      postalAddress: 'Rue du Lac Biwa, 1053 Les Berges du Lac 2',
      format: 'Double',
      surface: 'gazon synthétique · vitré',
      courts: [
        VenueCourt(id: 'c1', name: 'Court 1', indoor: false),
        VenueCourt(id: 'c2', name: 'Court 2', indoor: false),
        VenueCourt(id: 'c3', name: 'Court 3', indoor: true),
        VenueCourt(id: 'c4', name: 'Court 4', indoor: true),
      ],
      opens: 8 * 60,
      closes: 24 * 60,
      slotMinutes: 90,
      players: 4,
      offPeakPrice: 80,
      peakPrice: 100,
      eveningFrom: 18 * 60 + 30,
      photos: 6,
      review: VenueReview(
        author: 'Mariem K.',
        when: 'il y a 1 semaine',
        court: 'Court 3',
        rating: 5,
        text: 'Les courts couverts sont parfaits quand il vente. Accueil au top.',
      ),
    ),
    Story.padelHouse.id: const VenueDetails(
      venue: Story.padelHouse,
      street: 'Avenue Hédi Nouira, Menzah 6',
      postalAddress: 'Avenue Hédi Nouira, 2091 Menzah 6',
      format: 'Double',
      surface: 'gazon synthétique · vitré',
      courts: [
        VenueCourt(id: 'c1', name: 'Court 1', indoor: false),
        VenueCourt(id: 'c2', name: 'Court 2', indoor: false),
      ],
      opens: 9 * 60,
      closes: 24 * 60,
      slotMinutes: 90,
      players: 4,
      offPeakPrice: 72,
      peakPrice: 88,
      eveningFrom: 19 * 60 + 30,
      photos: 4,
    ),
    Story.hoopZone.id: const VenueDetails(
      venue: Story.hoopZone,
      street: 'Rue Abou Kacem Chebbi, Ennasr',
      postalAddress: 'Rue Abou Kacem Chebbi, 2037 Ennasr',
      format: '3x3 et 5x5',
      surface: 'parquet',
      courts: [
        VenueCourt(id: 'b1', name: 'Terrain 3x3', indoor: true),
        VenueCourt(id: 'b2', name: 'Terrain 5x5', indoor: true),
      ],
      opens: 10 * 60,
      closes: 23 * 60,
      slotMinutes: 60,
      players: 10,
      offPeakPrice: 90,
      peakPrice: 90,
      photos: 5,
    ),
  };

  @override
  Future<VenueDetails> details(String venueId) async {
    await Future<void>.delayed(latency);
    final d = _all[venueId];
    if (d == null) throw StateError('Terrain inconnu : $venueId');
    return d;
  }

  @override
  MuDayAvailability availability(String venueId, DateTime day) {
    final d = _all[venueId];
    if (d == null) return MuDayAvailability.closed;
    return d.soldOutDays.contains(day.day) && day.month == 10
        ? MuDayAvailability.soldOut
        : MuDayAvailability.available;
  }

  /// The designed day, then a fixed pattern: about one slot in four taken.
  bool _taken(VenueDetails d, int courtIndex, DateTime day, int minute) {
    if (availability(d.venue.id, day) == MuDayAvailability.soldOut) return true;
    if (d.venue.id == Story.arenaFive.id && day.month == 10 && day.day == 21) {
      final hour = minute ~/ 60;
      return (courtIndex == 1 && (hour == 20 || hour == 21)) ||
          (courtIndex == 2 && (hour == 20 || hour == 23));
    }
    return (day.day * 7 + courtIndex * 3 + minute ~/ d.slotMinutes) % 4 == 0;
  }

  @override
  Future<DaySchedule> schedule(String venueId, DateTime day, {required DateTime now}) async {
    final d = await details(venueId);
    final mine = (await bookings.upcoming()).bookings;
    final date = DateTime(day.year, day.month, day.day);
    final slots = <String, List<CourtSlot>>{};
    for (final (i, court) in d.courts.indexed) {
      final list = <CourtSlot>[];
      for (var m = d.opens; m + d.slotMinutes <= d.closes; m += d.slotMinutes) {
        final start = date.add(Duration(minutes: m));
        if (!start.isAfter(now)) continue;
        final isMine = mine.any(
          (b) =>
              b.venue == d.venue.name &&
              b.court == court.name &&
              !start.isBefore(b.start) &&
              start.isBefore(b.end),
        );
        list.add(
          CourtSlot(
            start: start,
            status: isMine
                ? MuSlotStatus.mine
                : (_taken(d, i, date, m) ? MuSlotStatus.booked : MuSlotStatus.available),
            price: d.priceAt(m),
            peak: d.peakAt(m),
          ),
        );
      }
      slots[court.id] = list;
    }
    return DaySchedule(day: date, slots: slots);
  }
}

final venueDetailsRepositoryProvider = Provider<VenueDetailsRepository>(
  (ref) => FakeVenueDetailsRepository(bookings: ref.watch(bookingsRepositoryProvider)),
);

final venueDetailsProvider = FutureProvider.family<VenueDetails, String>(
  (ref, id) => ref.watch(venueDetailsRepositoryProvider).details(id),
);
