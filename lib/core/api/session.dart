import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/app_database.dart';
import '../db/preferences.dart';

/// Who is signed in: the `id` of the account in the `utilisateurs` table, kept in `preferences`.
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

  Future<void> signOut() async {
    state = null;
    await _prefs.set(_key, null);
  }
}

final sessionProvider = NotifierProvider<Session, int?>(Session.new);
