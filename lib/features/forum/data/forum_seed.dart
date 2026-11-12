import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../core/clock.dart';
import 'forum_ai.dart';

/// The story's forum (design/screens/STORY-DATA.md « Forum », FRM-01…05). Ids are text, like
/// the rows the app creates (UUIDs), and every vote, reaction and report is its own row: counts
/// are computed from them. These demo rows stay on each phone; only what the member writes is
/// synced. Yassine ([me]) is the member using the app until Supabase gives a real user id.
abstract final class ForumSeed {
  static const me = 'demo-yassine';

  /// The story's people: number used in the data below → (id, name, handle, level, sport).
  static const members = <int, (String, String, String?, double?, String?)>{
    1: (me, 'Yassine B.', 'yassine.b', 3.0, 'football'),
    2: ('demo-ines', 'Ines M.', 'ines.m', 4.0, 'padel'),
    3: ('demo-skander', 'Skander T.', 'skander.t', 4.0, 'football'),
    4: ('demo-mariem', 'Mariem K.', 'mariem.k', 4.0, 'padel'),
    5: ('demo-sami', 'Sami C.', 'sami.c', 4.5, 'padel'),
    6: ('demo-hamza', 'Hamza R.', 'hamza.r', 3.5, 'football'),
    7: ('demo-aziz', 'Aziz H.', 'aziz.h', 4.5, 'football'),
    8: ('demo-omar', 'Omar D.', 'omar.d', 3.5, 'football'),
    9: ('demo-bonsplans', 'Bons Plans Sport TN', 'bonsplans.tn', null, null),
    10: ('demo-leila', 'Leila M.', 'leila.m', null, null),
    11: ('demo-promo', 'promo_crampons', 'promo_crampons', null, null),
    12: ('demo-bilel', 'coach.bilel', 'coach.bilel', null, 'padel'),
    13: ('demo-karim', 'Karim J.', 'karim.j', 5.0, 'padel'),
    14: ('demo-rami', 'Rami S.', 'rami.s', 3.5, 'padel'),
    15: ('demo-nour', 'Nour A.', 'nour.a', 3.0, 'padel'),
    16: ('demo-salma', 'Salma G.', 'salma.g', 3.0, 'football'),
    17: ('demo-lina', 'Lina F.', 'lina.f', 3.5, 'padel'),
    18: ('demo-mehdi', 'Mehdi K.', 'mehdi.k', 4.5, 'basketball'),
  };

  /// The id of story member [n].
  static String id(int n) => members[n]!.$1;

  /// Ids of the demo rows (stable, so tests and screens can find them).
  static String postId(String key) => 'demo-sujet-$key';
  static String replyId(String key) => 'demo-message-$key';

  static DateTime _ago(num hours) => storyNow.subtract(Duration(minutes: (hours * 60).round()));

