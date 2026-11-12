import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/db/app_database.dart';
import '../../../core/sync/sync_service.dart';

/// A signed-in device (SET-03 « Sessions actives »).
@immutable
class DeviceSession {
  const DeviceSession({
    required this.id,
    required this.name,
    required this.where,
    this.current = false,
    this.mobile = true,
  });

  final String id;
  final String name;

  /// « Tunis · actif maintenant », « Ariana · il y a 2 jours ».
  final String where;
  final bool current;
  final bool mobile;
}

enum Gender { male, female, unspecified }

enum InvitePolicy { everyone, teammates, nobody }

/// Everything the settings screens read and write (SET-02 to SET-06), kept in the
/// `reglages_compte` row and the `sessions_appareils` table.
@immutable
class AccountSettings {
  const AccountSettings({
    this.email = 'yassine.b@email.tn',
    this.phone = '20123456',
    this.firstName = 'Yassine',
    this.lastName = 'Belhaj',
    this.birthDate = '12/03/1998',
    this.gender = Gender.male,
    this.passwordChanged = 'il y a 3 mois',
    this.twoFactor = true,
    this.sessions = const [
      DeviceSession(
        id: 'iphone',
        name: 'iPhone 15',
        where: 'Tunis · actif maintenant',
        current: true,
      ),
      DeviceSession(
        id: 'chrome',
        name: 'Chrome sur Windows',
        where: 'Ariana · il y a 2 jours',
        mobile: false,
      ),
    ],
    this.googleEmail = 'yassine.b@gmail.com',
    this.appleConnected = false,
    this.profilePublic = true,
    this.invites = InvitePolicy.teammates,
    this.showLevel = true,
    this.showReliability = true,
    this.preciseLocation = true,
    this.blocked = 2,
    this.notificationsSummary = 'Push · email',
  });

  final String email;
  final String phone;
  final String firstName;
  final String lastName;
  final String birthDate;
  final Gender gender;
  final String passwordChanged;
  final bool twoFactor;
  final List<DeviceSession> sessions;

  /// Null when Google is not connected.
  final String? googleEmail;
  final bool appleConnected;
  final bool profilePublic;
  final InvitePolicy invites;
  final bool showLevel;
  final bool showReliability;
  final bool preciseLocation;
  final int blocked;
  final String notificationsSummary;

  /// « +216 20 ••• 456 ».
  String get maskedPhone => phone.length < 5
      ? phone
      : '+216 ${phone.substring(0, 2)} ••• ${phone.substring(phone.length - 3)}';

  AccountSettings copyWith({
    String? email,
    String? phone,
    String? firstName,
    String? lastName,
    String? birthDate,
    Gender? gender,
    bool? twoFactor,
    List<DeviceSession>? sessions,
    Object? googleEmail = _keep,
    bool? appleConnected,
    bool? profilePublic,
    InvitePolicy? invites,
    bool? showLevel,
    bool? showReliability,
    bool? preciseLocation,
  }) => AccountSettings(
    email: email ?? this.email,
    phone: phone ?? this.phone,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    birthDate: birthDate ?? this.birthDate,
    gender: gender ?? this.gender,
    passwordChanged: passwordChanged,
    twoFactor: twoFactor ?? this.twoFactor,
    sessions: sessions ?? this.sessions,
    googleEmail: identical(googleEmail, _keep) ? this.googleEmail : googleEmail as String?,
    appleConnected: appleConnected ?? this.appleConnected,
    profilePublic: profilePublic ?? this.profilePublic,
    invites: invites ?? this.invites,
    showLevel: showLevel ?? this.showLevel,
    showReliability: showReliability ?? this.showReliability,
    preciseLocation: preciseLocation ?? this.preciseLocation,
    blocked: blocked,
    notificationsSummary: notificationsSummary,
  );

  static const _keep = Object();
}

class AccountSettingsController extends Notifier<AccountSettings> {
  AppDatabase get _database => ref.read(appDatabaseProvider);

