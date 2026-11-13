import 'package:flutter/foundation.dart';

import '../../../core/connectivity.dart';
import '../../../ui/ui.dart';
import 'bookings_repository.dart';
import 'reservation_remote.dart';
import 'sqlite_bookings_repository.dart';

/// [BookingsRepository] with Supabase as the source of truth for booked courts and SQFlite as its
/// cache (supabase/reservation.sql):
///
/// - Reading: the screens get the phone's copy at once; when online, the player's bookings are
///   fetched from Supabase first and the copy updated. Offline, the copy is shown as it is.
/// - Booking and cancelling need the network: Supabase decides who gets a slot (a 15-minute hold
///   before the checkout, confirmed after payment), so two phones can never book the same one.
/// - What only concerns this player (invitations, ratings, scores, the story's past matches)
///   stays in [SqliteBookingsRepository] and is copied by the sync outbox.
class SupabaseBookingsRepository implements BookingsRepository {
  SupabaseBookingsRepository(this._local, this._remote, {required this.connect});

  final SqliteBookingsRepository _local;
  final ReservationRemote _remote;

  /// True once Supabase has a session (signs in anonymously if needed).
  final Future<bool> Function() connect;

  Future<bool> _online() async {
    try {
      return await connect();
    } on Object {
      return false;
    }
  }

  Future<void> _requireOnline() async {
    if (!await _online()) throw const OfflineException();
  }

  /// Copies the player's bookings from Supabase into the phone; keeps the copy if that fails.
  Future<void> _refresh() async {
    if (!await _online()) return;
    try {
      for (final r in await _remote.mine()) {
        await _local.keep(r.booking, r.cancellation);
      }
    } on Object catch (e) {
      debugPrint('Réservations : on garde la copie du téléphone ($e)');
    }
  }

  @override
  Future<UpcomingMatches> upcoming() async {
    await _refresh();
    return _local.upcoming();
  }

  @override
  Future<List<CancelledBooking>> cancelled() async {
    await _refresh();
    return _local.cancelled();
  }

  @override
  Future<String> nextReference() async {
    await _requireOnline();
    return _remote.nextReference();
  }

  @override
  Future<void> hold(MuBooking booking) async {
    await _requireOnline();
    await _remote.hold(booking);
  }

  @override
  Future<MuBooking> add(MuBooking booking) async {
    await _requireOnline();
    final saved = booking.id == null
        ? MuBooking(
            id: await _remote.nextReference(),
            sport: booking.sport,
            venue: booking.venue,
            court: booking.court,
            place: booking.place,
            start: booking.start,
            end: booking.end,
            share: booking.share,
            players: booking.players,
          )
        : booking;
    await _remote.confirm(saved);
    await _local.keep(saved, null);
    return saved;
  }

  /// Cancelled on Supabase too, which frees the slot for everyone. A booking only on this phone
  /// (the story's MU-48213) is cancelled here alone.
  @override
  Future<CancelledBooking> cancel(String id) async {
    await _requireOnline();
    final c = await _local.cancel(id);
    await _remote.cancel(c);
    return c;
  }

  /// Slots of [venue] taken by anyone between [from] and [to]; none when offline.
  Future<List<TakenSlot>> taken(String venue, DateTime from, DateTime to) async {
    if (!await _online()) return const [];
    try {
      return await _remote.taken(venue, from, to);
    } on Object catch (e) {
      debugPrint('Créneaux pris indisponibles ($e)');
      return const [];
    }
  }

  @override
  Future<BookingDetails> details(String id) => _local.details(id);

  @override
  Future<List<PastMatch>> past() => _local.past();

  @override
  Future<void> respond(String invitationId, {required bool accept}) =>
      _local.respond(invitationId, accept: accept);

  @override
  Future<void> rate(String matchId, List<MateRating> ratings) => _local.rate(matchId, ratings);

  @override
  Future<void> submitScore(String matchId, List<(int, int)> sets) =>
      _local.submitScore(matchId, sets);
}