  /// Writes the whole story in one batch (every id is known in advance), so creating a database
  /// stays fast.
  static Future<void> insert(DatabaseExecutor db) async {
    final batch = db.batch();
    final now = storyNow.toIso8601String();
    for (final (memberId, name, handle, level, sport) in members.values) {
      batch.insert('forum_membres', {
        'id': memberId,
        'auteur_id': memberId,
        'nom': name,
        'pseudo': handle,
        'niveau': level,
        'sport': sport,
        'maj_le': now,
      });
    }

    for (final p in _posts) {
      final created = _ago(p.hoursAgo).toIso8601String();
      final analysis = ForumAi.analyze('${p.title}\n${p.body}');
      final id = postId(p.key);
      batch.insert('forum_sujets', {
        'id': id,
        'auteur_id': ForumSeed.id(p.author),
        'titre': p.title,
        'contenu': p.body,
        'categorie': p.category,
        'sport': p.sport,
        'tags': jsonEncode(p.tags),
        'mentions': jsonEncode(ForumAi.mentions(p.body)),
        'epingle': p.pinned ? 1 : 0,
        // The spam post was hidden by the moderation (its 5 reports), not by a phone.
        'statut': p.hidden ? 'masque' : 'publie',
        'meilleure_reponse_id': p.key == 'crampons' ? replyId('tf') : null,
        'score_ia': analysis.score,
        'motif_ia': analysis.score >= 0.15 ? analysis.reason : null,
        'cree_le': created,
      });
      _crowd(batch, 'sujet', id, p.votes, p.useful, p.thanks, created);
      batch.insert('forum_suivis', {'utilisateur_id': ForumSeed.id(p.author), 'type': 'sujet', 'cible_id': id});
    }

    final authors = <String, int>{};
    final parents = <String, String?>{};
    for (final r in _replies) {
      final created = _ago(r.hoursAgo).toIso8601String();
      final analysis = ForumAi.analyze(r.body);
      final parent = r.parent;
      final id = replyId(r.key);
      authors[r.key] = r.author;
      parents[r.key] = parent == null ? null : (parents[parent] ?? replyId(parent));
      batch.insert('forum_messages', {
        'id': id,
        'sujet_id': postId(r.post),
        'parent_id': parents[r.key],
        'auteur_id': ForumSeed.id(r.author),
        'en_reponse_a_id': parent == null ? null : ForumSeed.id(authors[parent]!),
        'contenu': r.body,
        'mentions': jsonEncode(ForumAi.mentions(r.body)),
        // Yassine published it despite the FRM-03 warning: his own row, masked until reviewed.
        'statut': r.hidden ? 'masque' : 'publie',
        'publie_malgre_alerte': r.hidden ? 1 : 0,
        'score_ia': analysis.score,
        'motif_ia': analysis.score >= 0.15 ? analysis.reason : null,
        'cree_le': created,
      });
      _crowd(batch, 'message', id, r.votes, r.useful, 0, created);
    }

    // Reports (ADM-09): one row per reporter.
    for (final (target, key, by, reason) in _reports) {
      for (final (i, who) in by.indexed) {
        batch.insert('forum_signalements', {
          'id': 'demo-signalement-$key-$who',
          'auteur_id': ForumSeed.id(who),
          'cible': target,
          'cible_id': target == 'sujet' ? postId(key) : replyId(key),
          'motif': reason,
          'cree_le': _ago(10 - i).toIso8601String(),
        });
      }
    }

    // Yassine voted up Ines's bandeja (FRM-01) and Skander's post with « Utile » (FRM-04),
    // saved the Masters post, and last opened the forum yesterday at 12h00 (« Nouveaux depuis
    // ta dernière visite »).
    batch.insert('forum_votes', {
      'id': 'demo-vote-me-bandeja',
      'auteur_id': me,
      'cible': 'sujet',
      'cible_id': postId('bandeja'),
      'valeur': 1,
      'cree_le': now,
    });
    batch.insert('forum_votes', {
      'id': 'demo-vote-me-crampons',
      'auteur_id': me,
      'cible': 'sujet',
      'cible_id': postId('crampons'),
      'valeur': 1,
      'cree_le': now,
    });
    batch.insert('forum_reactions', {
      'id': 'demo-utile-me-crampons',
      'auteur_id': me,
      'cible': 'sujet',
      'cible_id': postId('crampons'),
      'type': 'utile',
      'cree_le': now,
    });
    batch.insert('forum_favoris', {'utilisateur_id': me, 'sujet_id': postId('masters'), 'cree_le': now});
    batch.insert('forum_visites', {'utilisateur_id': me, 'derniere_visite': _ago(30).toIso8601String()});
    await batch.commit(noResult: true);
  }

  /// Votes and reactions from anonymous demo voters, one row each.
  static void _crowd(Batch batch, String target, String id, int votes, int useful, int thanks, String at) {
    for (var i = 0; i < votes.abs(); i++) {
      batch.insert('forum_votes', {
        'id': '$id-vote-$i',
        'auteur_id': 'demo-foule-$i',
        'cible': target,
        'cible_id': id,
        'valeur': votes.sign,
        'cree_le': at,
      });
    }
    for (var i = 0; i < useful; i++) {
      batch.insert('forum_reactions', {
        'id': '$id-utile-$i',
        'auteur_id': 'demo-foule-$i',
        'cible': target,
        'cible_id': id,
        'type': 'utile',
        'cree_le': at,
      });
    }
    for (var i = 0; i < thanks; i++) {
      batch.insert('forum_reactions', {
        'id': '$id-merci-$i',
        'auteur_id': 'demo-foule-$i',
        'cible': target,
        'cible_id': id,
        'type': 'merci',
        'cree_le': at,
      });
    }
  }

  // ── The story ───────────────────────────────────────────────────────────────────────────

