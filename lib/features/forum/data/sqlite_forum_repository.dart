import 'dart:convert';
import 'dart:math' as math;

import 'package:sqflite/sqflite.dart';

import '../../../core/connectivity.dart';
import '../../../core/db/app_database.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/theme.dart';
import 'forum_ai.dart';
import 'forum_repository.dart';
import 'forum_seed.dart';
import 'forum_text.dart';

/// [ForumRepository] on the phone's database (schema v3, `forum_*` tables), applying the same
/// rules as the backend's forum module: what each reader sees, counters recounted after each
/// change, the FRM-03 alert, 3 reports hide a content, suspended members cannot write.
class SqliteForumRepository implements ForumRepository {
  SqliteForumRepository(this._database, {required this._now, bool Function()? offline, this.meId = ForumSeed.me})
    : _offline = offline ?? (() => false);

  final AppDatabase _database;
  final DateTime Function() _now;
  final bool Function() _offline;

  /// The member using the app.
  final int meId;

  static const _draftKey = 'forum_nouveau_post';
  static const _reportsToHide = 3;
  static const _pageMax = 50;

  Future<Database> get _db async {
    if (_offline()) throw const OfflineException();
    return _database.db;
  }

  String get _nowIso => _now().toIso8601String();

  // ── Reading helpers ───────────────────────────────────────────────────────────────────────

  Future<Map<int, ForumAuthor>> _members(DatabaseExecutor db) async => {
    for (final r in await db.query('forum_membres'))
      r['id']! as int: ForumAuthor(
        id: r['id']! as int,
        name: r['nom']! as String,
        handle: r['pseudo'] as String?,
        level: (r['niveau'] as num?)?.toDouble(),
        sport: MuSport.values.where((s) => s.name == r['sport']).firstOrNull,
      ),
  };

  static ForumAuthor _unknown(int id) => ForumAuthor(id: id, name: l10n.forumMembre);

  Future<Set<int>> _blocked(DatabaseExecutor db) async => {
    for (final r in await db.query('forum_blocages', columns: ['bloque_id'], where: 'utilisateur_id = ?', whereArgs: [meId]))
      r['bloque_id']! as int,
  };

  /// The reader's votes, reactions and reports on [ids].
  Future<Map<int, ForumMine>> _mine(DatabaseExecutor db, ForumTarget target, List<int> ids, Map<int, int> authors) async {
    final out = {for (final id in ids) id: ForumMine(author: authors[id] == meId)};
    if (ids.isEmpty) return out;
    final marks = List.filled(ids.length, '?').join(',');
    final args = [meId, target.code, ...ids];
    for (final r in await db.rawQuery(
      'SELECT cible_id, valeur FROM forum_votes WHERE utilisateur_id = ? AND cible = ? AND cible_id IN ($marks)',
      args,
    )) {
      final id = r['cible_id']! as int;
      out[id] = out[id]!.copyWith(vote: r['valeur']! as int);
    }
    for (final r in await db.rawQuery(
      'SELECT cible_id, type FROM forum_reactions WHERE utilisateur_id = ? AND cible = ? AND cible_id IN ($marks)',
      args,
    )) {
      final id = r['cible_id']! as int;
      out[id] = r['type'] == ForumReaction.useful.code ? out[id]!.copyWith(useful: true) : out[id]!.copyWith(thanks: true);
    }
    for (final r in await db.rawQuery(
      "SELECT cible_id FROM forum_signalements WHERE signaleur_id = ? AND cible = ? AND statut = 'ouvert' AND cible_id IN ($marks)",
      args,
    )) {
      final id = r['cible_id']! as int;
      out[id] = out[id]!.copyWith(reported: true);
    }
    return out;
  }

  static List<String> _list(Object? json) => [for (final v in jsonDecode(json as String? ?? '[]') as List) v as String];

