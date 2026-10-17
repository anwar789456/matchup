import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A payment that went through.
@immutable
class PaymentReceipt {
  const PaymentReceipt({required this.amount, required this.paidAt});

  final num amount;
  final DateTime paidAt;
}

/// Card payments. The checkout is designed in Milestone 4: until then every « Payer… » button
/// goes through [FakePaymentRepository] (CLAUDE.md rule 10).
abstract interface class PaymentRepository {
  Future<PaymentReceipt> pay(num amount, {required String reason});
}

/// Succeeds after 1 s.
class FakePaymentRepository implements PaymentRepository {
  const FakePaymentRepository({this.latency = const Duration(seconds: 1)});

  final Duration latency;

  @override
  Future<PaymentReceipt> pay(num amount, {required String reason}) async {
    await Future<void>.delayed(latency);
    return PaymentReceipt(amount: amount, paidAt: DateTime.now());
  }
}

final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => const FakePaymentRepository(),
);
