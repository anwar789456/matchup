/**
 * Pure tournament logic (no database): draws, round names, group standings and the schedule.
 * The services call these functions; keeping them pure makes them easy to test.
 *
 * Wiring between matches uses "sources" stored on each knockout slot:
 *   `match:<tour>:<ordre>`  winner of that knockout match
 *   `poule:<A>:<rang>`      team finishing <rang> in group <A>
 *   null                    a bye (no opponent): the other team goes through
 */

export type Phase = 'poule' | 'elimination';
export type StatutMatch = 'a_jouer' | 'en_direct' | 'termine';

export interface MatchPlan {
  phase: Phase;
  poule: string | null;
  /** Poule: journée (1, 2, 3…). Elimination: round index (0 = first round). */
  tour: number;
  ordre: number;
  label: string;
  equipe1Id: number | null;
  equipe2Id: number | null;
  source1: string | null;
  source2: string | null;
  statut: StatutMatch;
  exempt: boolean;
  vainqueurId: number | null;
  debut: Date | null;
  terrain: string | null;
}

export interface TeamSeed {
  id: number;
  nom: string;
}

/** Smallest power of two ≥ n (at least 2). */
export function bracketSize(n: number): number {
  let size = 2;
  while (size < n) size *= 2;
  return size;
}

/**
 * Standard seeding positions: for 8 → [1, 8, 4, 5, 2, 7, 3, 6]. Seed 1 and 2 can only meet in
 * the final, and the byes go to the best seeds.
 */
export function seedPositions(size: number): number[] {
  let order = [1, 2];
  while (order.length < size) {
    const sum = order.length * 2 + 1;
    order = order.flatMap((s) => [s, sum - s]);
  }
  return order;
}

/** « Finale », « Demi-finales », « Quarts de finale »… from the number of matches in the round. */
export function roundNames(matchesInRound: number): { name: string; short: string; prefix: string } {
  switch (matchesInRound) {
    case 1:
      return { name: 'Finale', short: 'Finale', prefix: 'Finale' };
    case 2:
      return { name: 'Demi-finales', short: 'Demies', prefix: 'Demie' };
    case 4:
      return { name: 'Quarts de finale', short: 'Quarts', prefix: 'QF' };
    case 8:
      return { name: 'Huitièmes de finale', short: 'Huitièmes', prefix: '8e' };
    case 16:
      return { name: 'Seizièmes de finale', short: 'Seizièmes', prefix: '16e' };
    default:
      return { name: `Tour de ${matchesInRound * 2}`, short: `${matchesInRound * 2}`, prefix: 'M' };
  }
}

export function matchLabel(matchesInRound: number, ordre: number): string {
  const { prefix } = roundNames(matchesInRound);
  return matchesInRound === 1 ? prefix : `${prefix} ${ordre + 1}`;
}

/** « 1er Poule A », « Vainqueur QF 4 », or null for a bye. */
export function placeholderFor(source: string | null, roundSizes: number[]): string | null {
  if (!source) return null;
  const [kind, a, b] = source.split(':');
  if (kind === 'poule') return `${Number(b) === 1 ? '1er' : `${b}e`} Poule ${a}`;
  const tour = Number(a);
  return `Vainqueur ${matchLabel(roundSizes[tour], Number(b))}`;
}

function blankMatch(partial: Partial<MatchPlan>): MatchPlan {
  return {
    phase: 'elimination',
    poule: null,
    tour: 0,
    ordre: 0,
    label: '',
    equipe1Id: null,
    equipe2Id: null,
    source1: null,
    source2: null,
    statut: 'a_jouer',
    exempt: false,
    vainqueurId: null,
    debut: null,
    terrain: null,
    ...partial,
  };
}

/**
 * Knockout tree from a list of slots ordered by seed (a slot is a team id, a `poule:…` source,
 * or both). Byes in the first round are settled at once when the team is already known.
 */
function knockout(slots: { equipeId: number | null; source: string | null }[]): MatchPlan[] {
  const size = bracketSize(slots.length);
  const positions = seedPositions(size);
  const matches: MatchPlan[] = [];
  const rounds = Math.log2(size);

  for (let tour = 0; tour < rounds; tour++) {
    const count = size / 2 ** (tour + 1);
    for (let ordre = 0; ordre < count; ordre++) {
      const m = blankMatch({ tour, ordre, label: matchLabel(count, ordre) });
      if (tour === 0) {
        const a = slots[positions[ordre * 2] - 1];
        const b = slots[positions[ordre * 2 + 1] - 1];
        m.equipe1Id = a?.equipeId ?? null;
        m.source1 = a?.source ?? null;
        m.equipe2Id = b?.equipeId ?? null;
        m.source2 = b?.source ?? null;
        if (!a || !b) m.exempt = true;
      } else {
        m.source1 = `match:${tour - 1}:${ordre * 2}`;
        m.source2 = `match:${tour - 1}:${ordre * 2 + 1}`;
      }
      matches.push(m);
    }
  }
  settleByes(matches);
  return matches;
}

