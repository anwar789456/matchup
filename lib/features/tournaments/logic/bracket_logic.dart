/// Pure tournament logic (no database): draws, group standings, results and the schedule.
/// Ported from the backend's `tableau.logic.ts` so the app works on SQFlite + Supabase.
///
/// Knockout slots are wired with « sources »:
///   `match:<tour>:<ordre>`  winner of that knockout match
///   `poule:<A>:<rang>`      team finishing at that rank in that group
///   null                    a bye: the other team goes through
library;

import 'dart:math' as math;

enum Phase { poule, elimination }

enum MatchStatus { aJouer, enDirect, termine }

/// One match of the plan. Mutable on purpose: the draw fills it, results and the schedule
/// update it, then the repository saves it.
class MatchPlan {
  MatchPlan({
    this.phase = Phase.elimination,
    this.poule,
    this.tour = 0,
    this.ordre = 0,
    this.equipe1,
    this.equipe2,
    this.source1,
    this.source2,
    this.statut = MatchStatus.aJouer,
    this.exempt = false,
    this.vainqueur,
    this.score1,
    this.score2,
    this.debut,
    this.terrain,
  });

  final Phase phase;

  /// Group letter (« A »), null in the knockout.
  final String? poule;

  /// Group: day (1, 2, 3…). Knockout: round index (0 = first round).
  final int tour;
  final int ordre;
  String? equipe1;
  String? equipe2;
  final String? source1;
  final String? source2;
  MatchStatus statut;

  /// A first-round bye: one slot stays empty.
  final bool exempt;
  String? vainqueur;
  int? score1;
  int? score2;
  DateTime? debut;
  String? terrain;

  /// `match:<tour>:<ordre>`, how the next round refers to this knockout match.
  String get key => 'match:$tour:$ordre';
}

/// Smallest power of two ≥ [n] (at least 2).
int bracketSize(int n) {
  var size = 2;
  while (size < n) {
    size *= 2;
  }
  return size;
}

/// Standard seeding positions: for 8 → [1, 8, 4, 5, 2, 7, 3, 6]. Seeds 1 and 2 can only meet in
/// the final, and the byes go to the best seeds.
List<int> seedPositions(int size) {
  var order = [1, 2];
  while (order.length < size) {
    final sum = order.length * 2 + 1;
    order = [for (final s in order) ...[s, sum - s]];
  }
  return order;
}

/// How many matches each knockout round has, first round first (8 teams → [4, 2, 1]).
List<int> roundSizes(List<MatchPlan> matches) {
  final ko = matches.where((m) => m.phase == Phase.elimination);
  if (ko.isEmpty) return const [];
  final rounds = ko.map((m) => m.tour).reduce(math.max) + 1;
  return [for (var t = 0; t < rounds; t++) ko.where((m) => m.tour == t).length];
}

typedef _Slot = ({String? equipe, String? source});

/// Knockout tree from slots ordered by seed. First-round byes with a known team are settled.
List<MatchPlan> _knockout(List<_Slot> slots) {
  final size = bracketSize(slots.length);
  final positions = seedPositions(size);
  final rounds = (math.log(size) / math.ln2).round();
  final matches = <MatchPlan>[];
  for (var tour = 0; tour < rounds; tour++) {
    final count = size ~/ math.pow(2, tour + 1);
    for (var ordre = 0; ordre < count; ordre++) {
      if (tour == 0) {
        final ia = positions[ordre * 2] - 1;
        final ib = positions[ordre * 2 + 1] - 1;
        final a = ia < slots.length ? slots[ia] : null;
        final b = ib < slots.length ? slots[ib] : null;
        matches.add(MatchPlan(
          tour: tour,
          ordre: ordre,
          equipe1: a?.equipe,
          source1: a?.source,
          equipe2: b?.equipe,
          source2: b?.source,
          exempt: a == null || b == null,
        ));
      } else {
        matches.add(MatchPlan(
          tour: tour,
          ordre: ordre,
          source1: 'match:${tour - 1}:${ordre * 2}',
          source2: 'match:${tour - 1}:${ordre * 2 + 1}',
        ));
      }
    }
  }
  settleByes(matches);
  return matches;
}

