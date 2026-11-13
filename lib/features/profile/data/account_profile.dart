import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show StringCharacters;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/preferences.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/sync/sync_service.dart';
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

  /// Supabase is the source of truth, the phone's rows a cache: after a sign-in (and at start),
  /// the account's profile and settings are read from Supabase and replace the cache. An account
  /// with nothing on Supabase yet gets rows made from the account itself (email, the names it
  /// signed up or signed in to Google with), which are then sent. Quiet without a real session
  /// (offline, no Supabase): the cache stays.
  Future<void> loadFromServer() async {
    final user = _realUser();
    final email = user?.email?.trim().toLowerCase();
    if (user == null || email == null) return;
    try {
      final client = Supabase.instance.client;
      final reglages = await client.from('reglages_compte').select().eq('owner_id', user.id).maybeSingle();
      final profil = await client.from('profil_joueur').select().eq('owner_id', user.id).maybeSingle();
      final db = await _database.db;
      Map<String, Object?> local(Map<String, dynamic> row) => {
            for (final e in row.entries)
              if (e.key != 'owner_id') e.key: e.value,
          };
      await db.transaction((txn) async {
        // What Supabase has replaces the cache, without being sent back.
        await _quiet(txn, true);
        try {
          if (reglages != null) {
            await txn.insert('reglages_compte', local(reglages), conflictAlgorithm: ConflictAlgorithm.replace);
          }
          if (profil != null) {
            await txn.insert('profil_joueur', local(profil), conflictAlgorithm: ConflictAlgorithm.replace);
          }
        } finally {
          await _quiet(txn, false);
        }
        // What Supabase lacks is made from the account, and sent.
        final meta = user.userMetadata ?? const {};
        final names = _split((meta['full_name'] ?? meta['name']) as String?);
        final prenom = (meta['prenom'] as String?) ?? names.$1;
        final nom = (meta['nom'] as String?) ?? names.$2;
        if (reglages == null) {
          await AccountSettingsRows.write(
            txn,
            AccountSettings(
              email: email,
              phone: user.phone ?? '',
              firstName: prenom,
              lastName: nom,
              birthDate: '',
              gender: Gender.unspecified,
              passwordChanged: '',
              twoFactor: false,
              sessions: const [],
              googleEmail: user.appMetadata['provider'] == 'google' ? email : null,
              blocked: 0,
            ),
          );
        }
        if (profil == null) {
          await txn.insert(
            'profil_joueur',
            SqlitePlayerProfileRepository.rowOf(FakePlayerProfileRepository.yassine.copyWith(
              handle: (meta['pseudo'] as String?) ?? '',
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
        }
      });
      await Preferences(_database).set(_ownerKey, email);
      refresh();
      if (reglages == null || profil == null) pushNow();
    } catch (e) {
      debugPrint('Profil non chargé depuis Supabase : $e');
    }
  }

  /// Sends the cache's changes to Supabase now instead of at the next 30 s tick.
  void pushNow() {
    if (_realUser() == null) return;
    unawaited(runSync(_ref).then((_) {}, onError: (Object e) => debugPrint('Synchronisation : $e')));
  }

  static (String, String) _split(String? fullName) {
    final parts = (fullName ?? '').trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    return (parts.firstOrNull ?? '', parts.skip(1).join(' '));
  }

  /// The device's Supabase user when it is a real account (not the anonymous device session).
  static User? _realUser() {
    if (!SupabaseConfig.ready) return null;
    final user = Supabase.instance.client.auth.currentUser;
    return user == null || user.isAnonymous ? null : user;
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
    pushNow();
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
