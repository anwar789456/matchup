import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/clock.dart';
import '../../../core/format.dart';
import '../../../ui/ui.dart';
import '../../explore/controllers/explore_controller.dart';
import '../../games/data/games_repository.dart';
import '../../home/controllers/home_providers.dart';
import '../../matches/data/bookings_repository.dart';
import '../../profile/data/me_repository.dart';
import '../../venue/data/venue_details.dart';
import '../data/payment_repository.dart';
import '../data/teammates_repository.dart';
import '../../wallet/data/wallet_repository.dart';
import '../../../l10n/l10n.dart';

/// Privée (friends only) or publique (open to players at the right level in Explorer).
enum BookingType { private, public }

/// « Chacun paie sa part » or « Je paie tout ».
enum PaymentSplit { share, all }

/// « Tout le monde » or « Mes abonnés ».
enum GameVisibility { everyone, followers }

/// « Mixte · Femmes · Hommes ».
enum GameGender {
  mixte,
  femmes,
  hommes;

  String get label => switch (this) {
    GameGender.mixte => l10n.mixte,
    GameGender.femmes => l10n.femmes,
    GameGender.hommes => l10n.hommes,
  };
}

/// The chosen slot, once « Continuer » leaves VEN-02.
@immutable
class PickedSlot {
  const PickedSlot({
    required this.venue,
    required this.court,
    required this.start,
    required this.end,
    required this.price,
    required this.peak,
  });

  final VenueDetails venue;
  final VenueCourt court;
  final DateTime start;
  final DateTime end;

  /// The court price for the whole run.
  final num price;
  final bool peak;

  Duration get length => end.difference(start);

  /// « 1 h », « 1 h 30 ».
  String get lengthLabel {
    final m = length.inMinutes;
    final rest = m % 60;
    return rest == 0 ? '${m ~/ 60} h' : '${m ~/ 60} h ${rest.toString().padLeft(2, '0')}';
  }

  /// « 21h00 – 22h00 ».
  String get timeRange => '${formatTime(start)} – ${formatHour(end.hour * 60 + end.minute)}';

  /// « Arena Five · Terrain 1 ».
  String get title => '${venue.venue.name} · ${court.name}';
}

/// The booking in progress, from the venue page to the payment (VEN-01 → BKG-05).
@immutable
class BookingDraft {
  const BookingDraft({
    this.venueId,
    required this.day,
    this.selection,
    this.fullDay = false,
    this.slot,
    this.type = BookingType.public,
    this.invited = const [],
    this.invitesSet = false,
    this.spots = 0,
    this.level = const RangeValues(2.5, 4),
    this.gender = GameGender.mixte,
    this.visibility = GameVisibility.everyone,
    this.note = '',
    this.split = PaymentSplit.share,
    this.useBalance = false,
    this.confirmed,
  });

  final String? venueId;
  final DateTime day;
  final MuSlotRange? selection;

  /// « Toute la journée » rather than the evening.
  final bool fullDay;
  final PickedSlot? slot;
  final BookingType type;

  /// Friends invited, by name.
  final List<String> invited;

  /// Whether the invites were set (the regular teammates are invited the first time).
  final bool invitesSet;

  /// Public game: places to fill with players.
  final int spots;
  final RangeValues level;
  final GameGender gender;
  final GameVisibility visibility;
  final String note;
  final PaymentSplit split;
  final bool useBalance;

  /// The booking once paid (BKG-05).
  final MuBooking? confirmed;

  int get capacity => slot?.venue.players ?? 10;

  /// The player and their invited friends.
  int get team => 1 + invited.length;

  /// Players the court is shared by: everyone invited plus the places to fill (public), or the
  /// court's capacity (private).
  int get players => type == BookingType.public ? (team + spots).clamp(1, capacity) : capacity;

  /// Each player's share: court price ÷ players.
  num get share => slot == null ? 0 : _round(slot!.price / players);

  /// What the player pays: their share, or the whole court.
  num get amount => split == PaymentSplit.share ? share : (slot?.price ?? 0);

  static num _round(num v) => (v * 1000).round() / 1000;