/// A bye whose team is known is won at once, and the team moves to the next round.
void settleByes(List<MatchPlan> matches) {
  for (final m in matches) {
    if (!m.exempt || m.statut == MatchStatus.termine) continue;
    final team = m.equipe1 ?? m.equipe2;
    if (team == null) continue;
    m
      ..statut = MatchStatus.termine
      ..vainqueur = team;
    advance(matches, m, team);
  }
}

/// Puts [winner] in the slot of the next match fed by [from]; returns that match.
MatchPlan? advance(List<MatchPlan> matches, MatchPlan from, String? winner) {
  for (final next in matches) {
    if (next.phase != Phase.elimination) continue;
    if (next.source1 == from.key) {
      next.equipe1 = winner;
    } else if (next.source2 == from.key) {
      next.equipe2 = winner;
    } else {
      continue;
    }
    return next;
  }
  return null;
}

/// Single elimination: [teams] ordered by seed, best first.
List<MatchPlan> drawSingleElimination(List<String> teams) =>
    _knockout([for (final t in teams) (equipe: t, source: null)]);

const groupLetters = 'ABCDEFGHIJKLMNOP';

/// Snake draw by seed (A B C D D C B A A B…), so every group gets a fair mix.
List<List<String>> splitIntoGroups(List<String> teams, int nbPoules) {
  final groups = [for (var i = 0; i < nbPoules; i++) <String>[]];
  for (var i = 0; i < teams.length; i++) {
    final lap = i ~/ nbPoules;
    final pos = i % nbPoules;
    groups[lap.isEven ? pos : nbPoules - 1 - pos].add(teams[i]);
  }
  return groups;
}

/// Round robin (circle method): the days, each a list of (home, away).
List<List<(T, T)>> roundRobin<T>(List<T> teams) {
  final list = <T?>[...teams];
  if (list.length.isOdd) list.add(null);
  final n = list.length;
  final days = <List<(T, T)>>[];
  for (var day = 0; day < n - 1; day++) {
    final pairs = <(T, T)>[];
    for (var i = 0; i < n ~/ 2; i++) {
      final a = list[i];
      final b = list[n - 1 - i];
      if (a != null && b != null) pairs.add(day.isEven ? (a, b) : (b, a));
    }
    days.add(pairs);
    list.insert(1, list.removeLast());
  }
  return days;
}

/// Groups then knockout. Qualifiers are seeded group winners first, then runners-up in group
/// order: the classic crossing A1–B2, B1–A2.
List<MatchPlan> drawGroupsAndKnockout(List<String> teams, int nbPoules, int qualifiesParPoule) {
  final groups = splitIntoGroups(teams, nbPoules);
  final matches = <MatchPlan>[];
  for (var g = 0; g < groups.length; g++) {
    final letter = groupLetters[g];
    var ordre = 0;
    final days = roundRobin(groups[g]);
    for (var day = 0; day < days.length; day++) {
      for (final (home, away) in days[day]) {
        matches.add(MatchPlan(
          phase: Phase.poule,
          poule: letter,
          tour: day + 1,
          ordre: ordre++,
          equipe1: home,
          equipe2: away,
        ));
      }
    }
  }
  final slots = <_Slot>[
    for (var rang = 1; rang <= qualifiesParPoule; rang++)
      for (var g = 0; g < groups.length; g++)
        if (groups[g].length >= rang) (equipe: null, source: 'poule:${groupLetters[g]}:$rang'),
  ];
  return [...matches, ..._knockout(slots)];
}

// ───────────────────────────────────────── Standings ─────────────────────────────────────────

class StandingRow {
  StandingRow(this.equipe);

