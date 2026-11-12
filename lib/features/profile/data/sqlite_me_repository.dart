import 'package:sqflite/sqflite.dart';

import '../../../core/db/app_database.dart';
import '../../common/data/story_data.dart';
import 'account_profile.dart';
import 'me_repository.dart';

/// Who the profile and settings rows belong to (the signed-in account, see [AccountProfile]).
typedef AccountIdentity = ({String firstName, String displayName, String email});

/// [AccountIdentity] from `reglages_compte` and `profil_joueur`; null without a usable name.
Future<AccountIdentity?> accountIdentity(DatabaseExecutor db) async {
  final s = (await db.query('reglages_compte')).firstOrNull;
  if (s == null) return null;
  final pseudo = (await db.query('profil_joueur', columns: ['pseudo'])).firstOrNull?['pseudo'] as String?;
  final first = s['prenom'] as String? ?? '';
  final email = s['email'] as String? ?? '';
  final display = AccountProfile.displayName(first: first, last: s['nom'] as String?, pseudo: pseudo, email: email);
  if (display.isEmpty) return null;
  return (firstName: first.isNotEmpty ? first : display, displayName: display, email: email);
}

/// [MeRepository] on the phone's database: the balance lives in `porte_monnaie` and the bell's
/// count is the unread rows of `notifications`. Name, zone and levels are Yassine's (the story).
class SqliteMeRepository implements MeRepository {
  SqliteMeRepository(this._database);

  final AppDatabase _database;

  Future<Database> get _db => _database.db;

  static Future<void> seed(DatabaseExecutor db) =>
      db.insert('porte_monnaie', {'id': 1, 'solde': Story.myBalance});

  Future<num> _balance(DatabaseExecutor db) async =>
      (await db.query('porte_monnaie', columns: ['solde'])).first['solde']! as num;

  @override
  Future<Me> me() async {
    final db = await _db;
    final unread = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM notifications WHERE non_lue = 1'),
        ) ??
        0;
    final id = await accountIdentity(db);
    return Me(
      firstName: id?.firstName ?? Story.myFirstName,
      displayName: id?.displayName ?? Story.myName,
      zone: Story.zone,
      levels: Story.myLevels,
      email: id?.email ?? Story.myEmail,
      balance: await _balance(db),
      unreadNotifications: unread,
      position: Story.me,
    );
  }

  @override
  Future<void> debit(num amount) async {
    final db = await _db;
    await db.transaction((txn) async {
      if (amount > await _balance(txn)) throw StateError('Solde insuffisant');
      await txn.rawUpdate('UPDATE porte_monnaie SET solde = solde - ? WHERE id = 1', [amount]);
    });
  }

  @override
  Future<void> credit(num amount) async {
    await (await _db).rawUpdate('UPDATE porte_monnaie SET solde = solde + ? WHERE id = 1', [amount]);
  }
}
