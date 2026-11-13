import 'dart:convert';
import 'dart:math' as math;

import 'package:sqflite/sqflite.dart';

import '../../../core/connectivity.dart';
import '../../../core/db/app_database.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/theme.dart';
import 'forum_ai.dart';
import 'forum_identity.dart';
import 'forum_repository.dart';
import 'forum_seed.dart';
import 'forum_text.dart';

/// [ForumRepository] on the phone's database (schema v5, `forum_*` tables), shaped for the
/// Supabase sync (shared tables, `auteur_id` = owner):
///
/// - Every row the phone creates gets a UUID ([newForumId]).
/// - The phone only writes rows whose `auteur_id` is the member using it: a vote, a reaction or
///   a report is its own row; scores, reply counts, « Utile » / « Merci » and the last activity
///   are computed from those rows when reading.
/// - Nothing here hides another member's post: the « hidden after 3 reports » rule will be a
///   Supabase trigger. What the phone hides is its own text published despite the FRM-03 alert.
class SqliteForumRepository implements ForumRepository {
  SqliteForumRepository(this._database, {required this._now, String Function()? meId, bool Function()? offline})
    : _meId = meId ?? (() => ForumSeed.me),
      _offline = offline ?? (() => false);

  final AppDatabase _database;
  final DateTime Function() _now;
  final String Function() _meId;
  final bool Function() _offline;

  static const _draftKey = 'forum_nouveau_post';
  static const _pageMax = 50;

  /// Photos and videos of a post (Facebook-like: a listing shows several angles).
  static const maxMedia = 8;

  /// The member using the app (Supabase user id, or the demo player).
  String get meId => _meId();

  Future<Database> get _db async {
    if (_offline()) throw const OfflineException();
    return _database.db;
  }

  String get _nowIso => _now().toIso8601String();

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

  static ForumAuthor _unknown(String id) => ForumAuthor(id: id, name: l10n.forumMembre);

