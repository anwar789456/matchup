import 'dart:convert';
import 'dart:math' as math;

import 'package:sqflite/sqflite.dart';

import '../../../core/connectivity.dart';
import '../../../core/format.dart';
import '../../../core/db/app_database.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/theme.dart';
import 'forum_ai.dart';
import 'forum_identity.dart';
import 'forum_models.dart';
import 'forum_seed.dart';
import 'forum_text.dart';
import 'messages_repository.dart';
import 'messages_seed.dart';

/// [MessagesRepository] on the phone's database (schema v6, `msg_*` tables), with the forum's
/// rules: UUID ids, the writer in `auteur_id`, one row per vote and reaction, counts computed.
///
/// The story's player (`demo-yassine`) is the same person as the member using the app: the
/// demo conversations stay theirs once a Supabase id replaces it.
class SqliteMessagesRepository implements MessagesRepository {
  SqliteMessagesRepository(this._database, {required this._now, String Function()? meId, bool Function()? offline})
    : _meId = meId ?? (() => ForumSeed.me),
      _offline = offline ?? (() => false);

  final AppDatabase _database;
  final DateTime Function() _now;
  final String Function() _meId;
  final bool Function() _offline;

  static const maxLength = 2000;
  static const maxPollOptions = 4;

  @override
  String get meId => _meId();

  /// The reader's ids: a signed-in (Supabase) member is also the story's player they replace;
  /// another story member is only themselves.
  List<String> get _me => _demo(meId) ? [meId] : [meId, ForumSeed.me];
  bool _isMe(String id) => id == meId || (!_demo(meId) && id == ForumSeed.me);
  static bool _demo(String id) => id.startsWith(_demoPrefix);
  static const _demoPrefix = 'demo-';
  String get _meIn => '(${List.filled(_me.length, '?').join(',')})';

  Future<Database> get _db async {
    if (_offline()) throw const OfflineException();
    return _database.db;
  }

  /// Never before the last message: the demo clock starts again at each launch.
  Future<String> _stamp(DatabaseExecutor db, String conversationId) async {
    final now = _now().toIso8601String();
    final last = (await db.rawQuery('SELECT MAX(cree_le) AS m FROM msg_messages WHERE conversation_id = ?', [conversationId]))
        .first['m'] as String?;
    if (last == null || last.compareTo(now) < 0) return now;
    return DateTime.parse(last).add(const Duration(seconds: 1)).toIso8601String();
  }

  static String _marks(int n) => List.filled(n, '?').join(',');

  // ── Members ───────────────────────────────────────────────────────────────────────────────

  Future<Map<String, ForumAuthor>> _members(DatabaseExecutor db) async => {
    for (final r in await db.query('forum_membres'))
      r['id']! as String: ForumAuthor(
        id: r['id']! as String,
        name: r['nom']! as String,
        handle: r['pseudo'] as String?,
        level: (r['niveau'] as num?)?.toDouble(),
        sport: MuSport.values.where((s) => s.name == r['sport']).firstOrNull,
      ),
  };

  ForumAuthor _author(Map<String, ForumAuthor> members, String id) =>
      members[id] ?? members[_isMe(id) ? ForumSeed.me : id] ?? ForumAuthor(id: id, name: l10n.forumMembre);

  Future<Set<String>> _muted(DatabaseExecutor db) async => {
    for (final r in await db.query('forum_blocages', where: 'utilisateur_id IN $_meIn', whereArgs: _me)) r['bloque_id']! as String,
  };

  // ── Conversations ─────────────────────────────────────────────────────────────────────────

  /// The reader's participation, or a rule error when they are not in the conversation.
  Future<Map<String, Object?>> _participation(DatabaseExecutor db, String conversationId) async {
    final row = (await db.query(
      'msg_participants',
      where: 'conversation_id = ? AND membre_id IN $_meIn AND quitte_le IS NULL',
      whereArgs: [conversationId, ..._me],
    )).firstOrNull;
    if (row == null) throw ForumRuleException(l10n.msgPlusDansLaConversation);
    return row;
  }

  Future<Conversation> _conversation(DatabaseExecutor db, Map<String, Object?> c, Map<String, ForumAuthor> members) async {
    final id = c['id']! as String;
    final people = await db.query('msg_participants', where: 'conversation_id = ? AND quitte_le IS NULL', whereArgs: [id]);
    final lastRow = (await db.query('msg_messages', where: 'conversation_id = ?', whereArgs: [id], orderBy: 'cree_le DESC, rowid DESC', limit: 1))
        .firstOrNull;
    final last = lastRow == null ? null : (await _messages(db, [lastRow], members)).single;
    final reading = (await db.query('msg_lectures', where: 'conversation_id = ? AND utilisateur_id = ?', whereArgs: [id, meId])).firstOrNull;
    final unread = (await db.rawQuery(
      "SELECT COUNT(*) AS n FROM msg_messages WHERE conversation_id = ? AND auteur_id NOT IN $_meIn "
      "AND type != 'systeme' AND statut = 'publie' AND cree_le > ?",
      [id, ..._me, reading?['lu_jusqua'] ?? ''],
    )).first['n']! as int;
    return Conversation(
      id: id,
      type: ConversationType.fromCode(c['type']! as String),
      name: c['nom'] as String?,
      members: [for (final p in people) _author(members, p['membre_id']! as String)],
      last: last,
      unread: unread,
      muted: (reading?['sourdine'] as int? ?? 0) == 1,
      admin: people.any((p) => _isMe(p['membre_id']! as String) && p['role'] == 'admin'),
      createdAt: DateTime.parse(c['cree_le']! as String),
    );
  }

