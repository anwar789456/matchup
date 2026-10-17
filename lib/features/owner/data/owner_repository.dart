import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/theme.dart';
import '../../common/data/story_data.dart';

/// A court of the owner's venue (OWN-11 columns, OWN-17).
@immutable
class OwnerCourt {
  const OwnerCourt({
    required this.id,
    required this.number,
    this.indoor = false,
    this.visible = true,
    this.maintenance = false,
  });

  final String id;

  /// 1 → « Terrain 1 » / « T1 ».
  final int number;
  final bool indoor;
  final bool visible;
  final bool maintenance;

  OwnerCourt copyWith({bool? visible, bool? maintenance}) => OwnerCourt(
    id: id,
    number: number,
    indoor: indoor,
    visible: visible ?? this.visible,
    maintenance: maintenance ?? this.maintenance,
  );
}

enum OwnerBookingKind { private, public }

/// Where a booking stands for the owner.
enum OwnerBookingStatus { confirmed, pendingPayment, inProgress, done, noShow, cancelled }

/// One booking of the venue (OWN-10 programme, OWN-11 grid, OWN-12 detail, OWN-14 list).
@immutable
class OwnerBooking {
  const OwnerBooking({
    required this.ref,
    required this.court,
    required this.start,
    required this.organiser,
    required this.kind,
    required this.price,
    required this.paid,
    this.hours = 1,
    this.players = 10,
    this.capacity = 10,
    this.status = OwnerBookingStatus.confirmed,
    this.mine = false,
    this.gameType = 'mixte',
    this.levelMin,
    this.levelMax,
    this.reliability = 96,
    this.honoured = 48,
    this.matches = 50,
    this.arrived = const [],
    this.expected = const [],
    this.noShows = const [],
    this.note,
  });

  /// « MU-48213 ».
  final String ref;
  final int court;
  final DateTime start;
  final int hours;

  /// Who booked (« Yassine B. »).
  final String organiser;
  final OwnerBookingKind kind;

  /// Players in / places (public games show « 8/10 joueurs »).
  final int players;
  final int capacity;

  /// The court price and what the players already paid (online).
  final num price;
  final num paid;
  final OwnerBookingStatus status;

  /// The owner's own game (« Toi »).
  final bool mine;
  final String gameType;
  final double? levelMin;
  final double? levelMax;

  /// The organiser's reliability (« Fiable 96 % · 48/50 matchs honorés »).
  final int reliability;
  final int honoured;
  final int matches;

  /// Check-in: who came in, who is still expected (OWN-21, OWN-24).
  final List<String> arrived;
  final List<String> expected;

  /// Players reported absent (OWN-24).
  final List<String> noShows;

  /// A short note (« Foot 5v5 femmes »).
  final String? note;

  DateTime get end => start.add(Duration(hours: hours));
  bool get fullyPaid => paid >= price;
  num get due => price - paid;

  OwnerBooking copyWith({
    OwnerBookingStatus? status,
    DateTime? start,
    int? court,
    List<String>? arrived,
    List<String>? expected,
    List<String>? noShows,
  }) => OwnerBooking(
    ref: ref,
    court: court ?? this.court,
    start: start ?? this.start,
    hours: hours,
    organiser: organiser,
    kind: kind,
    players: players,
    capacity: capacity,
    price: price,
    paid: paid,
    status: status ?? this.status,
    mine: mine,
    gameType: gameType,
    levelMin: levelMin,
    levelMax: levelMax,
    reliability: reliability,
    honoured: honoured,
    matches: matches,
    arrived: arrived ?? this.arrived,
    expected: expected ?? this.expected,
    noShows: noShows ?? this.noShows,
    note: note,
  );
}

enum BlockReason { maintenance, privateEvent, tournament, weather, other }

/// Slots the owner closed (OWN-13).
@immutable
class OwnerBlock {
  const OwnerBlock({
    required this.id,
    required this.court,
    required this.start,
    required this.end,
    required this.reason,
    this.note,
    this.weekly = false,
  });

  final String id;
  final int court;
  final DateTime start;
  final DateTime end;
  final BlockReason reason;

  /// « Nettoyage du terrain indoor ».
  final String? note;
  final bool weekly;

  /// The note's first word for a planning cell (« Nettoyage »).
  String? get shortNote => note?.split(' ').first;
}