  BookingDraft copyWith({
    String? venueId,
    DateTime? day,
    MuSlotRange? Function()? selection,
    bool? fullDay,
    PickedSlot? Function()? slot,
    BookingType? type,
    List<String>? invited,
    bool? invitesSet,
    int? spots,
    RangeValues? level,
    GameGender? gender,
    GameVisibility? visibility,
    String? note,
    PaymentSplit? split,
    bool? useBalance,
    MuBooking? Function()? confirmed,
  }) => BookingDraft(
    venueId: venueId ?? this.venueId,
    day: day ?? this.day,
    selection: selection == null ? this.selection : selection(),
    fullDay: fullDay ?? this.fullDay,
    slot: slot == null ? this.slot : slot(),
    type: type ?? this.type,
    invited: invited ?? this.invited,
    invitesSet: invitesSet ?? this.invitesSet,
    spots: spots ?? this.spots,
    level: level ?? this.level,
    gender: gender ?? this.gender,
    visibility: visibility ?? this.visibility,
    note: note ?? this.note,
    split: split ?? this.split,
    useBalance: useBalance ?? this.useBalance,
    confirmed: confirmed == null ? this.confirmed : confirmed(),
  );
}

/// The slot grid of a day: its first column, the column times and the courts' rows.
@immutable
class DayGrid {
  const DayGrid({required this.start, required this.times, required this.courts});

  /// Minutes after midnight of the first column.
  final int start;
  final List<DateTime> times;
  final List<MuSlotCourt> courts;
}

/// The day's slots in [MuSlotGrid] form: the evening (from [VenueDetails.eveningFrom]) or the
/// whole day.
DayGrid dayGrid(VenueDetails venue, DaySchedule schedule, {required bool fullDay}) {
  final times = <DateTime>{
    for (final list in schedule.slots.values)
      for (final s in list)
        if (fullDay || s.start.hour * 60 + s.start.minute >= venue.eveningFrom) s.start,
  }.toList()..sort();
  final courts = [
    for (final court in venue.courts)
      MuSlotCourt(
        id: court.id,
        name: court.name,
        detail: court.gridDetail,
        icon: court.indoor ? PhosphorIcons.umbrella() : null,
        iconLabel: court.indoor ? l10n.couvert : null,
        slots: [
          for (final t in times)
            () {
              final s = schedule.slots[court.id]?.where((x) => x.start == t).firstOrNull;
              return s == null
                  ? const MuSlot(status: MuSlotStatus.booked)
                  : MuSlot(status: s.status, price: s.price, peak: s.peak);
            }(),
        ],
      ),
  ];
  final start = times.isEmpty ? venue.eveningFrom : times.first.hour * 60 + times.first.minute;
  return DayGrid(start: start, times: times, courts: courts);
}

class BookingController extends Notifier<BookingDraft> {
  @override
  BookingDraft build() {
    final now = ref.read(clockProvider)();
    return BookingDraft(day: DateTime(now.year, now.month, now.day));
  }

  /// Opens [venueId]'s page: a new venue starts a fresh draft on today.
  void openVenue(String venueId) {
    if (state.venueId == venueId && state.confirmed == null) return;
    final now = ref.read(clockProvider)();
    state = BookingDraft(venueId: venueId, day: DateTime(now.year, now.month, now.day));
  }

  void setDay(DateTime day) => state = state.copyWith(day: day, selection: () => null);

  void select(MuSlotRange? selection) => state = state.copyWith(selection: () => selection);

  void toggleFullDay() => state = state.copyWith(fullDay: !state.fullDay, selection: () => null);

  /// « Continuer »: keeps the picked run, invites the regular teammates the first time, sizes the
  /// public game to the court and sets the level around the player's.
  Future<void> confirmSlot(VenueDetails venue, DayGrid grid) async {
    final sel = state.selection;
    if (sel == null) return;
    final court = venue.courts.firstWhere((c) => c.id == sel.courtId);
    final row = grid.courts.firstWhere((c) => c.id == sel.courtId);
    final runs = row.slots.sublist(sel.from, sel.to);
    final start = grid.times[sel.from];
    final end = grid.times[sel.to - 1].add(Duration(minutes: venue.slotMinutes));
    var invited = state.invited;
    if (!state.invitesSet) {
      final mates = await ref.read(teammatesRepositoryProvider).suggested(venue.venue.id);
      invited = [
        for (final m in mates)
          if (m.regular) m.name,
      ].take(venue.players - 1).toList();
    }
    final level = ref.read(meProvider).value?.levels[venue.venue.sport];
    final team = 1 + invited.length;
    state = state.copyWith(
      slot: () => PickedSlot(
        venue: venue,
        court: court,
        start: start,
        end: end,
        price: runs.fold<num>(0, (a, s) => a + (s.price ?? 0)),
        peak: runs.any((s) => s.peak),
      ),
      invited: invited,
      invitesSet: true,
      spots: (venue.players - team).clamp(1, venue.players),
      level: level == null
          ? state.level
          : RangeValues(
              (level - 0.5).clamp(ExploreFilters.levelMin, ExploreFilters.levelMax),
              (level + 1).clamp(ExploreFilters.levelMin, ExploreFilters.levelMax),
            ),
      confirmed: () => null,
    );
  }

