import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/data/story_data.dart';
import '../../home/controllers/home_providers.dart';
import '../../payments/data/payment_repository.dart';
import '../../profile/data/me_repository.dart';

enum RefundReason { venueClosed, gameCancelled, paidTwice, other }

extension RefundReasonLabel on RefundReason {
  String get label => switch (this) {
    RefundReason.venueClosed => 'Terrain fermé',
    RefundReason.gameCancelled => 'Partie annulée',
    RefundReason.paidTwice => 'Payé deux fois',
    RefundReason.other => 'Autre',
  };
}

enum RefundTarget { balance, card }

enum RefundStage { sent, reviewing, refunded }

/// A refund request (WAL-04 / WAL-05).
@immutable
class RefundRequest {
  const RefundRequest({
    required this.id,
    required this.transaction,
    required this.reason,
    required this.note,
    required this.target,
    required this.sentAt,
    this.reviewingSince,
    this.photos = 0,
    this.stage = RefundStage.sent,
  });

  final String id;
  final MuTransaction transaction;
  final RefundReason reason;
  final String note;
  final RefundTarget target;
  final DateTime sentAt;
  final DateTime? reviewingSince;
  final int photos;
  final RefundStage stage;

  num get amount => transaction.amount.abs();
}

/// The wallet: the balance (shared with [MeRepository]), the history and the refund requests.
abstract interface class WalletRepository {
  Future<List<MuTransaction>> history();
  Future<List<RefundRequest>> refunds();

  /// Adds a line after a payment, top-up or refund.
  Future<void> record(MuTransaction tx);
  Future<RefundRequest> requestRefund({
    required MuTransaction transaction,
    required RefundReason reason,
    required String note,
    required RefundTarget target,
    int photos = 0,
  });
}

/// The story's history (STORY-DATA « Wallet »), newest first, and the Hoop Zone refund request.
class FakeWalletRepository implements WalletRepository {
  FakeWalletRepository({this.latency = const Duration(milliseconds: 500)});

  final Duration latency;

  static final MuTransaction hoopZone = MuTransaction(
    id: 'tx-hoop',
    kind: MuTransactionKind.booking,
    sport: MuSport.basketball,
    label: 'Part · Hoop Zone',
    meta: 'dim. 27 sept. · Carte •••• 4242',
    amount: -9,
    date: DateTime(2026, 9, 27, 18),
  );

  final _history = <MuTransaction>[
    MuTransaction(
      id: 'tx-share-oct21',
      kind: MuTransactionKind.booking,
      sport: MuSport.football,
      label: 'Part · Arena Five, mer. 21 oct.',
      meta: 'ven. 16 oct. · 18h02 · Carte •••• 4242',
      amount: -15,
      date: Story.at(16, 18, 2),
    ),
    MuTransaction(
      id: 'tx-refund-oct9',
      kind: MuTransactionKind.refund,
      label: 'Remboursement · Arena Five',
      meta: 'ven. 9 oct. · partie annulée',
      amount: 15,
      date: Story.at(9, 14, 12),
      fromBalance: true,
    ),
    MuTransaction(
      id: 'tx-padel-oct9',
      kind: MuTransactionKind.booking,
      sport: MuSport.padel,
      label: 'Part · Smash Padel Club',
      meta: 'ven. 9 oct. · Solde MatchUp',
      amount: -20,
      date: Story.at(9, 19),
      fromBalance: true,
    ),
    MuTransaction(
      id: 'tx-arena-oct6',
      kind: MuTransactionKind.booking,
      sport: MuSport.football,
      label: 'Part · Arena Five',
      meta: 'mar. 6 oct. · Solde MatchUp',
      amount: -15,
      date: Story.at(6, 12),
      fromBalance: true,
      status: MuTransactionStatus.refunded,
    ),
    MuTransaction(
      id: 'tx-topup-oct5',
      kind: MuTransactionKind.topup,
      label: 'Recharge',
      meta: 'lun. 5 oct. · Carte Visa •••• 4242',
      amount: 50,
      date: Story.at(5, 10),
      fromBalance: true,
    ),
    MuTransaction(
      id: 'tx-arena-oct3',
      kind: MuTransactionKind.booking,
      sport: MuSport.football,
      label: 'Part · Arena Five',
      meta: 'sam. 3 oct. · Carte •••• 4242',
      amount: -15,
      date: Story.at(3, 20),
    ),
    hoopZone,
  ];

