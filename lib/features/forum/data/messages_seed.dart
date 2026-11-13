import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'forum_seed.dart';

/// The story's conversations (design/screens/STORY-DATA.md, « now » = ven. 16 oct. 2026 18h00):
/// Skander asks about Sunday's 5v5, the group of Yassine's booking of mer. 21 oct. (MU-48213),
/// Mariem and the Padel Masters, and the Lac 2 padel group. Demo rows, on the phone only.
abstract final class MessagesSeed {
  static String conversationId(String key) => 'demo-conv-$key';
  static String messageId(String key) => 'demo-msg-$key';

  static String _at(int day, int hour, int minute) => DateTime(2026, 10, day, hour, minute).toIso8601String();

  static const _me = ForumSeed.me;
  static final _skander = ForumSeed.id(3);
  static final _ines = ForumSeed.id(2);
  static final _mariem = ForumSeed.id(4);
  static final _hamza = ForumSeed.id(6);
  static final _aziz = ForumSeed.id(7);
  static final _omar = ForumSeed.id(8);
  static final _rami = ForumSeed.id(14);
  static final _nour = ForumSeed.id(15);
  static final _lina = ForumSeed.id(17);

  /// What a friend answers to a text (demo only, see `MessagesRepository.demoAnswer`).
  static const answers = [
    'Ça marche 👍',
    'Carrément, je suis chaud !',
    'Je te confirme ce soir.',
    'Ok pour moi, on se retrouve là-bas 10 min avant.',
    'Haha bien vu 😄',
    'Top, merci !',
  ];

  /// … to a question.
  static const answersToQuestion = [
    'Je regarde et je te dis.',
    'Oui, ça me va !',
    'Bonne question… je dirais oui.',
    'Pas sûr, je te redis demain matin.',
  ];

  /// … to a photo or a video.
  static const answersToMedia = [
    'Trop bien 😍',
    'Ha, je veux voir ça en vrai !',
    'Belle photo 🔥',
  ];

  /// … to a voice message.
  static const answersToVoice = [
    'Bien reçu, ça marche !',
    'Ok, je t’appelle tout à l’heure.',
    '😂 compris !',
  ];

  /// … to a shared discussion.
  static const answersToShare = [
    'Merci, je lis ça !',
    'Super utile, je garde 🔖',
    'Ah je l’avais pas vue, merci.',
  ];

