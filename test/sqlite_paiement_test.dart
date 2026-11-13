import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:matchup/core/db/app_database.dart';
import 'package:matchup/core/db/schema.dart';
import 'package:matchup/core/db/seed.dart';
import 'package:matchup/features/common/data/story_data.dart';
import 'package:matchup/features/payments/data/payment_repository.dart';
import 'package:matchup/features/payments/data/split_repository.dart';
import 'package:matchup/features/payments/data/sqlite_payment_repository.dart';
import 'package:matchup/features/profile/data/sqlite_me_repository.dart';
import 'package:matchup/features/wallet/data/sqlite_wallet_repository.dart';
import 'package:matchup/features/wallet/data/wallet_repository.dart';
import 'package:matchup/ui/ui.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Module Paiement (schema v3): payment lifecycle, attempts, split shares, finished refunds.
void main() {
  sqfliteFfiInit();
  late AppDatabase database;

  setUp(() => database = AppDatabase(factory: databaseFactoryFfi, path: inMemoryDatabasePath));
  tearDown(() => database.close());

  SqlitePaymentRepository payments([PaymentOutcome outcome = PaymentOutcome.success]) =>
      SqlitePaymentRepository(database, latency: Duration.zero, outcome: () => outcome);

  test('a v2 file is upgraded to v3: its payments stay paid, the PAY-11 shares appear', () async {
    final dir = await Directory.systemTemp.createTemp('matchup_db');
    final path = '${dir.path}${Platform.pathSeparator}${AppDatabase.fileName}';
    try {
      final v2 = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: (db, _) async {
            for (final v in [1, 2]) {
              for (final s in schemaVersions[v]!) {
                await db.execute(s);
              }
              await seedVersion(db, v);
            }
            await db.insert('paiements', {
              'numero': 'MU-R-2026-01482',
              'montant': 15,
              'paye_le': '2026-10-16T18:02:00.000',
              'moyen': 'card',
              'carte_id': 'visa-4242',
              'motif': 'Arena Five',
            });
          },
        ),
      );
      await v2.close();

      final file = AppDatabase(factory: databaseFactoryFfi, path: path);
      expect(await (await file.db).getVersion(), AppDatabase.version);
      final kept = (await SqlitePaymentRepository(file).payments()).single;
      expect(kept.number, 'MU-R-2026-01482');
      expect(kept.refunded, isFalse);
      final shares = await SqliteSplitRepository(file).shares(Story.myBooking.id!);
      expect(shares.map((s) => (s.person.name, s.state)), [
        ('Ines M.', ShareState.paid),
        ('Lina F.', ShareState.pending),
        ('Rami S.', ShareState.pending),
      ]);
      await file.close();
    } finally {
      await dir.delete(recursive: true);
    }
  });

  group('paiements', () {
    test('every attempt is kept; a payment remembers what it paid for', () async {
      await payments(PaymentOutcome.declined)
          .charge(amount: 15, reason: 'Arena Five', method: PayWith.card, reference: 'MU-48213');
      await payments(PaymentOutcome.networkError)
          .charge(amount: 15, reason: 'Arena Five', method: PayWith.card, reference: 'MU-48213');
      final ok = await payments()
          .charge(amount: 15, reason: 'Arena Five', method: PayWith.card, reference: 'MU-48213');
      await payments().charge(amount: 50, reason: 'Recharge', method: PayWith.card);

      final repo = payments();
      final attempts = await repo.attempts(reference: 'MU-48213');
      expect(attempts.map((a) => (a.state, a.failure)), [
        (AttemptState.paid, null),
        (AttemptState.failed, 'networkError'),
        (AttemptState.failed, 'fonds insuffisants'),
      ]);
      expect(attempts.first.receiptNumber, ok.receipt!.number);

      final forBooking = await repo.payments(reference: 'MU-48213');
      expect(forBooking.single.number, ok.receipt!.number);
      expect(forBooking.single.cardId, isNull, reason: 'no saved card: the bank answered for a typed one');
      expect(await repo.payments(), hasLength(2));
    });

    test('3-D Secure: the waiting attempt is the one that gets paid or refused', () async {
      final repo = payments(PaymentOutcome.threeDSecure);
      await repo.charge(amount: 15, reason: 'Part', method: PayWith.card, reference: 'g1');
      expect((await repo.attempts()).single.state, AttemptState.pending);
      final ok = await repo.confirmAuthentication(approved: true);
      final paid = (await repo.attempts()).single;
      expect(paid.state, AttemptState.paid);
      expect(paid.receiptNumber, ok.receipt!.number);
      expect((await repo.payments(reference: 'g1')).single.amount, 15);

      await repo.charge(amount: 9, reason: 'Part', method: PayWith.card);
      final no = await repo.confirmAuthentication(approved: false);
      expect(no.status, PaymentStatus.declined);
      final refused = (await repo.attempts()).first;
      expect((refused.state, refused.failure), (AttemptState.failed, 'authentification annulée'));
      expect(await repo.payments(), hasLength(1));
    });
  });

  group('suivi des parts (PAY-11)', () {
    final booking = Story.myBooking.id!;

    test('reminders are saved and survive a new repository', () async {
      await SqliteSplitRepository(database).remind(booking, ['Lina F.', 'Ines M.']);
      final shares = await SqliteSplitRepository(database).shares(booking);
      expect([for (final s in shares) if (s.reminded) s.person.name], ['Lina F.']);
    });

    test('« Payer le reste »: the pending shares are advanced with the receipt', () async {
      final receipt = (await payments().charge(
        amount: 30,
        reason: 'Parts avancées',
        method: PayWith.card,
        reference: booking,
      ))
          .receipt!;
      await SqliteSplitRepository(database).advance(booking, receiptNumber: receipt.number);
      final shares = await SqliteSplitRepository(database).shares(booking);
      expect(shares.where((s) => s.state == ShareState.pending), isEmpty);
      final advanced = shares.where((s) => s.state == ShareState.advanced).toList();
      expect(advanced.map((s) => s.person.name), ['Lina F.', 'Rami S.']);
      expect(advanced.every((s) => s.receiptNumber == receipt.number && s.paidAt != null), isTrue);
      expect(shares.first.state, ShareState.paid); // Ines untouched
    });
  });

  group('remboursements', () {
    test('Hoop Zone paid back to the balance: credited once, line refunded', () async {
      final wallet = SqliteWalletRepository(database);
      final me = SqliteMeRepository(database);
      final before = (await me.me()).balance;

      final done = await wallet.completeRefund('rf-hoop');
      expect(done.stage, RefundStage.refunded);
      expect(done.refundedAt, isNotNull);
      expect((await me.me()).balance, before + 9);

      final history = await wallet.history();
      expect(history.firstWhere((t) => t.id == 'tx-hoop').status, MuTransactionStatus.refunded);
      final line = history.firstWhere((t) => t.id == 'tx-rf-hoop');
      expect((line.kind, line.amount, line.label),
          (MuTransactionKind.refund, 9, 'Remboursement · Hoop Zone'));

      await wallet.completeRefund('rf-hoop'); // already done
      expect((await me.me()).balance, before + 9);
    });

    test('a card payment refunded to the card: payment marked, balance untouched', () async {
      final receipt = (await payments().charge(
        amount: 15,
        reason: 'Arena Five',
        method: PayWith.card,
        reference: 'MU-48213',
      ))
          .receipt!;
      final wallet = SqliteWalletRepository(database);
      final tx = MuTransaction(
        id: 'tx-${receipt.number}',
        kind: MuTransactionKind.booking,
        label: 'Part · Arena Five',
        meta: 'ven. 16 oct. · Visa •••• 4242',
        amount: -15,
        date: receipt.paidAt,
      );
      await wallet.record(tx);
      final r = await wallet.requestRefund(
        transaction: tx,
        reason: RefundReason.gameCancelled,
        note: 'Partie annulée',
        target: RefundTarget.card,
      );
      final balance = (await SqliteMeRepository(database).me()).balance;

      await wallet.completeRefund(r.id);
      final paid = (await payments().payments(reference: 'MU-48213')).single;
      expect(paid.refunded, isTrue);
      expect((await SqliteMeRepository(database).me()).balance, balance);
      final history = await wallet.history();
      expect(history.where((t) => t.id == 'tx-${r.id}'), isEmpty); // no balance line
      expect(history.firstWhere((t) => t.id == tx.id).status, MuTransactionStatus.refunded);
    });
  });

  test('the fakes follow the same rules', () async {
    final pay = FakePaymentRepository(latency: Duration.zero, outcome: () => PaymentOutcome.declined);
    await pay.charge(amount: 15, reason: 'Part', method: PayWith.card, reference: 'MU-48213');
    expect((await pay.attempts()).single.failure, 'fonds insuffisants');
    expect(await pay.payments(), isEmpty);

    final split = FakeSplitRepository();
    await split.advance(Story.myBooking.id!, receiptNumber: 'MU-R-2026-01482');
    expect(
      (await split.shares(Story.myBooking.id!)).where((s) => s.state == ShareState.advanced),
      hasLength(2),
    );

    final wallet = FakeWalletRepository(latency: Duration.zero);
    expect((await wallet.completeRefund('rf-hoop')).stage, RefundStage.refunded);
    expect((await wallet.history()).first.id, 'tx-rf-hoop');
  });
}
