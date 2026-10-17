import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/ui.dart';
import '../../common/data/story_data.dart';
import '../../payments/data/receipt.dart';

export '../../payments/data/receipt.dart';

/// Where the player's Premium stands (STORY-DATA « Premium story »).
enum PremiumStatus {
  /// Offre Gratuit.
  free,

  /// 14-day trial, first charge on ven. 30 oct.
  trial,

  /// Cancelled: Premium stays active until the end of the paid (or trial) period, then Gratuit.
  cancelled,
}

/// « Trop cher », « Je ne joue pas assez »… (SUB-06).
enum CancelReason {
  price('Trop cher'),
  notEnough('Je ne joue pas assez'),
  feature('Il manque une fonctionnalité'),
  other('Autre');

  const CancelReason(this.label);
  final String label;
}

/// The player's subscription.
@immutable
class Subscription {
  const Subscription({
    required this.status,
    required this.period,
    required this.trialEnds,
    required this.reminder,
    this.cardLabel = 'Visa •••• 4242',
    this.offerAccepted = false,
    this.cancelReason,
  });

  final PremiumStatus status;
  final MuBillingPeriod period;

  /// ven. 30 oct.: end of the trial, first charge.
  final DateTime trialEnds;

  /// mar. 27 oct.: the reminder 3 days before.
  final DateTime reminder;
  final String cardLabel;

  /// The −30 % retention offer (SUB-07) for the next 2 months.
  final bool offerAccepted;
  final CancelReason? cancelReason;

  static const monthly = 19;
  static const yearly = 190;
  static const trialDays = 14;

  /// −30 % for 2 months: 13,300 DT.
  static const num offerMonthly = 13.3;

  bool get premium => status != PremiumStatus.free;
  bool get yearlyPlan => period == MuBillingPeriod.year;

  /// What the next charge takes: 19, 190, or 13,300 with the retention offer.
  num get nextCharge => offerAccepted ? offerMonthly : (yearlyPlan ? yearly : monthly);
  num get price => yearlyPlan ? yearly : monthly;

  Subscription copyWith({
    PremiumStatus? status,
    MuBillingPeriod? period,
    String? cardLabel,
    bool? offerAccepted,
    CancelReason? Function()? cancelReason,
  }) => Subscription(
    status: status ?? this.status,
    period: period ?? this.period,
    trialEnds: trialEnds,
    reminder: reminder,
    cardLabel: cardLabel ?? this.cardLabel,
    offerAccepted: offerAccepted ?? this.offerAccepted,
    cancelReason: cancelReason == null ? this.cancelReason : cancelReason(),
  );
}

/// Plan changes. Until a backend exists, [FakeSubscriptionRepository] keeps the state in memory.
abstract interface class SubscriptionRepository {
  Future<Subscription> current();
  Future<Subscription> startTrial({required MuBillingPeriod period, required String cardLabel});
  Future<Subscription> changePeriod(MuBillingPeriod period);
  Future<Subscription> cancel({CancelReason? reason, String? note});
  Future<Subscription> acceptOffer();
  Future<Subscription> reactivate();
  Future<List<ReceiptEntry>> receipts();
}

/// Starts on Gratuit (STORY: Yassine starts the trial ven. 16 oct.).
class FakeSubscriptionRepository implements SubscriptionRepository {
  FakeSubscriptionRepository({
    this.latency = const Duration(milliseconds: 400),
    PremiumStatus initial = PremiumStatus.free,
  }) : _sub = Subscription(
         status: initial,
         period: MuBillingPeriod.month,
         trialEnds: Story.at(30, 0),
         reminder: Story.at(27, 0),
       );

  final Duration latency;
  Subscription _sub;

  Future<Subscription> _set(Subscription s) async {
    await Future<void>.delayed(latency);
    return _sub = s;
  }

  @override
  Future<Subscription> current() async => _sub;

  @override
  Future<Subscription> startTrial({required MuBillingPeriod period, required String cardLabel}) =>
      _set(
        _sub.copyWith(
          status: PremiumStatus.trial,
          period: period,
          cardLabel: cardLabel,
          offerAccepted: false,
          cancelReason: () => null,
        ),
      );

  @override
  Future<Subscription> changePeriod(MuBillingPeriod period) => _set(_sub.copyWith(period: period));

  @override
  Future<Subscription> cancel({CancelReason? reason, String? note}) => _set(
    _sub.copyWith(
      status: PremiumStatus.cancelled,
      offerAccepted: false,
      cancelReason: () => reason,
    ),
  );

  @override
  Future<Subscription> acceptOffer() => _set(
    _sub.copyWith(status: PremiumStatus.trial, offerAccepted: true, period: MuBillingPeriod.month),
  );

  @override
  Future<Subscription> reactivate() =>
      _set(_sub.copyWith(status: PremiumStatus.trial, cancelReason: () => null));

  @override
  Future<List<ReceiptEntry>> receipts() async => [
    ReceiptEntry(
      number: 'MU-R-2026-01482',
      label: 'Part Arena Five · MU-48213',
      date: Story.at(16, 18),
      amount: 15,
      card: 'Visa •••• 4242',
      reference: 'MU-48213',
      lines: const [
        ReceiptLine(
          'Part de réservation MU-48213',
          15,
          details: [
            'Arena Five · Terrain 1, La Marsa',
            'mer. 21 oct. 2026 · 21h00–22h00',
            'Ta part : 1 joueur sur 10 · terrain à 150 DT',
          ],
        ),
        ReceiptLine('Frais de service', 0, details: ['Offerts']),
      ],
      policy:
          'Gratuite jusqu’au mar. 20 oct. · 21h00, puis 50 % jusqu’au mer. 21 oct. · 15h00. '
          'Remboursement sur le solde MatchUp.',
    ),
    ReceiptEntry(
      number: 'MU-R-2026-01437',
      label: 'Recharge du solde',
      date: Story.at(5, 12, 10),
      amount: 50,
      card: 'Visa •••• 4242',
      lines: const [ReceiptLine('Recharge du solde MatchUp', 50)],
    ),
    ReceiptEntry(
      number: 'MU-R-2026-01391',
      label: 'Part Hoop Zone',
      date: DateTime(2026, 9, 27, 19),
      amount: 9,
      card: 'Visa •••• 4242',
      lines: const [
        ReceiptLine('Part de réservation · Hoop Zone', 9, details: ['Basket 3 vs 3']),
      ],
    ),
  ];
}

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>(
  (ref) => FakeSubscriptionRepository(),
);

final receiptsProvider = FutureProvider<List<ReceiptEntry>>(
  (ref) => ref.watch(subscriptionRepositoryProvider).receipts(),
);