  static const _posts = <_Post>[
    _Post(
      key: 'masters',
      author: 5,
      title: 'Padel Masters Lac 2 : toutes les infos et vos questions',
      body:
          'Sam. 24 → lun. 26 oct. au Smash Padel Club. 16 équipes, 120 DT par équipe, dotation 1 500 DT. '
          'Plus que 4 places, inscriptions jusqu’au mer. 21 oct.\n\n'
          '- Niveau 3,5 à 5,0\n- Poules le week-end, phase finale le lundi dès 18h00\n- Dotation 800 / 450 / 250 DT\n\n'
          'Posez vos questions ici, je réponds à tout le monde.',
      category: 'tournois',
      sport: 'padel',
      tags: ['tournoi', 'lac2'],
      hoursAgo: 72,
      votes: 41,
      useful: 15,
      pinned: true,
    ),
    _Post(
      key: 'bandeja',
      author: 2,
      title: 'Bandeja : je n’arrive pas à la placer croisée',
      body:
          'Elle part toujours au centre et finit dans la grille. @yassine.b tu bosses le programme de Karim J., '
          'tu frappes plus devant toi ?\n\nJe joue à droite, niveau 4,0. J’ai essayé d’ouvrir les épaules plus tôt, sans grand changement.',
      category: 'conseils_technique',
      sport: 'padel',
      tags: ['bandeja', 'technique'],
      hoursAgo: 2,
      votes: 15,
      useful: 4,
    ),
    _Post(
      key: 'smash',
      author: 4,
      title: 'Avis Smash Padel Club après rénovation',
      body:
          'Nouvelles vitres sur les courts 1 et 2, éclairage LED et vestiaires refaits. Seul bémol : le parking est plein dès 19h.\n\n'
          'Les balles sont fournies le week-end, et le court 3 reste le plus rapide.',
      category: 'terrains',
      sport: 'padel',
      tags: ['smashpadel', 'lac2'],
      hoursAgo: 26,
      votes: 27,
      thanks: 6,
    ),
    _Post(
      key: 'five',
      author: 1,
      title: '5v5 dimanche soir à La Marsa, qui est chaud ?',
      body: 'Il reste 2 places dim. 18 oct. à 20h00 à Arena Five, niveau 3,0 – 4,5. 15 DT par joueur, chasubles fournies. Qui vient ?',
      category: 'discussions_libres',
      sport: 'football',
      tags: ['foot5', 'lamarsa'],
      hoursAgo: 74,
      votes: 21,
    ),
    _Post(
      key: 'crampons',
      author: 3,
      title: 'Crampons pour synthétique ?',
      body:
          'Je joue deux fois par semaine à Arena Five, sur le synthétique. Mes crampons vissés glissent quand le gazon est sec '
          'et me tirent sur les genoux en fin de match.\n\nMoulés, stabilisés (TF) ou autre chose ? Budget autour de **200 DT**.',
      category: 'equipement',
      sport: 'football',
      tags: ['crampons', 'synthétique', 'lamarsa'],
      hoursAgo: 50,
      votes: 18,
      useful: 11,
      thanks: 4,
    ),
    _Post(
      key: 'vibora',
      author: 4,
      title: 'Bandeja ou vibora : laquelle sur une balle haute ?',
      body: 'Sur une balle haute qui sort de la vitre de fond, vous jouez quoi ? Je perds trop de points en vibora quand je suis à gauche.',
      category: 'conseils_technique',
      sport: 'padel',
      tags: ['bandeja', 'vibora'],
      hoursAgo: 14 * 24 + 2,
      votes: 32,
      useful: 10,
    ),
    _Post(
      key: 'basket',
      author: 18,
      title: 'Hoop Zone 3x3 Night : on monte une équipe ?',
      body: 'Ven. 30 oct. à 20h00 à Ennasr, 60 DT par équipe. Il me faut 2 joueurs niveau 3,5 ou plus, on s’entraîne mardi soir.',
      category: 'tournois',
      sport: 'basketball',
      tags: ['3x3', 'ennasr'],
      hoursAgo: 40,
      votes: 9,
    ),
    _Post(
      key: 'spam',
      author: 11,
      title: 'Vends crampons pas cher, livraison partout',
      body: 'Vends crampons pas cher, livraison partout, lien en bio',
      category: 'equipement',
      sport: 'football',
      tags: [],
      hoursAgo: 1,
      votes: 0,
      hidden: true,
    ),
  ];

