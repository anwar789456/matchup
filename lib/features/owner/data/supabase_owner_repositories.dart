import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_config.dart';

import '../../common/data/story_data.dart';
import '../../matches/data/reservation_remote.dart';
import '../../venue/data/venue_remote.dart';
import 'owner_repository.dart';
import 'sqlite_owner_repositories.dart';
import 'tariffs_repository.dart';

/// The owner's venue (the story's Arena Five) and its link to Supabase: the first account that
/// opens the owner space claims it (supabase/reservation.sql, revendiquer_etablissement).
class OwnerVenueLink {
  OwnerVenueLink(this.remote, {required this.connect, this.venueId = 'arena-five', String? venueName})
      : venueName = venueName ?? Story.arenaFive.name;

  final VenueRemote remote;
  final Future<bool> Function() connect;
  final String venueId;
  final String venueName;
  Future<bool>? _owner;

  /// True when Supabase is reached and this account owns the venue.
  Future<bool> isOwner() async {
    try {
      if (!await connect()) return false;
      return await (_owner ??= remote.claim(venueId).catchError((Object _) {
        _owner = null;
        return false;
      }));
    } on Object {
      return false;
    }
  }

  static String courtName(int number) => 'Terrain $number';

  static int courtNumber(String name) => int.tryParse(name.split(' ').last) ?? 1;
}

/// [OwnerRepository] for the venue's shared side on Supabase, with the phone's tables as cache:
///
/// - Closed slots live in Supabase (`blocages`): every player's slot grid shows them and
///   Supabase refuses a booking on them. The phone's `proprio_blocages` is their copy.
/// - The bookings players make at the venue (`reservations`, readable by its owner) join the
///   owner's day, planning and list next to the venue's own bookings.
/// - Courts, the venue's own bookings, arrivals and no-shows stay on the phone (copied by the
///   sync outbox).
class SupabaseOwnerRepository implements OwnerRepository {
  SupabaseOwnerRepository(this._local, this._link);

  final SqliteOwnerRepository _local;
  final OwnerVenueLink _link;

  /// The players' bookings fetched last, by reference (for booking() and the check-in).
  final _players = <String, OwnerBooking>{};

  static OwnerBooking _fromPlayer(RemoteBooking r, {required int capacity}) {
    final b = r.booking;
    final hours = (b.end.difference(b.start).inMinutes / 60).ceil().clamp(1, 24);
    final price = b.share * capacity;
    final paid = b.share * b.players.length;
    return OwnerBooking(
      ref: b.id!,
      court: OwnerVenueLink.courtNumber(b.court ?? ''),
      start: b.start,
      hours: hours,
      organiser: b.players.isEmpty ? '—' : b.players.first.name,
      kind: OwnerBookingKind.private,
      players: b.players.length,
      capacity: capacity,
      price: price,
      paid: paid,
      status: r.cancellation != null
          ? OwnerBookingStatus.cancelled
          : (paid >= price ? OwnerBookingStatus.confirmed : OwnerBookingStatus.pendingPayment),
      expected: [for (final p in b.players) p.name],
    );
  }

  /// Players' bookings at the venue from [from] for [days] days; none offline or not the owner.
  Future<List<OwnerBooking>> _playersBookings(DateTime from, int days) async {
    if (!await _link.isOwner()) return const [];
    try {
      final rows = await _link.remote.bookingsAt(_link.venueName, from, from.add(Duration(days: days)));
      final list = [for (final r in rows) _fromPlayer(r, capacity: 10)];
      for (final b in list) {
        _players[b.ref] = b;
      }
      return list;
    } on Object catch (e) {
      debugPrint('Réservations des joueurs indisponibles ($e)');
      return const [];
    }
  }

  static List<OwnerBooking> _merged(List<OwnerBooking> local, List<OwnerBooking> players) {
    final refs = {for (final b in local) b.ref};
    return [...local, ...players.where((b) => !refs.contains(b.ref))]
      ..sort((a, b) => a.start != b.start ? a.start.compareTo(b.start) : a.court - b.court);
  }

  @override
  Future<List<OwnerCourt>> courts() => _local.courts();

  @override
  Future<OwnerCourt> updateCourt(OwnerCourt court) => _local.updateCourt(court);

  @override
  Future<List<OwnerBooking>> bookingsOn(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final players = await _playersBookings(start, 1);
    return _merged(
      await _local.bookingsOn(day),
      [for (final b in players) if (b.status != OwnerBookingStatus.cancelled) b],
    );
  }

  @override
  Future<List<OwnerBooking>> upcoming(DateTime from) async {
    final start = DateTime(from.year, from.month, from.day);
    return _merged(await _local.upcoming(from), await _playersBookings(start, 60));
  }

  @override
  Future<OwnerBooking?> booking(String ref) async => await _local.booking(ref) ?? _players[ref];