enum CheckInStatus { valid, alreadyUsed, invalid }

/// The result of a scan or a typed code (OWN-21, OWN-22, OWN-23).
@immutable
class CheckInResult {
  const CheckInResult({
    required this.status,
    required this.code,
    required this.scannedAt,
    this.booking,
    this.firstScanAt,
    this.firstScanBy,
    this.ticketHolder,
  });

  final CheckInStatus status;
  final String code;
  final DateTime scannedAt;
  final OwnerBooking? booking;

  /// Already used: when and by whom the first scan was.
  final DateTime? firstScanAt;
  final String? firstScanBy;
  final String? ticketHolder;
}

/// The venue, its courts and its bookings. Until a backend exists
/// [FakeOwnerRepository] serves Arena Five's story (STORY-DATA « Venue owner »).
abstract interface class OwnerRepository {
  Future<List<OwnerCourt>> courts();
  Future<OwnerCourt> updateCourt(OwnerCourt court);

  /// Bookings starting on [day], by start then court.
  Future<List<OwnerBooking>> bookingsOn(DateTime day);

  /// Every booking from [from] on (OWN-14).
  Future<List<OwnerBooking>> upcoming(DateTime from);
  Future<OwnerBooking?> booking(String ref);
  Future<List<OwnerBlock>> blocksOn(DateTime day);
  Future<OwnerBlock> block({
    required List<int> courts,
    required DateTime start,
    required DateTime end,
    required BlockReason reason,
    String? note,
    bool weekly = false,
  });
  Future<void> unblock(String id);

  /// Reports [players] absent: their share stays due, their reliability drops (OWN-24).
  Future<OwnerBooking> markNoShow(String ref, List<String> players);
  Future<OwnerBooking> cancel(String ref);
  Future<CheckInResult> checkIn(String code, DateTime at);
}

class FakeOwnerRepository implements OwnerRepository {
  FakeOwnerRepository({this.latency = const Duration(milliseconds: 300)});

  final Duration latency;
  final _courts = [
    const OwnerCourt(id: 't1', number: 1),
    const OwnerCourt(id: 't2', number: 2),
    const OwnerCourt(id: 't3', number: 3, indoor: true),
  ];
  late final List<OwnerBooking> _bookings = _story();
  late final List<OwnerBlock> _blocks = [
    OwnerBlock(
      id: 'b1',
      court: 3,
      start: Story.at(16, 18),
      end: Story.at(16, 19),
      reason: BlockReason.maintenance,
      note: 'Nettoyage du terrain indoor',
    ),
  ];
  int _blockIds = 1;