  static const _replies = <_Reply>[
    // « Crampons pour synthétique ? » (FRM-04): 8 published replies, Yassine's masked one.
    _Reply(
      'tf',
      'crampons',
      1,
      'Prends des stabilisés (TF) ou des moulés courts (AG). Les vissés, c’est pour l’herbe naturelle : sur synthétique ils accrochent trop '
          'et tirent sur les genoux. À Arena Five, les AG passent très bien, même quand c’est sec.',
      hoursAgo: 49,
      votes: 24,
      useful: 9,
    ),
    _Reply(
      'ag',
      'crampons',
      6,
      'J’ai pris des AG à **180 DT** il y a 6 mois. Zéro glisse à Arena Five, même le dimanche soir quand le terrain est arrosé.',
      hoursAgo: 48,
      votes: 9,
    ),
    _Reply('ou', 'crampons', 3, 'Tu les as prises où ? Je passe en ville samedi.', parent: 'ag', hoursAgo: 47, votes: 2),
    _Reply(
      'marseille',
      'crampons',
      6,
      '@skander.t Au centre-ville, rue de Marseille. Essaie-les avec tes chaussettes de match, ça taille petit.',
      parent: 'ou',
      hoursAgo: 26,
      votes: 3,
    ),
    _Reply(
      'pluie',
      'crampons',
      7,
      'Les TF, c’est top sur synthétique sec, mais ça glisse sous la pluie. Si tu joues aussi en extérieur l’hiver, garde des AG.',
      hoursAgo: 25,
      votes: 6,
    ),
    _Reply(
      'visses',
      'crampons',
      8,
      'Les vissés c’est mieux, tout le monde sait ça. Les moulés c’est pour les débutants.',
      hoursAgo: 24,
      votes: -3,
    ),
    _Reply(
      'nul',
      'crampons',
      1,
      'T’as jamais mis les pieds sur un synthétique, franchement t’es nul. Arrête de raconter n’importe quoi.',
      parent: 'visses',
      hoursAgo: 23,
      hidden: true,
    ),
    _Reply(
      'mariem',
      'crampons',
      4,
      'Moulés pour moi, et je les change tous les 8 mois. Au-delà, ils glissent autant que des vissés.',
      hoursAgo: 8,
      votes: 1,
    ),
    _Reply(
      'bonsplans',
      'crampons',
      9,
      'Vends crampons pas cher, toutes marques, livraison partout en Tunisie. Écris-moi en privé !!',
      hoursAgo: 3,
    ),

    // « Bandeja : je n’arrive pas à la placer croisée »
    _Reply(
      'karim',
      'bandeja',
      13,
      'Frappe la balle devant l’épaule, pas au-dessus de la tête, et finis le geste vers la vitre latérale. '
          'C’est exactement la séance 5 du programme : fais-la deux fois cette semaine.',
      hoursAgo: 1.5,
      votes: 7,
      useful: 3,
    ),
    _Reply('ines2', 'bandeja', 2, 'Merci Karim, je teste demain soir au Lac.', parent: 'karim', hoursAgo: 1.2, votes: 1),
    _Reply(
      'yb',
      'bandeja',
      1,
      'Pareil que toi au début. Ce qui m’a aidé : viser le coin vitre de fond + grille, et rester de profil jusqu’au contact.',
      hoursAgo: 1,
      votes: 4,
    ),
    _Reply(
      'nour',
      'bandeja',
      15,
      'Tu joues avec quelle raquette ? Avec une ronde c’est plus facile de la sortir croisée.',
      hoursAgo: 0.8,
      votes: 2,
    ),
    _Reply('ines3', 'bandeja', 2, 'Une ronde, une Bullpadel de 2024.', parent: 'nour', hoursAgo: 0.7),
    _Reply('rami', 'bandeja', 14, 'Filme-toi de côté, tu verras tout de suite si tu frappes trop tard.', hoursAgo: 0.6, votes: 3),
    _Reply('lina', 'bandeja', 17, 'Je suis le même programme, séance 5 aussi. On s’entraîne ensemble samedi ?', hoursAgo: 0.4, votes: 1),
    _Reply('ines4', 'bandeja', 2, 'Avec plaisir ! 10h au Smash ?', parent: 'lina', hoursAgo: 0.3),

    // « Padel Masters Lac 2 »
    _Reply(
      'm1',
      'masters',
      4,
      'On s’inscrit avec Yassine sous le nom « Les Faucons ». Le paiement se fait en ligne ?',
      hoursAgo: 70,
      votes: 5,
    ),
    _Reply(
      'm2',
      'masters',
      5,
      'Oui, 120 DT par équipe, dans l’app. Chacun peut payer sa part.',
      parent: 'm1',
      hoursAgo: 69,
      votes: 8,
      useful: 4,
    ),
    _Reply('m3', 'masters', 15, 'Les balles sont fournies pour chaque match ?', hoursAgo: 60, votes: 3),
    _Reply('m4', 'masters', 5, 'Oui, 3 balles neuves par match, et de l’eau sur chaque court.', parent: 'm3', hoursAgo: 59, votes: 4),
    _Reply('m5', 'masters', 17, 'Il y a une catégorie mixte ?', hoursAgo: 40, votes: 2),
    _Reply('m6', 'masters', 5, 'Pas cette fois, mais la Coupe d’hiver en aura une.', parent: 'm5', hoursAgo: 39, votes: 3),
    _Reply('arbitres', 'masters', 14, 'Les arbitres de ce tournoi sont achetés, c’est une blague.', hoursAgo: 26, votes: -2),

    // « Avis Smash Padel Club après rénovation »
    _Reply('s1', 'smash', 2, 'Confirmé pour l’éclairage, on voit enfin la balle sur les lobs.', hoursAgo: 24, votes: 4),
    _Reply('s2', 'smash', 15, 'Le parking de la clinique juste derrière est ouvert après 19h.', hoursAgo: 20, votes: 6, useful: 3),
    _Reply('s3', 'smash', 4, 'Merci Nour, je ne savais pas !', parent: 's2', hoursAgo: 19),
    _Reply('s4', 'smash', 13, 'Les nouvelles vitres rebondissent plus : ajustez vos sorties de vitre.', hoursAgo: 10, votes: 5),

    // « 5v5 dimanche soir à La Marsa »
    _Reply('f1', 'five', 6, 'Compte sur moi, on vient à deux.', hoursAgo: 70, votes: 4),
    _Reply('f2', 'five', 16, 'Je peux jouer gardien si besoin.', hoursAgo: 60, votes: 3),
    _Reply('f3', 'five', 1, 'Parfait Salma, je te mets en gardienne.', parent: 'f2', hoursAgo: 59),
    _Reply('f4', 'five', 7, 'Dommage, je suis pris dimanche. La prochaine !', hoursAgo: 30, votes: 1),

    // « Bandeja ou vibora »
    _Reply(
      'v1',
      'vibora',
      13,
      'Bandeja dès que tu es en retard, vibora seulement si tu es bien placé et que la balle est devant toi.',
      hoursAgo: 14 * 24,
      votes: 18,
      useful: 7,
    ),
    _Reply('v2', 'vibora', 2, 'À gauche, je joue presque toujours bandeja, c’est plus sûr.', hoursAgo: 13 * 24, votes: 6),

    // « Hoop Zone 3x3 Night »
    _Reply('b1', 'basket', 16, 'Je suis à 3,5, je peux venir mardi.', hoursAgo: 30, votes: 2),
  ];

