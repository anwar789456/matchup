import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../../../core/connectivity.dart';
import '../../../core/db/app_database.dart';
import '../../../theme/theme.dart';
import 'forum_identity.dart';
import 'forum_models.dart';
import 'sqlite_forum_repository.dart';

export 'forum_models.dart';

/// What a vote, reaction or report points at.
enum ForumTarget {
  post('sujet'),
  reply('message');

  const ForumTarget(this.code);
  final String code;
}

/// The Communauté (FRM-01…05): discussions, replies, votes, reactions, saved posts, follows,
/// reports and the user-side moderation. Everything lives in SQFlite; the shared tables are
/// copied to Supabase by the sync (see [SqliteForumRepository] for the rules that makes safe:
/// UUID ids, `auteur_id` on every row, one row per vote / reaction / report).
abstract interface class ForumRepository {
  /// The member using the app.
  Future<ForumAuthor> me();

  /// FRM-01 list, pinned first. [limit] / [offset] page it.
  Future<ForumFeed> feed(ForumQuery query, {int limit = 20, int offset = 0});

  /// The 5 categories with « nouveaux depuis ta dernière visite ».
  Future<List<ForumCategoryCount>> categories({MuSport? sport, DateTime? since});

  /// Saves the visit (call it when leaving the Communauté), so the badges count from now.
  Future<DateTime?> markVisited();

  /// FRM-04.
  Future<ForumThread> thread(String postId, {ReplySort sort = ReplySort.useful});

  /// FRM-02 « Discussions similaires » (3 at most).
  Future<List<SimilarPost>> similar(String title, {MuSport? sport, List<String> tags = const [], String? exclude});

  /// FRM-02 « Suggérés par l’IA ».
  Future<List<TagSuggestion>> suggestTags(String title, String body, List<String> tags);

  /// FRM-03: the AI's reading of a text before it is published.
  Future<ModerationAnalysis> analyze(String text);

  /// FRM-02 « Publier ». Throws [ForumAlertException] when the text may hurt, unless [confirmed]
  /// (« Publier quand même »: then the post is published masked until a moderator checks it).
  Future<ForumPost> publish(PostDraft draft, {bool confirmed = false});

  Future<ForumPost> editPost(String postId, PostDraft draft, {bool confirmed = false});
  Future<void> deletePost(String postId);

  /// FRM-04 reply bar: to the post, or under a reply ([parentId]). Same alert as [publish].
  Future<ForumReply> reply(String postId, String body, {String? parentId, bool confirmed = false});

  Future<ForumReply> editReply(String replyId, String body, {bool confirmed = false});

  /// A reply with answers stays as « Message supprimé ».
  Future<void> deleteReply(String replyId);

  /// +1, −1 or 0 to remove. Returns the new score.
  Future<int> vote(ForumTarget target, String id, int value);

  Future<void> react(ForumTarget target, String id, ForumReaction reaction, {required bool on});

  /// Only the post's author: a published level-1 reply by someone else, or null to clear.
  Future<void> chooseBestAnswer(String postId, String? replyId);

  Future<void> save(String postId, {required bool on});

  /// FRM-04 bell: told about new replies.
  Future<void> follow(String postId, {required bool on});

  /// FRM-04 « Suivre ».
  Future<void> followMember(String memberId, {required bool on});
  Future<bool> isFollowingMember(String memberId);

  /// FRM-05 « Ne plus voir les messages de … ».
  Future<void> block(String memberId, {required bool on});

  /// FRM-05: one report row per reporter. The phone never hides the content; after 3 reports a
  /// Supabase trigger will.
  Future<void> report(ForumTarget target, String id, ReportReason reason, {String? details, bool muteAuthor = false});

  /// « Annuler » on the « Tu as signalé ce message » strip.
  Future<void> undoReport(ForumTarget target, String id);

  /// « Cherche joueurs » « Je viens »: the reader plays, or waits once it is full.
  Future<SearchStatus> join(String postId);

  /// « Je ne viens plus »: the first one waiting moves up.
  Future<void> leave(String postId);

  /// The organiser stops (or reopens) the search.
  Future<void> closeSearch(String postId, {required bool closed});

  /// Équipement · Marketplace: the seller marks the item sold, or for sale again.
  Future<void> markSold(String postId, {required bool sold});

  /// A seller's reviews by buyers (« Avis »), with the average and the stars.
  Future<ForumReviews> sellerReviews(String sellerId);

  /// The reader's review of [sellerId] (1 to 5 stars and a few words), written once and then
  /// updated; the text goes through the FRM-03 check like a reply.
  Future<void> review(String sellerId, int rating, String text, {String? postId, bool confirmed = false});

  Future<void> deleteReview(String sellerId);

  /// When the member is suspended from posting, else null.
  Future<DateTime?> suspendedUntil();

  /// FRM-02 « Brouillon enregistré ».
  Future<PostDraft?> loadDraft();
  Future<void> saveDraft(PostDraft draft);
  Future<void> clearDraft();
}

/// The forum lives in the phone's database (schema v5), seeded with the story's discussions;
/// the shared tables are copied to Supabase by the sync.
final forumRepositoryProvider = Provider<ForumRepository>(
  (ref) => SqliteForumRepository(
    ref.watch(appDatabaseProvider),
    now: ref.watch(clockProvider),
    meId: forumUserId,
    offline: () => ref.read(simulatedOfflineProvider),
  ),
);
