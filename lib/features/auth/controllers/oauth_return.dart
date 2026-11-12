import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/api/session.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../router.dart';
import '../data/supabase_auth_repository.dart';
import 'auth_providers.dart';
import '../../profile/data/account_profile.dart';

/// « Continuer avec Google » (AUTH-01, AUTH-05): the browser leaves for Google and the app
/// starts again signed in to Supabase as that Google account. This finishes the sign-in: the
/// phone's copy of the account is signed in, then the app opens the roles screen (first time) or
/// where the account lands once its setup is done. Read once at start-up (main.dart).
final oauthReturnProvider = Provider<void>((ref) {
  if (!SupabaseConfig.configured) return;
  StreamSubscription<AuthState>? sub;
  ref.onDispose(() => sub?.cancel());

  // The restored session and the « signedIn » event both arrive on the way back from Google:
  // handle each Supabase user once, never twice at the same time (two copies of the account).
  final handled = <String>{};

  Future<void> handle(User? user) async {
    if (user == null || !handled.add(user.id)) return;
    final repo = ref.read(authRepositoryProvider);
    if (repo is! SupabaseAuthRepository) return;
    try {
      final email = await repo.adoptOAuthUser(user);
      if (email == null) return;
      ref.read(authFlowProvider.notifier).setEmail(email);
      final meta = user.userMetadata ?? const {};
      await ref.read(accountProfileProvider).fillNames((meta['full_name'] ?? meta['name']) as String?);
      final next = await ref.read(sessionProvider.notifier).nextRoute();
      await _goWhenStarted(ref.read(routerProvider), next ?? Routes.roles);
      // Signed out later on this phone, then Google again: handled again then.
      handled.remove(user.id);
    } catch (e) {
      handled.remove(user.id); // a later sign-in event may try again
      debugPrint('Connexion Google non terminée : $e');
    }
  }

  SupabaseConfig.init().then((_) {
    if (!SupabaseConfig.ready) return;
    final auth = Supabase.instance.client.auth;
    handle(auth.currentUser);
    sub = auth.onAuthStateChange.listen((s) {
      if (s.event == AuthChangeEvent.signedIn) handle(s.session?.user);
    });
  });
});

/// Waits for the splash to hand over (it picks its own next screen), then opens [route] — only
/// from an entry screen (splash, welcome, login, sign-up), never over a screen of the app.
Future<void> _goWhenStarted(GoRouter router, String route) async {
  String path() => router.routerDelegate.currentConfiguration.uri.path;
  for (var i = 0; i < 50; i++) {
    if (path() != Routes.splash && path() != '/') break;
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
  final here = path();
  final entry = here == '/' || here.startsWith('/onb/') || here == Routes.login || here == Routes.signup;
  if (entry) router.go(route);
}