  @override
  Future<List<Conversation>> conversations() async {
    final db = await _db;
    final members = await _members(db);
    final rows = await db.rawQuery(
      'SELECT DISTINCT c.* FROM msg_conversations c JOIN msg_participants p ON p.conversation_id = c.id '
      'WHERE p.membre_id IN $_meIn AND p.quitte_le IS NULL',
      _me,
    );
    final list = [for (final c in rows) await _conversation(db, c, members)];
    // A private conversation with no message yet only shows once something is said.
    list.removeWhere((c) => !c.group && c.last == null);
    list.sort((a, b) => b.activity.compareTo(a.activity));
    return list;
  }

  @override
  Future<int> unreadCount() async {
    final list = await conversations();
    return list.where((c) => !c.muted).fold<int>(0, (n, c) => n + c.unread);
  }

  @override
  Future<Conversation> conversation(String id) async {
    final db = await _db;
    await _participation(db, id);
    final row = (await db.query('msg_conversations', where: 'id = ?', whereArgs: [id])).single;
    return _conversation(db, row, await _members(db));
  }

  @override
  Future<void> markRead(String conversationId) async {
    final db = await _db;
    final last = (await db.rawQuery('SELECT MAX(cree_le) AS m FROM msg_messages WHERE conversation_id = ?', [conversationId])).first['m']
        as String?;
    final now = _now().toIso8601String();
    final upTo = last != null && last.compareTo(now) > 0 ? last : now;
    final updated = await db.update(
      'msg_lectures',
      {'lu_jusqua': upTo},
      where: 'conversation_id = ? AND utilisateur_id = ?',
      whereArgs: [conversationId, meId],
    );
    if (updated == 0) await db.insert('msg_lectures', {'conversation_id': conversationId, 'utilisateur_id': meId, 'lu_jusqua': upTo});
  }

  @override
  Future<void> mute(String conversationId, {required bool on}) async {
    final db = await _db;
    await _participation(db, conversationId);
    final updated = await db.update(
      'msg_lectures',
      {'sourdine': on ? 1 : 0},
      where: 'conversation_id = ? AND utilisateur_id = ?',
      whereArgs: [conversationId, meId],
    );
    if (updated == 0) await db.insert('msg_lectures', {'conversation_id': conversationId, 'utilisateur_id': meId, 'sourdine': on ? 1 : 0});
  }

  // ── Friends, new conversations ────────────────────────────────────────────────────────────

  @override
  Future<List<ForumAuthor>> friends() async {
    final db = await _db;
    final members = await _members(db);
    final muted = await _muted(db);
    final followed = {
      for (final r in await db.query('forum_suivis', where: "utilisateur_id IN $_meIn AND type = 'membre'", whereArgs: _me))
        r['cible_id']! as String,
    };
    final talked = {
      for (final r in await db.rawQuery(
        'SELECT DISTINCT o.membre_id FROM msg_participants p JOIN msg_participants o ON o.conversation_id = p.conversation_id '
        'WHERE p.membre_id IN $_meIn',
        _me,
      ))
        r['membre_id']! as String,
    };
    int rank(ForumAuthor a) => followed.contains(a.id) ? 0 : (talked.contains(a.id) ? 1 : 2);
    final list = [
      for (final m in members.values)
        // Players only: brands and staff accounts have no level.
        if (!_isMe(m.id) && !muted.contains(m.id) && m.level != null) m,
    ]..sort((a, b) => rank(a) != rank(b) ? rank(a).compareTo(rank(b)) : a.name.compareTo(b.name));
    return list;
  }

