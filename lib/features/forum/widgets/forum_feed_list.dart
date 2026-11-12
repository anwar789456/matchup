import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/clock.dart';
import '../../../core/connectivity.dart';
import '../../../l10n/l10n.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../controllers/forum_providers.dart';
import '../data/forum_repository.dart';
import 'forum_actions.dart';
import 'forum_format.dart';
import 'report_sheet.dart';

/// A scrolling feed of [MuForumPostCard]s for [query] (FRM-01, search, saved posts): [header]
/// above, skeletons while loading, « X t’a mentionné » lines, the next page when the end
/// comes near, [empty] when there is nothing, « Hors ligne » with « Réessayer ».
class ForumFeedList extends ConsumerWidget {
  const ForumFeedList({super.key, required this.query, this.header = const [], required this.empty});

  final ForumQuery query;
  final List<Widget> header;
  final Widget empty;

  // Room under the last card for the FAB and the tab bar.
  static const double bottomRoom = MuSpace.s16 + MuSpace.s8;
  static const int _skeletons = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(forumFeedProvider(query));
    final now = ref.read(clockProvider)();
    final ctrl = ref.read(forumFeedProvider(query).notifier);

    final children = <Widget>[...header];
    final value = feed.value;
    if (value == null && feed.hasError) {
      children.add(
        Padding(
          padding: const EdgeInsets.all(MuSpace.s6),
          child: MuEmptyState(
            title: feed.error is OfflineException ? l10n.forumHorsLigne : l10n.forumErreur,
            description: feed.error is OfflineException ? l10n.forumHorsLigneDetail : null,
            actions: [
              MuButton.secondary(
                label: l10n.reessayer,
                leading: PhosphorIcons.arrowsClockwise(),
                onPressed: () => ref.invalidate(forumFeedProvider(query)),
              ),
            ],
          ),
        ),
      );
    } else if (value == null) {
      children.add(
        MuSkeletonGroup(
          child: Column(
            children: [
              for (var i = 0; i < _skeletons; i++)
                const Padding(padding: EdgeInsets.fromLTRB(MuSpace.s4, 0, MuSpace.s4, MuSpace.s3), child: MuForumPostCard.skeleton()),
            ],
          ),
        ),
      );
    } else if (value.posts.isEmpty) {
      children.add(Padding(padding: const EdgeInsets.all(MuSpace.s6), child: empty));
    } else {
      for (final post in value.posts) {
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(MuSpace.s4, 0, MuSpace.s4, MuSpace.s3),
            child: ForumPostTile(post: post, now: now, query: query),
          ),
        );
      }
      if (value.hasMore) {
        children.add(
          const Padding(
            padding: EdgeInsets.all(MuSpace.s4),
            child: Center(child: MuSpinner()),
          ),
        );
      } else if (value.posts.length > ForumFeedController.pageSize ~/ 2) {
        children.add(
          Padding(
            padding: const EdgeInsets.all(MuSpace.s4),
            child: Text(
              l10n.forumTuAsToutVu,
              textAlign: TextAlign.center,
              style: MuType.caption.copyWith(color: context.mu.textSecondary),
            ),
          ),
        );
      }
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (value != null && value.hasMore && !value.loadingMore && n.metrics.extentAfter < MuSize.appBarLarge * 4) {
          ctrl.loadMore().catchError((Object e) {
            if (context.mounted) showForumError(context, e);
          });
        }
        return false;
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: bottomRoom),
        children: children,
      ),
    );
  }
}

/// One card of a feed, with its mention line, votes, menu and moderation state.
class ForumPostTile extends ConsumerWidget {
  const ForumPostTile({super.key, required this.post, required this.now, required this.query});

  final ForumPost post;
  final DateTime now;
  final ForumQuery query;

  // FRM-01: the mention dot is 8.
  static const double _dot = 8;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final ctrl = ref.read(forumFeedProvider(query).notifier);
    void open() => context.push(Routes.forumPost(post.id));

    if (post.hidden) {
      return MuHiddenNotice(
        title: l10n.forumMasqueParLaModeration,
        description: post.mine.author ? l10n.forumTonPostSeulToi(post.title) : null,
        action: post.mine.author ? MuButton(label: l10n.forumVoir, variant: MuButtonVariant.link, onPressed: open) : null,
      );
    }

    Future<void> run(Future<void> Function() action) async {
      try {
        await action();
      } catch (e) {
        if (context.mounted) showForumError(context, e);
      }
    }

    Future<void> report() async {
      final choice = await showReportSheet(context, target: ForumTarget.post, author: post.author);
      if (choice == null || !context.mounted) return;
      await run(() async {
        await ctrl.report(post.id, choice.reason, details: choice.details, mute: choice.mute);
        if (context.mounted) MuToast.show(context, tone: MuToastTone.success, title: l10n.forumMerciSignalement);
      });
    }

    void more() => showForumMenu(context, [
      ForumMenuItem(
        post.mine.saved ? PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.fill) : PhosphorIcons.bookmarkSimple(),
        post.mine.saved ? l10n.forumRetirerDesFavoris : l10n.forumEnregistrer,
        () => run(() async {
          final on = !post.mine.saved;
          await ctrl.save(post.id, on);
          if (context.mounted) showSavedToast(context, saved: on);
        }),
      ),
      ForumMenuItem(
        PhosphorIcons.shareNetwork(),
        l10n.partager,
        () => SharePlus.instance.share(ShareParams(text: '${post.title}\n${forumLink(post.id)}')),
      ),
      ForumMenuItem(PhosphorIcons.link(), l10n.copierLeLien, () => copyForumLink(context, post.id)),
      if (!post.mine.author && !post.mine.reported) ForumMenuItem(PhosphorIcons.flag(), l10n.forumSignaler, report, destructive: true),
    ]);

    final card = MuForumPostCard(
      post: forumCardData(post, now),
      vote: post.mine.vote,
      onVote: post.mine.author ? null : (v) => run(() => ctrl.vote(post.id, v)),
      moderation: post.mine.reported ? MuModeration.reported : MuModeration.none,
      onTap: open,
      onMore: more,
      onUndoReport: () => run(() => ctrl.undoReport(post.id)),
    );
    if (!post.mentionsMe) return card;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: MuSpace.s2),
          child: Row(
            children: [
              Container(
                width: _dot,
                height: _dot,
                decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
              ),
              const SizedBox(width: MuSpace.s2),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: post.author.name,
                        style: MuType.labelS.copyWith(color: c.text),
                      ),
                      TextSpan(text: ' ${l10n.forumTAMentionne(forumTime(post.createdAt, now))}'),
                    ],
                  ),
                  style: MuType.caption.copyWith(color: c.textSecondary),
                ),
              ),
            ],
          ),
        ),
        card,
      ],
    );
  }
}
