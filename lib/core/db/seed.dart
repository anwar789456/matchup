import 'package:sqflite/sqflite.dart';

import '../../features/common/data/story_data.dart';
import '../../features/matches/data/booking_rows.dart';
import '../../features/matches/data/bookings_repository.dart';

/// What a new database starts with (design/screens/STORY-DATA.md): booking MU-48213, Skander's
/// cancelled game of sam. 10 oct. and Mariem's padel invitation.
Future<void> seedStory(Database db) => db.transaction((txn) async {
      await BookingRows.insert(txn, Story.myBooking, Story.myBooking.id!);
      final cancelled = FakeBookingsRepository.storyCancelled;
      await BookingRows.insert(txn, cancelled.booking, cancelled.booking.id!);
      await BookingRows.insertCancellation(txn, cancelled);
      final inv = FakeBookingsRepository.storyInvitation;
      await txn.insert('invitations', {
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
    });
