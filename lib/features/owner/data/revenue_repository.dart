import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/data/story_data.dart';

/// The day's headline figures (OWN-10 KPIs), each against the same weekday a week before.
@immutable
class OwnerTodaySummary {
  const OwnerTodaySummary({
    required this.compareTo,
    required this.occupancy,
    required this.occupancyDelta,
    required this.revenue,
    required this.revenueDelta,
    required this.bookings,
    required this.bookingsDelta,
    required this.noShows,
    required this.noShowsDelta,
    required this.collected,
    required this.inPayment,
  });

  /// « vs ven. 9 oct. ».
  final DateTime compareTo;

  /// Percent of the day's slots booked, and its change in points.
  final int occupancy;
  final int occupancyDelta;

  /// DT taken today, and its change in percent.
  final num revenue;
  final int revenueDelta;
  final int bookings;
  final int bookingsDelta;
  final int noShows;
  final int noShowsDelta;

  /// « 1 140 DT déjà encaissés · 900 DT en cours de paiement par les joueurs ».
  final num collected;
  final num inPayment;
}

/// One weekly payout to the venue's bank account (OWN-25 « Versements »).
@immutable
class OwnerPayout {
  const OwnerPayout({required this.date, required this.amount, this.ref, this.from, this.to});

  final DateTime date;
  final num amount;

  /// « VR-2026-0412 »; null while it is only planned.
  final String? ref;

  /// The payments it covers, while planned (« du 12 au 18 oct. »).
  final DateTime? from;
  final DateTime? to;

  bool get planned => ref == null;
}

/// Where the money goes and what is on its way (OWN-25 dark card, OWN-10 payout card).
@immutable
class OwnerPayouts {
  const OwnerPayouts({
    required this.next,
    required this.collected,
    required this.collectedFrom,
    required this.collectedTo,
    required this.expected,
    required this.expectedDays,
    required this.bank,
    required this.last4,
    required this.holder,
    required this.history,
  });

  /// The next payout, estimated.
  final OwnerPayout next;

  /// Already taken online since the last payout (« 1 020 DT · du 12 au 16 oct. »).
  final num collected;
  final DateTime collectedFrom;
  final DateTime collectedTo;

  /// Still to come before the payout (« ≈ 390 DT · sam. 17 et dim. 18 oct. »).
  final num expected;
  final List<DateTime> expectedDays;

  /// « Attijari bank », « 1234 », « Arena Five SARL ».
  final String bank;
  final String last4;
  final String holder;

  /// Past payouts, latest first.
  final List<OwnerPayout> history;

  OwnerPayout get last => history.first;
}

enum RevenuePeriod { week, month, year }

/// Revenue over a period (OWN-25): one point per day (per month over 12 months), the totals
/// against the period before, and the online / on-site split.
@immutable
class OwnerRevenue {
  const OwnerRevenue({
    required this.period,
    required this.dates,
    required this.values,
    required this.revenueDelta,
    required this.bookings,
    required this.bookingsDelta,
    required this.online,
  });

  final RevenuePeriod period;

  /// The day (or the month's first day) of each point.
  final List<DateTime> dates;
  final List<double> values;

  /// Percent change vs the period before.
  final int revenueDelta;
  final int bookings;
  final int bookingsDelta;

  /// Paid online (paid out on Mondays); the rest was taken at the desk.
  final num online;

  num get total => values.fold<double>(0, (a, b) => a + b);
  num get onSite => total - online;
  int get onlinePercent => total == 0 ? 0 : (online / total * 100).round();
}

/// Arena Five's money. Until a backend exists [FakeOwnerRevenueRepository] serves the story
/// (OWN-10, OWN-25).
abstract interface class OwnerRevenueRepository {
  Future<OwnerTodaySummary> today();
  Future<OwnerPayouts> payouts();
  Future<OwnerRevenue> revenue(RevenuePeriod period);
}

class FakeOwnerRevenueRepository implements OwnerRevenueRepository {
  FakeOwnerRevenueRepository({this.latency = const Duration(milliseconds: 300)});

