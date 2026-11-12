import 'package:flutter/widgets.dart' show StringCharacters;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/preferences.dart';
import '../../home/controllers/home_providers.dart';
import '../../settings/data/settings_repository.dart';
import 'profile_repository.dart';
import 'sqlite_profile_repository.dart';

/// Keeps the phone's profile and settings rows (`profil_joueur`, `reglages_compte`, one of each
/// per phone) on the signed-in account. Both tables are synced to Supabase per account
/// (lib/core/sync/sync_tables.dart), so a profile follows its account to any phone.
///
/// When another account signs in, [adopt] resets them to that account (its email, names, pseudo
/// and phone, blank bio and sports) with the sync triggers quiet: the reset is never sent, and
/// the sync then brings the account's own rows down if it already has some.
class AccountProfile {
  AccountProfile(this._ref);

  final Ref _ref;

  static const _ownerKey = 'profil.compte';

  AppDatabase get _database => _ref.read(appDatabaseProvider);

  /// After a sign-in: the rows become [userId]'s account (from its `utilisateurs` row). Nothing
  /// changes when they already are.
  Future<void> adopt(int userId) async {
    final db = await _database.db;
    final user = (await db.query('utilisateurs', where: 'id = ?', whereArgs: [userId])).firstOrNull;
    final email = (user?['email'] as String?)?.trim().toLowerCase();
    if (email == null) return;
    final prefs = Preferences(_database);
    if (await prefs.get(_ownerKey) == email) return;
    String text(Object? v) => v is String ? v : '';
    await db.transaction((txn) async {
      await _quiet(txn, true);
      try {
        await AccountSettingsRows.write(
          txn,
          AccountSettings(
            email: email,
            phone: text(user?['telephone']),
            firstName: text(user?['prenom']),
            lastName: text(user?['nom']),
            birthDate: '',
            gender: Gender.unspecified,
            passwordChanged: '',
            twoFactor: false,
            sessions: const [],
            googleEmail: null,
            blocked: 0,
          ),
        );
        await txn.insert(
          'profil_joueur',
          SqlitePlayerProfileRepository.rowOf(FakePlayerProfileRepository.yassine.copyWith(
            handle: text(user?['pseudo']),
            bio: '',
            sports: const [],
            positions: const {},
            zones: const [],
            visibility: ProfileVisibility.everyone,
            showLevel: true,
            showReliability: true,
            suggestPartner: true,
          )),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } finally {
        await _quiet(txn, false);
      }
    });
    await prefs.set(_ownerKey, email);
    refresh();
  }

  /// A Google account's name (`full_name`) fills the first and last names still empty (synced).
  Future<void> fillNames(String? fullName) async {
    final parts = (fullName ?? '').trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return;
    await _writeSettings((s) => s.copyWith(
          firstName: s.firstName.isEmpty ? parts.first : null,
          lastName: s.lastName.isEmpty && parts.length > 1 ? parts.skip(1).join(' ') : null,
        ));
  }

  /// PLY-10 « Ton profil »: the pseudo and name picked at the end of the onboarding (synced).
  Future<void> saveIdentity({required String pseudo, String? fullName}) async {
    final parts = (fullName ?? '').trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final db = await _database.db;
    await db.update('profil_joueur', {'pseudo': pseudo.trim().toLowerCase()});
    await _writeSettings((s) => s.copyWith(
          firstName: parts.isEmpty ? null : parts.first,
          lastName: parts.length > 1 ? parts.skip(1).join(' ') : null,
        ));
  }

  Future<void> _writeSettings(AccountSettings Function(AccountSettings s) change) async {
    final db = await _database.db;
    await db.transaction((txn) async {
      final row = (await txn.query('reglages_compte')).firstOrNull;
      if (row == null) return;
      final current = AccountSettingsRows.read(row, await txn.query('sessions_appareils', orderBy: 'position'));
      await AccountSettingsRows.write(txn, change(current));
    });
    refresh();
  }

  static Future<void> _quiet(DatabaseExecutor txn, bool on) =>
      txn.update('sync_etat', {'application': on ? 1 : 0}, where: 'id = 1');

  /// The screens re-read the account.
  void refresh() {
    _ref
      ..invalidate(accountSettingsProvider)
      ..invalidate(myProfileProvider)
      ..invalidate(meProvider);
  }

  /// « Yassine B. » from the account's names, else its pseudo, else its email before the @.
  static String displayName({String? first, String? last, String? pseudo, String? email}) {
    final f = (first ?? '').trim();
    final l = (last ?? '').trim();
    if (f.isNotEmpty) return l.isEmpty ? f : '$f ${l.characters.first.toUpperCase()}.';
    if ((pseudo ?? '').trim().isNotEmpty) return pseudo!.trim();
    return (email ?? '').split('@').first;
  }
}

final accountProfileProvider = Provider<AccountProfile>(AccountProfile.new);