  Future<void> _ensureMe(DatabaseExecutor db) async {
    if ((await db.query('forum_membres', where: 'id = ?', whereArgs: [meId])).isNotEmpty) return;
    final profile = (await db.query('forum_membres', where: 'id = ?', whereArgs: [ForumSeed.me])).firstOrNull;
    await db.insert('forum_membres', {
      'id': meId,
      'auteur_id': meId,
      'nom': profile?['nom'] ?? l10n.forumMembre,
      'pseudo': profile?['pseudo'],
      'niveau': profile?['niveau'],
      'sport': profile?['sport'],
      'maj_le': _now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  @override
  Future<String> openDirect(String memberId) async {
    if (_isMe(memberId)) throw ForumRuleException(l10n.msgPasAToiMeme);
    final db = await _db;
    final found = (await db.rawQuery(
      "SELECT c.id FROM msg_conversations c "
      "JOIN msg_participants a ON a.conversation_id = c.id AND a.membre_id IN $_meIn "
      "JOIN msg_participants b ON b.conversation_id = c.id AND b.membre_id = ? "
      "WHERE c.type = 'direct' LIMIT 1",
      [..._me, memberId],
    )).firstOrNull;
    if (found != null) {
      // Coming back to a conversation the reader had left.
      await db.update(
        'msg_participants',
        {'quitte_le': null},
        where: 'conversation_id = ? AND membre_id IN $_meIn',
        whereArgs: [found['id'], ..._me],
      );
      return found['id']! as String;
    }
    final id = newForumId();
    final now = _now().toIso8601String();
    await db.transaction((txn) async {
      await _ensureMe(txn);
      await txn.insert('msg_conversations', {'id': id, 'auteur_id': meId, 'type': ConversationType.direct.code, 'cree_le': now});
      for (final m in [meId, memberId]) {
        await txn.insert('msg_participants', {'conversation_id': id, 'membre_id': m, 'auteur_id': meId, 'rejoint_le': now});
      }
    });
    return id;
  }

  @override
  Future<String> createGroup(String name, List<String> memberIds) async {
    final title = name.trim();
    final others = {for (final m in memberIds) if (!_isMe(m)) m};
    if (title.isEmpty) throw ForumRuleException(l10n.msgDonneUnNom);
    if (others.length < 2) throw ForumRuleException(l10n.msgAuMoinsDeuxAmis);
    final db = await _db;
    final id = newForumId();
    final now = _now().toIso8601String();
    await db.transaction((txn) async {
      await _ensureMe(txn);
      await txn.insert('msg_conversations', {'id': id, 'auteur_id': meId, 'type': ConversationType.group.code, 'nom': title, 'cree_le': now});
      await txn.insert('msg_participants', {'conversation_id': id, 'membre_id': meId, 'auteur_id': meId, 'role': 'admin', 'rejoint_le': now});
      for (final m in others) {
        await txn.insert('msg_participants', {'conversation_id': id, 'membre_id': m, 'auteur_id': meId, 'rejoint_le': now});
      }
      await _system(txn, id, ChatEvent.created, now);
    });
    return id;
  }

  Future<void> _system(DatabaseExecutor db, String conversationId, ChatEvent event, String at, {String? name}) => db.insert('msg_messages', {
    'id': newForumId(),
    'conversation_id': conversationId,
    'auteur_id': meId,
    'type': ChatKind.system.code,
    'donnees': jsonEncode({'action': event.code, 'nom': ?name}),
    'cree_le': at,
  });

  Future<void> _requireAdmin(DatabaseExecutor db, String conversationId) async {
    final me = await _participation(db, conversationId);
    if (me['role'] != 'admin') throw ForumRuleException(l10n.msgSeulLeCreateur);
  }

  @override
  Future<void> rename(String conversationId, String name) async {
    final title = name.trim();
    if (title.isEmpty) throw ForumRuleException(l10n.msgDonneUnNom);
    final db = await _db;
    await _requireAdmin(db, conversationId);
    await db.transaction((txn) async {
      await txn.update('msg_conversations', {'nom': title}, where: 'id = ? AND auteur_id IN $_meIn', whereArgs: [conversationId, ..._me]);
      await _system(txn, conversationId, ChatEvent.renamed, await _stamp(txn, conversationId), name: title);
    });
  }

  @override
  Future<void> addMembers(String conversationId, List<String> memberIds) async {
    final db = await _db;
    await _requireAdmin(db, conversationId);
    final members = await _members(db);
    final now = await _stamp(db, conversationId);
    final added = <String>[];
    await db.transaction((txn) async {
      for (final m in memberIds) {
        if (_isMe(m)) continue;
        final back = await txn.update(
          'msg_participants',
          {'quitte_le': null, 'rejoint_le': now},
          where: 'conversation_id = ? AND membre_id = ? AND quitte_le IS NOT NULL',
          whereArgs: [conversationId, m],
        );
        final inserted = back > 0
            ? 1
            : await txn.insert('msg_participants', {
                'conversation_id': conversationId,
                'membre_id': m,
                'auteur_id': meId,
                'rejoint_le': now,
              }, conflictAlgorithm: ConflictAlgorithm.ignore);
        if (inserted > 0) added.add(_author(members, m).name);
      }
      if (added.isNotEmpty) await _system(txn, conversationId, ChatEvent.added, now, name: added.join(', '));
    });
  }

  @override
  Future<void> leave(String conversationId) async {
    final db = await _db;
    final me = await _participation(db, conversationId);
    final group = (await db.query('msg_conversations', where: 'id = ?', whereArgs: [conversationId])).single['type'] == ConversationType.group.code;
    final now = await _stamp(db, conversationId);
    await db.transaction((txn) async {
      if (group) await _system(txn, conversationId, ChatEvent.left, now);
      await txn.update(
        'msg_participants',
        {'quitte_le': now},
        where: 'conversation_id = ? AND membre_id = ?',
        whereArgs: [conversationId, me['membre_id']],
      );
    });
  }

  // ── Messages ──────────────────────────────────────────────────────────────────────────────

  @override
  Future<List<ChatMessage>> messages(String conversationId) async {
    final db = await _db;
    await _participation(db, conversationId);
    final rows = await db.query('msg_messages', where: 'conversation_id = ?', whereArgs: [conversationId], orderBy: 'cree_le, rowid');
    return _messages(db, rows, await _members(db));
  }

  Future<List<ChatMessage>> _messages(DatabaseExecutor db, List<Map<String, Object?>> rows, Map<String, ForumAuthor> members) async {
    if (rows.isEmpty) return const [];
    final ids = [for (final r in rows) r['id']! as String];
    final marks = _marks(ids.length);
    final muted = await _muted(db);

    final reactions = <String, Map<String, (int, bool)>>{};
    for (final r in await db.query('msg_reactions', where: 'message_id IN ($marks)', whereArgs: ids, orderBy: 'cree_le')) {
      final byEmoji = reactions[r['message_id']! as String] ??= {};
      final (n, mine) = byEmoji[r['emoji']! as String] ?? (0, false);
      byEmoji[r['emoji']! as String] = (n + 1, mine || _isMe(r['auteur_id']! as String));
    }
    final votes = <String, List<(String, String)>>{};
    for (final v in await db.query('msg_votes', where: 'message_id IN ($marks)', whereArgs: ids, orderBy: 'cree_le')) {
      (votes[v['message_id']! as String] ??= []).add((v['auteur_id']! as String, v['choix']! as String));
    }
    final quoted = {for (final r in rows) ?r['reponse_a_id'] as String?};
    final quotes = <String, ChatQuote>{
      if (quoted.isNotEmpty)
        for (final q in await db.query('msg_messages', where: 'id IN (${_marks(quoted.length)})', whereArgs: quoted.toList()))
          q['id']! as String: ChatQuote(
            id: q['id']! as String,
            author: _author(members, q['auteur_id']! as String),
            excerpt: q['statut'] == ForumStatus.published.code ? ForumText.excerpt(_quoteText(q), length: 80) : '',
          ),
    };

    final posts = <String, Map<String, Object?>>{};
    for (final r in rows) {
      if (r['type'] != ChatKind.share.code && r['type'] != ChatKind.offer.code) continue;
      final postId = (jsonDecode(r['donnees']! as String) as Map)['sujet_id'] as String;
      if (posts.containsKey(postId)) continue;
      final post = (await db.query('forum_sujets', where: 'id = ?', whereArgs: [postId])).firstOrNull;
      final listing = (await db.query('forum_annonces', where: 'sujet_id = ?', whereArgs: [postId])).firstOrNull;
      posts[postId] = {...?post, 'annonce': ?listing};
    }

    final latestOffer = <String, String>{};
    for (final o in await db.rawQuery(
      "SELECT id, conversation_id, donnees FROM msg_messages WHERE type = 'offre' AND conversation_id IN "
      '(${_marks({for (final r in rows) r['conversation_id']}.length)}) ORDER BY cree_le, rowid',
      {for (final r in rows) r['conversation_id']}.toList(),
    )) {
      final postId = (jsonDecode(o['donnees']! as String) as Map)['sujet_id'] as String;
      latestOffer['${o['conversation_id']}|$postId'] = o['id']! as String;
    }

    return [
      for (final r in rows)
        _message(
          r,
          members,
          latestOffer: latestOffer,
          muted: muted,
          reactions: reactions[r['id']] ?? const {},
          votes: votes[r['id']] ?? const [],
          quote: quotes[r['reponse_a_id']],
          posts: posts,
        ),
    ];
  }

  /// What a quoted message says in one line (a poll's question, a match's place…).
  String _quoteText(Map<String, Object?> q) {
    final data = q['donnees'] == null ? const {} : jsonDecode(q['donnees']! as String) as Map;
    final caption = q['contenu'] as String? ?? '';
    return switch (ChatKind.fromCode(q['type']! as String)) {
      ChatKind.poll => data['question'] as String? ?? '',
      ChatKind.match => data['lieu'] as String? ?? '',
      ChatKind.image => caption.isEmpty ? l10n.msgPhoto : caption,
      ChatKind.video => caption.isEmpty ? l10n.msgVideo : caption,
      ChatKind.voice => l10n.msgMessageVocal,
      ChatKind.offer => l10n.ofOffreX(formatDT((data['prix'] as num? ?? 0))),
      _ => caption,
    };
  }

  ChatMessage _message(
    Map<String, Object?> r,
    Map<String, ForumAuthor> members, {
    required Set<String> muted,
    required Map<String, (int, bool)> reactions,
    required List<(String, String)> votes,
    required ChatQuote? quote,
    required Map<String, Map<String, Object?>> posts,
    Map<String, String> latestOffer = const {},
  }) {
    final authorId = r['auteur_id']! as String;
    final kind = ChatKind.fromCode(r['type']! as String);
    final data = r['donnees'] == null ? const <String, Object?>{} : (jsonDecode(r['donnees']! as String) as Map).cast<String, Object?>();
    var status = ForumStatus.fromCode(r['statut']! as String);
    // A muted member's messages read as masked for the reader (FRM-05 « Ne plus voir »).
    if (muted.contains(authorId) && status == ForumStatus.published) status = ForumStatus.hidden;
    final mine = _isMe(authorId);

    ChatPoll? poll;
    ChatMatch? match;
    ChatSharedPost? shared;
    ChatMedia? media;
    ChatOffer? offer;
    if (kind == ChatKind.offer) {
      final postId = data['sujet_id']! as String;
      final post = posts[postId] ?? const {};
      final a = post['annonce'] as Map<String, Object?>?;
      final answer = votes.where((v) => v.$1 != authorId).firstOrNull?.$2;
      final images = post['images'] == null ? const [] : jsonDecode(post['images']! as String) as List;
      offer = ChatOffer(
        postId: postId,
        title: post['titre'] as String? ?? l10n.msgDiscussionSupprimee,
        price: (data['prix']! as num).toDouble(),
        asking: (a?['prix'] as num?)?.toDouble(),
        image: images.whereType<String>().where((s) => !s.startsWith('data:video/')).firstOrNull,
        sold: a?['statut'] == 'vendu',
        sellerId: post['auteur_id'] as String?,
        status: switch (answer) {
          'accepte' => OfferStatus.accepted,
          'refuse' => OfferStatus.declined,
          _ when latestOffer['${r['conversation_id']}|$postId'] != r['id'] => OfferStatus.replaced,
          _ => OfferStatus.pending,
        },
      );
    } else if (kind == ChatKind.image || kind == ChatKind.video || kind == ChatKind.voice) {
      final ms = data['duree'] as int?;
      media = ChatMedia(data['src']! as String, duration: ms == null ? null : Duration(milliseconds: ms));
    } else if (kind == ChatKind.poll) {
      final options = [for (final o in data['options']! as List) o as String];
      poll = ChatPoll(
        question: data['question']! as String,
        options: [
          for (final (i, o) in options.indexed)
            ChatPollOption(o, [for (final (who, choice) in votes) if (choice == '$i') _author(members, who)]),
        ],
        myChoice: int.tryParse(votes.where((v) => _isMe(v.$1)).firstOrNull?.$2 ?? ''),
      );
    } else if (kind == ChatKind.match) {
      final mineVote = votes.where((v) => _isMe(v.$1)).firstOrNull?.$2;
      match = ChatMatch(
        sport: MuSport.values.firstWhere((s) => s.name == data['sport'], orElse: () => MuSport.football),
        place: data['lieu']! as String,
        at: DateTime.parse(data['le']! as String),
        going: [for (final (who, c) in votes) if (c == 'oui') _author(members, who)],
        notGoing: [for (final (who, c) in votes) if (c == 'non') _author(members, who)],
        myAnswer: mineVote == null ? null : mineVote == 'oui',
      );
    } else if (kind == ChatKind.share) {
      final postId = data['sujet_id']! as String;
      final post = posts[postId] ?? const {};
      final gone = post.isEmpty || post['statut'] == ForumStatus.deleted.code;
      final a = post['annonce'] as Map<String, Object?>?;
      final images = post['images'] == null ? const [] : jsonDecode(post['images']! as String) as List;
      shared = ChatSharedPost(
        postId: postId,
        title: gone ? l10n.msgDiscussionSupprimee : post['titre']! as String,
        category: gone ? null : ForumCategory.fromCode(post['categorie']! as String),
        sport: MuSport.values.where((s) => s.name == post['sport']).firstOrNull,
        listing: a == null
            ? null
            : ForumListing(
                price: (a['prix']! as num).toDouble(),
                condition: ListingCondition.fromCode(a['etat'] as String?),
                size: a['taille'] as String?,
                city: a['ville'] as String?,
                sold: a['statut'] == 'vendu',
              ),
        image: gone ? null : images.whereType<String>().where((s) => !s.startsWith('data:video/')).firstOrNull,
      );
    }

    return ChatMessage(
      id: r['id']! as String,
      conversationId: r['conversation_id']! as String,
      author: _author(members, authorId),
      kind: kind,
      body: status == ForumStatus.deleted || (status == ForumStatus.hidden && !mine) ? '' : r['contenu']! as String,
      mine: mine,
      status: status,
      quote: quote,
      reactions: [for (final e in reactions.entries) ChatReaction(e.key, e.value.$1, mine: e.value.$2)],
      poll: poll,
      match: match,
      shared: shared,
      media: media,
      offer: offer,
      event: kind == ChatKind.system ? ChatEvent.fromCode(data['action'] as String?) : null,
      eventName: data['nom'] as String?,
      createdAt: DateTime.parse(r['cree_le']! as String),
      editedAt: r['modifie_le'] == null ? null : DateTime.parse(r['modifie_le']! as String),
    );
  }

  Future<ChatMessage> _insert(String conversationId, Map<String, Object?> values) async {
    final db = await _db;
    await _participation(db, conversationId);
    final id = newForumId();
    await db.transaction((txn) async {
      await _ensureMe(txn);
      await txn.insert('msg_messages', {
        'id': id,
        'conversation_id': conversationId,
        'auteur_id': meId,
        'cree_le': await _stamp(txn, conversationId),
        ...values,
      });
      // Writing in a private conversation the other member had left brings it back for them
      // (someone who left a group stays out).
      await txn.rawUpdate(
        'UPDATE msg_participants SET quitte_le = NULL WHERE conversation_id = ? '
        "AND (SELECT type FROM msg_conversations WHERE id = ?) = 'direct'",
        [conversationId, conversationId],
      );
    });
    await markRead(conversationId);
    final rows = await db.query('msg_messages', where: 'id = ?', whereArgs: [id]);
    return (await _messages(db, rows, await _members(db))).single;
  }

  @override
  Future<ChatMessage> send(String conversationId, String text, {String? replyToId, bool confirmed = false}) async {
    final body = text.trim();
    if (body.isEmpty) throw ForumRuleException(l10n.msgEcrisUnMessage);
    if (body.length > maxLength) throw ForumRuleException(l10n.forumRetireNCaracteres(body.length - maxLength));
    final analysis = ForumAi.analyze(body);
    if (analysis.alert && !confirmed) throw ForumAlertException(analysis);
    if (replyToId != null) {
      final db = await _db;
      final q = (await db.query('msg_messages', where: 'id = ? AND conversation_id = ?', whereArgs: [replyToId, conversationId])).firstOrNull;
      if (q == null) replyToId = null;
    }
    return _insert(conversationId, {
      'type': ChatKind.text.code,
      'contenu': body,
      'reponse_a_id': replyToId,
      'statut': analysis.alert ? ForumStatus.hidden.code : ForumStatus.published.code,
      'score_ia': analysis.score,
    });
  }

  @override
  Future<ChatMessage> sendMedia(String conversationId, String src, {String caption = ''}) async {
    final text = caption.trim();
    final analysis = text.isEmpty ? null : ForumAi.analyze(text);
    if (analysis != null && analysis.alert) throw ForumAlertException(analysis);
    return _insert(conversationId, {
      'type': src.startsWith('data:video/') ? ChatKind.video.code : ChatKind.image.code,
      'contenu': text,
      'donnees': jsonEncode({'src': src}),
    });
  }

  @override
  Future<ChatMessage> sendVoice(String conversationId, String src, Duration duration) => _insert(conversationId, {
    'type': ChatKind.voice.code,
    'donnees': jsonEncode({'src': src, 'duree': duration.inMilliseconds}),
  });

  @override
  Future<ChatMessage> sendOffer(String conversationId, String postId, double price) async {
    if (price <= 0) throw ForumRuleException(l10n.ofIndiqueUnPrix);
    final db = await _db;
    final listing = (await db.query('forum_annonces', where: 'sujet_id = ?', whereArgs: [postId])).firstOrNull;
    if (listing == null) throw ForumRuleException(l10n.msgDiscussionSupprimee);
    if (listing['statut'] == 'vendu') throw ForumRuleException(l10n.mktCetArticleEstVendu);
    return _insert(conversationId, {
      'type': ChatKind.offer.code,
      'donnees': jsonEncode({'sujet_id': postId, 'prix': price}),
    });
  }

  @override
  Future<void> answerOffer(String messageId, {required bool accept}) async {
    final db = await _db;
    final row = await _row(db, messageId);
    if (row['type'] != ChatKind.offer.code) return;
    if (_isMe(row['auteur_id']! as String)) throw ForumRuleException(l10n.ofPasTaPropreOffre);
    final answered = (await db.query('msg_votes', where: 'message_id = ?', whereArgs: [messageId])).any((v) => v['auteur_id'] != row['auteur_id']);
    if (answered) throw ForumRuleException(l10n.ofDejaRepondu);
    await db.insert('msg_votes', {
      'id': newForumId(),
      'message_id': messageId,
      'auteur_id': meId,
      'choix': accept ? 'accepte' : 'refuse',
      'cree_le': _now().toIso8601String(),
    });
  }

  @override
  Future<ChatMessage> sendPoll(String conversationId, String question, List<String> options) async {
    final q = question.trim();
    final answers = [for (final o in options) if (o.trim().isNotEmpty) o.trim()];
    if (q.isEmpty || answers.length < 2 || answers.length > maxPollOptions) throw ForumRuleException(l10n.msgSondageIncomplet);
    final analysis = ForumAi.analyze([q, ...answers].join('\n'));
    if (analysis.alert) throw ForumAlertException(analysis);
    return _insert(conversationId, {
      'type': ChatKind.poll.code,
      'donnees': jsonEncode({'question': q, 'options': answers}),
    });
  }

  @override
  Future<ChatMessage> sendMatch(String conversationId, ChatMatchDraft draft) async {
    final place = draft.place.trim();
    if (place.isEmpty) throw ForumRuleException(l10n.msgIndiqueLeLieu);
    final message = await _insert(conversationId, {
      'type': ChatKind.match.code,
      'donnees': jsonEncode({'sport': draft.sport.name, 'lieu': place, 'le': draft.at.toIso8601String()}),
    });
    // Whoever proposes comes.
    await vote(message.id, 'oui');
    return message;
  }

  @override
  Future<ChatMessage> sharePost(String conversationId, String postId) async {
    final db = await _db;
    final post = (await db.query('forum_sujets', where: 'id = ?', whereArgs: [postId])).firstOrNull;
    if (post == null) throw ForumRuleException(l10n.msgDiscussionSupprimee);
    return _insert(conversationId, {
      'type': ChatKind.share.code,
      'donnees': jsonEncode({'sujet_id': postId}),
    });
  }

  Future<Map<String, Object?>> _row(DatabaseExecutor db, String messageId) async {
    final row = (await db.query('msg_messages', where: 'id = ?', whereArgs: [messageId])).firstOrNull;
    if (row == null) throw ForumRuleException(l10n.msgMessageIntrouvable);
    await _participation(db, row['conversation_id']! as String);
    return row;
  }

  @override
  Future<void> vote(String messageId, String choice) async {
    final db = await _db;
    final row = await _row(db, messageId);
    final kind = ChatKind.fromCode(row['type']! as String);
    if (kind != ChatKind.poll && kind != ChatKind.match) return;
    final mine = (await db.query('msg_votes', where: 'message_id = ? AND auteur_id = ?', whereArgs: [messageId, meId])).firstOrNull;
    if (mine == null) {
      await db.insert('msg_votes', {'id': newForumId(), 'message_id': messageId, 'auteur_id': meId, 'choix': choice, 'cree_le': _now().toIso8601String()});
    } else if (mine['choix'] == choice) {
      await db.delete('msg_votes', where: 'id = ?', whereArgs: [mine['id']]);
    } else {
      await db.update('msg_votes', {'choix': choice}, where: 'id = ?', whereArgs: [mine['id']]);
    }
  }

  @override
  Future<void> react(String messageId, String emoji) async {
    final db = await _db;
    await _row(db, messageId);
    final removed = await db.delete(
      'msg_reactions',
      where: 'message_id = ? AND auteur_id = ? AND emoji = ?',
      whereArgs: [messageId, meId, emoji],
    );
    if (removed == 0) {
      await db.insert('msg_reactions', {
        'id': newForumId(),
        'message_id': messageId,
        'auteur_id': meId,
        'emoji': emoji,
        'cree_le': _now().toIso8601String(),
      });
    }
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    final db = await _db;
    final row = await _row(db, messageId);
    if (row['auteur_id'] != meId) throw ForumRuleException(l10n.msgSeulementTesMessages);
    await db.update(
      'msg_messages',
      {'statut': ForumStatus.deleted.code, 'contenu': '', 'modifie_le': _now().toIso8601String()},
      where: 'id = ? AND auteur_id = ?',
      whereArgs: [messageId, meId],
    );
  }

  @override
  Future<void> report(String messageId, ReportReason reason, {String? details, bool muteAuthor = false}) async {
    final db = await _db;
    final row = await _row(db, messageId);
    final author = row['auteur_id']! as String;
    if (_isMe(author)) throw ForumRuleException(l10n.forumPasTonPropreMessage);
    await db.transaction((txn) async {
      final values = {'motif': reason.code, 'details': details, 'statut': 'ouvert', 'cree_le': _now().toIso8601String()};
      final updated = await txn.update(
        'forum_signalements',
        values,
        where: "auteur_id = ? AND cible = 'message_prive' AND cible_id = ?",
        whereArgs: [meId, messageId],
      );
      if (updated == 0) {
        await txn.insert('forum_signalements', {'id': newForumId(), 'auteur_id': meId, 'cible': 'message_prive', 'cible_id': messageId, ...values});
      }
      if (muteAuthor) {
        await txn.insert('forum_blocages', {'utilisateur_id': meId, 'bloque_id': author}, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    });
  }

  // ── The story's friends answer (demo only) ────────────────────────────────────────────────

  /// A demo seller accepts an offer from 85 % of the price, else counters halfway (rounded to
  /// 5 DT); a demo buyer accepts the reader's counter-offer.
  Future<bool> _demoOffer(DatabaseExecutor db, Map<String, Object?> offer, List<String> demo) async {
    final data = jsonDecode(offer['donnees']! as String) as Map;
    final postId = data['sujet_id'] as String;
    final price = (data['prix'] as num).toDouble();
    final post = (await db.query('forum_sujets', where: 'id = ?', whereArgs: [postId])).firstOrNull;
    final listing = (await db.query('forum_annonces', where: 'sujet_id = ?', whereArgs: [postId])).firstOrNull;
    if (post == null || listing == null) return false;
    final seller = post['auteur_id']! as String;
    final other = demo.first;
    final now = await _stamp(db, offer['conversation_id']! as String);
    Future<void> answer(String choice) => db.insert('msg_votes', {
      'id': newForumId(),
      'message_id': offer['id'],
      'auteur_id': other,
      'choix': choice,
      'cree_le': now,
    });
    if (seller != other) {
      // The reader sells, the demo friend bought: they take the counter-offer.
      await answer('accepte');
      return true;
    }
    final asking = (listing['prix']! as num).toDouble();
    if (price >= asking * acceptShare) {
      await answer('accepte');
      return true;
    }
    final counter = ((price + asking) / 2 / counterStep).round() * counterStep;
    await db.insert('msg_messages', {
      'id': newForumId(),
      'conversation_id': offer['conversation_id'],
      'auteur_id': other,
      'type': ChatKind.offer.code,
      'donnees': jsonEncode({'sujet_id': postId, 'prix': counter}),
      'cree_le': now,
    });
    return true;
  }

  /// Demo sellers take offers from this share of their price.
  static const double acceptShare = 0.85;

  /// Counter-offers are rounded to 5 DT.
  static const double counterStep = 5;

  @override
  Future<bool> demoAnswer(String conversationId) async {
    final db = await _db;
    final muted = await _muted(db);
    final people = [
      for (final p in await db.query('msg_participants', where: 'conversation_id = ? AND quitte_le IS NULL', whereArgs: [conversationId]))
        p['membre_id']! as String,
    ];
    // Only the story's people answer by themselves; a real member answers from their phone.
    final demo = [for (final id in people) if (_demo(id) && !_isMe(id) && !muted.contains(id)) id];
    if (demo.isEmpty) return false;
    final last = (await db.query('msg_messages', where: 'conversation_id = ?', whereArgs: [conversationId], orderBy: 'cree_le DESC, rowid DESC', limit: 1))
        .firstOrNull;
    if (last == null || !_isMe(last['auteur_id']! as String) || last['statut'] != ForumStatus.published.code) return false;
    final random = math.Random(last['id'].hashCode);
    final kind = ChatKind.fromCode(last['type']! as String);
    final now = _now().toIso8601String();

    if (kind == ChatKind.poll || kind == ChatKind.match) {
      final options = kind == ChatKind.poll ? ((jsonDecode(last['donnees']! as String) as Map)['options']! as List).length : 2;
      final voted = {for (final v in await db.query('msg_votes', where: 'message_id = ?', whereArgs: [last['id']])) v['auteur_id']};
      final voters = [for (final id in demo) if (!voted.contains(id)) id]..shuffle(random);
      if (voters.isEmpty) return false;
      final batch = db.batch();
      for (final id in voters.take(math.max(1, (voters.length * 2 / 3).ceil()))) {
        // A match finds takers: 3 friends out of 4 come.
        final choice = kind == ChatKind.poll ? '${random.nextInt(options)}' : (random.nextInt(4) == 0 ? 'non' : 'oui');
        batch.insert('msg_votes', {'id': newForumId(), 'message_id': last['id'], 'auteur_id': id, 'choix': choice, 'cree_le': now});
      }
      await batch.commit(noResult: true);
      return true;
    }
    if (kind == ChatKind.system) return false;

    if (kind == ChatKind.offer) return _demoOffer(db, last, demo);

    final who = demo[random.nextInt(demo.length)];
    final text = (last['contenu'] as String? ?? '').toLowerCase();
    final lines = switch (kind) {
      ChatKind.share => MessagesSeed.answersToShare,
      ChatKind.image || ChatKind.video => MessagesSeed.answersToMedia,
      ChatKind.voice => MessagesSeed.answersToVoice,
      _ when text.contains('?') => MessagesSeed.answersToQuestion,
      _ => MessagesSeed.answers,
    };
    await db.insert('msg_messages', {
      'id': newForumId(),
      'conversation_id': conversationId,
      'auteur_id': who,
      'type': ChatKind.text.code,
      'contenu': lines[random.nextInt(lines.length)],
      'cree_le': await _stamp(db, conversationId),
    });
    return true;
  }
}
