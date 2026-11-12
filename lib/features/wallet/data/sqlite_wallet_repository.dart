import 'package:sqflite/sqflite.dart';

import '../../../core/db/app_database.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import 'wallet_repository.dart';

/// [WalletRepository] on the phone's database: the history in `transactions`, the refund
/// requests in `demandes_remboursement` (each pointing at its transaction).
class SqliteWalletRepository implements WalletRepository {
  SqliteWalletRepository(this._database);

  final AppDatabase _database;

  Future<Database> get _db => _database.db;

  static Map<String, Object?> transactionRow(MuTransaction t) => {
        'id': t.id,
        'type': t.kind.name,
        'sport': t.sport?.name,
        'libelle': t.label,
        'detail': t.meta,
        'montant': t.amount,
        'date': t.date.toIso8601String(),
        'statut': t.status.name,
        'depuis_solde': t.fromBalance ? 1 : 0,
      };

  static MuTransaction transaction(Map<String, Object?> r) => MuTransaction(
        id: r['id']! as String,
        kind: MuTransactionKind.values.byName(r['type']! as String),
        sport: r['sport'] == null ? null : MuSport.values.byName(r['sport']! as String),
        label: r['libelle']! as String,
        meta: r['detail']! as String,
        amount: r['montant']! as num,
        date: DateTime.parse(r['date']! as String),
        status: MuTransactionStatus.values.byName(r['statut']! as String),
        fromBalance: r['depuis_solde'] == 1,
      );

  static Map<String, Object?> _refundRow(RefundRequest r) => {
        'id': r.id,
        'transaction_id': r.transaction.id,
        'motif': r.reason.name,
        'note': r.note,
        'cible': r.target.name,
        'envoyee_le': r.sentAt.toIso8601String(),
        'examen_depuis': r.reviewingSince?.toIso8601String(),
        'photos': r.photos,
        'etape': r.stage.name,
      };

  static Future<void> seed(DatabaseExecutor db) async {
    for (final t in FakeWalletRepository.storyHistory) {
      await db.insert('transactions', transactionRow(t));
    }
    for (final r in FakeWalletRepository.storyRefunds) {
      await db.insert('demandes_remboursement', _refundRow(r));
    }
  }

  @override
  Future<List<MuTransaction>> history() async =>
      [for (final r in await (await _db).query('transactions', orderBy: 'date DESC')) transaction(r)];

  @override
  Future<List<RefundRequest>> refunds() async {
    final rows = await (await _db).rawQuery(
      'SELECT d.*, t.type, t.sport, t.libelle, t.detail, t.montant, t.date, t.statut, '
      't.depuis_solde FROM demandes_remboursement d '
      'JOIN transactions t ON t.id = d.transaction_id ORDER BY d.envoyee_le DESC',
    );
    return [
      for (final r in rows)
        RefundRequest(
          id: r['id']! as String,
          transaction: transaction({...r, 'id': r['transaction_id']}),
          reason: RefundReason.values.byName(r['motif']! as String),
          note: r['note']! as String,
          target: RefundTarget.values.byName(r['cible']! as String),
          sentAt: DateTime.parse(r['envoyee_le']! as String),
          reviewingSince: DateTime.tryParse('${r['examen_depuis']}'),
          photos: r['photos']! as int,
          stage: RefundStage.values.byName(r['etape']! as String),
          refundedAt: DateTime.tryParse('${r['rembourse_le']}'),
        ),
    ];
  }

  /// One transaction: the request is refunded, its line shows « Remboursé », its payment in
  /// `paiements` (line id `tx-` + receipt number) turns `rembourse` and, to the balance, `porte_monnaie`
  /// is credited with a « Remboursement » line.
  @override
  Future<RefundRequest> completeRefund(String id) async {
    final db = await _db;
    final now = DateTime.now();
    await db.transaction((txn) async {
      final row = (await txn.query('demandes_remboursement', where: 'id = ?', whereArgs: [id]))
          .firstOrNull;
      if (row == null) throw StateError('Demande de remboursement inconnue : $id');
      if (row['etape'] == RefundStage.refunded.name) return;
      final txId = row['transaction_id']! as String;
      await txn.update(
        'demandes_remboursement',
        {'etape': RefundStage.refunded.name, 'rembourse_le': now.toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );
      await txn.update('transactions', {'statut': MuTransactionStatus.refunded.name},
          where: 'id = ?', whereArgs: [txId]);
      if (txId.startsWith('tx-')) {
        await txn.update(
          'paiements',
          {'statut': 'rembourse', 'rembourse_le': now.toIso8601String()},
          where: 'numero = ?',
          whereArgs: [txId.substring(3)],
        );
      }
      if (row['cible'] == RefundTarget.balance.name) {
        final t = transaction(
            (await txn.query('transactions', where: 'id = ?', whereArgs: [txId])).first);
        final amount = t.amount.abs();
        await txn.rawUpdate(
            'UPDATE porte_monnaie SET solde = solde + ? WHERE id = 1', [amount]);
        final request = RefundRequest(
          id: id,
          transaction: t,
          reason: RefundReason.values.byName(row['motif']! as String),
          note: row['note']! as String,
          target: RefundTarget.balance,
          sentAt: DateTime.parse(row['envoyee_le']! as String),
        );
        await txn.insert('transactions', transactionRow(FakeWalletRepository.refundLine(request, now)),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
    return (await refunds()).firstWhere((r) => r.id == id);
  }

  @override
  Future<void> record(MuTransaction tx) async {
    await (await _db)
        .insert('transactions', transactionRow(tx), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<RefundRequest> requestRefund({
    required MuTransaction transaction,
    required RefundReason reason,
    required String note,
    required RefundTarget target,
    int photos = 0,
  }) async {
    final db = await _db;
    return db.transaction((txn) async {
      final count = Sqflite.firstIntValue(
            await txn.rawQuery('SELECT COUNT(*) FROM demandes_remboursement'),
          ) ??
          0;
      final r = RefundRequest(
        id: 'rf-${count + 1}',
        transaction: transaction,
        reason: reason,
        note: note,
        target: target,
        sentAt: DateTime.now(),
        photos: photos,
      );
      // The transaction may not be in the history yet (a card payment listed elsewhere).
      await txn.insert('transactions', transactionRow(transaction),
          conflictAlgorithm: ConflictAlgorithm.ignore);
      await txn.insert('demandes_remboursement', _refundRow(r));
      return r;
    });
  }
}