  /// The member's own profile row, created the first time they use the forum under a new id
  /// (a Supabase user), from the player's profile (the story's Yassine until the Utilisateur
  /// module gives real names).
  Future<void> _ensureMe(DatabaseExecutor db) async {
    final me = meId;
    if ((await db.query('forum_membres', where: 'id = ?', whereArgs: [me])).isNotEmpty) return;
    final profile = (await db.query('forum_membres', where: 'id = ?', whereArgs: [ForumSeed.me])).firstOrNull;
    await db.insert('forum_membres', {
      'id': me,
      'auteur_id': me,
      'nom': profile?['nom'] ?? l10n.forumMembre,
      'pseudo': profile?['pseudo'],
      'niveau': profile?['niveau'],
      'sport': profile?['sport'],
      'maj_le': _nowIso,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<Set<String>> _blocked(DatabaseExecutor db) async => {
    for (final r in await db.query('forum_blocages', columns: ['bloque_id'], where: 'utilisateur_id = ?', whereArgs: [meId]))
      r['bloque_id']! as String,
  };

  // ── Counts, computed from the rows ────────────────────────────────────────────────────────

  /// Score, « Utile » and « Merci » of [ids].
  Future<Map<String, ({int score, int useful, int thanks})>> _counts(DatabaseExecutor db, ForumTarget target, List<String> ids) async {
    final out = {for (final id in ids) id: (score: 0, useful: 0, thanks: 0)};
    if (ids.isEmpty) return out;
    final args = [target.code, ...ids];
    for (final r in await db.rawQuery(
      'SELECT cible_id, COALESCE(SUM(valeur), 0) AS s FROM forum_votes WHERE cible = ? AND cible_id IN (${_marks(ids.length)}) GROUP BY cible_id',
      args,
    )) {
      final id = r['cible_id']! as String;
      out[id] = (score: (r['s']! as num).toInt(), useful: out[id]!.useful, thanks: out[id]!.thanks);
    }
    for (final r in await db.rawQuery(
      'SELECT cible_id, type, COUNT(*) AS n FROM forum_reactions WHERE cible = ? AND cible_id IN (${_marks(ids.length)}) GROUP BY cible_id, type',
      args,
    )) {
      final id = r['cible_id']! as String;
      final n = r['n']! as int;
      final c = out[id]!;
      out[id] = r['type'] == ForumReaction.useful.code
          ? (score: c.score, useful: n, thanks: c.thanks)
          : (score: c.score, useful: c.useful, thanks: n);
    }
    return out;
  }

  /// Visible replies and the last reply time of each post.
  Future<Map<String, ({int replies, String? last})>> _replyStats(DatabaseExecutor db, List<String> ids) async {
    final out = <String, ({int replies, String? last})>{};
    if (ids.isEmpty) return out;
    for (final r in await db.rawQuery(
      "SELECT sujet_id, COUNT(*) AS n, MAX(cree_le) AS last FROM forum_messages WHERE statut = 'publie' AND sujet_id IN (${_marks(ids.length)}) GROUP BY sujet_id",
      ids,
    )) {
      out[r['sujet_id']! as String] = (replies: r['n']! as int, last: r['last'] as String?);
    }
    return out;
  }

  /// The reader's votes, reactions and open reports on [ids].
  Future<Map<String, ForumMine>> _mine(DatabaseExecutor db, ForumTarget target, List<String> ids, Map<String, String> authors) async {
    final me = meId;
    final out = {for (final id in ids) id: ForumMine(author: authors[id] == me)};
    if (ids.isEmpty) return out;
    final args = [me, target.code, ...ids];
    final marks = _marks(ids.length);
    for (final r in await db.rawQuery(
      'SELECT cible_id, valeur FROM forum_votes WHERE auteur_id = ? AND cible = ? AND cible_id IN ($marks)',
      args,
    )) {
      final id = r['cible_id']! as String;
      out[id] = out[id]!.copyWith(vote: r['valeur']! as int);
    }
    for (final r in await db.rawQuery(
      'SELECT cible_id, type FROM forum_reactions WHERE auteur_id = ? AND cible = ? AND cible_id IN ($marks)',
      args,
    )) {
      final id = r['cible_id']! as String;
      out[id] = r['type'] == ForumReaction.useful.code ? out[id]!.copyWith(useful: true) : out[id]!.copyWith(thanks: true);
    }
    for (final r in await db.rawQuery(
      "SELECT cible_id FROM forum_signalements WHERE auteur_id = ? AND cible = ? AND statut = 'ouvert' AND cible_id IN ($marks)",
      args,
    )) {
      final id = r['cible_id']! as String;
      out[id] = out[id]!.copyWith(reported: true);
    }
    return out;
  }

  static List<String> _list(Object? json) => [for (final v in jsonDecode(json as String? ?? '[]') as List) v as String];

  /// A post row with its computed numbers, before the reader's state.
  Future<List<_PostRow>> _rows(DatabaseExecutor db, List<Map<String, Object?>> rows) async {
    final ids = [for (final r in rows) r['id']! as String];
    final counts = await _counts(db, ForumTarget.post, ids);
    final stats = await _replyStats(db, ids);
    return [
      for (final r in rows)
        () {
          final id = r['id']! as String;
          final s = stats[id];
          final last = [r['cree_le']! as String, ?s?.last].reduce((a, b) => a.compareTo(b) >= 0 ? a : b);
          return _PostRow(r, counts[id]!, s?.replies ?? 0, DateTime.parse(last));
        }(),
    ];
  }

  Future<List<ForumPost>> _posts(DatabaseExecutor db, List<_PostRow> rows, {bool full = false}) async {
    if (rows.isEmpty) return const [];
    final me = meId;
    final members = await _members(db);
    final ids = [for (final r in rows) r.id];
    final mine = await _mine(db, ForumTarget.post, ids, {for (final r in rows) r.id: r.author});
    final saved = {
      for (final r in await db.rawQuery(
        'SELECT sujet_id FROM forum_favoris WHERE utilisateur_id = ? AND sujet_id IN (${_marks(ids.length)})',
        [me, ...ids],
      ))
        r['sujet_id']! as String,
    };
    final followed = {
      for (final r in await db.rawQuery(
        "SELECT cible_id FROM forum_suivis WHERE utilisateur_id = ? AND type = 'sujet' AND cible_id IN (${_marks(ids.length)})",
        [me, ...ids],
      ))
        r['cible_id']! as String,
    };
    final handle = members[me]?.handle;
    final listings = {
      for (final a in await db.rawQuery('SELECT * FROM forum_annonces WHERE sujet_id IN (${_marks(ids.length)})', ids))
        a['sujet_id']! as String: ForumListing(
          price: (a['prix']! as num).toDouble(),
          condition: ListingCondition.fromCode(a['etat'] as String?),
          size: a['taille'] as String?,
          city: a['ville'] as String?,
          sold: a['statut'] == 'vendu',
        ),
    };
    final ratings = await _sellerRatings(db, {for (final p in rows) if (listings.containsKey(p.id)) p.author});
    return [
      for (final p in rows)
        () {
          final r = p.row;
          final status = ForumStatus.fromCode(r['statut']! as String);
          final hiddenForMe = status == ForumStatus.hidden && p.author != me;
          final body = r['contenu']! as String;
          return ForumPost(
            id: p.id,
            author: members[p.author] ?? _unknown(p.author),
            title: r['titre']! as String,
            body: full && !hiddenForMe ? body : null,
            excerpt: hiddenForMe ? null : ForumText.excerpt(body),
            category: ForumCategory.fromCode(r['categorie']! as String),
            sport: MuSport.values.where((s) => s.name == r['sport']).firstOrNull,
            tags: _list(r['tags']),
            images: hiddenForMe ? const [] : _list(r['images']),
            pinned: r['epingle'] == 1,
            status: status,
            bestAnswerId: r['meilleure_reponse_id'] as String?,
            score: p.counts.score,
            replies: p.replies,
            useful: p.counts.useful,
            thanks: p.counts.thanks,
            mentionsMe: handle != null && p.author != me && _list(r['mentions']).contains(handle),
            createdAt: DateTime.parse(r['cree_le']! as String),
            editedAt: r['modifie_le'] == null ? null : DateTime.parse(r['modifie_le']! as String),
            lastActivity: p.lastActivity,
            mine: mine[p.id]!.copyWith(saved: saved.contains(p.id), following: followed.contains(p.id)),
            listing: listings[p.id],
            sellerRating: listings.containsKey(p.id) ? ratings[p.author] : null,
          );
        }(),
    ];
  }

  /// Each seller's average from the published reviews.
  Future<Map<String, ForumRating>> _sellerRatings(DatabaseExecutor db, Set<String> sellers) async {
    if (sellers.isEmpty) return const {};
    return {
      for (final r in await db.rawQuery(
        "SELECT vendeur_id, AVG(note) AS moyenne, COUNT(*) AS n FROM forum_avis WHERE statut = 'publie' "
        'AND vendeur_id IN (${_marks(sellers.length)}) GROUP BY vendeur_id',
        sellers.toList(),
      ))
        r['vendeur_id']! as String: ForumRating((r['moyenne']! as num).toDouble(), r['n']! as int),
    };
  }

  /// « Tendance »: (score + 2 × replies + reactions + 1) / (hours since last activity + 2)^1.3.
  double _trend(_PostRow p) {
    final hours = _now().difference(p.lastActivity).inMinutes / 60;
    final weight = p.counts.score + 2 * p.replies + p.counts.useful + p.counts.thanks + 1;
    return weight / math.pow(math.max(0, hours) + 2, 1.3);
  }

  // ── FRM-01 ────────────────────────────────────────────────────────────────────────────────

  @override
  Future<ForumAuthor> me() async {
    final db = await _db;
    await _ensureMe(db);
    return (await _members(db))[meId] ?? _unknown(meId);
  }

  @override
  Future<ForumFeed> feed(ForumQuery query, {int limit = 20, int offset = 0}) async {
    final db = await _db;
    final me = meId;
    final where = <String>["(statut = 'publie' OR (statut = 'masque' AND auteur_id = ?))"];
    final args = <Object?>[me];
    final blocked = await _blocked(db);
    if (blocked.isNotEmpty) {
      where.add('auteur_id NOT IN (${_marks(blocked.length)})');
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
      args.add(me);
    }
    final rows = await _rows(db, await db.query('forum_sujets', where: where.join(' AND '), whereArgs: args));
    rows.sort((a, b) {
      // Pinned posts lead « Tendance »; « Récents » is the plain timeline, newest first.
      final pin = query.sort == ForumSort.trending ? (b.row['epingle']! as int).compareTo(a.row['epingle']! as int) : 0;
      if (pin != 0) return pin;
      final byMode = switch (query.sort) {
        ForumSort.trending => _trend(b).compareTo(_trend(a)),
        ForumSort.top => b.counts.score != a.counts.score ? b.counts.score.compareTo(a.counts.score) : b.replies.compareTo(a.replies),
        ForumSort.recent => 0,
      };
      return byMode != 0 ? byMode : (b.row['cree_le']! as String).compareTo(a.row['cree_le']! as String);
    });
    final page = rows.skip(offset).take(math.min(limit, _pageMax)).toList();
    return ForumFeed(total: rows.length, posts: await _posts(db, page));
  }

  @override
  Future<List<ForumCategoryCount>> categories({MuSport? sport, DateTime? since}) async {
    final db = await _db;
    final me = meId;
    final visit =
        since?.toIso8601String() ??
        (await db.query('forum_visites', where: 'utilisateur_id = ?', whereArgs: [me])).firstOrNull?['derniere_visite'] as String?;
    final rows = await db.rawQuery(
      '''
      SELECT categorie, COUNT(*) AS n,
        SUM(CASE WHEN ? IS NOT NULL AND cree_le > ? AND auteur_id <> ? THEN 1 ELSE 0 END) AS nouveaux
      FROM forum_sujets WHERE statut = 'publie' ${sport != null ? 'AND sport = ?' : ''}
      GROUP BY categorie''',
      [visit, visit, me, if (sport != null) sport.name],
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
  Future<DateTime?> markVisited() async {
    final db = await _db;
    final before =
        (await db.query('forum_visites', where: 'utilisateur_id = ?', whereArgs: [meId])).firstOrNull?['derniere_visite'] as String?;
    await db.insert('forum_visites', {'utilisateur_id': meId, 'derniere_visite': _nowIso}, conflictAlgorithm: ConflictAlgorithm.replace);
    return before == null ? null : DateTime.parse(before);
  }

  // ── FRM-04 ────────────────────────────────────────────────────────────────────────────────

  @override
  Future<ForumThread> thread(String postId, {ReplySort sort = ReplySort.useful}) async {
    final db = await _db;
    final me = meId;
    final row = (await db.query('forum_sujets', where: 'id = ?', whereArgs: [postId])).firstOrNull;
    if (row == null || row['statut'] == ForumStatus.deleted.code) throw ForumRuleException(l10n.forumDiscussionSupprimee);
    final post = (await _posts(db, await _rows(db, [row]), full: true)).single;

    final members = await _members(db);
    final blocked = await _blocked(db);
    final rows = await db.query('forum_messages', where: 'sujet_id = ?', whereArgs: [postId], orderBy: 'cree_le, id');
    final ids = [for (final r in rows) r['id']! as String];
    final counts = await _counts(db, ForumTarget.reply, ids);
    final mine = await _mine(db, ForumTarget.reply, ids, {for (final r in rows) r['id']! as String: r['auteur_id']! as String});

    ForumReply view(Map<String, Object?> r, List<ForumReply> children) {
      final id = r['id']! as String;
      final author = r['auteur_id']! as String;
      final status = ForumStatus.fromCode(r['statut']! as String);
      final isBlocked = blocked.contains(author);
      final hiddenForMe = status == ForumStatus.hidden && author != me;
      final answering = r['en_reponse_a_id'] as String?;
      return ForumReply(
        id: id,
        postId: postId,
        parentId: r['parent_id'] as String?,
        author: members[author] ?? _unknown(author),
        // A direct reply answers the post's author (« Ta réponse à Skander T. »).
        answering: answering != null ? (members[answering] ?? _unknown(answering)) : (r['parent_id'] == null ? post.author : null),
        body: status == ForumStatus.deleted || hiddenForMe || isBlocked ? null : r['contenu']! as String,
        status: status,
        blocked: isBlocked,
        byPostAuthor: author == post.author.id,
        best: id == post.bestAnswerId,
        score: counts[id]!.score,
        useful: counts[id]!.useful,
        thanks: counts[id]!.thanks,
        createdAt: DateTime.parse(r['cree_le']! as String),
        editedAt: r['modifie_le'] == null ? null : DateTime.parse(r['modifie_le']! as String),
        mine: mine[id]!,
        children: children,
      );
    }

    // Deleted replies and blocked authors stay only as placeholders for their answers.
    bool keep(ForumReply r) => !(r.deleted || r.blocked) || r.children.isNotEmpty;
    final childrenOf = <String, List<ForumReply>>{};
    for (final r in rows) {
      final parent = r['parent_id'] as String?;
      if (parent == null) continue;
      final v = view(r, const []);
      if (keep(v)) childrenOf.putIfAbsent(parent, () => []).add(v);
    }
    final level1 = [
      for (final r in rows)
        if (r['parent_id'] == null) view(r, childrenOf[r['id']! as String] ?? const []),
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
  Future<List<SimilarPost>> similar(String title, {MuSport? sport, List<String> tags = const [], String? exclude}) async {
    final db = await _db;
    if (ForumAi.keywords(title).where((w) => w.length > 3).isEmpty) return const [];
    final raw = await db.query('forum_sujets', where: "statut = 'publie'${exclude != null ? ' AND id <> ?' : ''}", whereArgs: [?exclude]);
    final posts = await _posts(db, await _rows(db, raw));
    final bodies = {for (final r in raw) r['id']! as String: r['contenu']! as String};
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

  /// The FRM-03 check: throws on the first try above the threshold; with [confirmed] the
  /// member's own text is published masked until a moderator reads it.
  ModerationAnalysis _control(String text, bool confirmed) {
    final a = ForumAi.analyze(text);
    if (a.alert && !confirmed) throw ForumAlertException(a);
    return a;
  }

  Future<ForumPost> _post(DatabaseExecutor db, String id) async =>
      (await _posts(db, await _rows(db, await db.query('forum_sujets', where: 'id = ?', whereArgs: [id])), full: true)).single;

  @override
  Future<ForumPost> publish(PostDraft draft, {bool confirmed = false}) async {
    final db = await _db;
    await _checkCanWrite(db);
    final title = draft.title.trim();
    final body = draft.body.trim();
    if (title.length < 10) throw ForumRuleException(l10n.forumTitreTropCourt);
    if (body.isEmpty) throw ForumRuleException(l10n.forumMessageVide);
    final listing = _listingOf(draft);
    final a = _control('$title\n$body', confirmed);
    final me = meId;
    final id = newForumId();
    await db.transaction((txn) async {
      await _ensureMe(txn);
      await txn.insert('forum_sujets', {
        'id': id,
        'auteur_id': me,
        'titre': title,
        'contenu': body,
        'categorie': draft.category.code,
        'sport': draft.sport?.name,
        'tags': jsonEncode(ForumAi.cleanTags(draft.tags)),
        'images': jsonEncode(draft.images.take(maxMedia).toList()),
        'mentions': jsonEncode(ForumAi.mentions(body)),
        'statut': a.alert ? ForumStatus.hidden.code : ForumStatus.published.code,
        'publie_malgre_alerte': a.alert ? 1 : 0,
        'score_ia': a.score,
        'motif_ia': a.score >= 0.15 ? a.reason : null,
        'cree_le': _nowIso,
      });
      await txn.insert('forum_suivis', {
        'utilisateur_id': me,
        'type': 'sujet',
        'cible_id': id,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      if (listing != null) await _saveListing(txn, id, listing);
    });
    return _post(db, id);
  }

  /// The listing of an Équipement draft, checked; null for a discussion.
  ForumListing? _listingOf(PostDraft draft) {
    final l = draft.listing;
    if (l == null || draft.category != ForumCategory.equipment) return null;
    if (l.price <= 0) throw ForumRuleException(l10n.mktIndiqueUnPrix);
    if (l.price > maxPrice) throw ForumRuleException(l10n.mktPrixTropEleve);
    return l;
  }

  /// No equipment costs more on the Communauté.
  static const double maxPrice = 20000;

  Future<void> _saveListing(DatabaseExecutor db, String postId, ForumListing l) async {
    final values = {
      'auteur_id': meId,
      'prix': l.price,
      'etat': l.condition.code,
      'taille': _blankToNull(l.size),
      'ville': _blankToNull(l.city),
      'maj_le': _nowIso,
    };
    final updated = await db.update('forum_annonces', values, where: 'sujet_id = ? AND auteur_id = ?', whereArgs: [postId, meId]);
    if (updated == 0) await db.insert('forum_annonces', {'sujet_id': postId, 'statut': 'disponible', ...values});
  }

  static String? _blankToNull(String? s) => s == null || s.trim().isEmpty ? null : s.trim();

  @override
  Future<ForumPost> editPost(String postId, PostDraft draft, {bool confirmed = false}) async {
    final db = await _db;
    final row = await _row(db, ForumTarget.post, postId);
    if (row['auteur_id'] != meId) throw ForumRuleException(l10n.forumSeulLAuteur);
    await _checkCanWrite(db);
    final title = draft.title.trim();
    final body = draft.body.trim();
    if (title.length < 10) throw ForumRuleException(l10n.forumTitreTropCourt);
    final listing = _listingOf(draft);
    final a = _control('$title\n$body', confirmed);
    final hide = a.alert && row['statut'] == ForumStatus.published.code;
    if (listing != null) {
      await _saveListing(db, postId, listing);
    } else {
      await db.delete('forum_annonces', where: 'sujet_id = ? AND auteur_id = ?', whereArgs: [postId, meId]);
    }
    await db.update(
      'forum_sujets',
      {
        'titre': title,
        'contenu': body,
        'categorie': draft.category.code,
        'sport': draft.sport?.name,
        'tags': jsonEncode(ForumAi.cleanTags(draft.tags)),
        'images': jsonEncode(draft.images.take(maxMedia).toList()),
        'mentions': jsonEncode(ForumAi.mentions(body)),
        'score_ia': a.score,
        'motif_ia': a.score >= 0.15 ? a.reason : null,
        'modifie_le': _nowIso,
        if (hide) 'statut': ForumStatus.hidden.code,
        if (hide) 'publie_malgre_alerte': 1,
      },
      where: 'id = ? AND auteur_id = ?',
      whereArgs: [postId, meId],
    );
    return _post(db, postId);
  }

  @override
  Future<void> deletePost(String postId) async {
    final db = await _db;
    final row = await _row(db, ForumTarget.post, postId);
    if (row['auteur_id'] != meId) throw ForumRuleException(l10n.forumSeulLAuteur);
    await db.update('forum_sujets', {'statut': ForumStatus.deleted.code}, where: 'id = ? AND auteur_id = ?', whereArgs: [postId, meId]);
  }

  // ── Marketplace ───────────────────────────────────────────────────────────────────────────

  @override
  Future<void> markSold(String postId, {required bool sold}) async {
    final db = await _db;
    final updated = await db.update(
      'forum_annonces',
      {'statut': sold ? 'vendu' : 'disponible', 'maj_le': _nowIso},
      where: 'sujet_id = ? AND auteur_id = ?',
      whereArgs: [postId, meId],
    );
    if (updated == 0) throw ForumRuleException(l10n.forumSeulLAuteur);
  }

  @override
  Future<ForumReviews> sellerReviews(String sellerId) async {
    final db = await _db;
    final members = await _members(db);
    final me = meId;
    final rows = await db.rawQuery(
      'SELECT a.*, s.titre FROM forum_avis a LEFT JOIN forum_sujets s ON s.id = a.sujet_id '
      "WHERE a.vendeur_id = ? AND (a.statut = 'publie' OR a.auteur_id = ?) ORDER BY a.cree_le DESC",
      [sellerId, me],
    );
    final blocked = await _blocked(db);
    final reviews = [
      for (final r in rows)
        if (!blocked.contains(r['auteur_id']))
          ForumReview(
            id: r['id']! as String,
            author: members[r['auteur_id']] ?? _unknown(r['auteur_id']! as String),
            rating: r['note']! as int,
            text: r['texte'] as String? ?? '',
            item: r['titre'] as String?,
            createdAt: DateTime.parse(r['cree_le']! as String),
            mine: r['auteur_id'] == me,
            hidden: r['statut'] != 'publie',
          ),
    ];
    final stars = List.filled(5, 0);
    for (final r in reviews) {
      if (!r.hidden) stars[5 - r.rating]++;
    }
    return ForumReviews(
      seller: members[sellerId] ?? _unknown(sellerId),
      reviews: reviews,
      stars: stars,
      mine: reviews.where((r) => r.mine).firstOrNull,
    );
  }

  @override
  Future<void> review(String sellerId, int rating, String text, {String? postId, bool confirmed = false}) async {
    if (sellerId == meId) throw ForumRuleException(l10n.mktPasTonPropreAvis);
    if (rating < 1 || rating > 5) throw ForumRuleException(l10n.mktChoisisUneNote);
    final body = text.trim();
    final db = await _db;
    await _checkCanWrite(db);
    final a = body.isEmpty ? null : _control(body, confirmed);
    final values = {
      'note': rating,
      'texte': body,
      'sujet_id': postId,
      'statut': a != null && a.alert ? ForumStatus.hidden.code : ForumStatus.published.code,
      'modifie_le': _nowIso,
    };
    await db.transaction((txn) async {
      await _ensureMe(txn);
      final updated = await txn.update('forum_avis', values, where: 'auteur_id = ? AND vendeur_id = ?', whereArgs: [meId, sellerId]);
      if (updated == 0) {
        await txn.insert('forum_avis', {'id': newForumId(), 'auteur_id': meId, 'vendeur_id': sellerId, 'cree_le': _nowIso, ...values});
      }
    });
  }

  @override
  Future<void> deleteReview(String sellerId) async {
    final db = await _db;
    await db.delete('forum_avis', where: 'auteur_id = ? AND vendeur_id = ?', whereArgs: [meId, sellerId]);
  }

  // ── Replies ───────────────────────────────────────────────────────────────────────────────

  String _table(ForumTarget t) => t == ForumTarget.post ? 'forum_sujets' : 'forum_messages';

  Future<Map<String, Object?>> _row(DatabaseExecutor db, ForumTarget target, String id) async {
    final r = (await db.query(_table(target), where: 'id = ?', whereArgs: [id])).firstOrNull;
    if (r == null || r['statut'] == ForumStatus.deleted.code) {
      throw ForumRuleException(target == ForumTarget.post ? l10n.forumDiscussionSupprimee : l10n.forumReponseSupprimee);
    }
    return r;
  }

  Future<ForumReply> _reply(String postId, String replyId) async {
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
  Future<ForumReply> reply(String postId, String body, {String? parentId, bool confirmed = false}) async {
    final db = await _db;
    final me = meId;
    final post = await _row(db, ForumTarget.post, postId);
    if (post['statut'] == ForumStatus.hidden.code && post['auteur_id'] != me) throw ForumRuleException(l10n.forumEnVerification);
    await _checkCanWrite(db);
    final text = body.trim();
    if (text.isEmpty) throw ForumRuleException(l10n.forumMessageVide);

    String? level1;
    String? answering;
    if (parentId != null) {
      final parent = await _row(db, ForumTarget.reply, parentId);
      level1 = (parent['parent_id'] as String?) ?? parentId;
      answering = parent['auteur_id']! as String;
    }
    final a = _control(text, confirmed);
    final id = newForumId();
    await db.transaction((txn) async {
      await _ensureMe(txn);
      await txn.insert('forum_messages', {
        'id': id,
        'sujet_id': postId,
        'parent_id': level1,
        'auteur_id': me,
        'en_reponse_a_id': answering,
        'contenu': text,
        'mentions': jsonEncode(ForumAi.mentions(text)),
        'statut': a.alert ? ForumStatus.hidden.code : ForumStatus.published.code,
        'publie_malgre_alerte': a.alert ? 1 : 0,
        'score_ia': a.score,
        'motif_ia': a.score >= 0.15 ? a.reason : null,
        'cree_le': _nowIso,
      });
    });
    return _reply(postId, id);
  }

  @override
  Future<ForumReply> editReply(String replyId, String body, {bool confirmed = false}) async {
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
      where: 'id = ? AND auteur_id = ?',
      whereArgs: [replyId, meId],
    );
    return _reply(row['sujet_id']! as String, replyId);
  }

  /// The reply becomes « Message supprimé » (its answers stay). If it was the best answer, the
  /// post simply stops showing it: the post's own `meilleure_reponse_id` is the author's to change.
  @override
  Future<void> deleteReply(String replyId) async {
    final db = await _db;
    final row = await _row(db, ForumTarget.reply, replyId);
    if (row['auteur_id'] != meId) throw ForumRuleException(l10n.forumSeulLAuteur);
    await db.update('forum_messages', {'statut': ForumStatus.deleted.code}, where: 'id = ? AND auteur_id = ?', whereArgs: [replyId, meId]);
  }

  // ── Votes and reactions: one row per member ───────────────────────────────────────────────

  /// Not on your own content, not on a masked one, not while suspended.
  Future<void> _checkCanReact(DatabaseExecutor db, ForumTarget target, String id, String ownMessage) async {
    final row = await _row(db, target, id);
    if (row['auteur_id'] == meId) throw ForumRuleException(ownMessage);
    if (row['statut'] == ForumStatus.hidden.code) throw ForumRuleException(l10n.forumEnVerification);
    await _checkCanWrite(db);
  }

  @override
  Future<int> vote(ForumTarget target, String id, int value) async {
    final db = await _db;
    await _checkCanReact(db, target, id, l10n.forumPasDeVotePourSoi);
    final me = meId;
    await db.transaction((txn) async {
      final mine = (await txn.query(
        'forum_votes',
        where: 'auteur_id = ? AND cible = ? AND cible_id = ?',
        whereArgs: [me, target.code, id],
      )).firstOrNull;
      if (value == 0) {
        if (mine != null) await txn.delete('forum_votes', where: 'id = ?', whereArgs: [mine['id']]);
      } else if (mine != null) {
        await txn.update('forum_votes', {'valeur': value.sign}, where: 'id = ?', whereArgs: [mine['id']]);
      } else {
        await txn.insert('forum_votes', {
          'id': newForumId(),
          'auteur_id': me,
          'cible': target.code,
          'cible_id': id,
          'valeur': value.sign,
          'cree_le': _nowIso,
        });
      }
    });
    return (await _counts(db, target, [id]))[id]!.score;
  }

  @override
  Future<void> react(ForumTarget target, String id, ForumReaction reaction, {required bool on}) async {
    final db = await _db;
    await _checkCanReact(db, target, id, l10n.forumPasDeReactionPourSoi);
    final me = meId;
    if (on) {
      await db.insert('forum_reactions', {
        'id': newForumId(),
        'auteur_id': me,
        'cible': target.code,
        'cible_id': id,
        'type': reaction.code,
        'cree_le': _nowIso,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    } else {
      await db.delete(
        'forum_reactions',
        where: 'auteur_id = ? AND cible = ? AND cible_id = ? AND type = ?',
        whereArgs: [me, target.code, id, reaction.code],
      );
    }
  }

  @override
  Future<void> chooseBestAnswer(String postId, String? replyId) async {
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
    await db.update('forum_sujets', {'meilleure_reponse_id': replyId}, where: 'id = ? AND auteur_id = ?', whereArgs: [postId, meId]);
  }

  // ── Private lists: saved, followed, blocked ───────────────────────────────────────────────

  @override
  Future<void> save(String postId, {required bool on}) async {
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

  Future<void> _follow(String type, String id, bool on) async {
    final db = await _db;
    if (on) {
      await db.insert('forum_suivis', {'utilisateur_id': meId, 'type': type, 'cible_id': id}, conflictAlgorithm: ConflictAlgorithm.ignore);
    } else {
      await db.delete('forum_suivis', where: 'utilisateur_id = ? AND type = ? AND cible_id = ?', whereArgs: [meId, type, id]);
    }
  }

  @override
  Future<void> follow(String postId, {required bool on}) => _follow('sujet', postId, on);

  @override
  Future<void> followMember(String memberId, {required bool on}) {
    if (memberId == meId) throw ForumRuleException(l10n.forumPasTeSuivre);
    return _follow('membre', memberId, on);
  }

  @override
  Future<bool> isFollowingMember(String memberId) async {
    final db = await _db;
    final r = await db.query('forum_suivis', where: "utilisateur_id = ? AND type = 'membre' AND cible_id = ?", whereArgs: [meId, memberId]);
    return r.isNotEmpty;
  }

  @override
  Future<void> block(String memberId, {required bool on}) async {
    final db = await _db;
    if (memberId == meId) throw ForumRuleException(l10n.forumPasTeMasquer);
    if (on) {
      await db.insert('forum_blocages', {'utilisateur_id': meId, 'bloque_id': memberId}, conflictAlgorithm: ConflictAlgorithm.ignore);
    } else {
      await db.delete('forum_blocages', where: 'utilisateur_id = ? AND bloque_id = ?', whereArgs: [meId, memberId]);
    }
  }

  // ── FRM-05: one report row per reporter ───────────────────────────────────────────────────

  @override
  Future<void> report(ForumTarget target, String id, ReportReason reason, {String? details, bool muteAuthor = false}) async {
    final db = await _db;
    final row = await _row(db, target, id);
    final author = row['auteur_id']! as String;
    final me = meId;
    if (author == me) throw ForumRuleException(l10n.forumPasTonPropreMessage);
    await db.transaction((txn) async {
      final mine = (await txn.query(
        'forum_signalements',
        where: 'auteur_id = ? AND cible = ? AND cible_id = ?',
        whereArgs: [me, target.code, id],
      )).firstOrNull;
      final values = {'motif': reason.code, 'details': details, 'statut': 'ouvert', 'cree_le': _nowIso};
      if (mine != null) {
        await txn.update('forum_signalements', values, where: 'id = ?', whereArgs: [mine['id']]);
      } else {
        await txn.insert('forum_signalements', {'id': newForumId(), 'auteur_id': me, 'cible': target.code, 'cible_id': id, ...values});
      }
      if (muteAuthor) {
        await txn.insert('forum_blocages', {'utilisateur_id': me, 'bloque_id': author}, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    });
  }

  @override
  Future<void> undoReport(ForumTarget target, String id) async {
    final db = await _db;
    await db.delete(
      'forum_signalements',
      where: "auteur_id = ? AND cible = ? AND cible_id = ? AND statut = 'ouvert'",
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

/// A post row with the numbers computed from the vote, reaction and reply rows.
class _PostRow {
  _PostRow(this.row, this.counts, this.replies, this.lastActivity);

  final Map<String, Object?> row;
  final ({int score, int useful, int thanks}) counts;
  final int replies;
  final DateTime lastActivity;

  String get id => row['id']! as String;
  String get author => row['auteur_id']! as String;
}