  final _refunds = <RefundRequest>[
    RefundRequest(
      id: 'rf-hoop',
      transaction: hoopZone,
      reason: RefundReason.venueClosed,
      note: 'Le terrain était fermé à notre arrivée.',
      target: RefundTarget.balance,
      sentAt: Story.at(12, 9, 30),
      reviewingSince: Story.at(13, 10),
      photos: 1,
      stage: RefundStage.reviewing,
    ),
  ];

  @override
  Future<List<MuTransaction>> history() async {
    await Future<void>.delayed(latency);
    return [..._history]..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<List<RefundRequest>> refunds() async {
    await Future<void>.delayed(latency);
    return [..._refunds];
  }

  @override
  Future<void> record(MuTransaction tx) async => _history.insert(0, tx);

  @override
  Future<RefundRequest> requestRefund({
    required MuTransaction transaction,
    required RefundReason reason,
    required String note,
    required RefundTarget target,
    int photos = 0,
  }) async {
    await Future<void>.delayed(latency);
    final r = RefundRequest(
      id: 'rf-${_refunds.length + 1}',
      transaction: transaction,
      reason: reason,
      note: note,
      target: target,
      sentAt: DateTime.now(),
      photos: photos,
    );
    _refunds.insert(0, r);
    return r;
  }
}

final walletRepositoryProvider = Provider<WalletRepository>((ref) => FakeWalletRepository());

final walletHistoryProvider = FutureProvider<List<MuTransaction>>(
  (ref) => ref.watch(walletRepositoryProvider).history(),
);

final refundRequestsProvider = FutureProvider<List<RefundRequest>>(
  (ref) => ref.watch(walletRepositoryProvider).refunds(),
);

/// Wallet moves: a top-up credits the balance, a share paid from it debits it.
class WalletActions {
  const WalletActions(this._ref);

  final Ref _ref;

  Future<void> topUp(num amount, PaymentReceipt receipt) async {
    await _ref.read(meRepositoryProvider).credit(amount);
    await _ref
        .read(walletRepositoryProvider)
        .record(
          MuTransaction(
            id: 'tx-${receipt.number}',
            kind: MuTransactionKind.topup,
            label: 'Recharge',
            meta: '${_when(receipt.paidAt)} · ${receipt.methodLabel}',
            amount: amount,
            date: receipt.paidAt,
            fromBalance: true,
          ),
        );
    _ref
      ..invalidate(meProvider)
      ..invalidate(walletHistoryProvider);
  }

  /// A share paid — from the balance (debited) or by card (listed only).
  Future<void> paid({
    required PaymentReceipt receipt,
    required String label,
    required MuSport sport,
    num? fromBalance,
  }) async {
    if (fromBalance != null && fromBalance > 0) {
      await _ref.read(meRepositoryProvider).debit(fromBalance);
    }
    await _ref
        .read(walletRepositoryProvider)
        .record(
          MuTransaction(
            id: 'tx-${receipt.number}',
            kind: MuTransactionKind.booking,
            sport: sport,
            label: label,
            meta: '${_when(receipt.paidAt)} · ${receipt.methodLabel}',
            amount: -receipt.amount,
            date: receipt.paidAt,
            fromBalance: receipt.method == PayWith.balance,
          ),
        );
    _ref
      ..invalidate(meProvider)
      ..invalidate(walletHistoryProvider);
  }

  static String _when(DateTime d) {
    const days = ['lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.', 'dim.'];
    const months = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];
    return '${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]} · ${d.hour}h${d.minute.toString().padLeft(2, '0')}';
  }
}

final walletActionsProvider = Provider<WalletActions>(WalletActions.new);
