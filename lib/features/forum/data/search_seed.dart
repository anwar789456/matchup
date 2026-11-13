import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'forum_seed.dart';

/// « Cherche joueurs » in the story (« now » = ven. 16 oct. 2026 18h00): Skander's Sunday 5v5
/// (G1, 2 places left), Mariem's padel tonight (full, one on the waiting list), Mehdi's 3x3 on
/// Saturday. Demo rows.
abstract final class SearchSeed {
  static String postId(String key) => ForumSeed.postId('cherche-$key');

  static String _at(int day, int hour, [int minute = 0]) => DateTime(2026, 10, day, hour, minute).toIso8601String();

  static Future<void> insert(DatabaseExecutor db) async {
    final batch = db.batch();

    void search(
      String key,
      String author,
      String created, {
      required String title,
      required String body,
      required String category,
      required String sport,
      required String place,
      required String at,
      required int places,
      double? min,
      double? max,
      double? price,
      List<String> tags = const [],
    }) {
      batch.insert('forum_sujets', {
        'id': postId(key),
        'auteur_id': author,
        'titre': title,
        'contenu': body,
        'categorie': category,
        'sport': sport,
        'tags': jsonEncode(tags),
        'images': '[]',
        'mentions': '[]',
        'cree_le': created,
      });
      batch.insert('forum_recherches', {
        'sujet_id': postId(key),
        'auteur_id': author,
        'sport': sport,
        'lieu': place,
        'le': at,
        'places': places,
        'niveau_min': min,
        'niveau_max': max,
        'prix': price,
        'maj_le': created,
      });
    }

    void join(String key, int member, String at) => batch.insert('forum_participations', {
      'id': 'demo-participation-$key-$member',
      'auteur_id': ForumSeed.id(member),
      'sujet_id': postId(key),
      'cree_le': at,
    });

    search(
      'dimanche',
      ForumSeed.id(3),
      _at(16, 16, 30),
      title: 'Il manque 3 joueurs dimanche 20h à Arena Five',
      body: '5v5 mixte, terrain synthétique éclairé. Chasubles fournies, on arrive 10 min avant. Ambiance détente mais on joue sérieux 😄',
      category: 'terrains',
      sport: 'football',
      place: 'Arena Five · Terrain 2',
      at: _at(18, 20),
      places: 3,
      min: 3.0,
      max: 4.5,
      price: 15,
      tags: ['5v5', 'lamarsa'],
    );
    join('dimanche', 14, _at(16, 17, 5)); // Rami S.

    search(
      'padel',
      ForumSeed.id(4),
      _at(16, 14, 0),
      title: 'Padel ce soir 20h · il nous manque 1 joueur',
      body: 'Double mixte au Smash Padel Club, court 3. Côté gauche de préférence.',
      category: 'discussions_libres',
      sport: 'padel',
      place: 'Smash Padel Club · Court 3',
      at: _at(16, 20),
      places: 1,
      min: 3.0,
      max: 4.0,
      price: 25,
      tags: ['padel', 'lac2'],
    );
    join('padel', 17, _at(16, 14, 20)); // Lina F.
    join('padel', 15, _at(16, 15, 40)); // Nour A., waiting

    search(
      'basket',
      ForumSeed.id(18),
      _at(15, 21, 0),
      title: '3x3 samedi 18h à Hoop Zone, qui est chaud ?',
      body: 'On monte une équipe pour s’entraîner avant le Hoop Zone 3x3 Night. Niveau confirmé.',
      category: 'discussions_libres',
      sport: 'basketball',
      place: 'Hoop Zone · Ennasr',
      at: _at(17, 18),
      places: 3,
      min: 3.5,
      max: 5.0,
      tags: ['3x3', 'ennasr'],
    );
    join('basket', 7, _at(15, 22, 10)); // Aziz H.

    await batch.commit(noResult: true);
  }
}
