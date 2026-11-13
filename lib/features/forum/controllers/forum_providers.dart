import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/sync/sync_service.dart';
import '../../../theme/theme.dart';
import '../data/forum_repository.dart';

/// Bumped after every change the member makes, so every list and thread already built shows it
/// at once: a post saved from the feed is in « Favoris », a vote in FRM-04 is on the feed card
/// when coming back, a new reply counts on the card…
class ForumChanges extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final forumChangesProvider = NotifierProvider<ForumChanges, int>(ForumChanges.new);

/// The member using the app (avatar of the compose field and the reply bar).
final forumMeProvider = FutureProvider<ForumAuthor>((ref) {
  ref.watch(syncRevisionProvider);
  return ref.watch(forumRepositoryProvider).me();
});

/// FRM-01 filters: category tile, sport chip, sort.
class ForumQueryController extends Notifier<ForumQuery> {
  @override
  ForumQuery build() => const ForumQuery();

  void category(ForumCategory? c) => state = state.copyWith(category: () => state.category == c ? null : c);
  void sport(MuSport? s) => state = state.copyWith(sport: () => s);
  void sort(ForumSort s) => state = state.copyWith(sort: s);

  /// Only the « Cherche joueurs » that can still be joined.
  void looking(bool on) => state = state.copyWith(lookingOnly: on);
}

final forumQueryProvider = NotifierProvider<ForumQueryController, ForumQuery>(ForumQueryController.new);

/// The previous visit, read once per session; the visit is saved at the same time, so the
/// « nouveaux » badges count from it all session long and from now next time.
final forumPreviousVisitProvider = FutureProvider<DateTime?>((ref) => ref.watch(forumRepositoryProvider).markVisited());

/// The 5 category tiles with their « nouveaux depuis ta dernière visite » badges, refreshed when
/// the sync brings new posts.
final forumCategoriesProvider = FutureProvider<List<ForumCategoryCount>>((ref) async {
  ref.watch(syncRevisionProvider);
  ref.watch(forumChangesProvider);
  final since = await ref.watch(forumPreviousVisitProvider.future);
  return ref.watch(forumRepositoryProvider).categories(since: since);
});

/// A page of the feed plus the paging state.
class ForumFeedState {
  const ForumFeedState({required this.total, required this.posts, this.loadingMore = false});

  final int total;
  final List<ForumPost> posts;
  final bool loadingMore;

  bool get hasMore => posts.length < total;

  ForumFeedState copyWith({int? total, List<ForumPost>? posts, bool? loadingMore}) =>
      ForumFeedState(total: total ?? this.total, posts: posts ?? this.posts, loadingMore: loadingMore ?? this.loadingMore);
}

/// A feed (FRM-01, search, saved posts) for one [ForumQuery], paged by 20, with the reader's
/// votes and saves applied at once and saved in the background (rolled back on failure).
class ForumFeedController extends AsyncNotifier<ForumFeedState> {
  ForumFeedController(this.query);

  final ForumQuery query;
  static const pageSize = 20;

  ForumRepository get _repo => ref.read(forumRepositoryProvider);

  @override
  Future<ForumFeedState> build() async {
    // New rows from other phones refresh the list, keeping the pages already loaded.
    ref.watch(syncRevisionProvider);
    // The member's own changes refresh the cards where they are, without reordering the list.
    ref.listen(forumChangesProvider, (_, _) => _refreshInPlace());
    final loaded = state.value?.posts.length ?? 0;
    final feed = await ref.watch(forumRepositoryProvider).feed(query, limit: loaded > pageSize ? loaded : pageSize);
    return ForumFeedState(total: feed.total, posts: feed.posts);
  }

  void _changed() => ref.read(forumChangesProvider.notifier).bump();

  /// Reloads the pages already shown and keeps the cards in their place: a vote does not make
  /// the card jump in « Tendance ». New posts (just published, just saved) come first, gone
  /// ones leave.
  Future<void> _refreshInPlace() async {
    final s = state.value;
    if (s == null) return;
    try {
      final fresh = await _repo.feed(query, limit: s.posts.length > pageSize ? s.posts.length : pageSize);
      final byId = {for (final p in fresh.posts) p.id: p};
      final shown = {for (final p in s.posts) p.id};
      final now = state.value ?? s;
      state = AsyncData(
        now.copyWith(
          total: fresh.total,
          posts: [
            for (final p in fresh.posts)
              if (!shown.contains(p.id)) p,
            for (final p in s.posts) ?byId[p.id],
          ],
        ),
      );
    } catch (_) {
      // Offline or failing: the cards keep what they show; the next change or sync retries.
    }
  }

