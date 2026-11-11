import '../../../core/db/app_database.dart';
import 'owner_draft.dart';
import 'owner_repository.dart';

/// [OwnerRepository] on the phone's database: « Démarrer l’essai gratuit » (OWN-08) saves every
/// court in `terrains`, owned by the signed-in account. Starting data and the RIB check stay as
/// in [FakeOwnerRepository].
class SqliteOwnerRepository extends FakeOwnerRepository {
  const SqliteOwnerRepository(this._database, {required this.userId});

  final AppDatabase _database;
  final int? Function() userId;

  @override
  Future<void> startTrial(OwnerDraft draft) async {
    final db = await _database.db;
    final now = DateTime.now().toIso8601String();
    await db.transaction((txn) async {
      for (final court in draft.courts) {
        final price = draft.prices[court.priceKey];
        await txn.insert('terrains', {
          'proprietaire_id': userId(),
          'nom': court.name,
          'etablissement': draft.venueName,
          'sport': court.sport.name,
          'surface': court.surface,
          'interieur': court.indoor ? 1 : 0,
          'eclairage': court.lights ? 1 : 0,
          'prix_heure': price?.offPeak ?? price?.peak ?? 0,
          'ville': draft.city,
          'adresse': draft.street,
          'cree_le': now,
        });
      }
    });
  }
}
