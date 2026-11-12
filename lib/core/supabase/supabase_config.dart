import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The Supabase project, given at build time (never committed):
///
///     flutter run --dart-define-from-file=supabase.json
///
/// with `supabase.json` = `{ "SUPABASE_URL": "https://xxxx.supabase.co",
/// "SUPABASE_PUBLISHABLE_KEY": "sb_publishable_…" }` (copy `supabase.example.json`; the key is
/// in Project Settings › API Keys, the legacy « anon » key works too). Without it the app runs
/// on the phone's database alone.
abstract final class SupabaseConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const publishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static bool get configured => url.isNotEmpty && publishableKey.isNotEmpty;

  static bool _initialized = false;
  static bool _ready = false;
  static Future<void>? _connecting;

  /// Supabase is initialised and the device has a session.
  static bool get ready => _ready;

  /// The signed-in Supabase user: the author id of rows in shared tables. Null when Supabase is
  /// not configured or not reached yet; use a local id then (the row stays on this phone).
  static String? get userId => _ready ? Supabase.instance.client.auth.currentUser?.id : null;

  /// Connects and signs the device in (anonymously until the account module links a real user).
  /// Never throws: offline or misconfigured, the app keeps working on SQFlite and retries later.
  static Future<void> init() {
    if (!configured || _ready) return Future.value();
    return _connecting ??= _connect().whenComplete(() => _connecting = null);
  }

  static Future<void> _connect() async {
    try {
      if (!_initialized) {
        await Supabase.initialize(url: url, publishableKey: publishableKey);
        _initialized = true;
      }
      final auth = Supabase.instance.client.auth;
      if (auth.currentSession == null) await auth.signInAnonymously();
      _ready = true;
    } catch (e) {
      debugPrint('Supabase indisponible, on reste en local : $e');
    }
  }

  /// True once there is a session (tries again after starting offline).
  static Future<bool> ensureSession() async {
    await init();
    return _ready;
  }
}
