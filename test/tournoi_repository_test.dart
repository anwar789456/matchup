import 'package:flutter_test/flutter_test.dart';
import 'package:matchup/core/db/app_database.dart';
import 'package:matchup/features/tournaments/data/tournoi_repository.dart';
import 'package:matchup/features/tournaments/logic/bracket_logic.dart';
import 'package:matchup/theme/theme.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// The demo flow: create → register → pay → validate → bracket → scores → champion.
void main() {
  late AppDatabase database;
  late String me;
  late TournoiRepository repo;
  var clock = DateTime(2026, 11, 13, 10);

  setUp(() {
    sqfliteFfiInit();
    database = AppDatabase(factory: databaseFactoryFfi, path: inMemoryDatabasePath);
    me = 'orga';
    repo = TournoiRepository(database, me: () => me, now: () => clock = clock.add(const Duration(seconds: 1)));
  });
  tearDown(() => database.close());

  TournoiDraft draft({TournoiFormat format = TournoiFormat.elimination, int max = 8}) => TournoiDraft(
        nom: 'Padel Cup Lac 2',
        sport: MuSport.padel,
        debut: DateTime(2026, 11, 21, 9),
        fin: DateTime(2026, 11, 21, 19),
        etablissement: 'Padel Lac 2',
        lieu: 'Les Berges du Lac',
        fraisEquipe: 120,
        equipesMax: max,
        format: format,
      );

  Future<String> registerPaid(String tournoiId, String captain, String partner) async {
    me = captain;
    final team = await repo.inscrire(tournoiId,
        nom: 'Équipe $captain', capitaineNom: captain, coequipiers: [(partner, partner)]);
    await repo.marquerPaye(team.id);
    return team.id;
  }

  test('the whole tournament, from creation to champion', () async {
    final id = await repo.create(draft());
    expect((await repo.tournois(mine: true)).single.statut, TournoiStatut.inscriptionsOuvertes);

    final teams = [
      for (final c in ['c1', 'c2', 'c3', 'c4']) await registerPaid(id, c, 'p$c'),
    ];
    expect((await repo.equipe(teams.first))!.membres.first.$1, 'c1', reason: 'captain first');

    // Only the organiser decides; an unpaid team cannot be validated.
    await expectLater(repo.valider(teams.first), throwsA(isA<TournoiRefus>()));
    me = 'orga';
    for (final t in teams) {
      await repo.valider(t);
    }
    expect((await repo.equipes(id)).every((e) => e.statut == EquipeStatut.confirmee), isTrue);

    final day = DateTime(2026, 11, 21, 9);
    final plan = await repo.generer(id,
        terrains: ['Court 1', 'Court 2'], creneaux: [(debut: day, fin: day.add(const Duration(hours: 6)))]);
    expect(plan.where((m) => m.tour == 0), hasLength(2));
    await repo.publierTableau(id);

    var matches = await repo.matchs(id);
    for (final semi in matches.where((m) => m.tour == 0)) {
      await repo.scoreFinal(id, semi, 6, 3);
    }
    matches = await repo.matchs(id);
    final finale = matches.singleWhere((m) => m.tour == 1);
    expect(finale.equipe1, isNotNull);
    expect(finale.equipe2, isNotNull);
    await repo.scoreFinal(id, finale, 4, 6);
    expect((await repo.matchs(id)).singleWhere((m) => m.tour == 1).vainqueur, finale.equipe2);
    expect((await repo.tournoi(id))!.statut, TournoiStatut.termine);
  });

  test('registration rules: one team per player, unique names, invite code, full team', () async {
    final id = await repo.create(draft());
    me = 'c1';
    final team = await repo.inscrire(id, nom: 'Les Lions', capitaineNom: 'Alaa');
    await expectLater(repo.inscrire(id, nom: 'Autre', capitaineNom: 'Alaa'), throwsA(isA<TournoiRefus>()));
    me = 'c2';
    await expectLater(repo.inscrire(id, nom: 'les lions', capitaineNom: 'Ayoub'), throwsA(isA<TournoiRefus>()));

    final joined = await repo.rejoindre(team.codeInvitation.toLowerCase(), nom: 'Ayoub');
    expect(joined.membres.map((m) => m.$2), ['Alaa', 'Ayoub']);
    me = 'c3';
    await expectLater(repo.rejoindre(team.codeInvitation, nom: 'Hani'), throwsA(isA<TournoiRefus>()));
  });

  test('groups then knockout: group winners reach the final', () async {
    final id = await repo.create(draft(format: TournoiFormat.poulesElimination));
    final teams = [for (final c in ['c1', 'c2', 'c3', 'c4']) await registerPaid(id, c, 'p$c')];
    me = 'orga';
    for (final t in teams) {
      await repo.valider(t);
    }
    final day = DateTime(2026, 11, 21, 9);
    await repo.generer(id, terrains: ['Court 1', 'Court 2'], creneaux: [(debut: day, fin: day.add(const Duration(hours: 8)))]);
    final groups = await repo.poules(id);
    expect(groups.keys, ['A', 'B']);

    for (final m in (await repo.matchs(id)).where((m) => m.phase == Phase.poule)) {
      await repo.scoreFinal(id, m, 3, 1);
    }
    // The semi-finals now have their qualifiers (A1–B2, B1–A2); the final waits for them.
    final semis = (await repo.matchs(id)).where((m) => m.phase == Phase.elimination && m.tour == 0).toList();
    expect(semis, hasLength(2));
    expect(semis.every((m) => m.equipe1 != null && m.equipe2 != null), isTrue);
  });

  test('announcements are the organiser’s', () async {
    final id = await repo.create(draft());
    await repo.annoncer(id, 'Rendez-vous 8h30 au club.');
    me = 'c1';
    await expectLater(repo.annoncer(id, 'Spam'), throwsA(isA<TournoiRefus>()));
    expect((await repo.annonces(id)).single.$1, 'Rendez-vous 8h30 au club.');
  });
}
