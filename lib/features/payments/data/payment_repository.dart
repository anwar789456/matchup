import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
enum PayWith { card, balance, applePay, googlePay }

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

  /// The checkout's payment; the status says what the screen does next.
  Future<PaymentResult> charge({
    required num amount,
    required String reason,
    required PayWith method,
    PaymentCard? card,
  });

  /// After the bank's 3-D Secure step.
  Future<PaymentResult> confirmAuthentication({required bool approved});

  /// After a network error: was the last attempt charged?
  Future<PaymentResult> checkStatus();

  Future<PromoResult> applyPromo(String code);
}

/// Succeeds after 1 s, or plays the outcome of [PaymentOutcomeController].
class FakePaymentRepository implements PaymentRepository {
  FakePaymentRepository({
    this.latency = const Duration(seconds: 1),
    PaymentOutcome Function()? outcome,
  }) : _outcome = outcome ?? (() => PaymentOutcome.success);

  final Duration latency;
  final PaymentOutcome Function() _outcome;
  final _cards = <PaymentCard>[
    const PaymentCard(id: 'visa-4242', brand: CardBrand.visa, last4: '4242', expMonth: 8, expYear: 2027, isDefault: true),
    const PaymentCard(id: 'mc-5454', brand: CardBrand.mastercard, last4: '5454', expMonth: 11, expYear: 2026),
  ];
  int _receipts = 1482;
  ({num amount, PayWith method, PaymentCard? card})? _pending;

  PaymentReceipt _receipt(num amount, PayWith method, PaymentCard? card) => PaymentReceipt(
    number: 'MU-R-2026-${(_receipts++).toString().padLeft(5, '0')}',
    amount: amount,
    paidAt: DateTime.now(),
    method: method,
    card: card ?? (method == PayWith.card ? _cards.first : null),
  );

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
  }) async {
    await Future<void>.delayed(latency);
    _pending = (amount: amount, method: method, card: card);
    // The balance never fails: only the bank does.
    if (method == PayWith.balance) {
      return PaymentResult(PaymentStatus.success, receipt: _receipt(amount, method, null));
    }
    return switch (_outcome()) {
      PaymentOutcome.success => PaymentResult(
        PaymentStatus.success,
        receipt: _receipt(amount, method, card),
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
    };
  }

  @override
  Future<PaymentResult> confirmAuthentication({required bool approved}) async {
    await Future<void>.delayed(latency);
    final p = _pending;
    if (!approved || p == null) {
      return const PaymentResult(PaymentStatus.declined, reason: 'authentification annulée');
    }
    return PaymentResult(PaymentStatus.success, receipt: _receipt(p.amount, p.method, p.card));
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
    return switch (upper) {
      'BIENVENUE10' => PromoResult(code: upper, percent: 10),
      'MARSA2025' => PromoResult(code: upper, error: 'Ce code a expiré le 31 déc. 2025.'),
      _ => PromoResult(code: upper, error: 'Ce code n’existe pas.'),
    };
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

final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => FakePaymentRepository(outcome: () => ref.read(paymentOutcomeProvider)),
);

final paymentCardsProvider = FutureProvider<List<PaymentCard>>(
  (ref) => ref.watch(paymentRepositoryProvider).cards(),
);
