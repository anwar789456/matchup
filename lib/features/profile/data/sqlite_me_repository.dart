import 'package:sqflite/sqflite.dart';

import '../../../core/db/app_database.dart';
import '../../common/data/story_data.dart';
import 'me_repository.dart';

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
    return Me(
      firstName: Story.myFirstName,
      displayName: Story.myName,
      zone: Story.zone,
      levels: Story.myLevels,
      email: Story.myEmail,
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