  Future<List<ForumPost>> _posts(DatabaseExecutor db, List<Map<String, Object?>> rows, {bool full = false}) async {
    if (rows.isEmpty) return const [];
    final members = await _members(db);
    final ids = [for (final r in rows) r['id']! as int];
    final authors = {for (final r in rows) r['id']! as int: r['auteur_id']! as int};
    final mine = await _mine(db, ForumTarget.post, ids, authors);
    final marks = List.filled(ids.length, '?').join(',');
    final saved = {
      for (final r in await db.rawQuery('SELECT sujet_id FROM forum_favoris WHERE utilisateur_id = ? AND sujet_id IN ($marks)', [
        meId,
        ...ids,
      ]))
        r['sujet_id']! as int,
    };
    final followed = {
      for (final r in await db.rawQuery(
        "SELECT cible_id FROM forum_suivis WHERE utilisateur_id = ? AND type = 'sujet' AND cible_id IN ($marks)",
        [meId, ...ids],
      ))
        r['cible_id']! as int,
    };
    final me = members[meId];
    return [
      for (final r in rows)
        () {
          final id = r['id']! as int;
          final author = r['auteur_id']! as int;
          final status = ForumStatus.fromCode(r['statut']! as String);
          final hiddenForMe = status == ForumStatus.hidden && author != meId;
          final body = r['contenu']! as String;
          return ForumPost(
            id: id,
            author: members[author] ?? _unknown(author),
            title: r['titre']! as String,
            body: full && !hiddenForMe ? body : null,
            excerpt: hiddenForMe ? null : ForumText.excerpt(body),
            category: ForumCategory.fromCode(r['categorie']! as String),
            sport: MuSport.values.where((s) => s.name == r['sport']).firstOrNull,
            tags: _list(r['tags']),
            images: hiddenForMe ? const [] : _list(r['images']),
            pinned: r['epingle'] == 1,
            status: status,
            bestAnswerId: r['meilleure_reponse_id'] as int?,
            score: r['score']! as int,
            replies: r['nb_reponses']! as int,
            useful: r['nb_utile']! as int,
            thanks: r['nb_merci']! as int,
            mentionsMe: me?.handle != null && author != meId && _list(r['mentions']).contains(me!.handle),
            createdAt: DateTime.parse(r['cree_le']! as String),
            editedAt: r['modifie_le'] == null ? null : DateTime.parse(r['modifie_le']! as String),
            lastActivity: DateTime.parse(r['derniere_activite']! as String),
            mine: mine[id]!.copyWith(saved: saved.contains(id), following: followed.contains(id)),
          );
        }(),
    ];
  }

  /// « Tendance »: (score + 2 × replies + reactions + 1) / (hours since last activity + 2)^1.3.
  double _trend(Map<String, Object?> r) {
    final hours = _now().difference(DateTime.parse(r['derniere_activite']! as String)).inMinutes / 60;
    final weight = (r['score']! as int) + 2 * (r['nb_reponses']! as int) + (r['nb_utile']! as int) + (r['nb_merci']! as int) + 1;
    return weight / math.pow(math.max(0, hours) + 2, 1.3);
  }

  // ── FRM-01 ────────────────────────────────────────────────────────────────────────────────

  @override
  Future<ForumAuthor> me() async {
    final db = await _db;
    return (await _members(db))[meId] ?? _unknown(meId);
  }

