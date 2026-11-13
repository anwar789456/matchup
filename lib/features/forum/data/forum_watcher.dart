import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/clock.dart';
import '../../../core/db/app_database.dart';
import '../../../core/format.dart';
import '../../../core/sync/sync_service.dart';
import '../../../l10n/l10n.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../notifications/data/notification_models.dart';
import '../../notifications/data/notification_prefs.dart';
import '../../notifications/data/notification_repository.dart';
import '../../notifications/data/push_service.dart';
import '../controllers/forum_providers.dart';
import '../controllers/messages_providers.dart';
import 'forum_identity.dart';
import 'forum_models.dart';
import 'forum_seed.dart';
import 'forum_text.dart';
import 'sqlite_forum_repository.dart';

/// Something in the Communauté the member should hear about.
class ForumEvent {
  const ForumEvent({
    required this.key,
    required this.type,
    required this.title,
    required this.body,
    required this.route,
    required this.at,
    this.actor,
    this.sport,
    this.icon,
  });

  /// Stable: the same event is never told twice.
  final String key;
  final NotificationType type;
  final String title;
  final String body;

  /// Where a tap leads.
  final String route;
  final DateTime at;

  /// Who did it (the avatar).
  final String? actor;
  final MuSport? sport;
  final IconData? icon;
}

/// Finds what happened for the member in the forum, the chats' offers and the saved searches,
/// from the rows the phone has (its own and the ones the sync brought): replies, mentions, best
/// answers, players joining their « Cherche joueurs », their move from the waiting list into
/// the team, sellers' reviews, offers and their answers, new posts matching an alert. Nothing
/// is written for anyone else: what was already told is kept in `forum_evenements_vus`.
class ForumWatcher {
  ForumWatcher(this._database, {required this._now, String Function()? meId}) : _meId = meId ?? forumUserId;

  final AppDatabase _database;
  final DateTime Function() _now;
  final String Function() _meId;

  /// On the first scan, events of this recent past go to the centre (unread, without push).
  static const recent = Duration(hours: 24);

  String get me => _meId();

  /// The member's ids in the chats: a Supabase member is also the story's player.
  List<String> get _chatMe => me.startsWith('demo-') ? [me] : [me, ForumSeed.me];

  static String _marks(int n) => List.filled(n, '?').join(',');

