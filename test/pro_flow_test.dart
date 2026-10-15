import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matchup/app.dart';
import 'package:matchup/features/coach_onboarding/controllers/coach_controller.dart';
import 'package:matchup/features/coach_onboarding/data/coach_draft.dart';
import 'package:matchup/features/common/data/draft_store.dart';
import 'package:matchup/features/common/data/file_services.dart';
import 'package:matchup/features/common/data/pro_providers.dart';
import 'package:matchup/features/owner_onboarding/controllers/owner_controller.dart';
import 'package:matchup/features/owner_onboarding/data/owner_repository.dart';
import 'package:matchup/features/player_onboarding/controllers/onboarding_controller.dart';
import 'package:matchup/features/player_onboarding/data/onboarding_store.dart';
import 'package:matchup/router.dart';

/// Picks fixed files, instantly.
class _FakeFiles implements FileSource {
  @override
  Future<List<PickedFile>> pickImages() async => const [
        PickedFile(name: 'Vestiaires.jpg', sizeBytes: 1800000),
        PickedFile(name: 'Tribune de nuit.png', sizeBytes: 14200000),
      ];

  @override
  Future<PickedFile?> pickOne(List<String> extensions) async =>
      const PickedFile(name: 'Attestation.pdf', sizeBytes: 300000);
}

/// Uploads in one step.
class _InstantUpload implements UploadService {
  @override
  Stream<double> upload(String name, int sizeBytes) => Stream.value(1);
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  // A Wednesday, as in the designs.
  final today = DateTime(2026, 10, 14, 9);
  late MemoryDraftStore drafts;