  void setType(BookingType type) => state = state.copyWith(type: type);

  void toggleInvite(String name) {
    final invited = [...state.invited];
    if (!invited.remove(name)) {
      if (state.team >= state.capacity) return;
      invited.add(name);
    }
    state = state.copyWith(
      invited: invited,
      spots: state.spots.clamp(1, (state.capacity - 1 - invited.length).clamp(1, state.capacity)),
    );
  }

  void setSpots(int spots) => state = state.copyWith(spots: spots);
  void setLevel(RangeValues level) => state = state.copyWith(level: level);
  void setGender(GameGender gender) => state = state.copyWith(gender: gender);
  void setVisibility(GameVisibility v) => state = state.copyWith(visibility: v);
  void setNote(String note) => state = state.copyWith(note: note);
  void setSplit(PaymentSplit split) => state = state.copyWith(split: split);
  void setUseBalance(bool v) => state = state.copyWith(useBalance: v);

  /// The balance used now, if the player asked for it.
  num balanceUsed(num balance) =>
      state.useBalance ? (balance < state.amount ? balance : state.amount) : 0;

  /// « Payer ma part » went through the checkout (PAY-01): the booking is saved under
  /// [reference], a public game goes to Explorer, the wallet gets its line, and Home and Mes
  /// matchs refresh. [fromBalance] is what the checkout took from the balance.
  Future<MuBooking> completePaid(
    PaymentReceipt receipt,
    num fromBalance, {
    String? reference,
  }) async {
    final d = state;
    final slot = d.slot!;
    final me = await ref.read(meRepositoryProvider).me();
    final people = [MuPerson(me.displayName), for (final n in d.invited) MuPerson(n)];
    final booking = await ref
        .read(bookingsRepositoryProvider)
        .add(
          MuBooking(
            id: reference,
            sport: slot.venue.venue.sport,
            venue: slot.venue.venue.name,
            court: slot.court.name,
            place: slot.venue.venue.place,
            start: slot.start,
            end: slot.end,
            share: d.share,
            players: people,
          ),
        );
    if (d.type == BookingType.public && d.visibility == GameVisibility.everyone) {
      await ref
          .read(gamesRepositoryProvider)
          .publish(
            MuGame(
              id: booking.id,
              venueId: slot.venue.venue.id,
              sport: slot.venue.venue.sport,
              venue: slot.venue.venue.name,
              court: slot.court.name,
              place: slot.venue.venue.place,
              distanceKm: slot.venue.venue.distanceKm,
              gameType: d.gender.label,
              start: slot.start,
              spotsTotal: d.players,
              spotsLeft: d.spots,
              pricePerPlayer: d.share,
              levelMin: d.level.start,
              levelMax: d.level.end,
              players: people,
              organiser: me.displayName,
            ),
          );
    }
    await ref
        .read(walletActionsProvider)
        .paid(
          receipt: receipt,
          label: d.split == PaymentSplit.share
              ? l10n.partText(slot.venue.venue.name)
              : l10n.terrain(slot.venue.venue.name),
          sport: slot.venue.venue.sport,
          fromBalance: fromBalance,
        );
    ref
      ..invalidate(upcomingMatchesProvider)
      ..invalidate(meProvider)
      ..invalidate(exploreGamesProvider);
    state = state.copyWith(confirmed: () => booking);
    return booking;
  }
}

final bookingProvider = NotifierProvider<BookingController, BookingDraft>(BookingController.new);

/// A venue's day, for VEN-01 and VEN-02.
final dayScheduleProvider = FutureProvider.family<DaySchedule, (String, DateTime)>((ref, key) {
  return ref
      .watch(venueDetailsRepositoryProvider)
      .schedule(key.$1, key.$2, now: ref.read(clockProvider)());
});

/// The cancellation dates of a slot: free until, half until (« mar. 20 oct. · 21h00 »).
({DateTime freeUntil, DateTime halfUntil, DateTime payBefore}) policyFor(DateTime start) => (
  freeUntil: start.subtract(VenueDetails.freeUntil),
  halfUntil: start.subtract(VenueDetails.halfUntil),
  payBefore: start.subtract(VenueDetails.payBefore),
);

/// The sport chip label on VEN-01: « Football · 5 contre 5 ».
String sportFormat(VenueDetails v) => '${v.venue.sport.label} · ${v.format}';
