import '../../../core/db/app_database.dart';
import 'profile_repository.dart';

/// [ProfileRepository] on the phone's database: the pseudo is checked against every account in
/// `utilisateurs`, the profile is saved on the signed-in account ([userId]).
class SqliteProfileRepository implements ProfileRepository {
  SqliteProfileRepository(this._database, {required this.userId});

  final AppDatabase _database;
  final int? Function() userId;

  @override
  Future<bool> isPseudoAvailable(String pseudo) async {
    final db = await _database.db;
    final rows = await db.query(
      'utilisateurs',
      columns: ['id'],
      where: 'pseudo = ? AND id IS NOT ?',
      whereArgs: [pseudo.trim().toLowerCase(), userId()],
    );
    return rows.isEmpty;
  }

  @override
  Future<void> saveProfile({required String pseudo, String? fullName, List<int>? photo}) async {
    final id = userId();
    if (id == null) return;
    final parts = (fullName ?? '').trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final db = await _database.db;
    await db.update(
      'utilisateurs',
      {
        'pseudo': pseudo.trim().toLowerCase(),
        if (parts.isNotEmpty) 'prenom': parts.first,
        if (parts.length > 1) 'nom': parts.skip(1).join(' '),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
