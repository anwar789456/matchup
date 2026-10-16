import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Who is signed in: the `id` of the account in the utilisateur module, kept on the device.
/// No token yet — the team's backend has no authentication (school project).
class Session extends Notifier<int?> {
  static const _key = 'session.userId';

  @override
  int? build() {
    SharedPreferences.getInstance().then((prefs) {
      final id = prefs.getInt(_key);
      if (id != null && state == null) state = id;
    });
    return null;
  }

  Future<void> signIn(int userId) async {
    state = userId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, userId);
  }

  Future<void> signOut() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

final sessionProvider = NotifierProvider<Session, int?>(Session.new);
