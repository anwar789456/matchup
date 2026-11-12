import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchup/core/db/app_database.dart';
import 'package:matchup/features/home/controllers/home_providers.dart';
import 'package:matchup/features/profile/data/account_profile.dart';
import 'package:matchup/features/profile/data/profile_repository.dart';
import 'package:matchup/features/settings/data/settings_repository.dart';

/// The profile and settings follow the signed-in account, not the story's demo player.
void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  Future<int> account(String email, {String? prenom, String? nom, String? pseudo}) async {
    final db = await container.read(appDatabaseProvider).db;
    return db.insert('utilisateurs', {
      'email': email,
      'mot_de_passe': 'x',
      'sel': 'y',
      'prenom': prenom,
      'nom': nom,
      'pseudo': pseudo,
      'cree_le': '2026-11-12T10:00:00',
    });
  }

  Future<int> pending() async {
    final db = await container.read(appDatabaseProvider).db;
    return (await db.query('sync_outbox', where: "tableau IN ('reglages_compte', 'profil_joueur')")).length;
  }

  test('a sign-in shows the account, never the demo player, and sends nothing', () async {
    final id = await account('alaa.b@email.tn', prenom: 'Alaa', nom: 'Ben Slimene', pseudo: 'alaa.b');
    await container.read(accountProfileProvider).adopt(id);

    final me = await container.read(meProvider.future);
    expect(me.displayName, 'Alaa B.');
    expect(me.email, 'alaa.b@email.tn');
    final profile = await container.read(myProfileProvider.future);
    expect(profile.name, 'Alaa B.');
    expect(profile.handle, 'alaa.b');
    expect(profile.bio, isEmpty);
    expect(profile.sports, isEmpty);
    expect(await pending(), 0, reason: 'the reset must not overwrite the account on Supabase');

    container.read(accountSettingsProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final s = container.read(accountSettingsProvider);
    expect((s.email, s.firstName, s.phone), ('alaa.b@email.tn', 'Alaa', ''));
    expect(s.maskedPhone, isEmpty);
  });

  test('a new account with no name shows its email; edits are synced', () async {
    final id = await account('ayoub@email.tn');
    final profiles = container.read(accountProfileProvider);
    await profiles.adopt(id);
    expect((await container.read(meProvider.future)).displayName, 'ayoub');

    await profiles.saveIdentity(pseudo: 'Ayoub.T', fullName: 'Ayoub Trabelsi');
    expect((await container.read(meProvider.future)).displayName, 'Ayoub T.');
    expect((await container.read(myProfileProvider.future)).handle, 'ayoub.t');
    expect(await pending(), greaterThan(0));

    // Google's full name only fills what is still empty.
    await profiles.fillNames('Someone Else');
    expect((await container.read(meProvider.future)).displayName, 'Ayoub T.');
  });

  test('signing in again as the same account keeps its edits', () async {
    final id = await account('alaa.b@email.tn', prenom: 'Alaa');
    final profiles = container.read(accountProfileProvider);
    await profiles.adopt(id);
    await profiles.saveIdentity(pseudo: 'alaa.b', fullName: 'Alaa Ben');
    await profiles.adopt(id);
    expect((await container.read(meProvider.future)).displayName, 'Alaa B.');
  });
}
