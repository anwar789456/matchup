import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matchup/app.dart';
import 'package:matchup/features/auth/controllers/auth_providers.dart';
import 'package:matchup/features/auth/data/fake_auth_repository.dart';
import 'package:matchup/features/auth/screens/account_locked_screen.dart';
import 'package:matchup/features/auth/screens/login_screen.dart';
import 'package:matchup/features/auth/screens/password_changed_screen.dart';
import 'package:matchup/features/auth/screens/phone_screen.dart';
import 'package:matchup/features/auth/screens/role_choice_screen.dart';
import 'package:matchup/features/auth/screens/signup_screen.dart';
import 'package:matchup/features/auth/screens/verify_email_screen.dart';
import 'package:matchup/features/dev/pending_screen.dart';
import 'package:matchup/features/onboarding/screens/welcome_screen.dart';
import 'package:matchup/router.dart';

/// Walks the welcome and auth flows on a phone-sized screen with the fake repository.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  late FakeAuthRepository repo;

  Future<void> pumpApp(WidgetTester tester, {String? at}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // Reduced motion: no blinking caret or looping bars, so pumpAndSettle can settle.
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    repo = FakeAuthRepository(latency: Duration.zero);
    final container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);
    if (at != null) container.read(routerProvider).go(at);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MatchUpApp()),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final finder = find.text(text).last;
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> enter(WidgetTester tester, String label, String text) async {
    // MuTextField: the label is a sibling of the TextField inside the same column.
    final field = find.descendant(
      of: find.ancestor(of: find.text(label), matching: find.byType(Column)).first,
      matching: find.byType(TextField),
    );
    await tester.enterText(field.first, text);
    await tester.pumpAndSettle();
  }

  testWidgets('splash opens the welcome slides, then sign-up', (tester) async {
    await pumpApp(tester, at: Routes.splash);
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.text('Trouve des joueurs à ton niveau'), findsOneWidget);

    await tapText(tester, 'Suivant');
    expect(find.text('Réserve et paie en quelques secondes'), findsOneWidget);
    await tapText(tester, 'Suivant');
    expect(find.text('Commencer'), findsOneWidget);
    await tapText(tester, 'Commencer');
    expect(find.byType(SignupScreen), findsOneWidget);
  });

  testWidgets('« Passer » jumps to the last slide', (tester) async {
    await pumpApp(tester, at: Routes.welcome1);
    await tapText(tester, 'Passer');
    expect(find.text('J’ai déjà un compte'), findsOneWidget);
    await tapText(tester, 'J’ai déjà un compte');
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('sign-up shows the AUTH-01b errors, then reaches the roles', (tester) async {
    await pumpApp(tester, at: Routes.signup);

    await enter(tester, 'Email', 'yassine.b@email.tn');
    await enter(tester, 'Mot de passe', 'marsa26');
    await tapText(tester, 'Créer mon compte');
    expect(find.text('Ton mot de passe doit respecter les 3 règles.'), findsOneWidget);
    expect(find.text('Accepte les conditions pour continuer.'), findsOneWidget);

    await enter(tester, 'Mot de passe', 'Marsa2026');
    await tapText(tester, 'J’accepte les conditions d’utilisation et la politique de confidentialité');
    await tapText(tester, 'Créer mon compte');
    expect(find.text('Un compte existe déjà avec cet email.'), findsOneWidget);
    expect(find.text('Se connecter'), findsWidgets);

    await enter(tester, 'Email', 'nour.a@email.tn');
    await tapText(tester, 'Créer mon compte');
    expect(find.byType(PhoneScreen), findsOneWidget);

    await enter(tester, 'Numéro de téléphone', '2012');
    await tapText(tester, 'Recevoir le code');
    expect(find.text('Le numéro doit contenir 8 chiffres.'), findsOneWidget);
    await enter(tester, 'Numéro de téléphone', '20123456');
    await tapText(tester, 'Recevoir le code');
    expect(find.textContaining('+216 20 •• •• 56'), findsOneWidget);

    // Wrong code: AUTH-03b.
    await tester.enterText(find.byType(TextField).first, '482915');
    await tester.pumpAndSettle();
    expect(find.text('Code incorrect. Il te reste 2 essais.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '123456');
    await tester.pump();
    await tester.pump();
    expect(find.text('Numéro vérifié.'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();
    expect(find.byType(VerifyEmailScreen), findsOneWidget);
    expect(find.textContaining('nour.a@email.tn'), findsOneWidget);

    await tapText(tester, 'Continuer');
    expect(find.byType(RoleChoiceScreen), findsOneWidget);
    expect(find.text('Choisis au moins un rôle'), findsOneWidget);
    await tapText(tester, 'Coach');
    await tapText(tester, 'Joueur');
    expect(find.text('Continuer · Joueur d’abord'), findsOneWidget);
    await tapText(tester, 'Continuer · Joueur d’abord');
    expect(find.byType(PendingScreen), findsOneWidget);
    expect(repo.roles.length, 2);
  });

  testWidgets('five wrong sign-ins lock the account (AUTH-05b → AUTH-10)', (tester) async {
    await pumpApp(tester, at: Routes.login);
    await enter(tester, 'Email', 'yassine.b@email.tn');
    await enter(tester, 'Mot de passe', 'wrong');
    await tapText(tester, 'Se connecter');
    expect(find.text('Email ou mot de passe incorrect.'), findsOneWidget);
    expect(find.text('Il te reste 4 essais avant le blocage temporaire.'), findsOneWidget);
    for (var i = 0; i < 4; i++) {
      await tapText(tester, 'Se connecter');
    }
    expect(find.byType(AccountLockedScreen), findsOneWidget);
    expect(find.text('Compte bloqué pendant 15 min'), findsOneWidget);
    expect(find.text('Tu pourras réessayer dans'), findsOneWidget);
  });

  testWidgets('a right password signs in', (tester) async {
    await pumpApp(tester, at: Routes.login);
    await enter(tester, 'Email', 'yassine.b@email.tn');
    await enter(tester, 'Mot de passe', 'Marsa2026');
    await tapText(tester, 'Se connecter');
    expect(find.byType(RoleChoiceScreen), findsOneWidget);
  });

  testWidgets('forgot password: email → code → new password → done', (tester) async {
    await pumpApp(tester, at: Routes.login);
    await enter(tester, 'Email', 'yassine.b@email.tn');
    await tapText(tester, 'Mot de passe oublié ?');
    expect(find.text('Envoyer le code'), findsOneWidget);
    await tapText(tester, 'Envoyer le code');
    expect(find.text('Code reçu par email'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '123456');
    await tester.pumpAndSettle();
    expect(find.text('Choisis un nouveau mot de passe'), findsOneWidget);

    await enter(tester, 'Nouveau mot de passe', 'Marsa2026');
    await enter(tester, 'Confirme le mot de passe', 'Marsa2026');
    expect(find.text('Les mots de passe correspondent.'), findsOneWidget);
    await tapText(tester, 'Enregistrer');
    expect(find.text('Il doit être différent de l’ancien.'), findsWidgets);

    await enter(tester, 'Nouveau mot de passe', 'Lac2-Padel26');
    await enter(tester, 'Confirme le mot de passe', 'Lac2-Padel26');
    await tapText(tester, 'Enregistrer');
    expect(find.byType(PasswordChangedScreen), findsOneWidget);
    await tapText(tester, 'Se connecter');
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
