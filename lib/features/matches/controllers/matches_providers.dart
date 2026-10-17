import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/controllers/home_providers.dart';
import '../../profile/data/me_repository.dart';
import '../data/bookings_repository.dart';

export '../../home/controllers/home_providers.dart' show upcomingMatchesProvider, meProvider;

/// « Passés ».
final pastMatchesProvider = FutureProvider<List<PastMatch>>(
  (ref) => ref.watch(bookingsRepositoryProvider).past(),
);

/// « Annulés ».
final cancelledMatchesProvider = FutureProvider<List<CancelledBooking>>(
  (ref) => ref.watch(bookingsRepositoryProvider).cancelled(),
);

/// The booking page (MAT-05).
final bookingDetailsProvider = FutureProvider.family<BookingDetails, String>(
  (ref, id) => ref.watch(bookingsRepositoryProvider).details(id),
);

/// The tab of « Mes matchs » (0 À venir, 1 Passés, 2 Annulés), kept across visits.
class MatchesTab extends Notifier<int> {
  @override
  int build() => 0;

  void select(int i) => state = i;
}

final matchesTabProvider = NotifierProvider<MatchesTab, int>(MatchesTab.new);

/// What the player does from « Mes matchs »: answer an invitation, cancel a court, rate, score.
class MatchesActions {
  const MatchesActions(this._ref);

  final Ref _ref;

  BookingsRepository get _bookings => _ref.read(bookingsRepositoryProvider);

  Future<void> respond(String invitationId, {required bool accept}) async {
    await _bookings.respond(invitationId, accept: accept);
    _ref.invalidate(upcomingMatchesProvider);
  }

  /// Cancels a booking the player organises; the refund lands on the balance (MAT-06).
  Future<CancelledBooking> cancel(String id) async {
    final c = await _bookings.cancel(id);
    await _ref.read(meRepositoryProvider).credit(c.refund);
    _ref
      ..invalidate(meProvider)
      ..invalidate(upcomingMatchesProvider)
      ..invalidate(cancelledMatchesProvider)
      ..invalidate(bookingDetailsProvider(id));
    _ref.read(matchesTabProvider.notifier).select(2);
    return c;
  }

  Future<void> rate(String matchId, List<MateRating> ratings) async {
    await _bookings.rate(matchId, ratings);
    _ref.invalidate(pastMatchesProvider);
  }

  Future<void> submitScore(String matchId, List<(int, int)> sets) async {
    await _bookings.submitScore(matchId, sets);
    _ref.invalidate(pastMatchesProvider);
  }
}

final matchesActionsProvider = Provider<MatchesActions>(MatchesActions.new);