  Future<void> _wait() => Future<void>.delayed(latency);

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Arena Five's week (OWN-10, OWN-11, OWN-12, OWN-14).
  static List<OwnerBooking> _story() {
    OwnerBooking b(
      String ref,
      int day,
      int hour,
      int court,
      String who, {
      OwnerBookingKind kind = OwnerBookingKind.private,
      int players = 10,
      num? paid,
      num? price,
      int hours = 1,
      OwnerBookingStatus status = OwnerBookingStatus.confirmed,
      bool mine = false,
      String gameType = 'mixte',
      double? levelMin,
      double? levelMax,
      String? note,
      List<String> arrived = const [],
      List<String> expected = const [],
    }) {
      final p = price ?? (hour >= 18 && hour < 23 ? 150 : 120) * hours;
      return OwnerBooking(
        ref: ref,
        court: court,
        start: Story.at(day, hour),
        hours: hours,
        organiser: who,
        kind: kind,
        players: players,
        price: p,
        paid: paid ?? p,
        status: status,
        mine: mine,
        gameType: gameType,
        levelMin: levelMin,
        levelMax: levelMax,
        note: note,
        arrived: arrived,
        expected: expected,
      );
    }

    const done = OwnerBookingStatus.done;
    const live = OwnerBookingStatus.inProgress;
    const pending = OwnerBookingStatus.pendingPayment;
    const public = OwnerBookingKind.public;
    return [
      // Today, ven. 16 oct. (OWN-10, OWN-11).
      b('MU-48150', 16, 17, 1, 'Hamza R.', status: done),
      b('MU-48151', 16, 17, 2, 'Rami S.', status: OwnerBookingStatus.noShow),
      b(
        'MU-48160',
        16,
        18,
        1,
        'Aziz H.',
        status: live,
        arrived: [
          'Aziz H.',
          'Hamza R.',
          'Nour A.',
          'Mariem K.',
          'Yassine B.',
          'Salma G.',
          'Lina F.',
          'Ines M.',
          'Dorra K.',
        ],
        expected: ['Sarra B.'],
      ),
      b('MU-48161', 16, 18, 2, 'Omar D.', status: live),
      b('MU-48190', 16, 19, 1, 'Salma G.', kind: public, players: 8, levelMin: 2.5, levelMax: 4),
      b('MU-48185', 16, 19, 3, 'Amel T.'),
      b('MU-48192', 16, 20, 1, 'Nour A.'),
      b('MU-48196', 16, 20, 2, 'Ines M.', players: 9, paid: 135, status: pending),
      b('MU-48197', 16, 20, 3, 'Dorra K.'),
      b('MU-48201', 16, 21, 1, 'Lina F.', players: 7, paid: 105, status: pending),
      b('MU-48202', 16, 21, 2, 'Sarra B.'),
      b('MU-48203', 16, 21, 3, 'Yosra M.', kind: public, players: 6, levelMin: 3, levelMax: 4.5),
      b('MU-48204', 16, 22, 2, 'Mariem K.'),
      b('MU-48205', 16, 22, 3, 'Rim H.'),
      // Sam. 17 oct.
      b('MU-48164', 17, 18, 2, 'Omar D.'),
      b(
        'MU-48122',
        17,
        19,
        1,
        'Nour A.',
        kind: public,
        gameType: 'femmes',
        note: 'Foot 5v5 femmes',
      ),
      b('MU-48207', 17, 21, 3, 'Aziz H.', paid: 60, status: pending),
      b('MU-48208', 17, 17, 1, 'Hamza R.'),
      b('MU-48209', 17, 20, 2, 'Ines M.'),
      // Dim. 18 oct.
      b('MU-48131', 18, 20, 2, 'Skander T.', kind: public, players: 8, mine: true),
      b('MU-48132', 18, 19, 1, 'Salma G.'),
      // Mer. 21 oct. (OWN-12).
      b('MU-48210', 21, 17, 2, 'Aziz H.', price: 120),
      b('MU-48211', 21, 18, 1, 'Hamza R.'),
      b('MU-48212', 21, 18, 2, 'Omar D.'),
      b('MU-48214', 21, 19, 1, 'Ines M.'),
      b('MU-48215', 21, 19, 2, 'Nour A.'),
      b('MU-48216', 21, 19, 3, 'Salma G.', kind: public, players: 8),
      b('MU-48217', 21, 20, 2, 'Lina F.', hours: 2),
      b('MU-48218', 21, 20, 3, 'Rami S.'),
      b(
        'MU-48213',
        21,
        21,
        1,
        'Yassine B.',
        kind: public,
        players: 6,
        paid: 90,
        levelMin: 2.5,
        levelMax: 4,
        arrived: ['Yassine B.', 'Nour A.', 'Omar D.', 'Aziz H.', 'Hamza R.', 'Mariem K.'],
        expected: ['Ines M.', 'Lina F.', 'Rami S.', 'Salma G.'],
      ),
      b('MU-48219', 21, 23, 3, 'Rim H.', price: 120),
    ];
  }

  @override
  Future<List<OwnerCourt>> courts() async {
    await _wait();
    return [..._courts];
  }

  @override
  Future<OwnerCourt> updateCourt(OwnerCourt court) async {
    await _wait();
    final i = _courts.indexWhere((c) => c.id == court.id);
    _courts[i] = court;
    return court;
  }

  @override
  Future<List<OwnerBooking>> bookingsOn(DateTime day) async {
    await _wait();
    return [
      for (final b in _bookings)
        if (_sameDay(b.start, day) && b.status != OwnerBookingStatus.cancelled) b,
    ]..sort((a, b) => a.start != b.start ? a.start.compareTo(b.start) : a.court - b.court);
  }

  @override
  Future<List<OwnerBooking>> upcoming(DateTime from) async {
    await _wait();
    final day = DateTime(from.year, from.month, from.day);
    return [
      for (final b in _bookings)
        if (!b.start.isBefore(day)) b,
    ]..sort((a, b) => a.start != b.start ? a.start.compareTo(b.start) : a.court - b.court);
  }