  Future<ProviderContainer> pumpApp(
    WidgetTester tester, {
    required String at,
    Size size = const Size(1440, 900),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    drafts = MemoryDraftStore();
    final container = ProviderContainer(overrides: [
      onboardingStoreProvider.overrideWithValue(MemoryOnboardingStore()),
      draftStoreProvider.overrideWithValue(drafts),
      fileSourceProvider.overrideWithValue(_FakeFiles()),
      uploadServiceProvider.overrideWithValue(_InstantUpload()),
      clockProvider.overrideWithValue(() => today),
      ownerRepositoryProvider.overrideWithValue(const FakeOwnerRepository(latency: Duration.zero)),
      coachRepositoryProvider.overrideWithValue(FakeCoachRepository(now: () => today)),
    ]);
    addTearDown(container.dispose);
    container.read(routerProvider).go(at);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MatchUpApp()),
    );
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) => tap(tester, find.text(text).last);

  Future<void> enter(WidgetTester tester, String label, String text) async {
    final field = find.descendant(
      of: find.ancestor(of: find.text(label), matching: find.byType(Column)).first,
      matching: find.byType(TextField),
    );
    await tester.enterText(field.first, text);
    await tester.pumpAndSettle();
  }

  testWidgets('owner: company → … → plan → trial starts → dashboard', (tester) async {
    await pumpApp(tester, at: Routes.ownerCompany);
    expect(find.text('Parle-nous de ton entreprise'), findsOneWidget);
    expect(find.text('Mets Arena Five en ligne'), findsOneWidget);

    // The tax id is still missing.
    await tapText(tester, 'Continuer');
    expect(find.text('Indique ton matricule fiscal.'), findsOneWidget);
    await enter(tester, 'Matricule fiscal', '1234567/A/M/000');
    expect(drafts.drafts[OwnerController.storeKey]!['taxId'], '1234567/A/M/000');
    expect(find.textContaining('Brouillon enregistré'), findsOneWidget);
    await tapText(tester, 'Continuer');

    expect(find.text('Où se trouve Arena Five ?'), findsOneWidget);
    expect(find.text('Arena Five SARL'), findsOneWidget); // rail summary
    expect(find.text(' · épingle déplacée de 40 m'), findsOneWidget);
    await tapText(tester, 'Recentrer sur l’adresse');
    expect(find.text(' · épingle déplacée de 40 m'), findsNothing);
    await tapText(tester, 'Continuer');

    expect(find.text('Tes terrains'), findsOneWidget);
    await tap(tester, find.bySemanticsLabel('Modifier Terrain 2'));
    expect(find.text('Modification en cours'), findsOneWidget);
    await tapText(tester, 'Intérieur');
    await tapText(tester, 'Enregistrer');
    expect(find.text('Gazon synthétique · Intérieur'), findsNWidgets(2));
    await tapText(tester, 'Continuer');

    expect(find.text('Tes horaires d’ouverture'), findsOneWidget);
    expect(find.text('Fermé toute la journée'), findsOneWidget);
    expect(find.text('16 h'), findsNWidgets(3));
    await tapText(tester, 'Continuer');

    expect(find.text('Fixe tes tarifs'), findsOneWidget);
    expect(find.text('Terrains 1 et 2'), findsNothing); // Terrain 2 moved indoors
    expect(find.text('Terrain 1'), findsWidgets);
    expect(find.textContaining('soit 12'), findsOneWidget);
    await tapText(tester, 'Continuer');

    expect(find.text('Montre ton terrain'), findsOneWidget);
    await tap(tester, find.bySemanticsLabel(RegExp('^Ajoute tes photos. ')).first);
    expect(find.text('Fichier trop lourd'), findsOneWidget);
    expect(
      find.text('Tribune de nuit.png pèse 14,2 Mo (max 10 Mo). Réduis sa taille ou choisis une '
          'autre photo.'),
      findsOneWidget,
    );
    expect(find.text('6/20'), findsOneWidget);
    await tapText(tester, 'Continuer');

    expect(find.text('Où verser tes revenus ?'), findsOneWidget);
    expect(find.text('20 chiffres · clé RIB valide'), findsOneWidget);
    await tapText(tester, 'Continuer');

    expect(find.text('Choisis ton offre'), findsOneWidget);
    expect(find.text('Arena Five a 3 terrains : avec Starter, seuls 2 seraient réservables.'),
        findsOneWidget);
    await tapText(tester, 'Choisir Starter');
    expect(find.textContaining('Starter · 0 DT aujourd’hui'), findsOneWidget);
    await tapText(tester, 'Démarrer l’essai gratuit');

    expect(find.text('Bonjour Skander'), findsOneWidget);
    expect(find.text('Ton essai Starter court jusqu’au mer. 28 oct. Voici où en est Arena Five.'),
        findsOneWidget);
    expect(find.text('4/6 · 67 %'), findsOneWidget);
    expect(find.text('RIB en vérification'), findsOneWidget);
    expect(find.text('Aucune réservation pour l’instant'), findsOneWidget);
  });

  testWidgets('coach: profile → certification → dashboard', (tester) async {
    await pumpApp(tester, at: Routes.coachProfile);
    expect(find.text('Présente-toi aux joueurs'), findsOneWidget);
    expect(find.text('4 spécialités sur 6 max'), findsOneWidget);
    await tapText(tester, 'Tactique');
    expect(find.text('5 spécialités sur 6 max'), findsOneWidget);
    await tapText(tester, 'Continuer');

    expect(find.text('Ta certification'), findsOneWidget);
    expect(find.text('Padel · Lac 2, Tunis'), findsOneWidget); // rail summary
    expect(find.text('Vérification en cours · 48 h'), findsOneWidget);
    expect(find.textContaining('au plus tard le ven. 16 oct.'), findsOneWidget);
    await tapText(tester, 'Continuer');

    expect(find.text('Bienvenue, Skander'), findsOneWidget);
    expect(find.textContaining('Diplôme en vérification · réponse sous 48 h', findRichText: true),
        findsOneWidget);
    expect(find.text('Crée ton premier programme'), findsOneWidget);
    expect(find.text('Coach padel · Lac 2'), findsOneWidget);
    expect(find.textContaining('service, débutants'), findsOneWidget);
  });

  testWidgets('organiser: organisation with a second event → dashboard', (tester) async {
    await pumpApp(tester, at: Routes.organizerOrganisation);
    expect(find.text('Présente ton organisation'), findsOneWidget);
    expect(find.textContaining('1/3', findRichText: true), findsOneWidget);

    await tapText(tester, 'Ajouter un événement');
    await tapText(tester, 'Enregistrer');
    expect(find.text('Donne un nom à l’événement.'), findsOneWidget);
    await enter(tester, 'Nom de l’événement', 'Ramadan Cup');
    await tapText(tester, 'Enregistrer');
    expect(find.text('Ramadan Cup'), findsOneWidget);
    expect(find.textContaining('2/3', findRichText: true), findsOneWidget);
    await tapText(tester, 'Continuer');

    expect(find.text('Bienvenue, Ines'), findsOneWidget);
    expect(find.text('Reprendre Padel Cup Lac 2'), findsOneWidget);
    expect(find.text('TS'), findsWidgets);
  });

  testWidgets('narrow windows: compact stepper, sidebar in a drawer', (tester) async {
    await pumpApp(tester, at: Routes.ownerCompany, size: const Size(800, 900));
    expect(find.text('Étape 1 sur 8 · Entreprise'), findsOneWidget);
    expect(find.text('Besoin d’aide ?'), findsNothing);

    final container = ProviderScope.containerOf(tester.element(find.byType(MatchUpApp)));
    container.read(routerProvider).go(Routes.ownerDashboard);
    await tester.pumpAndSettle();
    expect(find.text('Planning'), findsNothing);
    await tap(tester, find.bySemanticsLabel('Ouvrir le menu'));
    expect(find.text('Planning'), findsOneWidget);
  });

  for (final size in const [Size(390, 844), Size(1024, 768), Size(1440, 900)]) {
    testWidgets('every pro screen lays out at ${size.width.toInt()} wide', (tester) async {
      final container = await pumpApp(tester, at: Routes.ownerCompany, size: size);
      final failures = <String>[];
      for (final route in [
        ...Routes.owner,
        Routes.ownerDashboard,
        Routes.coachProfile,
        Routes.coachCertification,
        Routes.coachDashboard,
        Routes.organizerOrganisation,
        Routes.organizerDashboard,
      ]) {
        container.read(routerProvider).go(route);
        await tester.pumpAndSettle();
        final e = tester.takeException();
        if (e != null) failures.add('$route: $e');
      }
      expect(failures, isEmpty);
    });
  }
}
