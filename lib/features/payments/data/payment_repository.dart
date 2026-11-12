import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import 'sqlite_payment_repository.dart';

enum CardBrand { visa, mastercard }

/// A saved card (STORY-DATA « Milestones 4–5 »: Visa 4242 default, Mastercard 5454 expiring).
@immutable
class PaymentCard {
  const PaymentCard({
    required this.id,
    required this.brand,
    required this.last4,
    required this.expMonth,
    required this.expYear,
    this.isDefault = false,
  });

  final String id;
  final CardBrand brand;
  final String last4;
  final int expMonth;
  final int expYear;
  final bool isDefault;

  String get brandLabel => brand == CardBrand.visa ? 'Visa' : 'Mastercard';
  String get mark => brand == CardBrand.visa ? 'VISA' : 'MC';

  /// « Visa •••• 4242 ».
  String get label => '$brandLabel •••• $last4';

  /// « 08/27 ».
  String get expiry => '${expMonth.toString().padLeft(2, '0')}/${expYear % 100}';

  /// Expires next month from the story's « now » (oct. 2026).
  bool get expiresSoon => expYear == 2026 && expMonth == 11;
}

/// How the share is paid.
enum PayWith { card, balance, applePay, googlePay, stripe }

/// The outcome the debug menu picks for the next fake payment (CLAUDE.md rule 10).
enum PaymentOutcome { success, threeDSecure, declined, networkError, timeout }

extension PaymentOutcomeLabel on PaymentOutcome {
  String get label => switch (this) {
    PaymentOutcome.success => 'Succès',
    PaymentOutcome.threeDSecure => '3-D Secure',
    PaymentOutcome.declined => 'Carte refusée',
    PaymentOutcome.networkError => 'Erreur réseau',
    PaymentOutcome.timeout => 'Délai dépassé',
  };
}

enum PaymentStatus { success, needsAuthentication, declined, networkError, timeout }

/// A payment that went through.
@immutable
class PaymentReceipt {
  const PaymentReceipt({
    required this.number,
    required this.amount,
    required this.paidAt,
    required this.method,
    this.card,
  });

  /// « MU-R-2026-01482 ».
  final String number;
  final num amount;
  final DateTime paidAt;
  final PayWith method;
  final PaymentCard? card;

  /// « Visa •••• 4242 », « Solde MatchUp ».
  String get methodLabel => switch (method) {
    PayWith.card => card?.label ?? 'Carte',
    PayWith.balance => 'Solde MatchUp',
    PayWith.applePay => 'Apple Pay',
    PayWith.googlePay => 'Google Pay',
    PayWith.stripe => card != null && card!.last4.isNotEmpty ? '${card!.label} · Stripe' : 'Carte · Stripe',
  };
}

@immutable
class PaymentResult {
  const PaymentResult(this.status, {this.receipt, this.reason, this.attemptAt});

  final PaymentStatus status;
  final PaymentReceipt? receipt;

  /// Declined: « fonds insuffisants ».
  final String? reason;
  final DateTime? attemptAt;
}

@immutable
class PromoResult {
  const PromoResult({required this.code, this.percent, this.error});

  final String code;

  /// −10 % when valid.
  final int? percent;

  /// « Ce code a expiré le 31 déc. 2025. ».
  final String? error;

  bool get valid => percent != null;
}

/// Card payments. Until a backend exists every payment goes through [FakePaymentRepository],
/// whose outcome is chosen in the debug menu (CLAUDE.md rule 10).
abstract interface class PaymentRepository {
  /// The old one-call payment kept for simple flows: succeeds after the latency.
  Future<PaymentReceipt> pay(num amount, {required String reason});

  Future<List<PaymentCard>> cards();
  Future<PaymentCard> addCard({required CardBrand brand, required String last4, required int expMonth, required int expYear, bool save = true});

  /// The checkout's payment; the status says what the screen does next. [reference] is what it
  /// pays for (booking « MU-48213 », game « g1 »), null for a top-up or Premium.
  Future<PaymentResult> charge({
    required num amount,
    required String reason,
    required PayWith method,
    PaymentCard? card,
    String? reference,
  });

  /// After the bank's 3-D Secure step.
  Future<PaymentResult> confirmAuthentication({required bool approved});

  /// After a network error: was the last attempt charged?
  Future<PaymentResult> checkStatus();

  Future<PromoResult> applyPromo(String code);

  /// The payments that went through, newest first, optionally for one [reference].
  Future<List<PaymentRecord>> payments({String? reference});

  /// Every try at the bank, failed ones included, newest first.
  Future<List<PaymentAttempt>> attempts({String? reference});

  /// A card payment Stripe accepted (test mode): numbered and kept like the others, with the
  /// PaymentIntent id (« pi_… ») in place of a saved card.
  Future<PaymentReceipt> recordStripe({
    required num amount,
    required String reason,
    required String intentId,
    String? reference,
    CardBrand? brand,
    String? last4,
  });
}