  @override
  Future<OwnerBooking?> booking(String ref) async {
    await _wait();
    return _bookings.where((b) => b.ref == ref).firstOrNull;
  }

  @override
  Future<List<OwnerBlock>> blocksOn(DateTime day) async {
    await _wait();
    return [
      for (final b in _blocks)
        if (_sameDay(b.start, day) ||
            (b.weekly && b.start.weekday == day.weekday && !day.isBefore(b.start)))
          b,
    ];
  }

  @override
  Future<OwnerBlock> block({
    required List<int> courts,
    required DateTime start,
    required DateTime end,
    required BlockReason reason,
    String? note,
    bool weekly = false,
  }) async {
    await _wait();
    late OwnerBlock last;
    for (final c in courts) {
      last = OwnerBlock(
        id: 'b${++_blockIds}',
        court: c,
        start: start,
        end: end,
        reason: reason,
        note: note,
        weekly: weekly,
      );
      _blocks.add(last);
    }
    return last;
  }

  @override
  Future<void> unblock(String id) async {
    await _wait();
    _blocks.removeWhere((b) => b.id == id);
  }

  OwnerBooking _update(String ref, OwnerBooking Function(OwnerBooking) change) {
    final i = _bookings.indexWhere((b) => b.ref == ref);
    return _bookings[i] = change(_bookings[i]);
  }

  @override
  Future<OwnerBooking> markNoShow(String ref, List<String> players) async {
    await _wait();
    return _update(
      ref,
      (b) => b.copyWith(
        expected: [
          for (final p in b.expected)
            if (!players.contains(p)) p,
        ],
        noShows: [...b.noShows, ...players],
      ),
    );
  }

  @override
  Future<OwnerBooking> cancel(String ref) async {
    await _wait();
    return _update(ref, (b) => b.copyWith(status: OwnerBookingStatus.cancelled));
  }

  @override
  Future<CheckInResult> checkIn(String code, DateTime at) async {
    await _wait();
    final c = code.trim().toUpperCase();
    if (c == 'MU-48213') {
      final b = _bookings.firstWhere((x) => x.ref == c);
      return CheckInResult(status: CheckInStatus.valid, code: c, scannedAt: at, booking: b);
    }
    if (c == 'MU-48190') {
      return CheckInResult(
        status: CheckInStatus.alreadyUsed,
        code: c,
        scannedAt: at,
        firstScanAt: DateTime(at.year, at.month, at.day, 19, 2),
        firstScanBy: Story.ownerName,
        ticketHolder: 'Hamza R.',
        booking: OwnerBooking(
          ref: c,
          court: 2,
          start: Story.at(21, 19),
          organiser: 'Hamza R.',
          kind: OwnerBookingKind.private,
          price: 150,
          paid: 150,
        ),
      );
    }
    return CheckInResult(status: CheckInStatus.invalid, code: c, scannedAt: at);
  }
}

final ownerRepositoryProvider = Provider<OwnerRepository>((ref) => FakeOwnerRepository());

final ownerCourtsProvider = FutureProvider<List<OwnerCourt>>(
  (ref) => ref.watch(ownerRepositoryProvider).courts(),
);

final ownerBookingsOnProvider = FutureProvider.family<List<OwnerBooking>, DateTime>(
  (ref, day) => ref.watch(ownerRepositoryProvider).bookingsOn(day),
);

final ownerBlocksOnProvider = FutureProvider.family<List<OwnerBlock>, DateTime>(
  (ref, day) => ref.watch(ownerRepositoryProvider).blocksOn(day),
);

final ownerUpcomingProvider = FutureProvider.family<List<OwnerBooking>, DateTime>(
  (ref, from) => ref.watch(ownerRepositoryProvider).upcoming(from),
);

final ownerBookingProvider = FutureProvider.family<OwnerBooking?, String>(
  (ref, id) => ref.watch(ownerRepositoryProvider).booking(id),
);

/// Peak hours (« Pointe »): 18h–23h at 150 DT, otherwise 120 DT (STORY-DATA prices).
bool isPeak(int hour) => hour >= 18 && hour < 23;
num slotPrice(int hour) => isPeak(hour) ? 150 : 120;

/// The venue opens 8h – midnight.
const ownerOpens = 8;
const ownerCloses = 24;

/// The sport icon of the venue.
const ownerSport = MuSport.football;