/** A bye whose team is known is won at once, and the team moves to the next round. */
export function settleByes(matches: MatchPlan[]): void {
  for (const m of matches) {
    if (!m.exempt || m.statut === 'termine') continue;
    const team = m.equipe1Id ?? m.equipe2Id;
    if (team == null) continue;
    m.statut = 'termine';
    m.vainqueurId = team;
    advance(matches, m, team);
  }
}

/** Puts `winner` in the slot of the next match fed by `from`. Returns the match it went into. */
export function advance(matches: MatchPlan[], from: MatchPlan, winner: number | null): MatchPlan | null {
  const key = `match:${from.tour}:${from.ordre}`;
  for (const next of matches) {
    if (next.phase !== 'elimination') continue;
    if (next.source1 === key) next.equipe1Id = winner;
    else if (next.source2 === key) next.equipe2Id = winner;
    else continue;
    return next;
  }
  return null;
}

/** Single elimination: teams are already ordered by seed (best first). */
export function drawSingleElimination(teams: TeamSeed[]): MatchPlan[] {
  return knockout(teams.map((t) => ({ equipeId: t.id, source: null })));
}

export const GROUP_LETTERS = 'ABCDEFGHIJKLMNOP';

/** Snake draw by seed: A B C D D C B A A B… so every group gets a fair mix. */
export function splitIntoGroups(teams: TeamSeed[], nbPoules: number): TeamSeed[][] {
  const groups: TeamSeed[][] = Array.from({ length: nbPoules }, () => []);
  teams.forEach((team, i) => {
    const lap = Math.floor(i / nbPoules);
    const pos = i % nbPoules;
    groups[lap % 2 === 0 ? pos : nbPoules - 1 - pos].push(team);
  });
  return groups;
}

/** Round robin (circle method): returns journées, each a list of [home, away]. */
export function roundRobin<T>(teams: T[]): [T, T][][] {
  const list: (T | null)[] = [...teams];
  if (list.length % 2 === 1) list.push(null);
  const n = list.length;
  const days: [T, T][][] = [];
  for (let day = 0; day < n - 1; day++) {
    const pairs: [T, T][] = [];
    for (let i = 0; i < n / 2; i++) {
      const a = list[i];
      const b = list[n - 1 - i];
      if (a != null && b != null) pairs.push(day % 2 === 0 ? [a, b] : [b, a]);
    }
    days.push(pairs);
    list.splice(1, 0, list.pop() as T | null);
  }
  return days;
}

/**
 * Groups then knockout. Qualifiers are seeded all the group winners first, then the runners-up
 * in group order, which gives the classic crossing A1–B2, B1–A2.
 */
export function drawGroupsAndKnockout(
  teams: TeamSeed[],
  nbPoules: number,
  qualifiesParPoule: number,
): MatchPlan[] {
  const groups = splitIntoGroups(teams, nbPoules);
  const matches: MatchPlan[] = [];

  groups.forEach((group, g) => {
    const letter = GROUP_LETTERS[g];
    let ordre = 0;
    roundRobin(group).forEach((pairs, day) => {
      for (const [home, away] of pairs) {
        matches.push(
          blankMatch({
            phase: 'poule',
            poule: letter,
            tour: day + 1,
            ordre: ordre++,
            label: `Poule ${letter} · J${day + 1}`,
            equipe1Id: home.id,
            equipe2Id: away.id,
          }),
        );
      }
    });
  });

  const slots: { equipeId: null; source: string }[] = [];
  for (let rang = 1; rang <= qualifiesParPoule; rang++) {
    for (let g = 0; g < groups.length; g++) {
      if (groups[g].length >= rang) slots.push({ equipeId: null, source: `poule:${GROUP_LETTERS[g]}:${rang}` });
    }
  }
  return [...matches, ...knockout(slots)];
}

// ---------------------------------------------------------------------------------------------
// Standings
// ---------------------------------------------------------------------------------------------

export interface ResultLike {
  phase: string;
  poule: string | null;
  equipe1Id: number | null;
  equipe2Id: number | null;
  score1: number | null;
  score2: number | null;
  statut: string;
  vainqueurId?: number | null;
}

export interface StandingRow {
  equipeId: number;
  rang: number;
  joues: number;
  victoires: number;
  nuls: number;
  defaites: number;
  pour: number;
  contre: number;
  diff: number;
  points: number;
  qualifie: boolean;
}

