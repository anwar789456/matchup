import 'package:sqflite/sqflite.dart';

import '../../features/common/data/story_data.dart';
import '../../features/matches/data/booking_rows.dart';
import '../../features/matches/data/bookings_repository.dart';
import '../../features/payments/data/split_repository.dart';
import 'seed_v2.dart';

/// What each schema version starts with (design/screens/STORY-DATA.md).
Future<void> seedVersion(DatabaseExecutor db, int version) => switch (version) {
      1 => _seedV1(db),
      2 => seedV2(db),
      3 => SqliteSplitRepository.seed(db),
      _ => Future<void>.value(),
    };

/// Booking MU-48213, Skander's cancelled game of sam. 10 oct. and Mariem's padel invitation.
Future<void> _seedV1(DatabaseExecutor db) async {
  await BookingRows.insert(db, Story.myBooking, Story.myBooking.id!);
  final cancelled = FakeBookingsRepository.storyCancelled;
  await BookingRows.insert(db, cancelled.booking, cancelled.booking.id!);
  await BookingRows.insertCancellation(db, cancelled);
  final inv = FakeBookingsRepository.storyInvitation;
  await db.insert('invitations', {
    'id': inv.id,
    'de': inv.from.name,
    'sport': inv.sport.name,
    'etablissement': inv.venue,
    'lieu': inv.place,
    'debut': inv.start.toIso8601String(),
    'part': inv.share,
    'places_total': inv.spotsTotal,
    'places_restantes': inv.spotsLeft,
  });
}