  static Future<void> insert(DatabaseExecutor db) async {
    final batch = db.batch();

    void conversation(String key, String author, String type, String created, List<String> members, {String? name, String? admin}) {
      batch.insert('msg_conversations', {'id': conversationId(key), 'auteur_id': author, 'type': type, 'nom': name, 'cree_le': created});
      for (final m in members) {
        batch.insert('msg_participants', {
          'conversation_id': conversationId(key),
          'membre_id': m,
          'auteur_id': author,
          'role': m == admin ? 'admin' : 'membre',
          'rejoint_le': created,
        });
      }
    }

    void message(String conv, String key, String author, String at, {String type = 'texte', String text = '', Object? data, String? replyTo}) {
      batch.insert('msg_messages', {
        'id': messageId(key),
        'conversation_id': conversationId(conv),
        'auteur_id': author,
        'type': type,
        'contenu': text,
        'donnees': data == null ? null : jsonEncode(data),
        'reponse_a_id': replyTo == null ? null : messageId(replyTo),
        'cree_le': at,
      });
    }

    void votes(String key, Map<String, String> choices, String at) {
      for (final e in choices.entries) {
        batch.insert('msg_votes', {'id': 'demo-vote-$key-${e.key}', 'message_id': messageId(key), 'auteur_id': e.key, 'choix': e.value, 'cree_le': at});
      }
    }

    void reaction(String key, String author, String emoji, String at) => batch.insert('msg_reactions', {
      'id': 'demo-reaction-$key-$author-${emoji.runes.first}',
      'message_id': messageId(key),
      'auteur_id': author,
      'emoji': emoji,
      'cree_le': at,
    });

    void read(String conv, String upTo) =>
        batch.insert('msg_lectures', {'conversation_id': conversationId(conv), 'utilisateur_id': _me, 'lu_jusqua': upTo});

    // ── Skander: Sunday's 5v5 (G1, dim. 18 oct. 20h00, Arena Five Terrain 2, 2 places left) ──
    conversation('skander', _skander, 'direct', _at(15, 21, 10), [_me, _skander]);
    message('skander', 'sk1', _skander, _at(15, 21, 12), text: 'Salut ! Tu joues dimanche à Arena Five ? 20h, Terrain 2.');
    message('skander', 'sk2', _me, _at(15, 21, 30), text: 'Je regarde mon planning et je te dis 👍');
    message('skander', 'sk3', _skander, _at(16, 17, 40), text: 'Il reste 2 places, Hamza garde les cages 😄 Dis-moi vite !');
    message(
      'skander',
      'sk4',
      _skander,
      _at(16, 17, 41),
      type: 'match',
      data: {'sport': 'football', 'lieu': 'Arena Five · Terrain 2', 'le': _at(18, 20, 0)},
    );
    votes('sk4', {_skander: 'oui'}, _at(16, 17, 41));
    read('skander', _at(15, 21, 30));

    // ── The group of MU-48213 (mer. 21 oct. 21h00, Arena Five Terrain 1), created by Yassine ──
    conversation(
      'mercredi',
      _me,
      'groupe',
      _at(14, 10, 0),
      [_me, _skander, _hamza, _aziz, _omar, _nour],
      name: 'Five du mercredi · Arena Five',
      admin: _me,
    );
    message('mercredi', 'me0', _me, _at(14, 10, 0), type: 'systeme', data: {'action': 'cree'});
    message(
      'mercredi',
      'me1',
      _me,
      _at(14, 10, 2),
      type: 'match',
      data: {'sport': 'football', 'lieu': 'Arena Five · Terrain 1', 'le': _at(21, 21, 0)},
    );
    votes('me1', {_me: 'oui', _skander: 'oui', _hamza: 'oui', _aziz: 'oui', _omar: 'oui', _nour: 'oui'}, _at(14, 11, 0));
    message('mercredi', 'me2', _hamza, _at(14, 10, 15), text: 'Je garde les cages, comme d’hab 🧤');
    message(
      'mercredi',
      'me3',
      _hamza,
      _at(15, 9, 20),
      type: 'sondage',
      data: {
        'question': 'Chasubles ou maillots ?',
        'options': ['Chasubles du club', 'Chacun son maillot'],
      },
    );
    votes('me3', {_skander: '0', _aziz: '0', _nour: '1', _hamza: '0'}, _at(15, 10, 0));
    message('mercredi', 'me4', _aziz, _at(16, 16, 5), text: 'Je ramène le ballon ⚽');
    reaction('me4', _skander, '👍', _at(16, 16, 10));
    reaction('me4', _me, '👍', _at(16, 16, 12));
    message('mercredi', 'me5', _omar, _at(16, 17, 20), text: 'Quelqu’un me prend en voiture depuis l’Aouina ?');
    message('mercredi', 'me6', _nour, _at(16, 17, 22), text: 'Je passe par là, je te prends à 20h30 !', replyTo: 'me5');
    reaction('me6', _omar, '🙏', _at(16, 17, 23));
    read('mercredi', _at(16, 16, 12));

    // ── Mariem: « Les Faucons » for the Padel Masters Lac 2 ─────────────────────────────────
    conversation('mariem', _mariem, 'direct', _at(14, 19, 0), [_me, _mariem]);
    message('mariem', 'ma1', _mariem, _at(14, 19, 0), text: 'On s’inscrit au Padel Masters ensemble ? « Les Faucons » 🦅');
    message('mariem', 'ma2', _me, _at(14, 19, 5), text: 'Carrément ! Je m’occupe de l’inscription.');
    message('mariem', 'ma3', _mariem, _at(15, 12, 10), type: 'partage', data: {'sujet_id': ForumSeed.postId('bandeja')});
    message('mariem', 'ma4', _mariem, _at(15, 12, 11), text: 'Regarde les conseils pour la bandeja, ça peut nous aider contre Ines et Nour 😉');
    reaction('ma4', _me, '😂', _at(15, 12, 30));
    message('mariem', 'ma5', _me, _at(15, 12, 30), text: 'Bien vu, on la travaille jeudi ?');
    read('mariem', _at(15, 12, 30));

    // ── The Lac 2 padel group, created by Mariem ────────────────────────────────────────────
    conversation(
      'padel',
      _mariem,
      'groupe',
      _at(12, 18, 0),
      [_mariem, _me, _ines, _nour, _rami, _lina],
      name: 'Padel Lac 2 · niveau 3,5',
      admin: _mariem,
    );
    message('padel', 'pa0', _mariem, _at(12, 18, 0), type: 'systeme', data: {'action': 'cree'});
    message(
      'padel',
      'pa1',
      _mariem,
      _at(15, 20, 0),
      type: 'sondage',
      data: {
        'question': 'Créneau pour jeudi prochain ?',
        'options': ['18h30', '20h00', '21h30'],
      },
    );
    votes('pa1', {_mariem: '1', _ines: '1', _rami: '2', _lina: '0'}, _at(15, 20, 30));
    message('padel', 'pa2', _ines, _at(15, 20, 30), text: '20h c’est parfait pour moi');
    message('padel', 'pa3', _rami, _at(16, 11, 0), text: 'Smash Padel Club a ouvert les réservations pour jeudi 👀');
    read('padel', _at(15, 20, 30));

    await batch.commit(noResult: true);
  }
}