  @override
  AccountSettings build() {
    // The account's row may arrive from Supabase (sync_tables.dart): re-read it then.
    ref.watch(syncRevisionProvider);
    _load();
    return const AccountSettings();
  }

  Future<void> _load() async {
    try {
      final db = await _database.db;
      final row = (await db.query('reglages_compte')).firstOrNull;
      if (row == null) return;
      state = AccountSettingsRows.read(row, await db.query('sessions_appareils', orderBy: 'position'));
    } catch (_) {
      // No database: keep the defaults.
    }
  }

  void _set(AccountSettings next) {
    state = next;
    _database.db
        .then((db) => db.transaction((txn) => AccountSettingsRows.write(txn, next)))
        .catchError((Object _) {});
  }

  void update(AccountSettings Function(AccountSettings s) change) => _set(change(state));

  void signOutSession(String id) => _set(state.copyWith(
    sessions: [
      for (final s in state.sessions)
        if (s.id != id) s,
    ],
  ));

  void signOutOthers() => _set(state.copyWith(
    sessions: [
      for (final s in state.sessions)
        if (s.current) s,
    ],
  ));
}

/// [AccountSettings] ⇄ the `reglages_compte` row and the `sessions_appareils` rows.
abstract final class AccountSettingsRows {
  static AccountSettings read(Map<String, Object?> r, List<Map<String, Object?>> sessions) =>
      AccountSettings(
        email: r['email']! as String,
        phone: r['telephone']! as String,
        firstName: r['prenom']! as String,
        lastName: r['nom']! as String,
        birthDate: r['date_naissance']! as String,
        gender: Gender.values.byName(r['genre']! as String),
        passwordChanged: r['mdp_change']! as String,
        twoFactor: r['double_facteur'] == 1,
        sessions: [
          for (final s in sessions)
            DeviceSession(
              id: s['id']! as String,
              name: s['nom']! as String,
              where: s['lieu']! as String,
              current: s['actuelle'] == 1,
              mobile: s['mobile'] == 1,
            ),
        ],
        googleEmail: r['google_email'] as String?,
        appleConnected: r['apple'] == 1,
        profilePublic: r['profil_public'] == 1,
        invites: InvitePolicy.values.byName(r['invitations']! as String),
        showLevel: r['montrer_niveau'] == 1,
        showReliability: r['montrer_fiabilite'] == 1,
        preciseLocation: r['position_precise'] == 1,
        blocked: r['bloques']! as int,
        notificationsSummary: r['resume_notifications']! as String,
      );

  /// Replaces the row and the sessions with [s].
  static Future<void> write(DatabaseExecutor db, AccountSettings s) async {
    await db.insert(
      'reglages_compte',
      {
        'id': 1,
        'email': s.email,
        'telephone': s.phone,
        'prenom': s.firstName,
        'nom': s.lastName,
        'date_naissance': s.birthDate,
        'genre': s.gender.name,
        'mdp_change': s.passwordChanged,
        'double_facteur': s.twoFactor ? 1 : 0,
        'google_email': s.googleEmail,
        'apple': s.appleConnected ? 1 : 0,
        'profil_public': s.profilePublic ? 1 : 0,
        'invitations': s.invites.name,
        'montrer_niveau': s.showLevel ? 1 : 0,
        'montrer_fiabilite': s.showReliability ? 1 : 0,
        'position_precise': s.preciseLocation ? 1 : 0,
        'bloques': s.blocked,
        'resume_notifications': s.notificationsSummary,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await db.delete('sessions_appareils');
    for (final (i, d) in s.sessions.indexed) {
      await db.insert('sessions_appareils', {
        'id': d.id,
        'nom': d.name,
        'lieu': d.where,
        'actuelle': d.current ? 1 : 0,
        'mobile': d.mobile ? 1 : 0,
        'position': i,
      });
    }
  }
}

final accountSettingsProvider = NotifierProvider<AccountSettingsController, AccountSettings>(
  AccountSettingsController.new,
);