/// The stand-in card of a Stripe payment: its id is `stripe:<PaymentIntent id>`.
PaymentCard stripeCard(String intentId, CardBrand? brand, String? last4) => PaymentCard(
  id: 'stripe:$intentId',
  brand: brand ?? CardBrand.visa,
  last4: last4 ?? '',
  expMonth: 0,
  expYear: 0,
);

/// A payment that went through, as stored: paid, or refunded later.
@immutable
class PaymentRecord {
  const PaymentRecord({
    required this.number,
    required this.amount,
    required this.paidAt,
    required this.method,
    this.cardId,
    this.reason,
    this.reference,
    this.refundedAt,
  });

  final String number;
  final num amount;
  final DateTime paidAt;
  final PayWith method;
  final String? cardId;
  final String? reason;
  final String? reference;
  final DateTime? refundedAt;

  bool get refunded => refundedAt != null;

  /// « pi_3Q… » for a payment made with Stripe.
  String? get stripeIntentId => cardId != null && cardId!.startsWith('stripe:') ? cardId!.substring(7) : null;
}

enum AttemptState { pending, paid, failed }

/// How a bank answer is kept as an attempt.
extension PaymentResultAttempt on PaymentResult {
  AttemptState get attemptState => switch (status) {
    PaymentStatus.success => AttemptState.paid,
    PaymentStatus.needsAuthentication => AttemptState.pending,
    _ => AttemptState.failed,
  };

  /// The bank's reason when declined, the status name when the network failed.
  String? get failure => switch (status) {
    PaymentStatus.declined => reason,
    PaymentStatus.networkError || PaymentStatus.timeout => status.name,
    _ => null,
  };
}

/// One try at the bank (« en attente » while 3-D Secure runs).
@immutable
class PaymentAttempt {
  const PaymentAttempt({
    required this.amount,
    required this.method,
    required this.state,
    required this.at,
    this.reason,
    this.reference,
    this.failure,
    this.receiptNumber,
  });

  final num amount;
  final PayWith method;
  final AttemptState state;
  final DateTime at;
  final String? reason;
  final String? reference;

  /// « fonds insuffisants », « networkError », « timeout »…
  final String? failure;
  final String? receiptNumber;
}

/// Succeeds after 1 s, or plays the outcome of [PaymentOutcomeController].
class FakePaymentRepository implements PaymentRepository {
  FakePaymentRepository({
    this.latency = const Duration(seconds: 1),
    PaymentOutcome Function()? outcome,
  }) : _outcome = outcome ?? (() => PaymentOutcome.success);

  final Duration latency;
  final PaymentOutcome Function() _outcome;
  final _cards = [...storyCards];

  /// Visa 4242 by default, Mastercard 5454 expiring next month.
  static const storyCards = <PaymentCard>[
    PaymentCard(id: 'visa-4242', brand: CardBrand.visa, last4: '4242', expMonth: 8, expYear: 2027, isDefault: true),
    PaymentCard(id: 'mc-5454', brand: CardBrand.mastercard, last4: '5454', expMonth: 11, expYear: 2026),
  ];

  /// The promo codes the checkout knows: valid (percent) or refused (message).
  static const storyPromos = <String, ({int? percent, String? error})>{
    'BIENVENUE10': (percent: 10, error: null),
    'MARSA2025': (percent: null, error: 'Ce code a expiré le 31 déc. 2025.'),
  };

  /// The first receipt number of the story, « MU-R-2026-01482 ».
  static const firstReceipt = 1482;

  static const unknownPromo = 'Ce code n’existe pas.';

  int _receipts = firstReceipt;
  ({num amount, PayWith method, PaymentCard? card, String reason, String? reference})? _pending;
  final _payments = <PaymentRecord>[];
  final _attempts = <PaymentAttempt>[];

  PaymentReceipt _receipt(num amount, PayWith method, PaymentCard? card, {String reason = '', String? reference}) {
    final receipt = PaymentReceipt(
      number: 'MU-R-2026-${(_receipts++).toString().padLeft(5, '0')}',
      amount: amount,
      paidAt: DateTime.now(),
      method: method,
      card: card ?? (method == PayWith.card ? _cards.first : null),
    );
    _payments.insert(
      0,
      PaymentRecord(
        number: receipt.number,
        amount: amount,
        paidAt: receipt.paidAt,
        method: method,
        cardId: receipt.card?.id,
        reason: reason,
        reference: reference,
      ),
    );
    return receipt;
  }

  PaymentResult _log(PaymentResult result, {required num amount, required PayWith method, required String reason, String? reference}) {
    _attempts.insert(
      0,
      PaymentAttempt(
        amount: amount,
        method: method,
        state: result.attemptState,
        at: DateTime.now(),
        reason: reason,
        reference: reference,
        failure: result.failure,
        receiptNumber: result.receipt?.number,
      ),
    );
    return result;
  }

