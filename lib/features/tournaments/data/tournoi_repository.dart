import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/api/session.dart';
import '../../../core/db/app_database.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../theme/theme.dart';
import '../logic/bracket_logic.dart';

/// A tournament's life (backend/apps/tournois/README.md « Lifecycle »).
enum TournoiStatut { brouillon, inscriptionsOuvertes, inscriptionsFermees, enCours, termine, annule }

enum TournoiFormat { poulesElimination, elimination }

/// A registered team's state for the organiser (ORG-10) and the captain (TRN-06/07).
enum EquipeStatut { enAttente, confirmee, refusee, annulee }

const _statutNames = {
  TournoiStatut.brouillon: 'brouillon',
  TournoiStatut.inscriptionsOuvertes: 'inscriptions_ouvertes',
  TournoiStatut.inscriptionsFermees: 'inscriptions_fermees',
  TournoiStatut.enCours: 'en_cours',
  TournoiStatut.termine: 'termine',
  TournoiStatut.annule: 'annule',
};
const _formatNames = {
  TournoiFormat.poulesElimination: 'poules_elimination',
  TournoiFormat.elimination: 'elimination',
};
const _matchStatusNames = {
  MatchStatus.aJouer: 'a_jouer',
  MatchStatus.enDirect: 'en_direct',
  MatchStatus.termine: 'termine',
};

T _byName<T>(Map<T, String> names, Object? value, T fallback) =>
    names.entries.firstWhere((e) => e.value == value, orElse: () => MapEntry(fallback, '')).key;

/// What the organiser fills in ORG-05 → ORG-08.
@immutable
class TournoiDraft {
  const TournoiDraft({
    required this.nom,
    required this.sport,
    required this.debut,
    required this.fin,
    required this.etablissement,
    required this.lieu,
    required this.fraisEquipe,
    required this.equipesMax,
    this.dotation,
    this.niveauMin,
    this.niveauMax,
    this.format = TournoiFormat.poulesElimination,
    this.nbPoules = 2,
    this.qualifiesParPoule = 2,
    this.joueursParEquipe = 2,
    this.description,
  });

  final String nom;
  final MuSport sport;
  final DateTime debut;
  final DateTime fin;
  final String etablissement;
  final String lieu;
  final num fraisEquipe;
  final int equipesMax;
  final num? dotation;
  final double? niveauMin;
  final double? niveauMax;
  final TournoiFormat format;
  final int nbPoules;
  final int qualifiesParPoule;
  final int joueursParEquipe;
  final String? description;
}

@immutable
class Tournoi {
  const Tournoi({
    required this.id,
    required this.draft,
    required this.statut,
    required this.organisateurId,
    required this.tableauPublie,
  });

  final String id;
  final TournoiDraft draft;
  final TournoiStatut statut;

  /// Null for the story's demo tournaments.
  final String? organisateurId;
  final bool tableauPublie;
}

@immutable
class Equipe {
  const Equipe({
    required this.id,
    required this.tournoiId,
    required this.nom,
    required this.capitaineId,
    required this.codeInvitation,
    required this.paye,
    required this.statut,
    required this.membres,
    this.motif,
  });

  final String id;
  final String tournoiId;
  final String nom;
  final String capitaineId;

  /// The 6-letter code of the invite link (TRN-05).
  final String codeInvitation;

  /// Paid, or a free tournament.
  final bool paye;
  final EquipeStatut statut;

  /// Why the organiser refused it.
  final String? motif;

  /// (joueur id, nom), captain first.
  final List<(String, String)> membres;
}

/// The phone or the player cannot do this now (a full tournament, a team not paid…). The
/// message is French, ready for a toast.
class TournoiRefus implements Exception {
  const TournoiRefus(this.message);
  final String message;

  @override
  String toString() => 'TournoiRefus: $message';
}

