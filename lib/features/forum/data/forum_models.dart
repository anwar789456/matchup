import 'package:flutter/widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../l10n/l10n.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';

/// The 5 forum categories (FRM-01 « Catégories »), with their icon (ForumPostCard.md): a
/// Phosphor icon, or a custom glyph for Terrains and Tournois.
enum ForumCategory {
  technique('conseils_technique'),
  equipment('equipement'),
  venues('terrains'),
  tournaments('tournois'),
  general('discussions_libres');

  const ForumCategory(this.code);

  /// The value stored and sent to the API.
  final String code;

  static ForumCategory fromCode(String code) => values.firstWhere((c) => c.code == code, orElse: () => ForumCategory.general);

  String get label => switch (this) {
    technique => l10n.forumCatTechnique,
    equipment => l10n.forumCatEquipement,
    venues => l10n.forumCatTerrains,
    tournaments => l10n.forumCatTournois,
    general => l10n.forumCatDiscussions,
  };

  /// Phosphor icon, null when [glyph] is used.
  IconData? get icon => switch (this) {
    technique => PhosphorIcons.lightbulb(),
    equipment => PhosphorIcons.tShirt(),
    general => PhosphorIcons.chatsCircle(),
    venues || tournaments => null,
  };

  String? get glyph => switch (this) {
    venues => MuGlyph.court,
    tournaments => MuGlyph.trophy,
    _ => null,
  };
}

/// FRM-01 sort.
enum ForumSort {
  trending('tendance'),
  recent('recents'),
  top('top');

  const ForumSort(this.code);
  final String code;

  String get label => switch (this) {
    trending => l10n.forumTriTendance,
    recent => l10n.forumTriRecents,
    top => l10n.forumTriTop,
  };
}

/// FRM-04 « Les plus utiles » menu.
enum ReplySort {
  useful('utiles'),
  newest('recentes'),
  oldest('anciennes');

  const ReplySort(this.code);
  final String code;

  String get label => switch (this) {
    useful => l10n.forumTriUtiles,
    newest => l10n.forumTriRecentes,
    oldest => l10n.forumTriAnciennes,
  };
}

/// FRM-05 reasons.
enum ReportReason {
  spam('spam'),
  insult('insulte'),
  unsafe('choquant'),
  fake('fausse_information'),
  other('autre');

  const ReportReason(this.code);
  final String code;

  static ReportReason fromCode(String code) => values.firstWhere((r) => r.code == code, orElse: () => ReportReason.other);

  String get label => switch (this) {
    spam => l10n.forumMotifSpam,
    insult => l10n.forumMotifInsulte,
    unsafe => l10n.forumMotifChoquant,
    fake => l10n.forumMotifFausseInfo,
    other => l10n.forumMotifAutre,
  };
}

/// « Utile » / « Merci ».
enum ForumReaction {
  useful('utile'),
  thanks('merci');

  const ForumReaction(this.code);
  final String code;
}

enum ForumStatus {
  published('publie'),
  hidden('masque'),
  deleted('supprime');

  const ForumStatus(this.code);
  final String code;

  static ForumStatus fromCode(String code) => values.firstWhere((s) => s.code == code, orElse: () => ForumStatus.published);
}

/// A member as the forum shows them: name, handle and level in their main sport.
@immutable
class ForumAuthor {
  const ForumAuthor({required this.id, required this.name, this.handle, this.level, this.sport, this.imageUrl});

  final String id;

  /// « Skander T. »
  final String name;

  /// « skander.t » (no « @ »), for mentions.
  final String? handle;
  final double? level;
  final MuSport? sport;
  final String? imageUrl;
}

/// What the reader did on a post or a reply.
@immutable
class ForumMine {
  const ForumMine({
    this.vote = 0,
    this.useful = false,
    this.thanks = false,
    this.author = false,
    this.saved = false,
    this.following = false,
    this.reported = false,
  });

  /// 1, −1 or 0.
  final int vote;
  final bool useful;
  final bool thanks;
  final bool author;
  final bool saved;
  final bool following;

  /// The reader reported it (« Tu as signalé ce message »).
  final bool reported;

  ForumMine copyWith({int? vote, bool? useful, bool? thanks, bool? saved, bool? following, bool? reported}) => ForumMine(
    vote: vote ?? this.vote,
    useful: useful ?? this.useful,
    thanks: thanks ?? this.thanks,
    author: author,
    saved: saved ?? this.saved,
    following: following ?? this.following,
    reported: reported ?? this.reported,
  );
}

