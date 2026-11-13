import 'package:flutter_test/flutter_test.dart';
import 'package:matchup/features/tournaments/logic/bracket_logic.dart';

/// The tournament rules of backend/apps/tournois/README.md, on the Dart port.
void main() {
  List<String> teams(int n) => [for (var i = 1; i <= n; i++) 'T$i'];

  test('seeding: 1 and 2 only meet in the final', () {
    expect(bracketSize(5), 8);
    expect(bracketSize(2), 2);
    expect(seedPositions(8), [1, 8, 4, 5, 2, 7, 3, 6]);
  });

  test('single elimination of 6: byes go to the best seeds and are settled', () {
    final m = drawSingleElimination(teams(6));
    expect(roundSizes(m), [4, 2, 1]);
    final first = m.where((x) => x.tour == 0).toList();
    expect(first.where((x) => x.exempt), hasLength(2));
    // T1 and T2 get the byes and are already in the semi-finals.
    final semis = m.where((x) => x.tour == 1).toList();
    expect([semis[0].equipe1, semis[1].equipe1], ['T1', 'T2']);
  });

  test('snake draw and round robin', () {
    expect(splitIntoGroups(teams(8), 2), [
      ['T1', 'T4', 'T5', 'T8'],
      ['T2', 'T3', 'T6', 'T7'],
    ]);
    final days = roundRobin(['A', 'B', 'C', 'D']);
    expect(days, hasLength(3));
    final pairs = {for (final d in days) for (final (a, b) in d) ({a, b}.toList()..sort()).join()};
    expect(pairs, {'AB', 'AC', 'AD', 'BC', 'BD', 'CD'});
    // Odd count: one team rests each day.
    expect(roundRobin(['A', 'B', 'C']).every((d) => d.length == 1), isTrue);
  });

  test('groups then knockout: classic crossing A1–B2, B1–A2', () {
    final m = drawGroupsAndKnockout(teams(8), 2, 2);
    expect(m.where((x) => x.phase == Phase.poule), hasLength(12));
    final semis = m.where((x) => x.phase == Phase.elimination && x.tour == 0).toList();
    expect([(semis[0].source1, semis[0].source2), (semis[1].source1, semis[1].source2)], [
      ('poule:A:1', 'poule:B:2'),
      ('poule:B:1', 'poule:A:2'),
    ]);
  });

  test('standings: 3 points a win, ties on difference then scored then seed', () {
    MatchPlan played(String a, String b, int s1, int s2) => MatchPlan(
          phase: Phase.poule,
          poule: 'A',
          equipe1: a,
          equipe2: b,
          score1: s1,
          score2: s2,
          statut: MatchStatus.termine,
        );
    final table = standings(
      ['T1', 'T2', 'T3'],
      [played('T1', 'T2', 2, 1), played('T2', 'T3', 3, 0), played('T3', 'T1', 1, 1)],
      qualifies: 2,
    );
    expect([for (final r in table) (r.equipe, r.points, r.diff)], [
      ('T1', 4, 1),
      ('T2', 3, 2),
      ('T3', 1, -3),
    ]);
    expect([for (final r in table) r.qualifie], [true, true, false]);
  });

  test('results: group winners fill the knockout, the final winner is known', () {
    final m = drawGroupsAndKnockout(teams(4), 2, 1);
    final groups = {'A': ['T1', 'T4'], 'B': ['T2', 'T3']};
    for (final g in m.where((x) => x.phase == Phase.poule).toList()) {
      // The first-listed team wins every group match.
      recordResult(m, g, score1: 2, score2: 0, groups: groups, qualifiesParPoule: 1);
    }
    final finale = m.singleWhere((x) => x.phase == Phase.elimination);
    expect({finale.equipe1, finale.equipe2}, hasLength(2));
    expect(() => recordResult(m, finale, score1: 1, score2: 1), throwsArgumentError);
    recordResult(m, finale, score1: 1, score2: 1, vainqueur: finale.equipe2);
    expect(finale.vainqueur, finale.equipe2);
  });

  test('schedule: rest between matches, knockout after its feeders, error when short', () {
    final m = drawSingleElimination(teams(4));
    final day = DateTime(2026, 11, 14, 9);
    schedule(
      m,
      terrains: ['Court 1', 'Court 2'],
      creneaux: [(debut: day, fin: day.add(const Duration(hours: 4)))],
      dureeMatch: const Duration(minutes: 45),
      repos: const Duration(minutes: 15),
    );
    final semis = m.where((x) => x.tour == 0).toList();
    final finale = m.singleWhere((x) => x.tour == 1);
    expect(semis.map((x) => x.debut), everyElement(day));
    expect({for (final s in semis) s.terrain}, {'Court 1', 'Court 2'});
    // 9:00 + 45 min + 15 min rest → the 10:30 slot (slots every 45 min: 9:00, 9:45, 10:30).
    expect(finale.debut, DateTime(2026, 11, 14, 10, 30));

    expect(
      () => schedule(
        drawSingleElimination(teams(8)),
        terrains: ['Court 1'],
        creneaux: [(debut: day, fin: day.add(const Duration(hours: 1)))],
        dureeMatch: const Duration(minutes: 45),
      ),
      throwsA(isA<ScheduleError>().having((e) => e.manquants, 'manquants', 6)),
    );
  });
}
