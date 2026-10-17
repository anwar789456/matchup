import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/theme.dart';
import '../data/payment_repository.dart';

enum CheckoutKind { share, topUp, advance, subscription }

/// What a checkout is for: the summary card, the lines of the total, the policy and what to do
/// once paid. Set with [checkoutRequestProvider] before opening PAY-01.
@immutable
class CheckoutRequest {
  const CheckoutRequest({
    required this.kind,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.lineLabel,
    required this.sport,
    required this.onPaid,
    this.reference,
    this.detailRows = const [],
    this.policy,
    this.policyVenue,
    this.spotsLine,
    this.successRoute,
    this.balanceAllowed = true,
    this.promoAllowed = true,
    this.extraInfo = const [],
    this.termsLabel = 'conditions de réservation',
    this.termsSuffix,
    this.lineup,
    this.publicGame = false,
  });

  final CheckoutKind kind;

  /// « TA PART · RÉSERVATION MU-48213 ».
  final String eyebrow;

  /// « Arena Five · Terrain 1 ».
  final String title;

  /// « mer. 21 oct. · 21h00 – 22h00 · Foot 5 vs 5 ».
  final String subtitle;
  final num amount;

  /// « Ta part · 1 joueur sur 10 ».
  final String lineLabel;
  final MuSport sport;
  final String? reference;

  /// (label, value, caption) rows of « Voir le détail ».
  final List<(String, String, String?)> detailRows;

  /// (free until, half until) of the cancellation policy.
  final (DateTime, DateTime)? policy;
  final String? policyVenue;

  /// « Ta part : 15 DT sur 150 DT » line.
  final String? spotsLine;

  /// Where to go after PAY-09 « Terminé » (or right after success when there is no PAY-09).
  final String? successRoute;
  final bool balanceAllowed;
  final bool promoAllowed;

  /// (icon label, title, text) « Bon à savoir » rows of a top-up.
  final List<(String, String)> extraInfo;
  final String termsLabel;
  final String? termsSuffix;

  /// (players in, players total) of the booking, for PAY-09's ticket and « Encore 4 places ».
  final (int, int)? lineup;

  /// The booking is a public game, visible in Explorer.
  final bool publicGame;

  /// Called once the payment went through, with how much came from the balance.
  final Future<void> Function(PaymentReceipt receipt, num fromBalance) onPaid;
}

/// The checkout in flight (one at a time).
class CheckoutRequestController extends Notifier<CheckoutRequest?> {
  @override
  CheckoutRequest? build() => null;

  void start(CheckoutRequest request) => state = request;
  void clear() => state = null;
}

final checkoutRequestProvider = NotifierProvider<CheckoutRequestController, CheckoutRequest?>(
  CheckoutRequestController.new,
);

/// The last successful payment, for PAY-09.
class LastPaymentController extends Notifier<(CheckoutRequest, PaymentReceipt)?> {
  @override
  (CheckoutRequest, PaymentReceipt)? build() => null;

  void set(CheckoutRequest request, PaymentReceipt receipt) => state = (request, receipt);
}

final lastPaymentProvider =
    NotifierProvider<LastPaymentController, (CheckoutRequest, PaymentReceipt)?>(
      LastPaymentController.new,
    );