  final Duration latency;

  Future<void> _wait() => Future<void>.delayed(latency);

  /// 17 sept. → 16 oct. (OWN-25 source), ending on today's 1 140 DT.
  static const _days = <double>[
    740, 920, 1150, 1010, 660, 670, 690, 790, 940, 1160, //
    1040, 620, 700, 810, 770, 990, 1220, 1180, 700, 720,
    850, 780, 1100, 1210, 1120, 660, 730, 860, 810, 1140,
  ];

  /// nov. 2025 → oct. 2026 (October so far).
  static const _months = <double>[
    21480,
    17920,
    15360,
    16840,
    19210,
    22650,
    24380,
    19940,
    17260,
    23120,
    25870,
    14840,
  ];

  @override
  Future<OwnerTodaySummary> today() async {
    await _wait();
    return OwnerTodaySummary(
      compareTo: Story.at(9, 0),
      occupancy: 78,
      occupancyDelta: 6,
      revenue: 1140,
      revenueDelta: 12,
      bookings: 14,
      bookingsDelta: 2,
      noShows: 1,
      noShowsDelta: 0,
      collected: 1140,
      inPayment: 900,
    );
  }

  @override
  Future<OwnerPayouts> payouts() async {
    await _wait();
    return OwnerPayouts(
      next: OwnerPayout(
        date: Story.at(19, 0),
        amount: 1410,
        from: Story.at(12, 0),
        to: Story.at(18, 0),
      ),
      collected: 1020,
      collectedFrom: Story.at(12, 0),
      collectedTo: Story.at(16, 0),
      expected: 390,
      expectedDays: [Story.at(17, 0), Story.at(18, 0)],
      bank: 'Attijari bank',
      last4: '1234',
      holder: 'Arena Five SARL',
      history: [
        OwnerPayout(date: Story.at(12, 0), amount: 1250, ref: 'VR-2026-0412'),
        OwnerPayout(date: Story.at(5, 0), amount: 1080, ref: 'VR-2026-0398'),
        OwnerPayout(date: DateTime(2026, 9, 28), amount: 940, ref: 'VR-2026-0383'),
      ],
    );
  }

  @override
  Future<OwnerRevenue> revenue(RevenuePeriod period) async {
    await _wait();
    final today = Story.at(16, 0);
    return switch (period) {
      RevenuePeriod.week => OwnerRevenue(
        period: period,
        dates: [for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i))],
        values: _days.sublist(_days.length - 7),
        revenueDelta: 9,
        bookings: 76,
        bookingsDelta: 6,
        online: 1130,
      ),
      RevenuePeriod.month => OwnerRevenue(
        period: period,
        dates: [for (var i = 29; i >= 0; i--) today.subtract(Duration(days: i))],
        values: _days,
        revenueDelta: 14,
        bookings: 312,
        bookingsDelta: 28,
        online: 4610,
      ),
      RevenuePeriod.year => OwnerRevenue(
        period: period,
        dates: [for (var i = 11; i >= 0; i--) DateTime(today.year, today.month - i)],
        values: _months,
        revenueDelta: 18,
        bookings: 3184,
        bookingsDelta: 412,
        online: 41230,
      ),
    };
  }
}

final ownerRevenueRepositoryProvider = Provider<OwnerRevenueRepository>(
  (ref) => FakeOwnerRevenueRepository(),
);

final ownerTodaySummaryProvider = FutureProvider<OwnerTodaySummary>(
  (ref) => ref.watch(ownerRevenueRepositoryProvider).today(),
);

final ownerPayoutsProvider = FutureProvider<OwnerPayouts>(
  (ref) => ref.watch(ownerRevenueRepositoryProvider).payouts(),
);

final ownerRevenueProvider = FutureProvider.family<OwnerRevenue, RevenuePeriod>(
  (ref, period) => ref.watch(ownerRevenueRepositoryProvider).revenue(period),
);
