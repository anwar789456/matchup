import 'package:sqflite/sqflite.dart';

import '../../../core/db/app_database.dart';
import 'payment_repository.dart';

/// [PaymentRepository] on the phone's database: saved cards in `cartes`, every payment that went
/// through in `paiements` (its receipt number follows the last one, `reference` says what it
/// paid for), every try at the bank in `tentatives_paiement`, promo codes in `codes_promo`. The
/// bank's answer is still the debug menu's [PaymentOutcome] (CLAUDE.md rule 10).
class SqlitePaymentRepository implements PaymentRepository {
  SqlitePaymentRepository(
    this._database, {
    this.latency = const Duration(seconds: 1),
    PaymentOutcome Function()? outcome,
  }) : _outcome = outcome ?? (() => PaymentOutcome.success);

  final AppDatabase _database;
  final Duration latency;
  final PaymentOutcome Function() _outcome;

  /// The attempt waiting for 3-D Secure (only in memory: the bank's step never outlives the app),
  /// with the id of its `tentatives_paiement` row.
  ({num amount, PayWith method, PaymentCard? card, String reason, String? reference, int attempt})?
      _pending;

  Future<Database> get _db => _database.db;

  static const _attemptStates = {
    AttemptState.pending: 'en_attente',
    AttemptState.paid: 'paye',
    AttemptState.failed: 'echoue',
  };

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

  static Map<String, Object?> _attemptRow({
    required num amount,
    required PayWith method,
    required PaymentCard? card,
    required String reason,
    required String? reference,
    required PaymentResult result,
  }) =>
      {
        'montant': amount,
        'moyen': method.name,
        'carte_id': card?.id,
        'motif': reason,
        'reference': reference,
        'statut': _attemptStates[result.attemptState],
        'raison': result.failure,
        'tentee_le': (result.attemptAt ?? DateTime.now()).toIso8601String(),
        'numero': result.receipt?.number,
      };

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

  /// Saves the payment (numbered after the last one) and its attempt in one transaction. With
  /// [attempt], that waiting attempt is the one marked paid.
  Future<PaymentReceipt> _pay(
    num amount,
    PayWith method,
    PaymentCard? card,
    String reason,
    String? reference, {
    int? attempt,
  }) async {
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
        'reference': reference,
      });
      final row = _attemptRow(
        amount: amount,
        method: method,
        card: used,
        reason: reason,
        reference: reference,
        result: PaymentResult(PaymentStatus.success, receipt: receipt, attemptAt: receipt.paidAt),
      );
      if (attempt == null) {
        await txn.insert('tentatives_paiement', row);
      } else {
        await txn.update('tentatives_paiement', row, where: 'id = ?', whereArgs: [attempt]);
      }
      return receipt;
    });
  }

  @override
  Future<PaymentReceipt> recordStripe({
    required num amount,
    required String reason,
    required String intentId,
    String? reference,
    CardBrand? brand,
    String? last4,
  }) =>
      _pay(amount, PayWith.stripe, stripeCard(intentId, brand, last4), reason, reference);

  @override
  Future<PaymentReceipt> pay(num amount, {required String reason}) async {
    await Future<void>.delayed(latency);
    return _pay(amount, PayWith.card, null, reason, null);
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
    _pending = null;
    // The balance never fails: only the bank does.
    if (method == PayWith.balance) {
      return PaymentResult(PaymentStatus.success,
          receipt: await _pay(amount, method, null, reason, reference));
    }
    final result = switch (_outcome()) {
      PaymentOutcome.success => null,
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
    if (result == null) {
      return PaymentResult(PaymentStatus.success,
          receipt: await _pay(amount, method, card, reason, reference));
    }
    final attempt = await (await _db).insert(
      'tentatives_paiement',
      _attemptRow(
        amount: amount,
        method: method,
        card: card,
        reason: reason,
        reference: reference,
        result: result,
      ),
    );
    if (result.status == PaymentStatus.needsAuthentication) {
      _pending = (
        amount: amount,
        method: method,
        card: card,
        reason: reason,
        reference: reference,
        attempt: attempt,
      );
    }
    return result;
  }

  @override
  Future<PaymentResult> confirmAuthentication({required bool approved}) async {
    await Future<void>.delayed(latency);
    final p = _pending;
    _pending = null;
    const cancelled = PaymentResult(PaymentStatus.declined, reason: 'authentification annulée');
    if (p == null) return cancelled;
    if (!approved) {
      await (await _db).update(
        'tentatives_paiement',
        {'statut': _attemptStates[AttemptState.failed], 'raison': cancelled.reason},
        where: 'id = ?',
        whereArgs: [p.attempt],
      );
      return cancelled;
    }
    return PaymentResult(PaymentStatus.success,
        receipt: await _pay(p.amount, p.method, p.card, p.reason, p.reference, attempt: p.attempt));
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

  static PayWith _method(Object? name) => PayWith.values.byName(name! as String);

  @override
  Future<List<PaymentRecord>> payments({String? reference}) async => [
        for (final r in await (await _db).query(
          'paiements',
          where: reference == null ? null : 'reference = ?',
          whereArgs: reference == null ? null : [reference],
          orderBy: 'paye_le DESC, numero DESC',
        ))
          PaymentRecord(
            number: r['numero']! as String,
            amount: r['montant']! as num,
            paidAt: DateTime.parse(r['paye_le']! as String),
            method: _method(r['moyen']),
            cardId: r['carte_id'] as String?,
            reason: r['motif'] as String?,
            reference: r['reference'] as String?,
            refundedAt:
                r['statut'] == 'rembourse' ? DateTime.tryParse('${r['rembourse_le']}') : null,
          ),
      ];

  @override
  Future<List<PaymentAttempt>> attempts({String? reference}) async => [
        for (final r in await (await _db).query(
          'tentatives_paiement',
          where: reference == null ? null : 'reference = ?',
          whereArgs: reference == null ? null : [reference],
          orderBy: 'id DESC',
        ))
          PaymentAttempt(
            amount: r['montant']! as num,
            method: _method(r['moyen']),
            state: _attemptStates.entries.firstWhere((e) => e.value == r['statut']).key,
            at: DateTime.parse(r['tentee_le']! as String),
            reason: r['motif'] as String?,
            reference: r['reference'] as String?,
            failure: r['raison'] as String?,
            receiptNumber: r['numero'] as String?,
          ),
      ];
}