/// A discussion (FRM-01 card, FRM-04 header).
@immutable
class ForumPost {
  const ForumPost({
    required this.id,
    required this.author,
    required this.title,
    required this.category,
    required this.createdAt,
    required this.lastActivity,
    this.body,
    this.excerpt,
    this.sport,
    this.tags = const [],
    this.images = const [],
    this.pinned = false,
    this.status = ForumStatus.published,
    this.bestAnswerId,
    this.score = 0,
    this.replies = 0,
    this.useful = 0,
    this.thanks = 0,
    this.mentionsMe = false,
    this.editedAt,
    this.mine = const ForumMine(),
  });

  final String id;
  final ForumAuthor author;
  final String title;

  /// Light Markdown; null in lists, and for others when hidden.
  final String? body;

  /// Plain text for the card; null when hidden for this reader.
  final String? excerpt;
  final ForumCategory category;
  final MuSport? sport;
  final List<String> tags;
  final List<String> images;
  final bool pinned;
  final ForumStatus status;
  final String? bestAnswerId;
  final int score;
  final int replies;
  final int useful;
  final int thanks;
  final bool mentionsMe;
  final DateTime createdAt;
  final DateTime? editedAt;
  final DateTime lastActivity;
  final ForumMine mine;

  bool get hidden => status == ForumStatus.hidden;
  bool get hasBestAnswer => bestAnswerId != null;

  ForumPost copyWith({int? score, int? useful, int? thanks, ForumMine? mine, String? Function()? bestAnswerId}) => ForumPost(
    id: id,
    author: author,
    title: title,
    body: body,
    excerpt: excerpt,
    category: category,
    sport: sport,
    tags: tags,
    images: images,
    pinned: pinned,
    status: status,
    bestAnswerId: bestAnswerId != null ? bestAnswerId() : this.bestAnswerId,
    score: score ?? this.score,
    replies: replies,
    useful: useful ?? this.useful,
    thanks: thanks ?? this.thanks,
    mentionsMe: mentionsMe,
    createdAt: createdAt,
    editedAt: editedAt,
    lastActivity: lastActivity,
    mine: mine ?? this.mine,
  );
}

/// A reply in FRM-04. Level-1 replies carry their answers in [children].
@immutable
class ForumReply {
  const ForumReply({
    required this.id,
    required this.postId,
    required this.author,
    required this.createdAt,
    this.parentId,
    this.answering,
    this.body,
    this.status = ForumStatus.published,
    this.blocked = false,
    this.byPostAuthor = false,
    this.best = false,
    this.score = 0,
    this.useful = 0,
    this.thanks = 0,
    this.editedAt,
    this.mine = const ForumMine(),
    this.children = const [],
  });

  final String id;
  final String postId;
  final String? parentId;
  final ForumAuthor author;

  /// The member this reply answers (« Ta réponse à Omar D. »).
  final ForumAuthor? answering;

  /// null when hidden for this reader, deleted, or from a blocked author.
  final String? body;
  final ForumStatus status;
  final bool blocked;

  /// « Auteur » badge.
  final bool byPostAuthor;
  final bool best;
  final int score;
  final int useful;
  final int thanks;
  final DateTime createdAt;
  final DateTime? editedAt;
  final ForumMine mine;
  final List<ForumReply> children;

  bool get hidden => status == ForumStatus.hidden;
  bool get deleted => status == ForumStatus.deleted;

  ForumReply copyWith({int? score, int? useful, int? thanks, ForumMine? mine, List<ForumReply>? children}) => ForumReply(
    id: id,
    postId: postId,
    parentId: parentId,
    author: author,
    answering: answering,
    body: body,
    status: status,
    blocked: blocked,
    byPostAuthor: byPostAuthor,
    best: best,
    score: score ?? this.score,
    useful: useful ?? this.useful,
    thanks: thanks ?? this.thanks,
    createdAt: createdAt,
    editedAt: editedAt,
    mine: mine ?? this.mine,
    children: children ?? this.children,
  );
}

/// FRM-04: the post, the best answer and the other replies.
@immutable
class ForumThread {
  const ForumThread({required this.post, required this.replies, this.bestAnswer, this.sort = ReplySort.useful});

  final ForumPost post;
  final ForumReply? bestAnswer;
  final List<ForumReply> replies;
  final ReplySort sort;
}

/// FRM-01 list query.
@immutable
class ForumQuery {
  const ForumQuery({
    this.category,
    this.sport,
    this.sort = ForumSort.trending,
    this.search,
    this.tag,
    this.authorId,
    this.savedOnly = false,
  });

  final ForumCategory? category;
  final MuSport? sport;
  final ForumSort sort;
  final String? search;
  final String? tag;
  final String? authorId;
  final bool savedOnly;

