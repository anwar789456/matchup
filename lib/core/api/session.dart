import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../db/app_database.dart';
import '../db/preferences.dart';
import '../supabase/supabase_config.dart';

/// Who is signed in: the `id` of the account in the `utilisateurs` table, kept in `preferences`.
///
/// It also remembers, per account, how far its setup went, so the roles screen (AUTH-11) and
/// the onboarding run once: [markRoleChosen] when a role is picked (the next sign-ins resume
/// that role's setup), [markSetupDone] at its end (the next sign-ins open the account's home).
/// Both are kept on the phone and, once the device's Supabase session is the real account, in
/// its `user_metadata` (`accueil`, `etape`), so they follow the account to any phone.
class Session extends Notifier<int?> {
  static const _key = 'session.utilisateur_id';

  Preferences get _prefs => Preferences(ref.read(appDatabaseProvider));

  @override
  int? build() {
    _prefs.get(_key).then((v) {
      final id = int.tryParse(v ?? '');
      if (id != null && state == null) state = id;
    }).catchError((Object _) {});
    return null;
  }

  Future<void> signIn(int userId) async {
    state = userId;
    await _prefs.set(_key, '$userId');
  }

  /// Signs out of the phone and of the Supabase account (Google included), so the next launch
  /// does not sign it back in; the device goes back to its anonymous session for the sync.
  Future<void> signOut() async {
    state = null;
    await _prefs.set(_key, null);
    if (_realUser() == null) return;
    try {
      final auth = Supabase.instance.client.auth;
      await auth.signOut();
      await auth.signInAnonymously();
    } catch (e) {
      debugPrint('Déconnexion Supabase incomplète : $e');
    }
  }

  /// The account picked its role: the next sign-ins resume at [route] (that role's next setup
  /// screen) instead of the roles screen.
  Future<void> markRoleChosen(String route) => _remember(etape: route);

  /// The account went through its setup: the next sign-ins open [route] (its home or dashboard).
  Future<void> markSetupDone(String route) => _remember(accueil: route);

  /// Where the signed-in account lands after signing in, or null while its setup was never done.
  Future<String?> setupDoneRoute() async {
    final id = state;
    return id == null ? null : _prefs.get(_setupKey(id));
  }

  /// Where to go after a sign-in: the home once the setup is done, else the setup of the role
  /// already chosen, else null (the roles screen). Reads the Supabase account first.
  Future<String?> nextRoute() async {
    await reconcile();
    final id = state;
    if (id == null) return null;
    return await _prefs.get(_setupKey(id)) ?? await _prefs.get(_stepKey(id));
  }

  /// Merges the phone's markers with the Supabase account's: what only one side has is copied
  /// to the other. Quiet without a real (non-anonymous) session; never throws.
  Future<void> reconcile() async {
    final id = state;
    final user = _realUser();
    if (id == null || user == null) return;
    try {
      final meta = user.userMetadata ?? const {};
      final remote = (accueil: meta['accueil'] as String?, etape: meta['etape'] as String?);
      final local = (accueil: await _prefs.get(_setupKey(id)), etape: await _prefs.get(_stepKey(id)));
      if (local.accueil == null && remote.accueil != null) await _prefs.set(_setupKey(id), remote.accueil);
      if (local.etape == null && remote.etape != null) await _prefs.set(_stepKey(id), remote.etape);
      final push = <String, Object?>{
        if (local.accueil != null && remote.accueil == null) 'accueil': local.accueil,
        if (local.etape != null && remote.etape == null) 'etape': local.etape,
      };
      if (push.isNotEmpty) await Supabase.instance.client.auth.updateUser(UserAttributes(data: push));
    } catch (e) {
      debugPrint('Étape du compte non synchronisée : $e');
    }
  }

  Future<void> _remember({String? accueil, String? etape}) async {
    final id = state;
    if (id == null) return;
    if (accueil != null) await _prefs.set(_setupKey(id), accueil);
    if (etape != null) await _prefs.set(_stepKey(id), etape);
    final user = _realUser();
    if (user == null) return; // Pushed by [reconcile] at the next real sign-in.
    try {
      await Supabase.instance.client.auth.updateUser(UserAttributes(data: {
        'accueil': ?accueil,
        'etape': ?etape,
      }));
    } catch (e) {
      debugPrint('Étape du compte non synchronisée : $e');
    }
  }

  /// The device's Supabase user when it is a real account (not the anonymous device session).
  static User? _realUser() {
    if (!SupabaseConfig.ready) return null;
    final user = Supabase.instance.client.auth.currentUser;
    return user == null || user.isAnonymous ? null : user;
  }

  static String _setupKey(int id) => 'compte.$id.accueil';
  static String _stepKey(int id) => 'compte.$id.etape';
}

final sessionProvider = NotifierProvider<Session, int?>(Session.new);
