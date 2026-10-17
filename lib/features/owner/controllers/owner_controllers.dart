import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../data/owner_repository.dart';

DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

/// The day shown on the planning (OWN-11); starts on today.
class OwnerPlanningDay extends Notifier<DateTime> {
  @override
  DateTime build() => dayOf(ref.read(clockProvider)());

  void set(DateTime day) => state = dayOf(day);
}

final ownerPlanningDayProvider = NotifierProvider<OwnerPlanningDay, DateTime>(OwnerPlanningDay.new);

enum PlanningView { day, week }

class OwnerPlanningView extends Notifier<PlanningView> {
  @override
  PlanningView build() => PlanningView.day;

  void set(PlanningView v) => state = v;
}

final ownerPlanningViewProvider = NotifierProvider<OwnerPlanningView, PlanningView>(
  OwnerPlanningView.new,
);

/// What the owner does to bookings and slots; every change refreshes the owner screens.
class OwnerActions {
  OwnerActions(this.ref);

  final Ref ref;

  OwnerRepository get _repo => ref.read(ownerRepositoryProvider);

  void _refresh() {
    ref.invalidate(ownerBookingsOnProvider);
    ref.invalidate(ownerBlocksOnProvider);
    ref.invalidate(ownerUpcomingProvider);
    ref.invalidate(ownerBookingProvider);
  }

  Future<OwnerBlock> block({
    required List<int> courts,
    required DateTime start,
    required DateTime end,
    required BlockReason reason,
    String? note,
    bool weekly = false,
  }) async {
    final b = await _repo.block(
      courts: courts,
      start: start,
      end: end,
      reason: reason,
      note: note,
      weekly: weekly,
    );
    _refresh();
    return b;
  }

  Future<void> unblock(String id) async {
    await _repo.unblock(id);
    _refresh();
  }

  Future<OwnerBooking> markNoShow(String ref, List<String> players) async {
    final b = await _repo.markNoShow(ref, players);
    _refresh();
    return b;
  }

  Future<OwnerBooking> cancel(String ref) async {
    final b = await _repo.cancel(ref);
    _refresh();
    return b;
  }

  Future<CheckInResult> checkIn(String code) => _repo.checkIn(code, ref.read(clockProvider)());
}

final ownerActionsProvider = Provider<OwnerActions>(OwnerActions.new);

/// Evening occupancy (OWN-10, OWN-11): bookings over the 17h–23h slots of every court.
int occupancy(int bookings, int courts) =>
    courts == 0 ? 0 : (bookings * 100 / (courts * 6)).round().clamp(0, 100);