/** 3 points a win, 1 a draw. Ties: points, difference, scored, then seed order. */
export function standings(teamIds: number[], matches: ResultLike[], qualifies = 0): StandingRow[] {
  const rows = new Map<number, StandingRow>(
    teamIds.map((id) => [
      id,
      { equipeId: id, rang: 0, joues: 0, victoires: 0, nuls: 0, defaites: 0, pour: 0, contre: 0, diff: 0, points: 0, qualifie: false },
    ]),
  );
  for (const m of matches) {
    if (m.statut !== 'termine' || m.equipe1Id == null || m.equipe2Id == null) continue;
    if (m.score1 == null || m.score2 == null) continue;
    const a = rows.get(m.equipe1Id);
    const b = rows.get(m.equipe2Id);
    if (!a || !b) continue;
    a.joues++;
    b.joues++;
    a.pour += m.score1;
    a.contre += m.score2;
    b.pour += m.score2;
    b.contre += m.score1;
    const winner = m.score1 > m.score2 ? m.equipe1Id : m.score2 > m.score1 ? m.equipe2Id : (m.vainqueurId ?? null);
    if (winner === m.equipe1Id) {
      a.victoires++;
      a.points += 3;
      b.defaites++;
    } else if (winner === m.equipe2Id) {
      b.victoires++;
      b.points += 3;
      a.defaites++;
    } else {
      a.nuls++;
      b.nuls++;
      a.points++;
      b.points++;
    }
  }
  const seed = new Map(teamIds.map((id, i) => [id, i]));
  const sorted = [...rows.values()]
    .map((r) => ({ ...r, diff: r.pour - r.contre }))
    .sort(
      (x, y) =>
        y.points - x.points ||
        y.diff - x.diff ||
        y.pour - x.pour ||
        (seed.get(x.equipeId) ?? 0) - (seed.get(y.equipeId) ?? 0),
    );
  sorted.forEach((r, i) => {
    r.rang = i + 1;
    r.qualifie = i < qualifies;
  });
  return sorted;
}

// ---------------------------------------------------------------------------------------------
// Schedule
// ---------------------------------------------------------------------------------------------

export interface Window {
  debut: Date;
  fin: Date;
}

export interface ScheduleConstraints {
  terrains: string[];
  creneaux: Window[];
  dureeMatchMinutes: number;
  reposMinutes: number;
}

export class ScheduleError extends Error {
  constructor(
    message: string,
    readonly manquants: number,
  ) {
    super(message);
  }
}

const MIN = 60_000;

/**
 * Greedy schedule: each match (group days first, then rounds) takes the earliest free court slot
 * that leaves both teams their rest time and comes after the matches feeding it. Byes take no slot.
 * Mutates `debut` and `terrain` on the matches.
 */
export function schedule(matches: MatchPlan[], c: ScheduleConstraints): void {
  const dur = c.dureeMatchMinutes * MIN;
  const rest = c.reposMinutes * MIN;

  // Free slots: every court, every `dur` within each window.
  const slots: { start: number; terrain: string; used: boolean }[] = [];
  for (const w of c.creneaux) {
    for (let t = w.debut.getTime(); t + dur <= w.fin.getTime(); t += dur) {
      for (const terrain of c.terrains) slots.push({ start: t, terrain, used: false });
    }
  }
  slots.sort((a, b) => a.start - b.start || c.terrains.indexOf(a.terrain) - c.terrains.indexOf(b.terrain));

  const teamFree = new Map<number, number>();
  const endOf = new Map<string, number>();
  const groupEnd = new Map<string, number>();
  let missing = 0;

  const order = [...matches].sort((a, b) => {
    if (a.phase !== b.phase) return a.phase === 'poule' ? -1 : 1;
    return a.tour - b.tour || (a.poule ?? '').localeCompare(b.poule ?? '') || a.ordre - b.ordre;
  });

  const readyFromSource = (source: string | null): number => {
    if (!source) return -Infinity;
    const [kind, a] = source.split(':');
    if (kind === 'poule') return (groupEnd.get(a) ?? -Infinity) + rest;
    return (endOf.get(source) ?? -Infinity) + rest;
  };

  for (const m of order) {
    const key = `match:${m.tour}:${m.ordre}`;
    if (m.exempt) {
      // A bye is "played" when its feeding source is; it adds no rest.
      endOf.set(key, readyFromSource(m.source1 ?? m.source2) - rest);
      continue;
    }
    let ready = -Infinity;
    for (const id of [m.equipe1Id, m.equipe2Id]) if (id != null) ready = Math.max(ready, teamFree.get(id) ?? -Infinity);
    if (m.phase === 'elimination') ready = Math.max(ready, readyFromSource(m.source1), readyFromSource(m.source2));

    const slot = slots.find((s) => !s.used && s.start >= ready);
    if (!slot) {
      missing++;
      continue;
    }
    slot.used = true;
    m.debut = new Date(slot.start);
    m.terrain = slot.terrain;
    const end = slot.start + dur;
    if (m.phase === 'elimination') endOf.set(key, end);
    for (const id of [m.equipe1Id, m.equipe2Id]) if (id != null) teamFree.set(id, end + rest);
    if (m.phase === 'poule' && m.poule) groupEnd.set(m.poule, Math.max(groupEnd.get(m.poule) ?? -Infinity, end));
  }

  if (missing > 0) {
    throw new ScheduleError(
      `Pas assez de créneaux : ${missing} match${missing > 1 ? 's' : ''} sans horaire. Ajoute un terrain ou une plage horaire.`,
      missing,
    );
  }
}