  ForumQuery copyWith({
    ForumCategory? Function()? category,
    MuSport? Function()? sport,
    ForumSort? sort,
    String? Function()? search,
    bool? savedOnly,
  }) => ForumQuery(
    category: category != null ? category() : this.category,
    sport: sport != null ? sport() : this.sport,
    sort: sort ?? this.sort,
    search: search != null ? search() : this.search,
    tag: tag,
    authorId: authorId,
    savedOnly: savedOnly ?? this.savedOnly,
  );

  @override
  bool operator ==(Object other) =>
      other is ForumQuery &&
      other.category == category &&
      other.sport == sport &&
      other.sort == sort &&
      other.search == search &&
      other.tag == tag &&
      other.authorId == authorId &&
      other.savedOnly == savedOnly;

  @override
  int get hashCode => Object.hash(category, sport, sort, search, tag, authorId, savedOnly);
}

@immutable
class ForumFeed {
  const ForumFeed({required this.total, required this.posts});

  /// « 248 discussions ».
  final int total;
  final List<ForumPost> posts;
}

/// A category tile with its « nouveaux depuis ta dernière visite » badge.
@immutable
class ForumCategoryCount {
  const ForumCategoryCount({required this.category, required this.posts, required this.fresh});

  final ForumCategory category;
  final int posts;
  final int fresh;
}

/// FRM-02 « Discussions similaires ».
@immutable
class SimilarPost {
  const SimilarPost({required this.post, required this.similarity});

  final ForumPost post;
  final double similarity;
}

/// FRM-02 « Suggérés par l’IA ».
@immutable
class TagSuggestion {
  const TagSuggestion(this.tag, this.reason);

  final String tag;

  /// The word that made the AI suggest it.
  final String reason;
}

/// A passage of the text to highlight (FRM-03 / ADM-10): `text.substring(start, end)`.
@immutable
class TextExcerpt {
  const TextExcerpt(this.start, this.end);

  final int start;
  final int end;
}

enum RiskLevel { low, medium, high }

/// The AI's reading of a text (FRM-03).
@immutable
class ModerationAnalysis {
  const ModerationAnalysis({
    required this.score,
    required this.level,
    required this.reason,
    required this.explanation,
    this.excerpts = const [],
    this.rewrite,
  });

  /// 0 → 1; from 0,5 the author is asked to review the text.
  final double score;
  final RiskLevel level;
  final String reason;
  final String explanation;
  final List<TextExcerpt> excerpts;

  /// A calmer version keeping the advice, or null when there is none.
  final String? rewrite;

  static const alertThreshold = 0.5;

  bool get alert => score >= alertThreshold;
}

/// What a new post or reply is.
@immutable
class PostDraft {
  const PostDraft({
    this.category = ForumCategory.technique,
    this.sport,
    this.title = '',
    this.body = '',
    this.tags = const [],
    this.images = const [],
  });

  final ForumCategory category;
  final MuSport? sport;
  final String title;
  final String body;
  final List<String> tags;

  /// Local paths or URLs of the post's images.
  final List<String> images;

  bool get isEmpty => title.trim().isEmpty && body.trim().isEmpty && tags.isEmpty && images.isEmpty;

  PostDraft copyWith({
    ForumCategory? category,
    MuSport? Function()? sport,
    String? title,
    String? body,
    List<String>? tags,
    List<String>? images,
  }) => PostDraft(
    category: category ?? this.category,
    sport: sport != null ? sport() : this.sport,
    title: title ?? this.title,
    body: body ?? this.body,
    tags: tags ?? this.tags,
    images: images ?? this.images,
  );

  Map<String, Object?> toJson() => {
    'categorie': category.code,
    'sport': sport?.name,
    'titre': title,
    'contenu': body,
    'tags': tags,
    'images': images,
  };

  static PostDraft fromJson(Map<String, Object?> j) => PostDraft(
    category: ForumCategory.fromCode(j['categorie'] as String? ?? ''),
    sport: MuSport.values.where((s) => s.name == j['sport']).firstOrNull,
    title: j['titre'] as String? ?? '',
    body: j['contenu'] as String? ?? '',
    tags: [for (final t in (j['tags'] as List? ?? const [])) t as String],
    images: [for (final t in (j['images'] as List? ?? const [])) t as String],
  );
}

/// The text may hurt (FRM-03): publish only once the author confirms.
class ForumAlertException implements Exception {
  const ForumAlertException(this.analysis);

  final ModerationAnalysis analysis;
}

/// The member is suspended from the forum until [until].
class ForumSuspendedException implements Exception {
  const ForumSuspendedException(this.until);

  final DateTime until;
}

/// A rule of the forum refused the action (« Tu ne peux pas voter pour ton propre message. »).
class ForumRuleException implements Exception {
  const ForumRuleException(this.message);

  final String message;

  @override
  String toString() => message;
}
