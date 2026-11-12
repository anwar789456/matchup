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

/// « Continuer avec Google » (AUTH-01, AUTH-05): the browser leaves for Google and the app
/// starts again signed in to Supabase as that Google account. This finishes the sign-in: the
/// phone's copy of the account is signed in, then the app opens the roles screen (first time) or
/// where the account lands once its setup is done. Read once at start-up (main.dart).
final oauthReturnProvider = Provider<void>((ref) {
  if (!SupabaseConfig.configured) return;
  StreamSubscription<AuthState>? sub;
  ref.onDispose(() => sub?.cancel());

  Future<void> handle(User? user) async {
    if (user == null) return;
    final repo = ref.read(authRepositoryProvider);
    if (repo is! SupabaseAuthRepository) return;
    try {
      final email = await repo.adoptOAuthUser(user);
      if (email == null) return;
      ref.read(authFlowProvider.notifier).setEmail(email);
      final home = await ref.read(sessionProvider.notifier).setupDoneRoute();
      await _goWhenStarted(ref.read(routerProvider), home ?? Routes.roles);
    } catch (e) {
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

/// Waits for the splash to hand over (it picks its own next screen), then opens [route].
Future<void> _goWhenStarted(GoRouter router, String route) async {
  for (var i = 0; i < 50; i++) {
    final path = router.routerDelegate.currentConfiguration.uri.path;
    if (path != Routes.splash && path != '/') break;
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
  router.go(route);
}