  /// (target, key, reporters (story numbers), reason)
  static const _reports = <(String, String, List<int>, String)>[
    ('sujet', 'spam', [1, 2, 3, 4, 6], 'spam'),
    ('message', 'nul', [8, 7, 6], 'insulte'),
    ('message', 'arbitres', [5], 'fausse_information'),
    ('message', 'bonsplans', [4], 'spam'),
  ];
}

class _Post {
  const _Post({
    required this.key,
    required this.author,
    required this.title,
    required this.body,
    required this.category,
    required this.sport,
    required this.tags,
    required this.hoursAgo,
    required this.votes,
    this.useful = 0,
    this.thanks = 0,
    this.pinned = false,
    this.hidden = false,
  });

  final String key;
  final int author;
  final String title;
  final String body;
  final String category;
  final String? sport;
  final List<String> tags;
  final num hoursAgo;
  final int votes;
  final int useful;
  final int thanks;
  final bool pinned;
  final bool hidden;
}

class _Reply {
  const _Reply(
    this.key,
    this.post,
    this.author,
    this.body, {
    this.parent,
    required this.hoursAgo,
    this.votes = 0,
    this.useful = 0,
    this.hidden = false,
  });

  final String key;
  final String post;
  final int author;
  final String body;
  final String? parent;
  final num hoursAgo;
  final int votes;
  final int useful;
  final bool hidden;
}