/// Tournaments, teams, decisions, matches and announcements on SQFlite; the shared tables reach
/// Supabase through the sync (lib/core/sync/sync_tables.dart). One author per row: the
/// organiser writes the tournament, its decisions and its matches; the captain writes the team;
/// each member row is written by whoever added it.
class TournoiRepository {
  TournoiRepository(this._database, {required this.me, DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final AppDatabase _database;
  /// Who writes the rows (see [currentAuthorId]).
  final String Function() me;
  final DateTime Function() _now;
  final _random = Random.secure();

  Future<Database> get _db => _database.db;

  /// A random UUID v4: shared rows need ids no other phone can make.
  String newId() {
    final b = List<int>.generate(16, (_) => _random.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    final h = [for (final x in b) x.toRadixString(16).padLeft(2, '0')].join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
        '${h.substring(16, 20)}-${h.substring(20)}';
  }

  String _code() {
    const letters = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(6, (_) => letters[_random.nextInt(letters.length)]).join();
  }

  // ─────────────────────────────────────── Tournaments ───────────────────────────────────────

  /// ORG-09 « Publier »: registrations open at once (no draft step kept on the phone).
  Future<String> create(TournoiDraft d, {bool publier = true}) async {
    final id = newId();
    await (await _db).insert('tournois', {
      'id': id,
      ..._draftRow(d),
      'equipes_inscrites': 0,
      'organisateur_id': me(),
      'statut': _statutNames[publier ? TournoiStatut.inscriptionsOuvertes : TournoiStatut.brouillon],
      'tableau_publie': 0,
      'cree_le': _now().toIso8601String(),
    });
    return id;
  }

  Map<String, Object?> _draftRow(TournoiDraft d) => {
        'sport': d.sport.name,
        'nom': d.nom,
        'debut': d.debut.toIso8601String(),
        'fin': d.fin.toIso8601String(),
        'etablissement': d.etablissement,
        'lieu': d.lieu,
        'frais_equipe': d.fraisEquipe,
        'dotation': d.dotation,
        'equipes_total': d.equipesMax,
        'niveau_min': d.niveauMin,
        'niveau_max': d.niveauMax,
        'format': _formatNames[d.format],
        'nb_poules': d.nbPoules,
        'qualifies_par_poule': d.qualifiesParPoule,
        'joueurs_par_equipe': d.joueursParEquipe,
        'description': d.description,
      };

  Tournoi _tournoi(Map<String, Object?> r) => Tournoi(
        id: r['id']! as String,
        organisateurId: r['organisateur_id'] as String?,
        statut: _byName(_statutNames, r['statut'], TournoiStatut.inscriptionsOuvertes),
        tableauPublie: r['tableau_publie'] == 1,
        draft: TournoiDraft(
          nom: r['nom']! as String,
          sport: MuSport.values.byName(r['sport']! as String),
          debut: DateTime.parse(r['debut']! as String),
          fin: DateTime.parse(r['fin']! as String),
          etablissement: r['etablissement']! as String,
          lieu: r['lieu']! as String,
          fraisEquipe: r['frais_equipe']! as num,
          equipesMax: r['equipes_total']! as int,
          dotation: r['dotation'] as num?,
          niveauMin: (r['niveau_min'] as num?)?.toDouble(),
          niveauMax: (r['niveau_max'] as num?)?.toDouble(),
          format: _byName(_formatNames, r['format'], TournoiFormat.poulesElimination),
          nbPoules: (r['nb_poules'] as int?) ?? 2,
          qualifiesParPoule: (r['qualifies_par_poule'] as int?) ?? 2,
          joueursParEquipe: (r['joueurs_par_equipe'] as int?) ?? 2,
          description: r['description'] as String?,
        ),
      );

  Future<Tournoi?> tournoi(String id) async {
    final r = (await (await _db).query('tournois', where: 'id = ?', whereArgs: [id])).firstOrNull;
    return r == null ? null : _tournoi(r);
  }

  /// Every tournament, soonest first ([mine]: the ones I organise, ORG-04).
  Future<List<Tournoi>> tournois({bool mine = false}) async => [
        for (final r in await (await _db).query(
          'tournois',
          where: mine ? 'organisateur_id = ?' : null,
          whereArgs: mine ? [me()] : null,
          orderBy: 'debut',
        ))
          _tournoi(r),
      ];

  Future<void> _setStatut(String id, TournoiStatut s) async {
    await _ownTournoi(id);
    await (await _db).update('tournois', {'statut': _statutNames[s]}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> cloturer(String id) => _setStatut(id, TournoiStatut.inscriptionsFermees);
  Future<void> rouvrir(String id) => _setStatut(id, TournoiStatut.inscriptionsOuvertes);
  Future<void> annuler(String id) => _setStatut(id, TournoiStatut.annule);

  Future<Tournoi> _ownTournoi(String id) async {
    final t = await tournoi(id);
    if (t == null) throw const TournoiRefus('Ce tournoi n’existe plus.');
    if (t.organisateurId != me()) throw const TournoiRefus('Seul l’organisateur peut faire ça.');
    return t;
  }

  // ───────────────────────────────────────── Teams ─────────────────────────────────────────

  /// TRN-04/05 « Inscrire mon équipe »: the captain (me) and the teammates already known.
  Future<Equipe> inscrire(
    String tournoiId, {
    required String nom,
    required String capitaineNom,
    List<(String, String)> coequipiers = const [],
  }) async {
    final t = await tournoi(tournoiId);
    if (t == null) throw const TournoiRefus('Ce tournoi n’existe plus.');
    if (t.statut != TournoiStatut.inscriptionsOuvertes) {
      throw const TournoiRefus('Les inscriptions sont fermées.');
    }
    final teams = await equipes(tournoiId);
    final self = me();
    if (teams.any((e) => e.statut != EquipeStatut.annulee && e.membres.any((m) => m.$1 == self))) {
      throw const TournoiRefus('Tu es déjà dans une équipe de ce tournoi.');
    }
    if (teams.any((e) => e.statut != EquipeStatut.annulee && e.nom.toLowerCase() == nom.trim().toLowerCase())) {
      throw const TournoiRefus('Ce nom d’équipe est déjà pris.');
    }
    final id = newId();
    final now = _now().toIso8601String();
    final db = await _db;
    await db.transaction((txn) async {
      await txn.insert('tournoi_equipes', {
        'id': id,
        'tournoi_id': tournoiId,
        'capitaine_id': self,
        'nom': nom.trim(),
        'code_invitation': _code(),
        'paiement': t.draft.fraisEquipe == 0 ? 'gratuit' : 'non_paye',
        'cree_le': now,
      });
      for (final (joueur, joueurNom) in [(self, capitaineNom), ...coequipiers]) {
        await txn.insert('tournoi_membres', {
          'equipe_id': id,
          'joueur_id': joueur,
          'nom': joueurNom,
          'auteur_id': self,
          'rejoint_le': now,
        });
      }
    });
    return (await equipe(id))!;
  }

  /// The invite link (TRN-05): the player joins with the team's code.
  Future<Equipe> rejoindre(String code, {required String nom}) async {
    final db = await _db;
    final r = (await db.query('tournoi_equipes', where: 'code_invitation = ? AND annulee = 0', whereArgs: [code.trim().toUpperCase()]))
        .firstOrNull;
    if (r == null) throw const TournoiRefus('Ce code ne correspond à aucune équipe.');
    final team = (await equipe(r['id']! as String))!;
    final t = (await tournoi(team.tournoiId))!;
    if (team.membres.length >= t.draft.joueursParEquipe) throw const TournoiRefus('L’équipe est complète.');
    final self = me();
    if (team.membres.any((m) => m.$1 == self)) return team;
    await db.insert('tournoi_membres', {
      'equipe_id': team.id,
      'joueur_id': self,
      'nom': nom,
      'auteur_id': self,
      'rejoint_le': _now().toIso8601String(),
    });
    return (await equipe(team.id))!;
  }

  /// The team I am in for [tournoiId] (not withdrawn), or null.
  Future<Equipe?> monEquipe(String tournoiId) async {
    final self = me();
    for (final e in await equipes(tournoiId)) {
      if (e.statut != EquipeStatut.annulee && e.membres.any((m) => m.$1 == self)) return e;
    }
    return null;
  }

  /// A teammate added by name, who has no account yet: a placeholder id (they can also join
  /// with the invite code).
  String invite() => 'invite-${newId()}';

  /// The captain paid the fee (after PAY-01 accepted it).
  Future<void> marquerPaye(String equipeId) async {
    final e = await equipe(equipeId);
    if (e == null || e.capitaineId != me()) throw const TournoiRefus('Seul le capitaine peut payer.');
    await (await _db).update('tournoi_equipes', {'paiement': 'paye'}, where: 'id = ?', whereArgs: [equipeId]);
  }

  /// The captain withdraws the team.
  Future<void> annulerEquipe(String equipeId) async {
    final e = await equipe(equipeId);
    if (e == null || e.capitaineId != me()) throw const TournoiRefus('Seul le capitaine peut annuler.');
    await (await _db).update('tournoi_equipes', {'annulee': 1}, where: 'id = ?', whereArgs: [equipeId]);
  }

  Future<Equipe?> equipe(String id) async {
    final db = await _db;
    final r = (await db.query('tournoi_equipes', where: 'id = ?', whereArgs: [id])).firstOrNull;
    return r == null ? null : _equipe(db, r);
  }

  /// A tournament's teams, in registration order (their seed).
  Future<List<Equipe>> equipes(String tournoiId) async {
    final db = await _db;
    return [
      for (final r in await db.query('tournoi_equipes', where: 'tournoi_id = ?', whereArgs: [tournoiId], orderBy: 'cree_le'))
        await _equipe(db, r),
    ];
  }

  Future<Equipe> _equipe(DatabaseExecutor db, Map<String, Object?> r) async {
    final id = r['id']! as String;
    final captain = r['capitaine_id']! as String;
    final decision = (await db.query('tournoi_decisions', where: 'equipe_id = ?', whereArgs: [id])).firstOrNull;
    final members = [
      for (final m in await db.query('tournoi_membres', where: 'equipe_id = ?', whereArgs: [id], orderBy: 'rejoint_le'))
        (m['joueur_id']! as String, m['nom']! as String),
    ]..sort((a, b) => (a.$1 == captain ? 0 : 1).compareTo(b.$1 == captain ? 0 : 1));
    return Equipe(
      id: id,
      tournoiId: r['tournoi_id']! as String,
      nom: r['nom']! as String,
      capitaineId: captain,
      codeInvitation: r['code_invitation']! as String,
      paye: r['paiement'] != 'non_paye',
      membres: members,
      motif: decision?['motif'] as String?,
      statut: r['annulee'] == 1
          ? EquipeStatut.annulee
          : switch (decision?['statut']) {
              'confirmee' => EquipeStatut.confirmee,
              'refusee' => EquipeStatut.refusee,
              _ => EquipeStatut.enAttente,
            },
    );
  }

  // ─────────────────────────────────────── Decisions ───────────────────────────────────────

  /// ORG-10 « Valider »: paid (or free), complete, and a place left.
  Future<void> valider(String equipeId) async {
    final e = await equipe(equipeId);
    if (e == null) throw const TournoiRefus('Cette équipe n’existe plus.');
    final t = await _ownTournoi(e.tournoiId);
    if (!e.paye) throw const TournoiRefus('L’équipe n’a pas encore payé.');
    if (e.membres.length < t.draft.joueursParEquipe) {
      throw TournoiRefus('Il faut ${t.draft.joueursParEquipe} joueurs dans l’équipe.');
    }
    final confirmed = (await equipes(t.id)).where((x) => x.statut == EquipeStatut.confirmee).length;
    if (confirmed >= t.draft.equipesMax) throw const TournoiRefus('Le tournoi est complet.');
    await _decide(equipeId, 'confirmee');
  }

  /// ORG-10 « Refuser » with a reason (the team is refunded by the paiement module).
  Future<void> refuser(String equipeId, {String? motif}) async {
    final e = await equipe(equipeId);
    if (e == null) throw const TournoiRefus('Cette équipe n’existe plus.');
    await _ownTournoi(e.tournoiId);
    await _decide(equipeId, 'refusee', motif: motif);
  }

  Future<void> _decide(String equipeId, String statut, {String? motif}) async {
    await (await _db).insert(
      'tournoi_decisions',
      {'equipe_id': equipeId, 'organisateur_id': me(), 'statut': statut, 'motif': motif, 'le': _now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ───────────────────────────────────────── Bracket ─────────────────────────────────────────

  /// ORG-11 « Générer »: draws the confirmed teams (registration order = seed), schedules them
  /// and replaces the previous draft. Throws [ScheduleError] when the slots are too few,
  /// [TournoiRefus] with fewer than 2 teams or once a match was played.
  Future<List<MatchPlan>> generer(
    String tournoiId, {
    required List<String> terrains,
    required List<TimeWindow> creneaux,
    Duration dureeMatch = const Duration(minutes: 45),
    Duration repos = const Duration(minutes: 15),
  }) async {
    final t = await _ownTournoi(tournoiId);
    final teams = [for (final e in await equipes(tournoiId)) if (e.statut == EquipeStatut.confirmee) e.id];
    if (teams.length < 2) throw const TournoiRefus('Il faut au moins 2 équipes validées.');
    final existing = await matchs(tournoiId);
    if (existing.any((m) => m.statut != MatchStatus.aJouer && !m.exempt)) {
      throw const TournoiRefus('Des matchs ont déjà été joués : le tableau ne peut plus changer.');
    }
    final plan = t.draft.format == TournoiFormat.elimination || teams.length < t.draft.nbPoules * 2
        ? drawSingleElimination(teams)
        : drawGroupsAndKnockout(teams, t.draft.nbPoules, t.draft.qualifiesParPoule);
    schedule(plan, terrains: terrains, creneaux: creneaux, dureeMatch: dureeMatch, repos: repos);
    await _saveMatchs(tournoiId, plan, replace: true);
    return plan;
  }

  /// Shows the bracket to the players (TRN-08) and closes registrations.
  Future<void> publierTableau(String tournoiId) async {
    await _ownTournoi(tournoiId);
    await (await _db).update(
      'tournois',
      {'tableau_publie': 1, 'statut': _statutNames[TournoiStatut.inscriptionsFermees]},
      where: 'id = ?',
      whereArgs: [tournoiId],
    );
  }

  static String matchId(String tournoiId, MatchPlan m) =>
      '$tournoiId:${m.phase.name}:${m.poule ?? '-'}:${m.tour}:${m.ordre}';

  Future<void> _saveMatchs(String tournoiId, List<MatchPlan> plan, {bool replace = false}) async {
    final self = me();
    await (await _db).transaction((txn) async {
      if (replace) await txn.delete('tournoi_matchs', where: 'tournoi_id = ?', whereArgs: [tournoiId]);
      for (final m in plan) {
        await txn.insert(
          'tournoi_matchs',
          {
            'id': matchId(tournoiId, m),
            'tournoi_id': tournoiId,
            'organisateur_id': self,
            'phase': m.phase.name,
            'poule': m.poule,
            'tour': m.tour,
            'ordre': m.ordre,
            'equipe1': m.equipe1,
            'equipe2': m.equipe2,
            'source1': m.source1,
            'source2': m.source2,
            'statut': _matchStatusNames[m.statut],
            'exempt': m.exempt ? 1 : 0,
            'vainqueur': m.vainqueur,
            'score1': m.score1,
            'score2': m.score2,
            'debut': m.debut?.toIso8601String(),
            'terrain': m.terrain,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// The plan, group days first then rounds.
  Future<List<MatchPlan>> matchs(String tournoiId) async => [
        for (final r in await (await _db).query(
          'tournoi_matchs',
          where: 'tournoi_id = ?',
          whereArgs: [tournoiId],
          orderBy: "phase = 'elimination', tour, poule, ordre",
        ))
          MatchPlan(
            phase: r['phase'] == 'poule' ? Phase.poule : Phase.elimination,
            poule: r['poule'] as String?,
            tour: r['tour']! as int,
            ordre: r['ordre']! as int,
            equipe1: r['equipe1'] as String?,
            equipe2: r['equipe2'] as String?,
            source1: r['source1'] as String?,
            source2: r['source2'] as String?,
            statut: _byName(_matchStatusNames, r['statut'], MatchStatus.aJouer),
            exempt: r['exempt'] == 1,
            vainqueur: r['vainqueur'] as String?,
            score1: r['score1'] as int?,
            score2: r['score2'] as int?,
            debut: r['debut'] == null ? null : DateTime.parse(r['debut']! as String),
            terrain: r['terrain'] as String?,
          ),
      ];

  /// The groups as drawn (letter → teams in seed order), read back from the group matches.
  Future<Map<String, List<String>>> poules(String tournoiId) async {
    final teams = [for (final e in await equipes(tournoiId)) e.id];
    final groups = <String, Set<String>>{};
    for (final m in await matchs(tournoiId)) {
      if (m.phase != Phase.poule || m.poule == null) continue;
      groups.putIfAbsent(m.poule!, () => {}).addAll([?m.equipe1, ?m.equipe2]);
    }
    return {
      for (final MapEntry(:key, :value) in groups.entries)
        key: [for (final t in teams) if (value.contains(t)) t],
    };
  }

  /// ORG-12/13: the match starts (« en direct ») or gets its live score.
  Future<void> scoreEnDirect(String tournoiId, MatchPlan m, int score1, int score2) async {
    await _ownTournoi(tournoiId);
    m
      ..statut = MatchStatus.enDirect
      ..score1 = score1
      ..score2 = score2;
    await _saveMatchs(tournoiId, [m]);
    final t = (await tournoi(tournoiId))!;
    if (t.statut != TournoiStatut.enCours) await _setStatut(tournoiId, TournoiStatut.enCours);
  }

  /// ORG-13 « Confirmer le score final »: the winner moves on, the group qualifiers are placed;
  /// the final ends the tournament.
  Future<void> scoreFinal(String tournoiId, MatchPlan m, int score1, int score2, {String? vainqueur}) async {
    final t = await _ownTournoi(tournoiId);
    final plan = await matchs(tournoiId);
    final target = plan.firstWhere((x) => matchId(tournoiId, x) == matchId(tournoiId, m));
    try {
      recordResult(
        plan,
        target,
        score1: score1,
        score2: score2,
        vainqueur: vainqueur,
        groups: await poules(tournoiId),
        qualifiesParPoule: t.draft.qualifiesParPoule,
      );
    } on ArgumentError {
      throw const TournoiRefus('Match nul en phase finale : choisis le vainqueur.');
    }
    await _saveMatchs(tournoiId, plan);
    final finale = plan.where((x) => x.phase == Phase.elimination).fold<MatchPlan?>(
          null,
          (best, x) => best == null || x.tour > best.tour ? x : best,
        );
    await _setStatut(
      tournoiId,
      finale?.statut == MatchStatus.termine ? TournoiStatut.termine : TournoiStatut.enCours,
    );
  }

  // ─────────────────────────────────────── Announcements ───────────────────────────────────────

  /// ORG-14: a message to every team of the tournament.
  Future<void> annoncer(String tournoiId, String message) async {
    await _ownTournoi(tournoiId);
    await (await _db).insert('tournoi_annonces', {
      'id': newId(),
      'tournoi_id': tournoiId,
      'organisateur_id': me(),
      'message': message.trim(),
      'le': _now().toIso8601String(),
    });
  }

  /// Newest first: (message, date).
  Future<List<(String, DateTime)>> annonces(String tournoiId) async => [
        for (final r in await (await _db).query('tournoi_annonces', where: 'tournoi_id = ?', whereArgs: [tournoiId], orderBy: 'le DESC'))
          (r['message']! as String, DateTime.parse(r['le']! as String)),
      ];
}

/// Who writes the rows: the signed-in Supabase user, or a local id while there is none (the
/// row then stays on this phone, supabase/README.md « Shared tables »).
String currentAuthorId(Ref ref) => SupabaseConfig.userId ?? 'local-${ref.read(sessionProvider) ?? 0}';

final tournoiRepositoryProvider = Provider<TournoiRepository>(
  (ref) => TournoiRepository(ref.watch(appDatabaseProvider), me: () => currentAuthorId(ref)),
);
