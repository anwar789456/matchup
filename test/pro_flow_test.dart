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
import 'package:matchup/features/common/widgets/flow_scaffold.dart';
import 'package:matchup/features/common/widgets/pro_wizard_scaffold.dart';
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
    Size size = const Size(390, 844),
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

  /// Opens « Voir les étapes », runs [check] on the steps sheet, then closes it.
  Future<void> inSteps(WidgetTester tester, void Function() check) async {
    await tap(tester, find.bySemanticsLabel('Voir les étapes'));
    check();
    await tap(tester, find.bySemanticsLabel('Fermer').last);
  }

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
    expect(
      find.text('Étape 2 sur 8 · Adresse', findRichText: true),
      findsOneWidget,
    );
    await inSteps(tester, () {
      expect(find.text('Arena Five SARL'), findsOneWidget); // step summary
      expect(find.text('Besoin d’aide ?'), findsOneWidget);
    });
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
    await inSteps(tester, () {
      expect(find.text('Padel · Lac 2, Tunis'), findsOneWidget); // step summary
    });
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

  const proRoutes = [
    ...Routes.owner,
    Routes.ownerDashboard,
    Routes.coachProfile,
    Routes.coachCertification,
    Routes.coachDashboard,
    Routes.organizerOrganisation,
    Routes.organizerDashboard,
  ];

  group('every pro screen lays out at 360, 390 and 430 wide without overflow', () {
    for (final size in const [Size(360, 740), Size(390, 844), Size(430, 932)]) {
      testWidgets('${size.width.toInt()} wide', (tester) async {
        final container = await pumpApp(tester, at: Routes.ownerCompany, size: size);
        final failures = <String>[];
        for (final route in proRoutes) {
          container.read(routerProvider).go(route);
          await tester.pumpAndSettle();
          final e = tester.takeException();
          if (e != null) failures.add('${size.width.toInt()} $route: $e');
        }
        // The editors open in place: a court, then a past event.
        container.read(routerProvider).go(Routes.owner[2]);
        await tester.pumpAndSettle();
        await tap(tester, find.bySemanticsLabel('Modifier Terrain 1'));
        container.read(routerProvider).go(Routes.organizerOrganisation);
        await tester.pumpAndSettle();
        await tapText(tester, 'Ajouter un événement');
        final e = tester.takeException();
        if (e != null) failures.add('${size.width.toInt()} editors: $e');
        expect(failures, isEmpty);
        });
    }
  });

  testWidgets('on a 1024-wide tablet the form is centred at max 480', (tester) async {
    final container = await pumpApp(tester, at: Routes.ownerCompany, size: const Size(1024, 768));
    Rect frame() => tester.getRect(
      find.descendant(of: find.byType(ProPhoneFrame), matching: find.byType(ConstrainedBox)).first,
    );

    expect(find.text('Étape 1 sur 8 · Entreprise', findRichText: true), findsOneWidget);
    expect(frame().width, ProPhoneFrame.maxWidth);
    expect(frame().center.dx, 512);
    expect(tester.getRect(find.byType(StickyActionBar)).width, ProPhoneFrame.maxWidth);

    for (final route in [Routes.ownerDashboard, Routes.coachProfile, Routes.organizerDashboard]) {
      container.read(routerProvider).go(route);
      await tester.pumpAndSettle();
      expect(frame().width, ProPhoneFrame.maxWidth, reason: route);
      expect(frame().center.dx, 512, reason: route);
    }
    expect(tester.takeException(), isNull);
  });
}