  /// Copies the venue's closed slots from Supabase into the phone (another phone of the owner
  /// may have closed some).
  Future<void> _pullBlocks(DateTime day) async {
    if (!await _link.isOwner()) return;
    try {
      final start = DateTime(day.year, day.month, day.day);
      for (final b in await _link.remote.blocks(_link.venueId, start, start.add(const Duration(days: 1)))) {
        await _local.keepBlock(OwnerBlock(
          id: b.id,
          court: OwnerVenueLink.courtNumber(b.court),
          start: b.start,
          end: b.end,
          reason: BlockReason.values.asNameMap()[b.reason] ?? BlockReason.other,
          note: b.note,
          weekly: b.weekly,
        ));
      }
    } on Object catch (e) {
      debugPrint('Créneaux fermés : copie du téléphone ($e)');
    }
  }

  @override
  Future<List<OwnerBlock>> blocksOn(DateTime day) async {
    await _pullBlocks(day);
    return _local.blocksOn(day);
  }

  static RemoteBlock _remoteBlock(OwnerBlock b) => RemoteBlock(
        id: b.id,
        court: OwnerVenueLink.courtName(b.court),
        start: b.start,
        end: b.end,
        reason: b.reason.name,
        note: b.note,
        weekly: b.weekly,
      );

  /// Saved on the phone, then on Supabase so players can no longer book the slots. The ids are
  /// made unique for Supabase (`bN` alone would clash between two phones).
  @override
  Future<OwnerBlock> block({
    required List<int> courts,
    required DateTime start,
    required DateTime end,
    required BlockReason reason,
    String? note,
    bool weekly = false,
  }) async {
    late OwnerBlock last;
    final owner = await _link.isOwner();
    for (final c in courts) {
      final made = await _local.block(courts: [c], start: start, end: end, reason: reason, note: note, weekly: weekly);
      final id = '${_link.venueId}-${made.id}-${start.millisecondsSinceEpoch}';
      await _local.unblock(made.id);
      last = OwnerBlock(id: id, court: c, start: start, end: end, reason: reason, note: note, weekly: weekly);
      await _local.keepBlock(last);
      if (owner) {
        try {
          await _link.remote.saveBlock(_link.venueId, _remoteBlock(last));
        } on Object catch (e) {
          debugPrint('Créneau fermé gardé sur le téléphone ($e)');
        }
      }
    }
    return last;
  }

  @override
  Future<void> unblock(String id) async {
    await _local.unblock(id);
    if (await _link.isOwner()) {
      try {
        await _link.remote.deleteBlock(id);
      } on Object catch (e) {
        debugPrint('Créneau rouvert sur le téléphone seulement ($e)');
      }
    }
  }

  @override
  Future<OwnerBooking> markNoShow(String ref, List<String> players) => _local.markNoShow(ref, players);

  @override
  Future<OwnerBooking> cancel(String ref) => _local.cancel(ref);

  /// A player's booking made through the app is a valid ticket on its day; the venue's own
  /// bookings follow the story's rules.
  @override
  Future<CheckInResult> checkIn(String code, DateTime at) async {
    final c = code.trim().toUpperCase();
    if (await _local.booking(c) == null) {
      final day = DateTime(at.year, at.month, at.day);
      final match = (await _playersBookings(day, 1)).where((b) => b.ref == c).firstOrNull;
      if (match != null && match.status != OwnerBookingStatus.cancelled) {
        return CheckInResult(status: CheckInStatus.valid, code: c, scannedAt: at, booking: match);
      }
    }
    return _local.checkIn(code, at);
  }
}

/// [TariffsRepository] whose saved prices reach the players: the venue's off-peak and peak
/// prices and peak hours are written to Supabase (`etablissements`). The full price list
/// (groups, special dates, promos) stays the owner's, on the phone.
class SupabaseTariffsRepository implements TariffsRepository {
  SupabaseTariffsRepository(this._local, this._link);

  final SqliteTariffsRepository _local;
  final OwnerVenueLink _link;

  @override
  Future<Tariffs> load() => _local.load();

  @override
  Future<Tariffs> save(Tariffs tariffs) async {
    final saved = await _local.save(tariffs);
    if (await _link.isOwner()) {
      try {
        await _link.remote.updatePrices(
          _link.venueId,
          offPeak: saved.minPrice,
          peak: saved.maxPrice,
          peakFrom: saved.peakFrom * 60,
          peakTo: saved.peakTo * 60,
        );
      } on Object catch (e) {
        debugPrint('Tarifs gardés sur le téléphone ($e)');
      }
    }
    return saved;
  }

  @override
  Future<Tariffs> publishPromo(OwnerPromo promo) => _local.publishPromo(promo);
}

/// The owner's venue on Supabase when supabase.json was given, none otherwise.
final ownerVenueLinkProvider = Provider<OwnerVenueLink?>((ref) {
  final remote = ref.watch(venueRemoteProvider);
  return remote == null ? null : OwnerVenueLink(remote, connect: SupabaseConfig.ensureSession);
});