  final String equipe;
  int rang = 0;
  int joues = 0;
  int victoires = 0;
  int nuls = 0;
  int defaites = 0;
  int pour = 0;
  int contre = 0;
  int points = 0;
  bool qualifie = false;

  int get diff => pour - contre;
}

/// 3 points a win, 1 a draw. Ties: points, difference, scored, then seed order ([teams] order).
List<StandingRow> standings(List<String> teams, Iterable<MatchPlan> matches, {int qualifies = 0}) {
  final rows = {for (final t in teams) t: StandingRow(t)};
  for (final m in matches) {
    if (m.statut != MatchStatus.termine || m.equipe1 == null || m.equipe2 == null) continue;
    final s1 = m.score1;
    final s2 = m.score2;
    if (s1 == null || s2 == null) continue;
    final a = rows[m.equipe1];
    final b = rows[m.equipe2];
    if (a == null || b == null) continue;
    a
      ..joues += 1
      ..pour += s1
      ..contre += s2;
    b
      ..joues += 1
      ..pour += s2
      ..contre += s1;
    final winner = s1 > s2 ? m.equipe1 : (s2 > s1 ? m.equipe2 : m.vainqueur);
    if (winner == m.equipe1) {
      a
        ..victoires += 1
        ..points += 3;
      b.defaites += 1;
    } else if (winner == m.equipe2) {
      b
        ..victoires += 1
        ..points += 3;
      a.defaites += 1;
    } else {
      a
        ..nuls += 1
        ..points += 1;
      b
        ..nuls += 1
        ..points += 1;
    }
  }
  final seed = {for (var i = 0; i < teams.length; i++) teams[i]: i};
  final sorted = rows.values.toList()
    ..sort((x, y) {
      final byPoints = y.points.compareTo(x.points);
      if (byPoints != 0) return byPoints;
      final byDiff = y.diff.compareTo(x.diff);
      if (byDiff != 0) return byDiff;
      final byScored = y.pour.compareTo(x.pour);
      if (byScored != 0) return byScored;
      return seed[x.equipe]!.compareTo(seed[y.equipe]!);
    });
  for (var i = 0; i < sorted.length; i++) {
    sorted[i]
      ..rang = i + 1
      ..qualifie = i < qualifies;
  }
  return sorted;
}

// ───────────────────────────────────────── Results ─────────────────────────────────────────

/// The final score of [m] (ORG-13): the winner goes to the next round. A knockout draw needs
/// [vainqueur] (tie-break, penalties). Then the group qualifiers are placed once every match of
/// their group is over ([groups] = the teams of each group letter, seed order).
void recordResult(
  List<MatchPlan> matches,
  MatchPlan m, {
  required int score1,
  required int score2,
  String? vainqueur,
  Map<String, List<String>> groups = const {},
  int qualifiesParPoule = 0,
}) {
  final winner = score1 > score2 ? m.equipe1 : (score2 > score1 ? m.equipe2 : vainqueur);
  if (m.phase == Phase.elimination && winner == null) {
    throw ArgumentError('Match nul en phase finale : choisis le vainqueur.');
  }
  m
    ..score1 = score1
    ..score2 = score2
    ..vainqueur = winner
    ..statut = MatchStatus.termine;
  if (m.phase == Phase.elimination) {
    advance(matches, m, winner);
  } else {
    fillFromGroups(matches, groups, qualifiesParPoule);
  }
}

/// Places `poule:<A>:<rang>` qualifiers into the knockout once group A has played every match.
void fillFromGroups(List<MatchPlan> matches, Map<String, List<String>> groups, int qualifiesParPoule) {
  for (final MapEntry(key: letter, value: teams) in groups.entries) {
    final played = matches.where((m) => m.phase == Phase.poule && m.poule == letter);
    if (played.isEmpty || played.any((m) => m.statut != MatchStatus.termine)) continue;
    final table = standings(teams, played, qualifies: qualifiesParPoule);
    for (final row in table.where((r) => r.qualifie)) {
      final source = 'poule:$letter:${row.rang}';
      for (final next in matches) {
        if (next.source1 == source) next.equipe1 = row.equipe;
        if (next.source2 == source) next.equipe2 = row.equipe;
      }
    }
  }
  settleByes(matches);
}

