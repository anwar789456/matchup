import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'forum_seed.dart';

/// Équipement · Marketplace in the story (« now » = ven. 16 oct. 2026 18h00): three items for
/// sale with questions in their comments, and buyers' reviews of the sellers. Demo rows.
abstract final class MarketSeed {
  static String postId(String key) => ForumSeed.postId('vente-$key');

  static String _at(int day, int hour, int minute) => DateTime(2026, 10, day, hour, minute).toIso8601String();

  static Future<void> insert(DatabaseExecutor db) async {
    final batch = db.batch();
    final ines = ForumSeed.id(2);
    final skander = ForumSeed.id(3);
    final mariem = ForumSeed.id(4);
    final hamza = ForumSeed.id(6);
    final aziz = ForumSeed.id(7);
    final omar = ForumSeed.id(8);
    final nour = ForumSeed.id(15);
    final lina = ForumSeed.id(17);
    final mehdi = ForumSeed.id(18);

    void listing(
      String key,
      String author,
      String at, {
      required String title,
      required String body,
      required String sport,
      required List<String> tags,
      required double price,
      required String condition,
      String? size,
      String? city,
      bool sold = false,
    }) {
      batch.insert('forum_sujets', {
        'id': postId(key),
        'auteur_id': author,
        'titre': title,
        'contenu': body,
        'categorie': 'equipement',
        'sport': sport,
        'tags': jsonEncode(tags),
        'images': '[]',
        'mentions': '[]',
        'cree_le': at,
      });
      batch.insert('forum_annonces', {
        'sujet_id': postId(key),
        'auteur_id': author,
        'prix': price,
        'etat': condition,
        'taille': size,
        'ville': city,
        'statut': sold ? 'vendu' : 'disponible',
        'maj_le': at,
      });
    }

    void comment(String key, String post, String author, String at, String text, {String? parent}) => batch.insert('forum_messages', {
      'id': ForumSeed.replyId('vente-$key'),
      'sujet_id': postId(post),
      'parent_id': parent == null ? null : ForumSeed.replyId('vente-$parent'),
      'auteur_id': author,
      'contenu': text,
      'cree_le': at,
    });

    void review(String author, String seller, int stars, String text, String at, {String? post}) => batch.insert('forum_avis', {
      'id': 'demo-avis-$author-$seller',
      'auteur_id': author,
      'vendeur_id': seller,
      'sujet_id': post == null ? null : postId(post),
      'note': stars,
      'texte': text,
      'cree_le': at,
    });

    listing(
      'raquette',
      mariem,
      _at(16, 9, 30),
      title: 'Raquette Bullpadel Vertex 03 · très bon état',
      body:
          'Achetée en mars, jouée une vingtaine de fois. Grip neuf, housse offerte.\n\n'
          'Parfaite pour un niveau 3,5–4,5, plutôt attaquant. Remise en main propre au Smash Padel Club.',
      sport: 'padel',
      tags: ['raquette', 'bullpadel'],
      price: 180,
      condition: 'tres_bon',
      city: 'La Marsa',
    );
    comment('r1', 'raquette', ines, _at(16, 10, 5), 'Elle pèse combien ? Je cherche plus léger que ma Head.');
    comment('r2', 'raquette', mariem, _at(16, 10, 20), '370 g, équilibre plutôt en tête.', parent: 'r1');

    listing(
      'crampons',
      omar,
      _at(15, 19, 0),
      title: 'Crampons Nike Phantom GX · pointure 42',
      body: 'Portés une saison sur synthétique, semelle encore bien accrocheuse. Je change de pointure, d’où la vente.',
      sport: 'football',
      tags: ['crampons', 'synthétique'],
      price: 120,
      condition: 'bon',
      size: '42',
      city: 'L’Aouina',
    );
    comment('c1', 'crampons', hamza, _at(15, 20, 10), 'Ils taillent grand ou normal ?');
    comment('c2', 'crampons', omar, _at(15, 20, 40), 'Normal, comme des Adidas. Tu peux les essayer jeudi à Arena Five.', parent: 'c1');
    comment('c3', 'crampons', aziz, _at(16, 8, 15), 'Dernier prix ?');

    listing(
      'ballon',
      mehdi,
      _at(12, 18, 0),
      title: 'Ballon de basket Wilson Evolution taille 7',
      body: 'Neuf, jamais gonflé (cadeau en double). Le ballon indoor de référence.',
      sport: 'basketball',
      tags: ['ballon', 'wilson'],
      price: 75,
      condition: 'neuf',
      city: 'Ennasr',
      sold: true,
    );

    review(ines, mariem, 5, 'Raquette conforme aux photos, très bon contact. Je recommande !', _at(2, 19, 0));
    review(nour, mariem, 5, 'Vendeuse au top, rendez-vous au club, rien à redire.', _at(8, 12, 0));
    review(lina, mariem, 4, 'Petite rayure non mentionnée, mais prix juste et très sympa.', _at(11, 17, 30));
    review(skander, omar, 4, 'Bon deal, chaussures propres. Un peu de retard au rendez-vous.', _at(5, 21, 0));
    review(aziz, mehdi, 5, 'Ballon neuf comme annoncé, remise en main propre à Ennasr.', _at(14, 18, 0), post: 'ballon');

    await batch.commit(noResult: true);
  }
}
