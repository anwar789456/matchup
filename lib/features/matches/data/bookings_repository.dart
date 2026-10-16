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
}

/// The story's « À venir » (design/screens/STORY-DATA.md): Mariem's invitation, G1 and MU-48213.
class FakeBookingsRepository implements BookingsRepository {
  const FakeBookingsRepository({this.latency = const Duration(milliseconds: 700)});

  final Duration latency;

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
      bookings: [Story.g1Booking, Story.myBooking],
    );
  }
}

final bookingsRepositoryProvider = Provider<BookingsRepository>(
  (ref) => const FakeBookingsRepository(),
);