  Future<void> loadMore() async {
    final s = state.value;
    if (s == null || s.loadingMore || !s.hasMore) return;
    state = AsyncData(s.copyWith(loadingMore: true));
    try {
      final next = await _repo.feed(query, limit: pageSize, offset: s.posts.length);
      state = AsyncData(s.copyWith(total: next.total, posts: [...s.posts, ...next.posts], loadingMore: false));
    } catch (_) {
      state = AsyncData(s.copyWith(loadingMore: false));
      rethrow;
    }
  }

  void _replace(ForumPost post) {
    final s = state.value;
    if (s == null) return;
    state = AsyncData(s.copyWith(posts: [for (final p in s.posts) p.id == post.id ? post : p]));
  }

  ForumPost? _find(String id) => state.value?.posts.where((p) => p.id == id).firstOrNull;

  /// Votes at once; the score is corrected from the database, or rolled back on error.
  Future<void> vote(String postId, int value) async {
    final before = _find(postId);
    if (before == null) return;
    _replace(
      before.copyWith(
        score: before.score - before.mine.vote + value,
        mine: before.mine.copyWith(vote: value),
      ),
    );
    try {
      final score = await _repo.vote(ForumTarget.post, postId, value);
      final now = _find(postId);
      if (now != null) _replace(now.copyWith(score: score));
      _changed();
    } catch (_) {
      _replace(before);
      rethrow;
    }
  }

  Future<void> save(String postId, bool on) async {
    final before = _find(postId);
    if (before == null) return;
    _replace(before.copyWith(mine: before.mine.copyWith(saved: on)));
    try {
      await _repo.save(postId, on: on);
      _changed();
    } catch (_) {
      _replace(before);
      rethrow;
    }
  }

  Future<void> undoReport(String postId) async {
    final before = _find(postId);
    if (before == null) return;
    _replace(before.copyWith(mine: before.mine.copyWith(reported: false)));
    await _repo.undoReport(ForumTarget.post, postId);
    _changed();
  }

  /// FRM-05 from a card.
  Future<void> report(String postId, ReportReason reason, {String? details, bool mute = false}) async {
    await _repo.report(ForumTarget.post, postId, reason, details: details, muteAuthor: mute);
    _changed();
  }
}

final forumFeedProvider = AsyncNotifierProvider.family<ForumFeedController, ForumFeedState, ForumQuery>(ForumFeedController.new);

/// FRM-04 for one post, with the reply sort.
class ForumThreadController extends AsyncNotifier<ForumThread> {
  ForumThreadController(this.postId);

  final String postId;
  ReplySort _sort = ReplySort.useful;

  ForumRepository get _repo => ref.read(forumRepositoryProvider);

  @override
  Future<ForumThread> build() {
    // Replies, votes and reactions from other phones appear while the thread is open.
    ref.watch(syncRevisionProvider);
    // A change made elsewhere (the post saved or voted from a feed) shows when coming back.
    ref.listen(forumChangesProvider, (_, _) {
      if (!_changing) _quietReload();
    });
    return ref.watch(forumRepositoryProvider).thread(postId, sort: _sort);
  }

  /// True while this thread tells the others about its own change (it is already up to date).
  bool _changing = false;

  void _changed() {
    _changing = true;
    try {
      ref.read(forumChangesProvider.notifier).bump();
    } finally {
      _changing = false;
    }
  }

  Future<void> _quietReload() async {
    try {
      state = AsyncData(await _repo.thread(postId, sort: _sort));
    } catch (_) {
      // The post was deleted or the phone is offline: keep what is shown.
    }
  }

  Future<void> sortBy(ReplySort sort) async {
    _sort = sort;
    state = AsyncData(await _repo.thread(postId, sort: sort));
  }

  Future<void> reload() async => state = AsyncData(await _repo.thread(postId, sort: _sort));

  ForumThread? get _t => state.value;

  void _setPost(ForumPost p) {
    final t = _t;
    if (t != null) state = AsyncData(ForumThread(post: p, bestAnswer: t.bestAnswer, replies: t.replies, sort: t.sort));
  }

  void _setReply(ForumReply r) {
    final t = _t;
    if (t == null) return;
    ForumReply swap(ForumReply x) => x.id == r.id
        ? r
        : (x.children.any((c) => c.id == r.id) ? x.copyWith(children: [for (final c in x.children) c.id == r.id ? r : c]) : x);
    state = AsyncData(
      ForumThread(
        post: t.post,
        bestAnswer: t.bestAnswer == null ? null : swap(t.bestAnswer!),
        replies: [for (final x in t.replies) swap(x)],
        sort: t.sort,
      ),
    );
  }

