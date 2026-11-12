import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../../../core/connectivity.dart';
import '../../../core/db/app_database.dart';
import '../../../theme/theme.dart';
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
/// reports and the user-side moderation. The same rules as the forum module of the backend
/// (backend/apps/forum/README.md), so an API implementation can replace the local one without
/// touching the screens.
abstract interface class ForumRepository {
  /// The member using the app.
  Future<ForumAuthor> me();

  /// FRM-01 list, pinned first. [limit] / [offset] page it.
  Future<ForumFeed> feed(ForumQuery query, {int limit = 20, int offset = 0});

  /// The 5 categories with « nouveaux depuis ta dernière visite ».
  Future<List<ForumCategoryCount>> categories({MuSport? sport});

  /// Saves the visit (call it when leaving the Communauté), so the badges count from now.
  Future<void> markVisited();

  /// FRM-04.
  Future<ForumThread> thread(int postId, {ReplySort sort = ReplySort.useful});

  /// FRM-02 « Discussions similaires » (3 at most).
  Future<List<SimilarPost>> similar(String title, {MuSport? sport, List<String> tags = const [], int? exclude});

  /// FRM-02 « Suggérés par l’IA ».
  Future<List<TagSuggestion>> suggestTags(String title, String body, List<String> tags);

  /// FRM-03: the AI's reading of a text before it is published.
  Future<ModerationAnalysis> analyze(String text);

  /// FRM-02 « Publier ». Throws [ForumAlertException] when the text may hurt, unless [confirmed]
  /// (« Publier quand même »: then the post is published masked until a moderator checks it).
  Future<ForumPost> publish(PostDraft draft, {bool confirmed = false});

  Future<ForumPost> editPost(int postId, PostDraft draft, {bool confirmed = false});
  Future<void> deletePost(int postId);

  /// FRM-04 reply bar: to the post, or under a reply ([parentId]). Same alert as [publish].
  Future<ForumReply> reply(int postId, String body, {int? parentId, bool confirmed = false});

  Future<ForumReply> editReply(int replyId, String body, {bool confirmed = false});

  /// A reply with answers stays as « Message supprimé ».
  Future<void> deleteReply(int replyId);

  /// +1, −1 or 0 to remove. Returns the new score.
  Future<int> vote(ForumTarget target, int id, int value);

  Future<void> react(ForumTarget target, int id, ForumReaction reaction, {required bool on});

  /// Only the post's author: a published level-1 reply by someone else, or null to clear.
  Future<void> chooseBestAnswer(int postId, int? replyId);

  Future<void> save(int postId, {required bool on});

  /// FRM-04 bell: told about new replies.
  Future<void> follow(int postId, {required bool on});

  /// FRM-04 « Suivre ».
  Future<void> followMember(int memberId, {required bool on});
  Future<bool> isFollowingMember(int memberId);

  /// FRM-05 « Ne plus voir les messages de … ».
  Future<void> block(int memberId, {required bool on});

  /// FRM-05. Returns true when the content is now hidden for everyone (3rd report).
  Future<bool> report(ForumTarget target, int id, ReportReason reason, {String? details, bool muteAuthor = false});

  /// « Annuler » on the « Tu as signalé ce message » strip.
  Future<void> undoReport(ForumTarget target, int id);

  /// When the member is suspended from posting, else null.
  Future<DateTime?> suspendedUntil();

  /// FRM-02 « Brouillon enregistré ».
  Future<PostDraft?> loadDraft();
  Future<void> saveDraft(PostDraft draft);
  Future<void> clearDraft();
}

/// The forum lives in the phone's database (schema v3), seeded with the story's discussions.
final forumRepositoryProvider = Provider<ForumRepository>(
  (ref) => SqliteForumRepository(
    ref.watch(appDatabaseProvider),
    now: ref.watch(clockProvider),
    offline: () => ref.read(simulatedOfflineProvider),
  ),
);