// ───────────────────────────────────────── Schedule ─────────────────────────────────────────

typedef TimeWindow = ({DateTime debut, DateTime fin});

/// Not enough slots for every match: [manquants] matches got no time.
class ScheduleError implements Exception {
  const ScheduleError(this.manquants);
  final int manquants;

  @override
  String toString() => 'ScheduleError: $manquants match(s) sans horaire';
}

/// Greedy schedule: each match (group days first, then rounds) takes the earliest free court slot
/// that leaves both teams [repos] and comes after the matches feeding it. Byes take no slot.
/// Sets [MatchPlan.debut] and [MatchPlan.terrain]; throws [ScheduleError] when slots run out.
void schedule(
  List<MatchPlan> matches, {
  required List<String> terrains,
  required List<TimeWindow> creneaux,
  required Duration dureeMatch,
  Duration repos = Duration.zero,
}) {
  final slots = <({DateTime start, String terrain})>[
    for (final w in creneaux)
      for (var t = w.debut; !t.add(dureeMatch).isAfter(w.fin); t = t.add(dureeMatch))
        for (final terrain in terrains) (start: t, terrain: terrain),
  ]..sort((a, b) {
      final byTime = a.start.compareTo(b.start);
      return byTime != 0 ? byTime : terrains.indexOf(a.terrain).compareTo(terrains.indexOf(b.terrain));
    });
  final used = List.filled(slots.length, false);

  final never = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  DateTime later(DateTime a, DateTime b) => a.isAfter(b) ? a : b;
  final teamFree = <String, DateTime>{};
  final endOf = <String, DateTime>{};
  final groupEnd = <String, DateTime>{};
  var missing = 0;

  DateTime readyFrom(String? source) {
    if (source == null) return never;
    final parts = source.split(':');
    final end = parts[0] == 'poule' ? groupEnd[parts[1]] : endOf[source];
    return end == null ? never : end.add(repos);
  }

  final order = [...matches]..sort((a, b) {
      if (a.phase != b.phase) return a.phase == Phase.poule ? -1 : 1;
      final byTour = a.tour.compareTo(b.tour);
      if (byTour != 0) return byTour;
      final byGroup = (a.poule ?? '').compareTo(b.poule ?? '');
      return byGroup != 0 ? byGroup : a.ordre.compareTo(b.ordre);
    });

  for (final m in order) {
    if (m.exempt) {
      // A bye is « played » when its feeding source is; it adds no rest.
      final ready = readyFrom(m.source1 ?? m.source2);
      endOf[m.key] = ready == never ? never : ready.subtract(repos);
      continue;
    }
    var ready = never;
    for (final id in [m.equipe1, m.equipe2]) {
      if (id != null) ready = later(ready, teamFree[id] ?? never);
    }
    if (m.phase == Phase.elimination) {
      ready = later(ready, later(readyFrom(m.source1), readyFrom(m.source2)));
    }
    final i = [for (var j = 0; j < slots.length; j++) j]
        .firstWhere((j) => !used[j] && !slots[j].start.isBefore(ready), orElse: () => -1);
    if (i < 0) {
      missing++;
      continue;
    }
    used[i] = true;
    final end = slots[i].start.add(dureeMatch);
    m
      ..debut = slots[i].start
      ..terrain = slots[i].terrain;
    if (m.phase == Phase.elimination) endOf[m.key] = end;
    for (final id in [m.equipe1, m.equipe2]) {
      if (id != null) teamFree[id] = end.add(repos);
    }
    if (m.phase == Phase.poule && m.poule != null) {
      groupEnd[m.poule!] = later(groupEnd[m.poule!] ?? never, end);
    }
  }
  if (missing > 0) throw ScheduleError(missing);
}