  ForumReply? findReply(String id) {
    final t = _t;
    if (t == null) return null;
    for (final r in [?t.bestAnswer, ...t.replies]) {
      if (r.id == id) return r;
      for (final c in r.children) {
        if (c.id == id) return c;
      }
    }
    return null;
  }

  Future<void> votePost(int value) async {
    final before = _t?.post;
    if (before == null) return;
    _setPost(
      before.copyWith(
        score: before.score - before.mine.vote + value,
        mine: before.mine.copyWith(vote: value),
      ),
    );
    try {
      final score = await _repo.vote(ForumTarget.post, postId, value);
      _setPost(_t!.post.copyWith(score: score));
      _changed();
    } catch (_) {
      _setPost(before);
      rethrow;
    }
  }

  Future<void> reactPost(ForumReaction reaction, bool on) async {
    final before = _t?.post;
    if (before == null) return;
    final delta = on ? 1 : -1;
    _setPost(
      reaction == ForumReaction.useful
          ? before.copyWith(
              useful: before.useful + delta,
              mine: before.mine.copyWith(useful: on),
            )
          : before.copyWith(
              thanks: before.thanks + delta,
              mine: before.mine.copyWith(thanks: on),
            ),
    );
    try {
      await _repo.react(ForumTarget.post, postId, reaction, on: on);
      _changed();
    } catch (_) {
      _setPost(before);
      rethrow;
    }
  }

  Future<void> follow(bool on) async {
    final before = _t?.post;
    if (before == null) return;
    _setPost(before.copyWith(mine: before.mine.copyWith(following: on)));
    try {
      await _repo.follow(postId, on: on);
      _changed();
    } catch (_) {
      _setPost(before);
      rethrow;
    }
  }

  Future<void> save(bool on) async {
    final before = _t?.post;
    if (before == null) return;
    _setPost(before.copyWith(mine: before.mine.copyWith(saved: on)));
    try {
      await _repo.save(postId, on: on);
      _changed();
    } catch (_) {
      _setPost(before);
      rethrow;
    }
  }

  Future<void> voteReply(String id, int value) async {
    final before = findReply(id);
    if (before == null) return;
    _setReply(
      before.copyWith(
        score: before.score - before.mine.vote + value,
        mine: before.mine.copyWith(vote: value),
      ),
    );
    try {
      final score = await _repo.vote(ForumTarget.reply, id, value);
      final now = findReply(id);
      if (now != null) _setReply(now.copyWith(score: score));
      _changed();
    } catch (_) {
      _setReply(before);
      rethrow;
    }
  }

  Future<void> reactReply(String id, ForumReaction reaction, bool on) async {
    final before = findReply(id);
    if (before == null) return;
    final delta = on ? 1 : -1;
    _setReply(
      reaction == ForumReaction.useful
          ? before.copyWith(
              useful: before.useful + delta,
              mine: before.mine.copyWith(useful: on),
            )
          : before.copyWith(
              thanks: before.thanks + delta,
              mine: before.mine.copyWith(thanks: on),
            ),
    );
    try {
      await _repo.react(ForumTarget.reply, id, reaction, on: on);
      _changed();
    } catch (_) {
      _setReply(before);
      rethrow;
    }
  }

  /// Publishes a reply (throws [ForumAlertException] for FRM-03) and reloads the thread.
  Future<ForumReply> reply(String body, {String? parentId, bool confirmed = false}) async {
    final r = await _repo.reply(postId, body, parentId: parentId, confirmed: confirmed);
    await reload();
    _changed();
    return r;
  }

  Future<void> editReply(String id, String body, {bool confirmed = false}) async {
    await _repo.editReply(id, body, confirmed: confirmed);
    await reload();
    _changed();
  }

  Future<void> deleteReply(String id) async {
    await _repo.deleteReply(id);
    await reload();
    _changed();
  }

  Future<void> chooseBest(String? replyId) async {
    await _repo.chooseBestAnswer(postId, replyId);
    await reload();
    _changed();
  }

  Future<void> report(ForumTarget target, String id, ReportReason reason, {String? details, bool mute = false}) async {
    await _repo.report(target, id, reason, details: details, muteAuthor: mute);
    await reload();
    _changed();
  }
}

final forumThreadProvider = AsyncNotifierProvider.family<ForumThreadController, ForumThread, String>(ForumThreadController.new);

/// Whether the reader follows a member (FRM-04 « Suivre »).
final forumFollowingMemberProvider = FutureProvider.family<bool, String>((ref, id) {
  ref.watch(syncRevisionProvider);
  ref.watch(forumChangesProvider);
  return ref.watch(forumRepositoryProvider).isFollowingMember(id);
});