  /// The new events, newest first, now marked as told. [first] says whether this phone had
  /// never scanned for this member (then only [recent] events are returned).
  Future<({List<ForumEvent> events, bool first})> scan() async {
    final db = await _database.db;
    final seen = {
      for (final r in await db.query('forum_evenements_vus', columns: ['cle'], where: 'utilisateur_id = ?', whereArgs: [me]))
        r['cle']! as String,
    };
    final first = seen.isEmpty;
    final names = {for (final r in await db.query('forum_membres')) r['id']! as String: r['nom']! as String};
    String name(Object? id) => names[id] ?? l10n.forumMembre;

    final found = <ForumEvent>[];
    final quiet = <String>[]; // remembered without telling (a waiting-list place)
    void add(ForumEvent e) {
      if (!seen.contains(e.key)) found.add(e);
    }

    // Replies to the member's posts and replies.
    for (final r in await db.rawQuery(
      'SELECT m.id, m.auteur_id, m.contenu, m.cree_le, m.parent_id, s.id AS sid, s.titre, s.sport, s.auteur_id AS sauteur, '
      'p.auteur_id AS pauteur FROM forum_messages m JOIN forum_sujets s ON s.id = m.sujet_id '
      'LEFT JOIN forum_messages p ON p.id = m.parent_id '
      "WHERE m.statut = 'publie' AND m.auteur_id <> ? AND (s.auteur_id = ? OR p.auteur_id = ?)",
      [me, me, me],
    )) {
      final toMyReply = r['pauteur'] == me;
      add(
        ForumEvent(
          key: 'reponse:${r['id']}',
          type: NotificationType.postReply,
          title: toMyReply ? l10n.ntTARepondu(name(r['auteur_id'])) : l10n.ntARepondu(name(r['auteur_id'])),
          body: l10n.ntCitationSur(ForumText.excerpt(r['contenu']! as String, length: 90), r['titre']! as String),
          route: Routes.forumPost(r['sid']! as String),
          at: DateTime.parse(r['cree_le']! as String),
          actor: name(r['auteur_id']),
          icon: PhosphorIcons.chatsCircle(),
        ),
      );
    }

    // Mentions in posts and replies.
    final handle = (await db.query('forum_membres', where: 'id = ?', whereArgs: [me])).firstOrNull?['pseudo'] as String?;
    if (handle != null) {
      final like = '%"$handle"%';
      for (final r in await db.rawQuery(
        "SELECT id, auteur_id, titre, cree_le FROM forum_sujets WHERE statut = 'publie' AND auteur_id <> ? AND mentions LIKE ?",
        [me, like],
      )) {
        add(
          ForumEvent(
            key: 'mention:${r['id']}',
            type: NotificationType.mention,
            title: l10n.ntTAMentionne(name(r['auteur_id'])),
            body: r['titre']! as String,
            route: Routes.forumPost(r['id']! as String),
            at: DateTime.parse(r['cree_le']! as String),
            actor: name(r['auteur_id']),
            icon: PhosphorIcons.at(),
          ),
        );
      }
      for (final r in await db.rawQuery(
        'SELECT m.id, m.auteur_id, m.contenu, m.cree_le, m.sujet_id FROM forum_messages m '
        "WHERE m.statut = 'publie' AND m.auteur_id <> ? AND m.mentions LIKE ?",
        [me, like],
      )) {
        add(
          ForumEvent(
            key: 'mention:${r['id']}',
            type: NotificationType.mention,
            title: l10n.ntTAMentionne(name(r['auteur_id'])),
            body: ForumText.excerpt(r['contenu']! as String, length: 120),
            route: Routes.forumPost(r['sujet_id']! as String),
            at: DateTime.parse(r['cree_le']! as String),
            actor: name(r['auteur_id']),
            icon: PhosphorIcons.at(),
          ),
        );
      }
    }

    // The member's reply chosen as the best answer.
    for (final r in await db.rawQuery(
      'SELECT s.id, s.titre, s.auteur_id, m.id AS mid, COALESCE(s.modifie_le, s.cree_le) AS le FROM forum_sujets s '
      'JOIN forum_messages m ON m.id = s.meilleure_reponse_id WHERE m.auteur_id = ? AND s.auteur_id <> ?',
      [me, me],
    )) {
      add(
        ForumEvent(
          key: 'meilleure:${r['id']}:${r['mid']}',
          type: NotificationType.bestAnswer,
          title: l10n.ntMeilleureReponse(name(r['auteur_id'])),
          body: r['titre']! as String,
          route: Routes.forumPost(r['id']! as String),
          at: DateTime.parse(r['le']! as String),
          actor: name(r['auteur_id']),
          icon: PhosphorIcons.checkCircle(),
        ),
      );
    }

    // « Cherche joueurs »: players joining the member's searches…
    for (final r in await db.rawQuery(
      'SELECT p.id, p.auteur_id, p.cree_le, r.sujet_id, r.lieu, r.le, r.sport, r.places FROM forum_participations p '
      'JOIN forum_recherches r ON r.sujet_id = p.sujet_id WHERE r.auteur_id = ? AND p.auteur_id <> ?',
      [me, me],
    )) {
      add(
        ForumEvent(
          key: 'participation:${r['id']}',
          type: NotificationType.playersJoined,
          title: l10n.ntVientATonMatch(name(r['auteur_id'])),
          body: l10n.ntLieuEtHeure(r['lieu']! as String, formatDateTime(DateTime.parse(r['le']! as String))),
          route: Routes.forumPost(r['sujet_id']! as String),
          at: DateTime.parse(r['cree_le']! as String),
          actor: name(r['auteur_id']),
          sport: MuSport.values.where((s) => s.name == r['sport']).firstOrNull,
        ),
      );
    }
    // … and the member moving up from the waiting list.
    final now = _now();
    for (final r in await db.rawQuery(
      'SELECT r.sujet_id, r.auteur_id, r.places, r.lieu, r.le, r.sport FROM forum_recherches r '
      "JOIN forum_participations p ON p.sujet_id = r.sujet_id AND p.auteur_id = ? WHERE r.statut = 'ouverte' AND r.le > ?",
      [me, now.toIso8601String()],
    )) {
      final order = [
        for (final p in await db.query(
          'forum_participations',
          columns: ['auteur_id'],
          where: 'sujet_id = ?',
          whereArgs: [r['sujet_id']],
          orderBy: 'cree_le, rowid',
        ))
          if (p['auteur_id'] != r['auteur_id']) p['auteur_id']! as String,
      ];
      final playing = order.indexOf(me) < (r['places']! as int);
      final waitKey = 'attente:${r['sujet_id']}';
      if (!playing) {
        if (!seen.contains(waitKey)) quiet.add(waitKey);
      } else if (seen.contains(waitKey)) {
        add(
          ForumEvent(
            key: 'promu:${r['sujet_id']}',
            type: NotificationType.spotFreed,
            title: l10n.ntPlaceLiberee,
            body: l10n.ntTuJoues(r['lieu']! as String, formatDateTime(DateTime.parse(r['le']! as String))),
            route: Routes.forumPost(r['sujet_id']! as String),
            at: now,
            sport: MuSport.values.where((s) => s.name == r['sport']).firstOrNull,
          ),
        );
      }
    }

    // Buyers' reviews of the member.
    for (final r in await db.rawQuery(
      "SELECT id, auteur_id, note, texte, cree_le FROM forum_avis WHERE vendeur_id = ? AND auteur_id <> ? AND statut = 'publie'",
      [me, me],
    )) {
      final text = r['texte'] as String? ?? '';
      add(
        ForumEvent(
          key: 'avis:${r['id']}',
          type: NotificationType.sellerReview,
          title: l10n.ntAvisRecu(name(r['auteur_id']), r['note']! as int),
          body: text.isEmpty ? l10n.ntAvisSansTexte : '« $text »',
          route: Routes.forumMine,
          at: DateTime.parse(r['cree_le']! as String),
          actor: name(r['auteur_id']),
          icon: PhosphorIcons.star(),
        ),
      );
    }

    // Offers in the member's chats, and the answers to theirs.
    final chatMe = _chatMe;
    final inChats = 'conversation_id IN (SELECT conversation_id FROM msg_participants WHERE membre_id IN (${_marks(chatMe.length)}) AND quitte_le IS NULL)';
    final titles = {for (final r in await db.query('forum_sujets', columns: ['id', 'titre'])) r['id']! as String: r['titre']! as String};
    for (final r in await db.rawQuery(
      "SELECT id, auteur_id, conversation_id, donnees, cree_le FROM msg_messages WHERE type = 'offre' "
      'AND auteur_id NOT IN (${_marks(chatMe.length)}) AND $inChats',
      [...chatMe, ...chatMe],
    )) {
      final data = jsonDecode(r['donnees']! as String) as Map;
      add(
        ForumEvent(
          key: 'offre:${r['id']}',
          type: NotificationType.offerReceived,
          title: l10n.ntOffreRecue(name(r['auteur_id']), formatDT(data['prix'] as num)),
          body: titles[data['sujet_id']] ?? '',
          route: Routes.chat(r['conversation_id']! as String),
          at: DateTime.parse(r['cree_le']! as String),
          actor: name(r['auteur_id']),
          icon: PhosphorIcons.tag(),
        ),
      );
    }
    for (final r in await db.rawQuery(
      'SELECT v.id, v.auteur_id, v.choix, v.cree_le, o.conversation_id, o.donnees FROM msg_votes v '
      "JOIN msg_messages o ON o.id = v.message_id WHERE o.type = 'offre' "
      'AND o.auteur_id IN (${_marks(chatMe.length)}) AND v.auteur_id NOT IN (${_marks(chatMe.length)})',
      [...chatMe, ...chatMe],
    )) {
      final data = jsonDecode(r['donnees']! as String) as Map;
      final accepted = r['choix'] == 'accepte';
      add(
        ForumEvent(
          key: 'reponse-offre:${r['id']}',
          type: NotificationType.offerAnswered,
          title: accepted
              ? l10n.ntOffreAcceptee(name(r['auteur_id']), formatDT(data['prix'] as num))
              : l10n.ntOffreRefusee(name(r['auteur_id']), formatDT(data['prix'] as num)),
          body: titles[data['sujet_id']] ?? '',
          route: Routes.chat(r['conversation_id']! as String),
          at: DateTime.parse(r['cree_le']! as String),
          actor: name(r['auteur_id']),
          icon: accepted ? PhosphorIcons.handshake() : PhosphorIcons.xCircle(),
        ),
      );
    }

    // New posts matching a saved search.
    final forum = SqliteForumRepository(_database, now: _now, meId: _meId);
    for (final a in await forum.alerts()) {
      if (!a.active) continue;
      for (final p in (await forum.feed(a.query, limit: 20)).posts) {
        if (p.mine.author || !p.createdAt.isAfter(a.createdAt)) continue;
        add(
          ForumEvent(
            key: 'alerte:${a.id}:${p.id}',
            type: NotificationType.savedSearchMatch,
            title: a.kind == AlertKind.listing ? l10n.ntNouvelleAnnonce(alertLabel(a)) : l10n.ntNouvellePartie(alertLabel(a)),
            body: p.listing != null ? '${p.title} · ${formatDT(p.listing!.price)}' : p.title,
            route: Routes.forumPost(p.id),
            at: p.createdAt,
            actor: p.author.name,
            sport: p.sport,
          ),
        );
      }
    }

    final told = first ? [for (final e in found) if (now.difference(e.at) <= recent) e] : found;
    final stamp = now.toIso8601String();
    final batch = db.batch();
    for (final key in [for (final e in found) e.key, ...quiet]) {
      batch.insert('forum_evenements_vus', {'cle': key, 'utilisateur_id': me, 'vu_le': stamp}, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    // Remember the first scan even when there was nothing to tell.
    if (first) {
      batch.insert('forum_evenements_vus', {'cle': 'debut', 'utilisateur_id': me, 'vu_le': stamp}, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
    told.sort((a, b) => b.at.compareTo(a.at));
    return (events: told, first: first);
  }
}

/// « crampons · Football · ≤ 100 DT · taille 42 ».
String alertLabel(ForumAlert a) => [
  if (a.words.trim().isNotEmpty) a.words.trim(),
  ?a.sport?.label,
  if (a.maxPrice != null) l10n.alMaxPrix(formatDT(a.maxPrice!)),
  if (a.size != null) l10n.mktTailleX(a.size!),
].join(' · ');

/// Runs [ForumWatcher] after every change in the forum, the chats or the sync, and gives what
/// it finds to the notification centre (Communauté) and as a push, as NOT-10 allows.
final forumWatcherProvider = Provider<void>((ref) {
  final watcher = ForumWatcher(ref.watch(appDatabaseProvider), now: ref.watch(clockProvider));
  var running = false;
  var again = false;

  Future<void> run() async {
    if (running) {
      again = true;
      return;
    }
    running = true;
    try {
      do {
        again = false;
        final (:events, :first) = await watcher.scan();
        if (events.isEmpty || !ref.mounted) continue;
        final prefs = ref.read(notificationPrefsProvider);
        final center = ref.read(notificationRepositoryProvider);
        for (final e in events.reversed) {
          if (!prefs.isOn(e.type.category, NotificationChannel.app)) continue;
          await center.push(
            AppNotification(
              id: 'forum:${e.key}',
              type: e.type,
              title: e.title,
              body: e.body,
              at: e.at,
              avatar: e.actor,
              sport: e.sport,
              icon: e.icon,
              target: NotificationTarget.community,
              targetId: e.route,
              unread: true,
            ),
          );
        }
        if (first || !prefs.isOn(NotificationCategory.community, NotificationChannel.push)) continue;
        for (final e in events.take(3)) {
          try {
            await ref
                .read(pushServiceProvider)
                .show(PushMessage(id: e.key.hashCode & 0x7fffffff, category: e.type.category, title: e.title, body: e.body, route: e.route));
          } catch (_) {
            // No system notifications here (browser, tests): the centre has it.
          }
        }
      } while (again && ref.mounted);
    } catch (_) {
      // A failed scan is tried again at the next change.
    } finally {
      running = false;
    }
  }

  void soon() => Future.microtask(run);
  ref.listen(forumChangesProvider, (_, _) => soon());
  ref.listen(messagesChangesProvider, (_, _) => soon());
  ref.listen(syncRevisionProvider, (_, _) => soon());
  soon();
});