  @override
  Future<List<PaymentRecord>> payments({String? reference}) async => [
    for (final p in _payments)
      if (reference == null || p.reference == reference) p,
  ];

  @override
  Future<PaymentReceipt> recordStripe({
    required num amount,
    required String reason,
    required String intentId,
    String? reference,
    CardBrand? brand,
    String? last4,
  }) async {
    final receipt = _receipt(amount, PayWith.stripe, stripeCard(intentId, brand, last4), reason: reason, reference: reference);
    _log(PaymentResult(PaymentStatus.success, receipt: receipt), amount: amount, method: PayWith.stripe, reason: reason, reference: reference);
    return receipt;
  }

  @override
  Future<List<PaymentAttempt>> attempts({String? reference}) async => [
    for (final a in _attempts)
      if (reference == null || a.reference == reference) a,
  ];

  @override
  Future<PaymentReceipt> pay(num amount, {required String reason}) async {
    await Future<void>.delayed(latency);
    return _receipt(amount, PayWith.card, _cards.first);
  }

  @override
  Future<List<PaymentCard>> cards() async => [..._cards];

  @override
  Future<PaymentCard> addCard({required CardBrand brand, required String last4, required int expMonth, required int expYear, bool save = true}) async {
    final card = PaymentCard(id: '${brand.name}-$last4-${_cards.length}', brand: brand, last4: last4, expMonth: expMonth, expYear: expYear);
    if (save) _cards.add(card);
    return card;
  }

  @override
  Future<PaymentResult> charge({
    required num amount,
    required String reason,
    required PayWith method,
    PaymentCard? card,
    String? reference,
  }) async {
    await Future<void>.delayed(latency);
    _pending = (amount: amount, method: method, card: card, reason: reason, reference: reference);
    PaymentResult log(PaymentResult r) => _log(r, amount: amount, method: method, reason: reason, reference: reference);
    // The balance never fails: only the bank does.
    if (method == PayWith.balance) {
      return log(PaymentResult(PaymentStatus.success, receipt: _receipt(amount, method, null, reason: reason, reference: reference)));
    }
    return log(switch (_outcome()) {
      PaymentOutcome.success => PaymentResult(
        PaymentStatus.success,
        receipt: _receipt(amount, method, card, reason: reason, reference: reference),
      ),
      PaymentOutcome.threeDSecure => const PaymentResult(PaymentStatus.needsAuthentication),
      PaymentOutcome.declined => PaymentResult(
        PaymentStatus.declined,
        reason: 'fonds insuffisants',
        attemptAt: DateTime.now(),
      ),
      PaymentOutcome.networkError => PaymentResult(
        PaymentStatus.networkError,
        attemptAt: DateTime.now(),
      ),
      PaymentOutcome.timeout => PaymentResult(PaymentStatus.timeout, attemptAt: DateTime.now()),
    });
  }

  @override
  Future<PaymentResult> confirmAuthentication({required bool approved}) async {
    await Future<void>.delayed(latency);
    final p = _pending;
    if (p == null) {
      return const PaymentResult(PaymentStatus.declined, reason: 'authentification annulée');
    }
    // The waiting attempt gets its answer.
    if (_attempts.firstOrNull?.state == AttemptState.pending) _attempts.removeAt(0);
    final result = approved
        ? PaymentResult(PaymentStatus.success, receipt: _receipt(p.amount, p.method, p.card, reason: p.reason, reference: p.reference))
        : const PaymentResult(PaymentStatus.declined, reason: 'authentification annulée');
    return _log(result, amount: p.amount, method: p.method, reason: p.reason, reference: p.reference);
  }

  @override
  Future<PaymentResult> checkStatus() async {
    await Future<void>.delayed(latency);
    // The interrupted attempt never went through: the player can retry safely.
    return const PaymentResult(PaymentStatus.networkError);
  }

  @override
  Future<PromoResult> applyPromo(String code) async {
    await Future<void>.delayed(latency);
    final upper = code.trim().toUpperCase();
    final promo = storyPromos[upper];
    return PromoResult(
      code: upper,
      percent: promo?.percent,
      error: promo == null ? unknownPromo : promo.error,
    );
  }
}

/// The outcome of the next fake payment, picked in the debug menu.
class PaymentOutcomeController extends Notifier<PaymentOutcome> {
  @override
  PaymentOutcome build() => PaymentOutcome.success;

  void select(PaymentOutcome o) => state = o;
}

final paymentOutcomeProvider = NotifierProvider<PaymentOutcomeController, PaymentOutcome>(
  PaymentOutcomeController.new,
);

/// Cards and payments live in the phone's database; the bank's answer comes from the debug
/// menu. Tests override it with the fake.
final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => SqlitePaymentRepository(
    ref.watch(appDatabaseProvider),
    outcome: () => ref.read(paymentOutcomeProvider),
  ),
);

final paymentCardsProvider = FutureProvider<List<PaymentCard>>(
  (ref) => ref.watch(paymentRepositoryProvider).cards(),
);
