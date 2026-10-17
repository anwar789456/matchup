import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/data/story_data.dart';

/// An invitation to a game, waiting for an answer (« Mariem K. t’invite au padel »).
@immutable
class MatchInvitation {
  const MatchInvitation({
    required this.id,
    required this.from,
    required this.sport,
    required this.venue,
    required this.start,
    required this.share,
  });

  final String id;
  final MuPerson from;
  final MuSport sport;
  final String venue;
  final DateTime start;

  /// The share per person, « 25 DT /pers. ».
  final num share;
}

/// What « Tes prochains matchs » shows: invitations first, then the bookings and games ahead.
@immutable
class UpcomingMatches {
  const UpcomingMatches({required this.invitations, required this.bookings});

  final List<MatchInvitation> invitations;
  final List<MuBooking> bookings;
}

/// The player's bookings and games (« Mes matchs »).
abstract interface class BookingsRepository {
  Future<UpcomingMatches> upcoming();

  /// Saves a paid booking; returns it with its reference (« MU-48214 »).
  Future<MuBooking> add(MuBooking booking);

  /// The reference the next booking will get (its share link exists before the payment).
  Future<String> nextReference();
}

/// The story's « À venir » (design/screens/STORY-DATA.md): Mariem's invitation, G1 and MU-48213,
/// then the bookings made in the app, kept in memory.
class FakeBookingsRepository implements BookingsRepository {
  FakeBookingsRepository({this.latency = const Duration(milliseconds: 700)});

  final Duration latency;
  final _bookings = [Story.g1Booking, Story.myBooking];

  // References follow the story's MU-48213.
  static const int _firstRef = 48213;

  @override
  Future<UpcomingMatches> upcoming() async {
    await Future<void>.delayed(latency);
    final i = Story.invitation;
    return UpcomingMatches(
      invitations: [
        MatchInvitation(
          id: 'inv-mariem',
          from: i.from,
          sport: i.sport,
          venue: i.venue,
          start: i.start,
          share: i.share,
        ),
      ],
      bookings: [..._bookings]..sort((a, b) => a.start.compareTo(b.start)),
    );
  }

  @override
  Future<String> nextReference() async {
    final used = [
      for (final b in _bookings)
        if (b.id != null && b.id!.startsWith('MU-')) int.tryParse(b.id!.substring(3)) ?? 0,
    ];
    return 'MU-${used.fold(_firstRef - 1, (a, b) => a > b ? a : b) + 1}';
  }

  @override
  Future<MuBooking> add(MuBooking booking) async {
    final ref = booking.id ?? await nextReference();
    final saved = MuBooking(
      id: ref,
      sport: booking.sport,
      venue: booking.venue,
      court: booking.court,
      place: booking.place,
      start: booking.start,
      end: booking.end,
      share: booking.share,
      status: booking.status,
      payBefore: booking.payBefore,
      players: booking.players,
    );
    _bookings.add(saved);
    return saved;
  }
}

final bookingsRepositoryProvider = Provider<BookingsRepository>((ref) => FakeBookingsRepository());
