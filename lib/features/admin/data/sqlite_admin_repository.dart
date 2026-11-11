import '../../../core/db/app_database.dart';
import 'admin_repository.dart';

/// [AdminRepository] on the phone's database. Every decision of the admin (suspend, approve a
/// verification, validate a payout, refund, ignore a churn risk, moderate) is a row of
/// `admin_journal`; the lists are the story's with the journal replayed over them, in order.
/// Undoing one is never needed: a later row (« churn_ignore » 0) overrides an earlier one.
class SqliteAdminRepository implements AdminRepository {
  SqliteAdminRepository(this._database);

  final AppDatabase _database;
  Future<FakeAdminRepository>? _state;

  /// The story's admin space after every decision of the journal.
  Future<FakeAdminRepository> get _replayed => _state ??= () async {
        final state = FakeAdminRepository(latency: Duration.zero);
        final db = await _database.db;
        for (final r in await db.query('admin_journal', orderBy: 'id')) {
          await _apply(state, r['action']! as String, r['cible']! as String, r['valeur'] as String?);
        }
        return state;
      }();

  static Future<void> _apply(FakeAdminRepository s, String action, String target, String? value) =>
      switch (action) {
        'suspension' => s.suspend(target, until: DateTime.tryParse(value ?? '')),
        'approbation' => s.approve(target, value ?? ''),
        'virement_valide' => s.validatePayouts({target}),
        'remboursement' => s.refund(target),
        'churn_ignore' => s.ignoreChurn(target, ignored: value == '1'),
        'moderation' => s.decide(target, ModerationDecision.values.byName(value!)),
        _ => Future<void>.value(),
      };

  /// Writes the decision, then applies it to the replayed state.
  Future<void> _record(String action, String target, [String? value]) async {
    await (await _database.db).insert('admin_journal', {
      'action': action,
      'cible': target,
      'valeur': value,
      'le': DateTime.now().toIso8601String(),
    });
    await _apply(await _replayed, action, target, value);
  }

  @override
  Future<AdminOverview> overview() async => (await _replayed).overview();

  @override
  Future<List<AdminUser>> users() async => (await _replayed).users();

  @override
  Future<AdminUserDetail?> userDetail(String id) async => (await _replayed).userDetail(id);

  @override
  Future<AdminSanctionPlan> sanctionPlan(String id) async => (await _replayed).sanctionPlan(id);

  /// [until] null bans.
  @override
  Future<void> suspend(String id, {required DateTime? until}) =>
      _record('suspension', id, until?.toIso8601String());

  @override
  Future<List<AdminVerification>> verifications() async => (await _replayed).verifications();

  @override
  Future<void> approve(String id, String doneLine) => _record('approbation', id, doneLine);

  @override
  Future<AdminFinance> finance() async => (await _replayed).finance();

  @override
  Future<List<AdminPayout>> payouts() async => (await _replayed).payouts();

  @override
  Future<void> validatePayouts(Set<String> ids) async {
    for (final id in ids) {
      await _record('virement_valide', id);
    }
  }

  @override
  Future<List<AdminRefund>> refunds() async => (await _replayed).refunds();

  @override
  Future<void> refund(String id) => _record('remboursement', id);

  @override
  Future<List<ChurnRisk>> churn() async => (await _replayed).churn();

  @override
  Future<void> ignoreChurn(String id, {required bool ignored}) =>
      _record('churn_ignore', id, ignored ? '1' : '0');

  @override
  Future<List<ModerationItem>> moderation() async => (await _replayed).moderation();

  @override
  Future<ModerationReview?> review(String id) async => (await _replayed).review(id);

  @override
  Future<void> decide(String id, ModerationDecision decision) =>
      _record('moderation', id, decision.name);
}