  @override
  Future<ForumFeed> feed(ForumQuery query, {int limit = 20, int offset = 0}) async {
    final db = await _db;
    final where = <String>["(statut = 'publie' OR (statut = 'masque' AND auteur_id = ?))"];
    final args = <Object?>[meId];
    final blocked = await _blocked(db);
    if (blocked.isNotEmpty) {
      where.add('auteur_id NOT IN (${List.filled(blocked.length, '?').join(',')})');
      args.addAll(blocked);
    }
    if (query.category != null) {
      where.add('categorie = ?');
      args.add(query.category!.code);
    }
    if (query.sport != null) {
      where.add('sport = ?');
      args.add(query.sport!.name);
    }
    if (query.authorId != null) {
      where.add('auteur_id = ?');
      args.add(query.authorId);
    }
    if (query.tag != null) {
      where.add('LOWER(tags) LIKE ?');
      args.add('%"${query.tag!.replaceFirst('#', '').toLowerCase()}"%');
    }
    final search = query.search?.trim();
    if (search != null && search.isNotEmpty) {
      where.add('(titre LIKE ? OR contenu LIKE ? OR tags LIKE ?)');
      args.addAll(List.filled(3, '%$search%'));
    }
    if (query.savedOnly) {
      where.add('id IN (SELECT sujet_id FROM forum_favoris WHERE utilisateur_id = ?)');
      args.add(meId);
    }
    final rows = [...await db.query('forum_sujets', where: where.join(' AND '), whereArgs: args)];
    int created(Map<String, Object?> r) => DateTime.parse(r['cree_le']! as String).millisecondsSinceEpoch;
    rows.sort((a, b) {
      final pin = (b['epingle']! as int).compareTo(a['epingle']! as int);
      if (pin != 0) return pin;
      final byMode = switch (query.sort) {
        ForumSort.trending => _trend(b).compareTo(_trend(a)),
        ForumSort.top =>
          (b['score']! as int).compareTo(a['score']! as int) != 0
              ? (b['score']! as int).compareTo(a['score']! as int)
              : (b['nb_reponses']! as int).compareTo(a['nb_reponses']! as int),
        ForumSort.recent => 0,
      };
      return byMode != 0 ? byMode : created(b).compareTo(created(a));
    });
    final page = rows.skip(offset).take(math.min(limit, _pageMax)).toList();
    return ForumFeed(total: rows.length, posts: await _posts(db, page));
  }

  @override
  Future<List<ForumCategoryCount>> categories({MuSport? sport}) async {
    final db = await _db;
    final visit = (await db.query('forum_visites', where: 'utilisateur_id = ?', whereArgs: [meId])).firstOrNull;
    final since = visit?['derniere_visite'] as String?;
    final rows = await db.rawQuery(
      '''
      SELECT categorie, COUNT(*) AS n,
        SUM(CASE WHEN ? IS NOT NULL AND cree_le > ? AND auteur_id <> ? THEN 1 ELSE 0 END) AS nouveaux
      FROM forum_sujets WHERE statut = 'publie' ${sport != null ? 'AND sport = ?' : ''}
      GROUP BY categorie''',
      [since, since, meId, if (sport != null) sport.name],
    );
    return [
      for (final c in ForumCategory.values)
        () {
          final r = rows.where((r) => r['categorie'] == c.code).firstOrNull;
          return ForumCategoryCount(category: c, posts: (r?['n'] as int?) ?? 0, fresh: (r?['nouveaux'] as int?) ?? 0);
        }(),
    ];
  }

  @override
  Future<void> markVisited() async {
    final db = await _db;
    await db.insert('forum_visites', {'utilisateur_id': meId, 'derniere_visite': _nowIso}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ── FRM-04 ────────────────────────────────────────────────────────────────────────────────

  @override
  Future<ForumThread> thread(int postId, {ReplySort sort = ReplySort.useful}) async {
    final db = await _db;
    final row = (await db.query('forum_sujets', where: 'id = ?', whereArgs: [postId])).firstOrNull;
    if (row == null || row['statut'] == ForumStatus.deleted.code) throw ForumRuleException(l10n.forumDiscussionSupprimee);
    final post = (await _posts(db, [row], full: true)).single;

    final members = await _members(db);
    final blocked = await _blocked(db);
    final rows = await db.query('forum_messages', where: 'sujet_id = ?', whereArgs: [postId], orderBy: 'cree_le, id');
    final mine = await _mine(
      db,
      ForumTarget.reply,
      [for (final r in rows) r['id']! as int],
      {for (final r in rows) r['id']! as int: r['auteur_id']! as int},
    );

    ForumReply view(Map<String, Object?> r, List<ForumReply> children) {
      final id = r['id']! as int;
      final author = r['auteur_id']! as int;
      final status = ForumStatus.fromCode(r['statut']! as String);
      final isBlocked = blocked.contains(author);
      final hiddenForMe = status == ForumStatus.hidden && author != meId;
      final answering = r['en_reponse_a_id'] as int?;
      return ForumReply(
        id: id,
        postId: postId,
        parentId: r['parent_id'] as int?,
        author: members[author] ?? _unknown(author),
        // A direct reply answers the post's author (« Ta réponse à Skander T. »).
        answering: answering != null ? members[answering] : (r['parent_id'] == null ? post.author : null),
        body: status == ForumStatus.deleted || hiddenForMe || isBlocked ? null : r['contenu']! as String,
        status: status,
        blocked: isBlocked,
        byPostAuthor: author == post.author.id,
        best: id == post.bestAnswerId,
        score: r['score']! as int,
        useful: r['nb_utile']! as int,
        thanks: r['nb_merci']! as int,
        createdAt: DateTime.parse(r['cree_le']! as String),
        editedAt: r['modifie_le'] == null ? null : DateTime.parse(r['modifie_le']! as String),
        mine: mine[id]!,
        children: children,
      );
    }

    // Deleted replies and blocked authors stay only as placeholders for their answers.
    bool keep(ForumReply r) => !(r.deleted || r.blocked) || r.children.isNotEmpty;
    final childrenOf = <int, List<ForumReply>>{};
    for (final r in rows) {
      final parent = r['parent_id'] as int?;
      if (parent == null) continue;
      final v = view(r, const []);
      if (keep(v)) childrenOf.putIfAbsent(parent, () => []).add(v);
    }
    final level1 = [
      for (final r in rows)
        if (r['parent_id'] == null) view(r, childrenOf[r['id']! as int] ?? const []),
    ].where(keep).toList();

    int weight(ForumReply r) => r.score + r.useful;
    switch (sort) {
      case ReplySort.useful:
        level1.sort((a, b) => weight(b) != weight(a) ? weight(b).compareTo(weight(a)) : a.createdAt.compareTo(b.createdAt));
      case ReplySort.newest:
        level1.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case ReplySort.oldest:
        break;
    }
    final best = level1.where((r) => r.best && r.status == ForumStatus.published).firstOrNull;
    return ForumThread(
      post: post,
      bestAnswer: best,
      replies: [
        for (final r in level1)
          if (r != best) r,
      ],
      sort: sort,
    );
  }

  // ── FRM-02 ────────────────────────────────────────────────────────────────────────────────

  @override
  Future<List<SimilarPost>> similar(String title, {MuSport? sport, List<String> tags = const [], int? exclude}) async {
    final db = await _db;
    if (ForumAi.keywords(title).where((w) => w.length > 3).isEmpty) return const [];
    final rows = await db.query('forum_sujets', where: "statut = 'publie'${exclude != null ? ' AND id <> ?' : ''}", whereArgs: [?exclude]);
    final posts = await _posts(db, rows);
    final bodies = {for (final r in rows) r['id']! as int: r['contenu']! as String};
    final scored =
        [
            for (final p in posts)
              SimilarPost(
                post: p,
                similarity: ForumAi.similarity(title, sport: sport?.name, tags: tags, candidate: p, candidateBody: bodies[p.id]),
              ),
          ].where((s) => s.similarity >= 0.25).toList()
          ..sort((a, b) => b.similarity != a.similarity ? b.similarity.compareTo(a.similarity) : b.post.score.compareTo(a.post.score));
    return scored.take(3).toList();
  }

  @override
  Future<List<TagSuggestion>> suggestTags(String title, String body, List<String> tags) async =>
      ForumAi.suggestTags(title, ForumText.plain(body), tags);

  @override
  Future<ModerationAnalysis> analyze(String text) async => ForumAi.analyze(text);

  Future<void> _checkCanWrite(DatabaseExecutor db) async {
    final until = await _suspension(db);
    if (until != null) throw ForumSuspendedException(until);
  }

  Future<DateTime?> _suspension(DatabaseExecutor db) async {
    final r = (await db.query(
      'forum_sanctions',
      where: "utilisateur_id = ? AND type = 'suspension' AND jusqua > ?",
      whereArgs: [meId, _nowIso],
      orderBy: 'jusqua DESC',
      limit: 1,
    )).firstOrNull;
    return r == null ? null : DateTime.parse(r['jusqua']! as String);
  }

  /// The FRM-03 check: throws on the first try above the threshold; with [confirmed] the text is
  /// published masked and reported by the AI.
  ModerationAnalysis _control(String text, bool confirmed) {
    final a = ForumAi.analyze(text);
    if (a.alert && !confirmed) throw ForumAlertException(a);
    return a;
  }

  Future<void> _reportByAi(DatabaseExecutor db, ForumTarget target, int id, ModerationAnalysis a) => db.insert('forum_signalements', {
    'cible': target.code,
    'cible_id': id,
    'signaleur_id': null,
    'motif': a.reason == l10n.forumIaSpamContact || a.reason == l10n.forumIaSpamPub ? ReportReason.spam.code : ReportReason.insult.code,
    'details': 'IA · ${a.reason} · ${a.score}',
    'cree_le': _nowIso,
  });

  Future<ForumPost> _post(DatabaseExecutor db, int id) async =>
      (await _posts(db, await db.query('forum_sujets', where: 'id = ?', whereArgs: [id]), full: true)).single;

  @override
  Future<ForumPost> publish(PostDraft draft, {bool confirmed = false}) async {
    final db = await _db;
    await _checkCanWrite(db);
    final title = draft.title.trim();
    final body = draft.body.trim();
    if (title.length < 10) throw ForumRuleException(l10n.forumTitreTropCourt);
    if (body.isEmpty) throw ForumRuleException(l10n.forumMessageVide);
    final a = _control('$title\n$body', confirmed);
    return db.transaction((txn) async {
      final id = await txn.insert('forum_sujets', {
        'auteur_id': meId,
        'titre': title,
        'contenu': body,
        'categorie': draft.category.code,
        'sport': draft.sport?.name,
        'tags': jsonEncode(ForumAi.cleanTags(draft.tags)),
        'images': jsonEncode(draft.images.take(4).toList()),
        'mentions': jsonEncode(ForumAi.mentions(body)),
        'statut': a.alert ? ForumStatus.hidden.code : ForumStatus.published.code,
        'publie_malgre_alerte': a.alert ? 1 : 0,
        'score_ia': a.score,
        'motif_ia': a.score >= 0.15 ? a.reason : null,
        'derniere_activite': _nowIso,
        'cree_le': _nowIso,
      });
      if (a.alert) await _reportByAi(txn, ForumTarget.post, id, a);
      await txn.insert('forum_suivis', {
        'utilisateur_id': meId,
        'type': 'sujet',
        'cible_id': id,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      return _post(txn, id);
    });
  }

  @override
  Future<ForumPost> editPost(int postId, PostDraft draft, {bool confirmed = false}) async {
    final db = await _db;
    final row = await _row(db, ForumTarget.post, postId);
    if (row['auteur_id'] != meId) throw ForumRuleException(l10n.forumSeulLAuteur);
    await _checkCanWrite(db);
    final title = draft.title.trim();
    final body = draft.body.trim();
    if (title.length < 10) throw ForumRuleException(l10n.forumTitreTropCourt);
    final a = _control('$title\n$body', confirmed);
    final hide = a.alert && row['statut'] == ForumStatus.published.code;
    await db.update(
      'forum_sujets',
      {
        'titre': title,
        'contenu': body,
        'categorie': draft.category.code,
        'sport': draft.sport?.name,
        'tags': jsonEncode(ForumAi.cleanTags(draft.tags)),
        'images': jsonEncode(draft.images.take(4).toList()),
        'mentions': jsonEncode(ForumAi.mentions(body)),
        'score_ia': a.score,
        'motif_ia': a.score >= 0.15 ? a.reason : null,
        'modifie_le': _nowIso,
        if (hide) 'statut': ForumStatus.hidden.code,
        if (hide) 'publie_malgre_alerte': 1,
      },
      where: 'id = ?',
      whereArgs: [postId],
    );
    if (hide) await _reportByAi(db, ForumTarget.post, postId, a);
    return _post(db, postId);
  }

  @override
  Future<void> deletePost(int postId) async {
    final db = await _db;
    final row = await _row(db, ForumTarget.post, postId);
    if (row['auteur_id'] != meId) throw ForumRuleException(l10n.forumSeulLAuteur);
    await db.update('forum_sujets', {'statut': ForumStatus.deleted.code}, where: 'id = ?', whereArgs: [postId]);
  }

  // ── Replies ───────────────────────────────────────────────────────────────────────────────

  Future<Map<String, Object?>> _row(DatabaseExecutor db, ForumTarget target, int id) async {
    final r = (await db.query(
      target == ForumTarget.post ? 'forum_sujets' : 'forum_messages',
      where: 'id = ?',
      whereArgs: [id],
    )).firstOrNull;
    if (r == null || r['statut'] == ForumStatus.deleted.code) {
      throw ForumRuleException(target == ForumTarget.post ? l10n.forumDiscussionSupprimee : l10n.forumReponseSupprimee);
    }
    return r;
  }

  Future<void> _recountReplies(DatabaseExecutor db, int postId, {bool activity = false}) => db.rawUpdate(
    '''
    UPDATE forum_sujets SET nb_reponses = (SELECT COUNT(*) FROM forum_messages WHERE sujet_id = ?1 AND statut = 'publie')
    ${activity ? ', derniere_activite = ?2' : ''} WHERE id = ?1''',
    [postId, if (activity) _nowIso],
  );

  Future<ForumReply> _reply(DatabaseExecutor db, int postId, int replyId) async {
    final t = await thread(postId, sort: ReplySort.oldest);
    for (final r in [?t.bestAnswer, ...t.replies]) {
      if (r.id == replyId) return r;
      for (final c in r.children) {
        if (c.id == replyId) return c;
      }
    }
    throw ForumRuleException(l10n.forumReponseSupprimee);
  }

  @override
  Future<ForumReply> reply(int postId, String body, {int? parentId, bool confirmed = false}) async {
    final db = await _db;
    final post = await _row(db, ForumTarget.post, postId);
    if (post['statut'] == ForumStatus.hidden.code && post['auteur_id'] != meId) throw ForumRuleException(l10n.forumEnVerification);
    await _checkCanWrite(db);
    final text = body.trim();
    if (text.isEmpty) throw ForumRuleException(l10n.forumMessageVide);

    int? level1;
    int? answering;
    if (parentId != null) {
      final parent = await _row(db, ForumTarget.reply, parentId);
      level1 = (parent['parent_id'] as int?) ?? parentId;
      answering = parent['auteur_id']! as int;
    }
    final a = _control(text, confirmed);
    final id = await db.transaction((txn) async {
      final id = await txn.insert('forum_messages', {
        'sujet_id': postId,
        'parent_id': level1,
        'auteur_id': meId,
        'en_reponse_a_id': answering,
        'contenu': text,
        'mentions': jsonEncode(ForumAi.mentions(text)),
        'statut': a.alert ? ForumStatus.hidden.code : ForumStatus.published.code,
        'publie_malgre_alerte': a.alert ? 1 : 0,
        'score_ia': a.score,
        'motif_ia': a.score >= 0.15 ? a.reason : null,
        'cree_le': _nowIso,
      });
      if (a.alert) await _reportByAi(txn, ForumTarget.reply, id, a);
      await _recountReplies(txn, postId, activity: !a.alert);
      return id;
    });
    return _reply(db, postId, id);
  }

  @override
  Future<ForumReply> editReply(int replyId, String body, {bool confirmed = false}) async {
    final db = await _db;
    final row = await _row(db, ForumTarget.reply, replyId);
    if (row['auteur_id'] != meId) throw ForumRuleException(l10n.forumSeulLAuteur);
    await _checkCanWrite(db);
    final text = body.trim();
    if (text.isEmpty) throw ForumRuleException(l10n.forumMessageVide);
    final a = _control(text, confirmed);
    final hide = a.alert && row['statut'] == ForumStatus.published.code;
    await db.update(
      'forum_messages',
      {
        'contenu': text,
        'mentions': jsonEncode(ForumAi.mentions(text)),
        'score_ia': a.score,
        'motif_ia': a.score >= 0.15 ? a.reason : null,
        'modifie_le': _nowIso,
        if (hide) 'statut': ForumStatus.hidden.code,
        if (hide) 'publie_malgre_alerte': 1,
      },
      where: 'id = ?',
      whereArgs: [replyId],
    );
    final postId = row['sujet_id']! as int;
    if (hide) {
      await _reportByAi(db, ForumTarget.reply, replyId, a);
      await _recountReplies(db, postId);
    }
    return _reply(db, postId, replyId);
  }

  @override
  Future<void> deleteReply(int replyId) async {
    final db = await _db;
    final row = await _row(db, ForumTarget.reply, replyId);
    if (row['auteur_id'] != meId) throw ForumRuleException(l10n.forumSeulLAuteur);
    final postId = row['sujet_id']! as int;
    await db.transaction((txn) async {
      await txn.update('forum_messages', {'statut': ForumStatus.deleted.code}, where: 'id = ?', whereArgs: [replyId]);
      await txn.update(
        'forum_sujets',
        {'meilleure_reponse_id': null},
        where: 'id = ? AND meilleure_reponse_id = ?',
        whereArgs: [postId, replyId],
      );
      await _recountReplies(txn, postId);
    });
  }

  // ── Votes, reactions, saves, follows ──────────────────────────────────────────────────────

  String _table(ForumTarget t) => t == ForumTarget.post ? 'forum_sujets' : 'forum_messages';

  /// Not on your own content, not on a masked one, not while suspended.
  Future<void> _checkCanReact(DatabaseExecutor db, ForumTarget target, int id, String ownMessage) async {
    final row = await _row(db, target, id);
    if (row['auteur_id'] == meId) throw ForumRuleException(ownMessage);
    if (row['statut'] == ForumStatus.hidden.code) throw ForumRuleException(l10n.forumEnVerification);
    await _checkCanWrite(db);
  }

  @override
  Future<int> vote(ForumTarget target, int id, int value) async {
    final db = await _db;
    await _checkCanReact(db, target, id, l10n.forumPasDeVotePourSoi);
    return db.transaction((txn) async {
      if (value == 0) {
        await txn.delete('forum_votes', where: 'utilisateur_id = ? AND cible = ? AND cible_id = ?', whereArgs: [meId, target.code, id]);
      } else {
        await txn.insert('forum_votes', {
          'utilisateur_id': meId,
          'cible': target.code,
          'cible_id': id,
          'valeur': value.sign,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await txn.rawUpdate(
        'UPDATE ${_table(target)} SET score = (SELECT COALESCE(SUM(valeur), 0) FROM forum_votes WHERE cible = ?1 AND cible_id = ?2) WHERE id = ?2',
        [target.code, id],
      );
      final r = await txn.query(_table(target), columns: ['score'], where: 'id = ?', whereArgs: [id]);
      return r.single['score']! as int;
    });
  }

  @override
  Future<void> react(ForumTarget target, int id, ForumReaction reaction, {required bool on}) async {
    final db = await _db;
    await _checkCanReact(db, target, id, l10n.forumPasDeReactionPourSoi);
    await db.transaction((txn) async {
      if (on) {
        await txn.insert('forum_reactions', {
          'utilisateur_id': meId,
          'cible': target.code,
          'cible_id': id,
          'type': reaction.code,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      } else {
        await txn.delete(
          'forum_reactions',
          where: 'utilisateur_id = ? AND cible = ? AND cible_id = ? AND type = ?',
          whereArgs: [meId, target.code, id, reaction.code],
        );
      }
      await txn.rawUpdate(
        '''
        UPDATE ${_table(target)} SET
          nb_utile = (SELECT COUNT(*) FROM forum_reactions WHERE cible = ?1 AND cible_id = ?2 AND type = 'utile'),
          nb_merci = (SELECT COUNT(*) FROM forum_reactions WHERE cible = ?1 AND cible_id = ?2 AND type = 'merci')
        WHERE id = ?2''',
        [target.code, id],
      );
    });
  }

  @override
  Future<void> chooseBestAnswer(int postId, int? replyId) async {
    final db = await _db;
    final post = await _row(db, ForumTarget.post, postId);
    if (post['auteur_id'] != meId) throw ForumRuleException(l10n.forumSeulLAuteurChoisit);
    if (replyId != null) {
      final r = await _row(db, ForumTarget.reply, replyId);
      if (r['sujet_id'] != postId || r['parent_id'] != null || r['statut'] != ForumStatus.published.code) {
        throw ForumRuleException(l10n.forumReponseDirecte);
      }
      if (r['auteur_id'] == meId) throw ForumRuleException(l10n.forumPasTaPropreReponse);
    }
    await db.update('forum_sujets', {'meilleure_reponse_id': replyId}, where: 'id = ?', whereArgs: [postId]);
  }

  @override
  Future<void> save(int postId, {required bool on}) async {
    final db = await _db;
    await _row(db, ForumTarget.post, postId);
    if (on) {
      await db.insert('forum_favoris', {
        'utilisateur_id': meId,
        'sujet_id': postId,
        'cree_le': _nowIso,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    } else {
      await db.delete('forum_favoris', where: 'utilisateur_id = ? AND sujet_id = ?', whereArgs: [meId, postId]);
    }
  }

  Future<void> _follow(String type, int id, bool on) async {
    final db = await _db;
    if (on) {
      await db.insert('forum_suivis', {'utilisateur_id': meId, 'type': type, 'cible_id': id}, conflictAlgorithm: ConflictAlgorithm.ignore);
    } else {
      await db.delete('forum_suivis', where: 'utilisateur_id = ? AND type = ? AND cible_id = ?', whereArgs: [meId, type, id]);
    }
  }

  @override
  Future<void> follow(int postId, {required bool on}) => _follow('sujet', postId, on);

  @override
  Future<void> followMember(int memberId, {required bool on}) {
    if (memberId == meId) throw ForumRuleException(l10n.forumPasTeSuivre);
    return _follow('membre', memberId, on);
  }

  @override
  Future<bool> isFollowingMember(int memberId) async {
    final db = await _db;
    final r = await db.query('forum_suivis', where: "utilisateur_id = ? AND type = 'membre' AND cible_id = ?", whereArgs: [meId, memberId]);
    return r.isNotEmpty;
  }

  @override
  Future<void> block(int memberId, {required bool on}) async {
    final db = await _db;
    if (memberId == meId) throw ForumRuleException(l10n.forumPasTeMasquer);
    if (on) {
      await db.insert('forum_blocages', {'utilisateur_id': meId, 'bloque_id': memberId}, conflictAlgorithm: ConflictAlgorithm.ignore);
    } else {
      await db.delete('forum_blocages', where: 'utilisateur_id = ? AND bloque_id = ?', whereArgs: [meId, memberId]);
    }
  }

  // ── FRM-05 ────────────────────────────────────────────────────────────────────────────────

  @override
  Future<bool> report(ForumTarget target, int id, ReportReason reason, {String? details, bool muteAuthor = false}) async {
    final db = await _db;
    final row = await _row(db, target, id);
    final author = row['auteur_id']! as int;
    if (author == meId) throw ForumRuleException(l10n.forumPasTonPropreMessage);
    return db.transaction((txn) async {
      await txn.insert('forum_signalements', {
        'cible': target.code,
        'cible_id': id,
        'signaleur_id': meId,
        'motif': reason.code,
        'details': details,
        'statut': 'ouvert',
        'cree_le': _nowIso,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      if (muteAuthor) {
        await txn.insert('forum_blocages', {'utilisateur_id': meId, 'bloque_id': author}, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      final n =
          Sqflite.firstIntValue(
            await txn.rawQuery(
              "SELECT COUNT(*) FROM forum_signalements WHERE cible = ? AND cible_id = ? AND statut = 'ouvert' AND signaleur_id IS NOT NULL",
              [target.code, id],
            ),
          ) ??
          0;
      if (row['statut'] == ForumStatus.published.code && n >= _reportsToHide) {
        await txn.update(_table(target), {'statut': ForumStatus.hidden.code}, where: 'id = ?', whereArgs: [id]);
        if (target == ForumTarget.reply) await _recountReplies(txn, row['sujet_id']! as int);
        return true;
      }
      return row['statut'] == ForumStatus.hidden.code;
    });
  }

  @override
  Future<void> undoReport(ForumTarget target, int id) async {
    final db = await _db;
    await db.delete(
      'forum_signalements',
      where: "signaleur_id = ? AND cible = ? AND cible_id = ? AND statut = 'ouvert'",
      whereArgs: [meId, target.code, id],
    );
  }

  @override
  Future<DateTime?> suspendedUntil() async => _suspension(await _db);

  // ── Draft ─────────────────────────────────────────────────────────────────────────────────

  @override
  Future<PostDraft?> loadDraft() async {
    final db = await _db;
    final r = (await db.query('brouillons', where: 'cle = ?', whereArgs: [_draftKey])).firstOrNull;
    if (r == null) return null;
    return PostDraft.fromJson(jsonDecode(r['contenu']! as String) as Map<String, Object?>);
  }

  @override
  Future<void> saveDraft(PostDraft draft) async {
    final db = await _db;
    await db.insert('brouillons', {
      'cle': _draftKey,
      'contenu': jsonEncode(draft.toJson()),
      'maj_le': _nowIso,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> clearDraft() async {
    final db = await _db;
    await db.delete('brouillons', where: 'cle = ?', whereArgs: [_draftKey]);
  }
}
