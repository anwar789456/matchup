import 'package:sqflite/sqflite.dart';

import '../../../core/db/app_database.dart';
import 'payment_repository.dart';

/// [PaymentRepository] on the phone's database: saved cards in `cartes`, every payment that went
/// through in `paiements` (its receipt number follows the last one), promo codes in
/// `codes_promo`. The bank's answer is still the debug menu's [PaymentOutcome] (CLAUDE.md rule 10).
class SqlitePaymentRepository implements PaymentRepository {
  SqlitePaymentRepository(
    this._database, {
    this.latency = const Duration(seconds: 1),
    PaymentOutcome Function()? outcome,
  }) : _outcome = outcome ?? (() => PaymentOutcome.success);

  final AppDatabase _database;
  final Duration latency;
  final PaymentOutcome Function() _outcome;

  /// The attempt waiting for 3-D Secure (only in memory: the bank's step never outlives the app).
  ({num amount, PayWith method, PaymentCard? card, String reason})? _pending;

  Future<Database> get _db => _database.db;

  static Map<String, Object?> _cardRow(PaymentCard c, int position) => {
        'id': c.id,
        'marque': c.brand.name,
        'derniers_chiffres': c.last4,
        'mois_exp': c.expMonth,
        'annee_exp': c.expYear,
        'par_defaut': c.isDefault ? 1 : 0,
        'position': position,
      };

  static PaymentCard _card(Map<String, Object?> r) => PaymentCard(
        id: r['id']! as String,
        brand: CardBrand.values.byName(r['marque']! as String),
        last4: r['derniers_chiffres']! as String,
        expMonth: r['mois_exp']! as int,
        expYear: r['annee_exp']! as int,
        isDefault: r['par_defaut'] == 1,
      );

  static Future<void> seed(DatabaseExecutor db) async {
    for (final (i, c) in FakePaymentRepository.storyCards.indexed) {
      await db.insert('cartes', _cardRow(c, i));
    }
    for (final e in FakePaymentRepository.storyPromos.entries) {
      await db.insert('codes_promo',
          {'code': e.key, 'pourcentage': e.value.percent, 'erreur': e.value.error});
    }
  }

  @override
  Future<List<PaymentCard>> cards() async =>
      [for (final r in await (await _db).query('cartes', orderBy: 'position')) _card(r)];

  @override
  Future<PaymentCard> addCard({
    required CardBrand brand,
    required String last4,
    required int expMonth,
    required int expYear,
    bool save = true,
  }) async {
    final db = await _db;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM cartes')) ?? 0;
    final card = PaymentCard(
      id: '${brand.name}-$last4-$count',
      brand: brand,
      last4: last4,
      expMonth: expMonth,
      expYear: expYear,
    );
    if (save) await db.insert('cartes', _cardRow(card, count));
    return card;
  }

  /// Saves the payment and returns its receipt, numbered after the last one.
  Future<PaymentReceipt> _receipt(num amount, PayWith method, PaymentCard? card, String reason) async {
    final db = await _db;
    final used = card ?? (method == PayWith.card ? (await cards()).firstOrNull : null);
    return db.transaction((txn) async {
      final last = Sqflite.firstIntValue(await txn.rawQuery(
        'SELECT MAX(CAST(SUBSTR(numero, 11) AS INTEGER)) FROM paiements',
      ));
      final next = (last ?? FakePaymentRepository.firstReceipt - 1) + 1;
      final receipt = PaymentReceipt(
        number: 'MU-R-2026-${next.toString().padLeft(5, '0')}',
        amount: amount,
        paidAt: DateTime.now(),
        method: method,
        card: used,
      );
      await txn.insert('paiements', {
        'numero': receipt.number,
        'montant': amount,
        'paye_le': receipt.paidAt.toIso8601String(),
        'moyen': method.name,
        'carte_id': used?.id,
        'motif': reason,
      });
      return receipt;
    });
  }

  @override
  Future<PaymentReceipt> pay(num amount, {required String reason}) async {
    await Future<void>.delayed(latency);
    return _receipt(amount, PayWith.card, null, reason);
  }

  @override
  Future<PaymentResult> charge({
    required num amount,
    required String reason,
    required PayWith method,
    PaymentCard? card,
  }) async {
    await Future<void>.delayed(latency);
    _pending = (amount: amount, method: method, card: card, reason: reason);
    // The balance never fails: only the bank does.
    if (method == PayWith.balance) {
      return PaymentResult(PaymentStatus.success,
          receipt: await _receipt(amount, method, null, reason));
    }
    return switch (_outcome()) {
      PaymentOutcome.success => PaymentResult(
          PaymentStatus.success,
          receipt: await _receipt(amount, method, card, reason),
        ),
      PaymentOutcome.threeDSecure => const PaymentResult(PaymentStatus.needsAuthentication),
      PaymentOutcome.declined => PaymentResult(
          PaymentStatus.declined,
          reason: 'fonds insuffisants',
          attemptAt: DateTime.now(),
        ),
      PaymentOutcome.networkError =>
        PaymentResult(PaymentStatus.networkError, attemptAt: DateTime.now()),
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
    return PaymentResult(PaymentStatus.success,
        receipt: await _receipt(p.amount, p.method, p.card, p.reason));
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
    final row = (await (await _db).query('codes_promo', where: 'code = ?', whereArgs: [upper]))
        .firstOrNull;
    return PromoResult(
      code: upper,
      percent: row?['pourcentage'] as int?,
      error: row == null ? FakePaymentRepository.unknownPromo : row['erreur'] as String?,
    );
  }
}
