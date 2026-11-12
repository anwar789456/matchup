import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../core/db/app_database.dart';
import '../../../ui/ui.dart';
import '../../common/data/story_data.dart';
import 'subscription_repository.dart';

/// [SubscriptionRepository] on the phone's database: the plan in the `abonnement` row, the
/// receipts in `recus` and their lines in `recu_lignes`.
class SqliteSubscriptionRepository implements SubscriptionRepository {
  SqliteSubscriptionRepository(this._database);

  final AppDatabase _database;

  Future<Database> get _db => _database.db;

  static Map<String, Object?> _row(Subscription s, {String? note}) => {
        'id': 1,
        'statut': s.status.name,
        'periode': s.period.name,
        'fin_essai': s.trialEnds.toIso8601String(),
        'rappel': s.reminder.toIso8601String(),
        'carte': s.cardLabel,
        'offre_acceptee': s.offerAccepted ? 1 : 0,
        'motif_annulation': s.cancelReason?.name,
        'note_annulation': note,
      };

  static Subscription _subscription(Map<String, Object?> r) => Subscription(
        status: PremiumStatus.values.byName(r['statut']! as String),
        period: MuBillingPeriod.values.byName(r['periode']! as String),
        trialEnds: DateTime.parse(r['fin_essai']! as String),
        reminder: DateTime.parse(r['rappel']! as String),
        cardLabel: r['carte']! as String,
        offerAccepted: r['offre_acceptee'] == 1,
        cancelReason: r['motif_annulation'] == null
            ? null
            : CancelReason.values.byName(r['motif_annulation']! as String),
      );

  /// Gratuit on ven. 16 oct. No receipt: SUB-04 lists the invoices Stripe really charged.
  static Future<void> seed(DatabaseExecutor db) async {
    await db.insert(
      'abonnement',
      _row(Subscription(
        status: PremiumStatus.free,
        period: MuBillingPeriod.month,
        trialEnds: Story.at(30, 0),
        reminder: Story.at(27, 0),
      )),
    );
  }

  @override
  Future<Subscription> save(Subscription s) async {
    await (await _db).insert('abonnement', _row(s), conflictAlgorithm: ConflictAlgorithm.replace);
    return s;
  }

  @override
  Future<void> addReceipt(ReceiptEntry r) async {
    final db = await _db;
    await db.transaction((txn) async {
      final kept = await txn.insert('recus', {
        'numero': r.number,
        'libelle': r.label,
        'date': r.date.toIso8601String(),
        'montant': r.amount,
        'carte': r.card,
        'reference': r.reference,
        'politique': r.policy,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      if (kept == 0) return;
      for (final (i, l) in r.lines.indexed) {
        await txn.insert('recu_lignes', {
          'numero': r.number,
          'position': i,
          'libelle': l.title,
          'montant': l.amount,
          'quantite': l.quantity,
          'details': jsonEncode(l.details),
        });
      }
    });
  }

  @override
  Future<Subscription> current() async =>
      _subscription((await (await _db).query('abonnement')).single);

  Future<Subscription> _change(Subscription Function(Subscription s) change, {String? note}) async {
    final next = change(await current());
    await (await _db).insert('abonnement', _row(next, note: note),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return next;
  }

  @override
  Future<Subscription> startTrial({required MuBillingPeriod period, required String cardLabel}) =>
      _change((s) => s.copyWith(
            status: PremiumStatus.trial,
            period: period,
            cardLabel: cardLabel,
            offerAccepted: false,
            cancelReason: () => null,
          ));

  @override
  Future<Subscription> changePeriod(MuBillingPeriod period) =>
      _change((s) => s.copyWith(period: period));

  @override
  Future<Subscription> cancel({CancelReason? reason, String? note}) => _change(
        (s) => s.copyWith(
          status: PremiumStatus.cancelled,
          offerAccepted: false,
          cancelReason: () => reason,
        ),
        note: note,
      );

  @override
  Future<Subscription> acceptOffer() => _change((s) => s.copyWith(
        status: PremiumStatus.trial,
        offerAccepted: true,
        period: MuBillingPeriod.month,
      ));

  @override
  Future<Subscription> reactivate() =>
      _change((s) => s.copyWith(status: PremiumStatus.trial, cancelReason: () => null));

  @override
  Future<List<ReceiptEntry>> receipts() async {
    final db = await _db;
    final lines = <String, List<ReceiptLine>>{};
    for (final l in await db.query('recu_lignes', orderBy: 'numero, position')) {
      (lines[l['numero']! as String] ??= []).add(ReceiptLine(
        l['libelle']! as String,
        l['montant']! as num,
        details: [for (final d in jsonDecode(l['details']! as String) as List) d as String],
        quantity: l['quantite']! as int,
      ));
    }
    return [
      for (final r in await db.query('recus', orderBy: 'date DESC'))
        ReceiptEntry(
          number: r['numero']! as String,
          label: r['libelle']! as String,
          date: DateTime.parse(r['date']! as String),
          amount: r['montant']! as num,
          card: r['carte']! as String,
          reference: r['reference'] as String?,
          policy: r['politique'] as String?,
          lines: lines[r['numero']] ?? const [],
        ),
    ];
  }
}
