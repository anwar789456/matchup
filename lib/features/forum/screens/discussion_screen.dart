import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
import '../data/forum_ai.dart';
import '../data/forum_repository.dart';
import '../widgets/forum_actions.dart';
import '../widgets/forum_format.dart';
import '../widgets/forum_image.dart';
import '../widgets/forum_markdown.dart';
import '../widgets/moderation_alert.dart';
import '../widgets/report_sheet.dart';

/// FRM-04 · Discussion: the post (category, title, author with « Suivre », text, tags, votes,
/// « Utile » / « Merci »), the best answer, the replies on 2 levels sorted « Les plus utiles »,
/// masked and deleted replies as placeholders, and the reply bar. Sending runs the FRM-03 check.
class DiscussionScreen extends ConsumerStatefulWidget {
  const DiscussionScreen({super.key, required this.postId});

  final String postId;

  @override
  ConsumerState<DiscussionScreen> createState() => _DiscussionScreenState();
}

class _DiscussionScreenState extends ConsumerState<DiscussionScreen> {
  final _text = TextEditingController();
  final _focus = FocusNode();

  /// The reply being answered (« Réponse à Hamza R. »), or null for the post.
  ForumReply? _replyingTo;

  /// The own reply being edited, or null.
  ForumReply? _editing;
  bool _sending = false;

  ForumThreadController get _ctrl => ref.read(forumThreadProvider(widget.postId).notifier);

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (mounted) showForumError(context, e);
    }
  }

  void _startReply(ForumReply? to) {
    setState(() {
      _replyingTo = to;
      _editing = null;
    });
    _focus.requestFocus();
  }

  void _startEdit(ForumReply r) {
    setState(() {
      _editing = r;
      _replyingTo = null;
      _text.text = r.body ?? '';
    });
    _focus.requestFocus();
  }

  void _cancelTarget() => setState(() {
    if (_editing != null) _text.clear();
    _editing = null;
    _replyingTo = null;
  });

  Future<void> _send(ForumThread thread, {bool confirmed = false}) async {
    final text = _text.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      if (_editing != null) {
        await _ctrl.editReply(_editing!.id, text, confirmed: confirmed);
      } else {
        await _ctrl.reply(text, parentId: _replyingTo?.id, confirmed: confirmed);
      }
      if (!mounted) return;
      _text.clear();
      _focus.unfocus();
      setState(() {
        _replyingTo = null;
        _editing = null;
      });
      if (confirmed) MuToast.show(context, tone: MuToastTone.info, title: l10n.forumPublieeMasquee, icon: PhosphorIcons.eyeSlash());
    } on ForumAlertException catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      final choice = await showModerationAlert(
        context,
        text: text,
        analysis: e.analysis,
        answering: _replyingTo?.author ?? thread.post.author,
      );
      if (!mounted) return;
      switch (choice) {
        case PublishAnyway():
          await _send(thread, confirmed: true);
        case UseRewrite(:final text):
          _text.text = text;
          _focus.requestFocus();
        case EditMessage():
          _focus.requestFocus();
      }
      return;
    } catch (e) {
      if (mounted) showForumError(context, e);
    }
    if (mounted) setState(() => _sending = false);
  }

  Future<void> _report(ForumTarget target, String id, ForumAuthor author) async {
    final choice = await showReportSheet(context, target: target, author: author);
    if (choice == null || !mounted) return;
    await _run(() async {
      await _ctrl.report(target, id, choice.reason, details: choice.details, mute: choice.mute);
      if (target == ForumTarget.post) ref.invalidate(forumFeedProvider);
      if (mounted) MuToast.show(context, tone: MuToastTone.success, title: l10n.forumMerciSignalement);
    });
  }

  Future<void> _confirmDelete({required bool post, required Future<void> Function() delete}) async {
    final ok = await MuDialog.show<bool>(
      context,
      tone: MuDialogTone.destructive,
      title: post ? l10n.forumSupprimerCePost : l10n.forumSupprimerCetteReponse,
      description: post ? l10n.forumSupprimerCePostDetail : l10n.forumSupprimerCetteReponseDetail,
      actions: [
        Builder(
          builder: (context) => MuButton.secondary(
            label: l10n.annuler,
            fullWidth: true,
            size: MuButtonSize.l,
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
          ),
        ),
        Builder(
          builder: (context) => MuButton.destructive(
            label: l10n.supprimer,
            fullWidth: true,
            size: MuButtonSize.l,
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
          ),
        ),
      ],
    );
    if (ok == true) await _run(delete);
  }

  void _postMenu(ForumThread t) {
    final p = t.post;
    showForumMenu(context, [
      ForumMenuItem(
        p.mine.saved ? PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.fill) : PhosphorIcons.bookmarkSimple(),
        p.mine.saved ? l10n.forumRetirerDesFavoris : l10n.forumEnregistrer,
        () => _run(() async {
          await _ctrl.save(!p.mine.saved);
          ref.invalidate(forumFeedProvider);
        }),
      ),
      ForumMenuItem(
        PhosphorIcons.shareNetwork(),
        l10n.partager,
        () => SharePlus.instance.share(ShareParams(text: '${p.title}\n${forumLink(p.id)}')),
      ),
      ForumMenuItem(PhosphorIcons.link(), l10n.copierLeLien, () => copyForumLink(context, p.id)),
      if (p.mine.author) ...[
        ForumMenuItem(PhosphorIcons.pencilSimple(), l10n.modifier, () => context.push(Routes.forumEdit(p.id))),
        ForumMenuItem(
          PhosphorIcons.trash(),
          l10n.supprimer,
          () => _confirmDelete(
            post: true,
            delete: () async {
              await ref.read(forumRepositoryProvider).deletePost(p.id);
              ref.invalidate(forumFeedProvider);
              ref.invalidate(forumCategoriesProvider);
              if (!mounted) return;
              MuToast.show(context, tone: MuToastTone.success, title: l10n.forumPostSupprime);
              context.pop();
            },
          ),
          destructive: true,
        ),
      ] else
        ForumMenuItem(PhosphorIcons.flag(), l10n.forumSignaler, () => _report(ForumTarget.post, p.id, p.author), destructive: true),
    ]);
  }

  void _replyMenu(ForumThread t, ForumReply r) {
    final mine = r.mine.author;
    final canChooseBest = t.post.mine.author && !mine && r.parentId == null && !r.hidden && !r.deleted;
    showForumMenu(context, [
      if (canChooseBest)
        r.best
            ? ForumMenuItem(PhosphorIcons.xCircle(), l10n.forumRetirerLaMeilleureReponse, () => _run(() => _ctrl.chooseBest(null)))
            : ForumMenuItem(
                PhosphorIcons.checkCircle(),
                l10n.forumChoisirCommeMeilleureReponse,
                () => _run(() async {
                  await _ctrl.chooseBest(r.id);
                  ref.invalidate(forumFeedProvider);
                }),
              ),
      if (mine && !r.deleted) ...[
        ForumMenuItem(PhosphorIcons.pencilSimple(), l10n.modifier, () => _startEdit(r)),
        ForumMenuItem(
          PhosphorIcons.trash(),
          l10n.supprimer,
          () => _confirmDelete(post: false, delete: () => _ctrl.deleteReply(r.id)),
          destructive: true,
        ),
      ],
      if (!mine && !r.mine.reported)
        ForumMenuItem(PhosphorIcons.flag(), l10n.forumSignaler, () => _report(ForumTarget.reply, r.id, r.author), destructive: true),
    ]);
  }

  /// « Pourquoi ? » under a masked reply of the reader.
  Future<void> _why(ForumReply r) async {
    final analysis = ForumAi.analyze(r.body ?? '');
    await MuDialog.show<void>(
      context,
      tone: MuDialogTone.info,
      icon: PhosphorIcons.eyeSlash(),
      title: l10n.forumPourquoiMasque,
      description: l10n.forumPourquoiMasqueDetail(analysis.reason),
      actions: [
        Builder(
          builder: (context) => MuButton.secondary(
            label: l10n.modifier,
            fullWidth: true,
            size: MuButtonSize.l,
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
              _startEdit(r);
            },
          ),
        ),
        Builder(
          builder: (context) => MuButton.primary(
            label: l10n.jAiCompris,
            fullWidth: true,
            size: MuButtonSize.l,
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final async = ref.watch(forumThreadProvider(widget.postId));
    final thread = async.value;
    final now = ref.read(clockProvider)();

    final Widget body;
    if (thread == null && async.hasError) {
      final offline = async.error is OfflineException;
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(MuSpace.s6),
          child: MuEmptyState(
            title: offline ? l10n.forumHorsLigne : (async.error is ForumRuleException ? '${async.error}' : l10n.forumErreur),
            description: offline ? l10n.forumHorsLigneDetail : null,
            actions: [
              MuButton.secondary(
                label: l10n.reessayer,
                leading: PhosphorIcons.arrowsClockwise(),
                onPressed: () => ref.invalidate(forumThreadProvider(widget.postId)),
              ),
            ],
          ),
        ),
      );
    } else if (thread == null) {
      body = const Center(child: MuSpinner());
    } else {
      body = RefreshIndicator(
        color: c.primary,
        onRefresh: () => _ctrl.reload(),
        child: ListView(
          padding: const EdgeInsets.only(bottom: MuSpace.s6),
          children: [
            _PostHeader(thread: thread, now: now, onRun: _run),
            if (thread.bestAnswer != null)
              _BestAnswer(
                reply: thread.bestAnswer!,
                chosenBy: thread.post.author,
                now: now,
                onVote: (v) => _run(() => _ctrl.voteReply(thread.bestAnswer!.id, v)),
                onUseful: (on) => _run(() => _ctrl.reactReply(thread.bestAnswer!.id, ForumReaction.useful, on)),
                onReply: () => _startReply(thread.bestAnswer),
                onMore: () => _replyMenu(thread, thread.bestAnswer!),
              ),
            _RepliesHeader(count: thread.post.replies, sort: thread.sort, onSort: (s) => _run(() => _ctrl.sortBy(s))),
            if (thread.replies.isEmpty && thread.bestAnswer == null)
              Padding(
                padding: const EdgeInsets.all(MuSpace.s6),
                child: MuEmptyState(compact: true, title: l10n.forumPasEncoreDeReponse, description: l10n.forumPasEncoreDeReponseDetail),
              ),
            for (final (i, r) in thread.replies.indexed) ...[
              if (i > 0) Divider(height: 1, thickness: 1, indent: MuSpace.s4, endIndent: MuSpace.s4, color: c.border),
              _ReplyBlock(
                reply: r,
                now: now,
                onVote: (id, v) => _run(() => _ctrl.voteReply(id, v)),
                onReply: _startReply,
                onMore: (x) => _replyMenu(thread, x),
                onWhy: _why,
              ),
            ],
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MuTopAppBar.compact(
              title: l10n.forumDiscussion,
              onBack: () => context.canPop() ? context.pop() : context.go(Routes.community),
              backLabel: l10n.forumRetourALaCommunaute,
              actions: thread == null
                  ? const []
                  : [
                      MuBarAction(
                        icon: thread.post.mine.following ? PhosphorIcons.bellRinging(PhosphorIconsStyle.fill) : PhosphorIcons.bell(),
                        label: thread.post.mine.following ? l10n.forumNePlusSuivreLaDiscussion : l10n.forumSuivreLaDiscussion,
                        onPressed: () => _run(() async {
                          final on = !thread.post.mine.following;
                          await _ctrl.follow(on);
                          if (mounted) {
                            MuToast.show(this.context, title: on ? l10n.forumTuSuisLaDiscussion : l10n.forumTuNeSuisPlusLaDiscussion);
                          }
                        }),
                      ),
                      MuBarAction(
                        icon: PhosphorIcons.dotsThree(),
                        label: l10n.forumPlusDOptionsSignalerCopier,
                        onPressed: () => _postMenu(thread),
                      ),
                    ],
            ),
            Expanded(child: body),
            if (thread != null && !thread.post.hidden)
              _ReplyBar(
                controller: _text,
                focus: _focus,
                hint: l10n.forumRepondsA(thread.post.author.name),
                target: _editing != null
                    ? l10n.forumModifierTaReponse
                    : _replyingTo != null
                    ? l10n.forumReponseA(_replyingTo!.author.name)
                    : null,
                onCancelTarget: _cancelTarget,
                sending: _sending,
                onSend: () => _send(thread),
              ),
          ],
        ),
      ),
    );
  }
}

// ── The post ────────────────────────────────────────────────────────────────────────────────

class _PostHeader extends ConsumerWidget {
  const _PostHeader({required this.thread, required this.now, required this.onRun});

  final ForumThread thread;
  final DateTime now;
  final Future<void> Function(Future<void> Function()) onRun;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final p = thread.post;
    final ctrl = ref.read(forumThreadProvider(p.id).notifier);
    final following = ref.watch(forumFollowingMemberProvider(p.author.id)).value ?? false;
    final level = forumAuthorLevel(p.author);
    return Padding(
      padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s2, MuSpace.s4, MuSpace.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ForumCategoryGlyph(category: p.category, color: c.textSecondary),
              const SizedBox(width: MuSpace.s2),
              Text(p.category.label.toUpperCase(), style: MuType.overline.copyWith(color: c.textSecondary)),
              if (p.sport != null) ...[const SizedBox(width: MuSpace.s2), MuChip.sport(p.sport!, size: MuChipSize.s)],
              if (p.pinned) ...[
                const Spacer(),
                Icon(PhosphorIcons.pushPin(PhosphorIconsStyle.fill), size: MuSize.iconXs, color: c.textSecondary),
                const SizedBox(width: MuSpace.s1),
                Text(l10n.forumEpingle, style: MuType.labelS.copyWith(color: c.textSecondary)),
              ],
            ],
          ),
          const SizedBox(height: MuSpace.s2),
          Semantics(header: true, child: Text(p.title, style: MuType.h2)),
          const SizedBox(height: MuSpace.s3),
          Row(
            children: [
              MuAvatar(name: p.author.name, imageUrl: p.author.imageUrl, level: p.author.level),
              const SizedBox(width: MuSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.author.name, style: MuType.label),
                    Text(
                      [if (level.isNotEmpty) level, forumTime(p.createdAt, now), if (p.editedAt != null) l10n.forumModifie].join(' · '),
                      style: MuType.caption.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              ),
              if (!p.mine.author)
                MuToggleButton(
                  size: MuToggleSize.s,
                  pressed: following,
                  icon: PhosphorIcons.userPlus(),
                  label: l10n.forumSuivre,
                  onLabel: l10n.forumSuivi,
                  onChanged: (on) => onRun(() async {
                    await ref.read(forumRepositoryProvider).followMember(p.author.id, on: on);
                    ref.invalidate(forumFollowingMemberProvider(p.author.id));
                  }),
                ),
            ],
          ),
          if (p.hidden) ...[
            const SizedBox(height: MuSpace.s4),
            MuHiddenNotice(title: l10n.forumMasqueParLaModeration, description: p.mine.author ? l10n.forumTonPostSeulToiDetail : null),
          ],
          if (p.body != null) ...[const SizedBox(height: MuSpace.s4), ForumMarkdown(p.body!)],
          if (p.images.isNotEmpty) ...[const SizedBox(height: MuSpace.s4), ForumImageGrid(images: p.images)],
          if (p.tags.isNotEmpty) ...[
            const SizedBox(height: MuSpace.s3),
            Wrap(
              spacing: MuSpace.s3,
              runSpacing: MuSpace.s1,
              children: [for (final t in p.tags) Text(ForumAi.hashtag(t), style: MuType.labelS.copyWith(color: c.textSecondary))],
            ),
          ],
          const SizedBox(height: MuSpace.s4),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: MuSpace.s2,
            runSpacing: MuSpace.s2,
            children: [
              MuVoteCapsule(
                score: p.score,
                vote: p.mine.vote,
                onVote: p.mine.author || p.hidden ? null : (v) => onRun(() => ctrl.votePost(v)),
              ),
              MuChip(
                icon: PhosphorIcons.thumbsUp(p.mine.useful ? PhosphorIconsStyle.fill : PhosphorIconsStyle.regular),
                label: l10n.forumUtile,
                count: p.useful,
                size: MuChipSize.s,
                selected: p.mine.useful,
                onSelected: p.mine.author || p.hidden ? null : (on) => onRun(() => ctrl.reactPost(ForumReaction.useful, on)),
              ),
              MuChip(
                icon: PhosphorIcons.handshake(),
                label: l10n.forumMerci,
                count: p.thanks,
                size: MuChipSize.s,
                selected: p.mine.thanks,
                onSelected: p.mine.author || p.hidden ? null : (on) => onRun(() => ctrl.reactPost(ForumReaction.thanks, on)),
              ),
              Semantics(
                label: l10n.forumNReponses(p.replies),
                excludeSemantics: true,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(start: MuSpace.s2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(PhosphorIcons.chatCircle(), size: MuSize.iconXs, color: c.textSecondary),
                      const SizedBox(width: MuSpace.s1),
                      Text('${p.replies}', style: MuType.numXs.copyWith(color: c.textSecondary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The category icon: Phosphor, or the custom glyph for Terrains and Tournois.
class ForumCategoryGlyph extends StatelessWidget {
  const ForumCategoryGlyph({super.key, required this.category, required this.color, this.size = MuSize.iconXs});

  final ForumCategory category;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => category.glyph != null
      ? SvgPicture.asset(
          category.glyph!,
          width: size,
          height: size,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          excludeFromSemantics: true,
        )
      : Icon(category.icon, size: size, color: color);
}

// ── Replies ─────────────────────────────────────────────────────────────────────────────────

/// « Meilleure réponse · choisie par Skander T. »: a `success` bordered card on a muted band.
class _BestAnswer extends StatelessWidget {
  const _BestAnswer({
    required this.reply,
    required this.chosenBy,
    required this.now,
    required this.onVote,
    required this.onUseful,
    required this.onReply,
    required this.onMore,
  });

  final ForumReply reply;
  final ForumAuthor chosenBy;
  final DateTime now;
  final ValueChanged<int> onVote;
  final ValueChanged<bool> onUseful;
  final VoidCallback onReply;
  final VoidCallback onMore;

  // FRM-04: the best answer's border is 2 px.
  static const double _border = 2;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return ColoredBox(
      color: c.surfaceMuted,
      child: Padding(
        padding: const EdgeInsets.all(MuSpace.s4),
        child: Container(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: MuRadius.mdAll,
            border: Border.all(color: c.success, width: _border),
          ),
          padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s3, MuSpace.s4, MuSpace.s2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(PhosphorIcons.checkCircle(PhosphorIconsStyle.fill), size: MuSize.iconS, color: c.success),
                  const SizedBox(width: MuSpace.s2),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(l10n.forumMeilleureReponse, style: MuType.label.copyWith(color: c.successText)),
                    ),
                  ),
                  Text(l10n.forumChoisiePar(chosenBy.name), style: MuType.caption.copyWith(color: c.textSecondary)),
                ],
              ),
              const SizedBox(height: MuSpace.s3),
              _ReplyTile(reply: reply, now: now, level: 1, onVote: onVote, onUseful: onUseful, onReply: onReply, onMore: onMore),
            ],
          ),
        ),
      ),
    );
  }
}

class _RepliesHeader extends StatelessWidget {
  const _RepliesHeader({required this.count, required this.sort, required this.onSort});

  final int count;
  final ReplySort sort;
  final ValueChanged<ReplySort> onSort;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(MuSpace.s4, MuSpace.s5, MuSpace.s2, MuSpace.s1),
      child: Row(
        children: [
          Expanded(
            child: Semantics(header: true, child: Text(l10n.forumNReponses(count), style: MuType.h3)),
          ),
          MuButton.tertiary(
            label: sort.label,
            trailing: PhosphorIcons.caretDown(),
            size: MuButtonSize.s,
            onPressed: () => showForumMenu(context, [
              for (final s in ReplySort.values)
                ForumMenuItem(
                  s == sort ? PhosphorIcons.check(PhosphorIconsStyle.bold) : PhosphorIcons.sortDescending(),
                  s.label,
                  () => onSort(s),
                ),
            ]),
          ),
        ],
      ),
    );
  }
}

/// A level-1 reply with its answers indented behind a rule.
class _ReplyBlock extends StatelessWidget {
  const _ReplyBlock({
    required this.reply,
    required this.now,
    required this.onVote,
    required this.onReply,
    required this.onMore,
    required this.onWhy,
  });

  final ForumReply reply;
  final DateTime now;
  final void Function(String id, int value) onVote;
  final ValueChanged<ForumReply> onReply;
  final ValueChanged<ForumReply> onMore;
  final ValueChanged<ForumReply> onWhy;

  // FRM-04: the thread rule of the answers is 2 px, under the avatar's centre.
  static const double _rule = 2;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Padding(
      padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s4, MuSpace.s4, MuSpace.s2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ReplyTile(
            reply: reply,
            now: now,
            level: 1,
            onVote: (v) => onVote(reply.id, v),
            onReply: () => onReply(reply),
            onMore: () => onMore(reply),
            onWhy: () => onWhy(reply),
          ),
          if (reply.children.isNotEmpty)
            Container(
              margin: const EdgeInsetsDirectional.only(start: MuSize.avatarM / 2 - _rule / 2, top: MuSpace.s2),
              padding: const EdgeInsetsDirectional.only(start: MuSpace.s5),
              decoration: BoxDecoration(
                border: BorderDirectional(
                  start: BorderSide(color: c.border, width: _rule),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final child in reply.children)
                    Padding(
                      padding: const EdgeInsets.only(bottom: MuSpace.s3),
                      child: _ReplyTile(
                        reply: child,
                        now: now,
                        level: 2,
                        onVote: (v) => onVote(child.id, v),
                        onReply: () => onReply(child),
                        onMore: () => onMore(child),
                        onWhy: () => onWhy(child),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ReplyTile extends StatelessWidget {
  const _ReplyTile({
    required this.reply,
    required this.now,
    required this.level,
    required this.onVote,
    required this.onReply,
    required this.onMore,
    this.onUseful,
    this.onWhy,
  });

  final ForumReply reply;
  final DateTime now;
  final int level;
  final ValueChanged<int> onVote;
  final VoidCallback onReply;
  final VoidCallback onMore;
  final ValueChanged<bool>? onUseful;
  final VoidCallback? onWhy;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final r = reply;
    final caption = MuType.caption.copyWith(color: c.textSecondary);

    if (r.hidden) {
      return MuHiddenNotice(
        title: l10n.forumMasqueParLaModeration,
        description: r.mine.author
            ? (r.answering != null ? l10n.forumTaReponseASeulToi(r.answering!.name) : l10n.forumTaReponseSeulToi)
            : null,
        action: r.mine.author && onWhy != null
            ? MuButton(label: l10n.forumPourquoi, variant: MuButtonVariant.link, onPressed: onWhy)
            : null,
      );
    }
    if (r.deleted || r.blocked) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: MuSpace.s2),
        child: Row(
          children: [
            Icon(r.deleted ? PhosphorIcons.trash() : PhosphorIcons.eyeSlash(), size: MuSize.iconXs, color: c.textSecondary),
            const SizedBox(width: MuSpace.s2),
            Text(
              r.deleted ? l10n.forumMessageSupprime : l10n.forumMessageDUnMembreMasque,
              style: caption.copyWith(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      );
    }

    final canReact = !r.mine.author;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MuAvatar(
          name: r.author.name,
          imageUrl: r.author.imageUrl,
          size: level == 1 ? MuAvatarSize.m : MuAvatarSize.s,
          level: level == 1 ? r.author.level : null,
        ),
        const SizedBox(width: MuSpace.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: MuSpace.s1,
                      children: [
                        Text(r.author.name, style: MuType.labelS),
                        if (r.byPostAuthor) const _AuthorBadge(),
                        // « · toi · il y a 2 j » (FRM-04).
                        Text(
                          '· ${[if (r.mine.author) l10n.forumToi, forumTime(r.createdAt, now), if (r.editedAt != null) l10n.forumModifie].join(' · ')}',
                          style: caption,
                        ),
                      ],
                    ),
                  ),
                  MuIconButton(icon: PhosphorIcons.dotsThree(), label: l10n.plusDOptions, size: MuIconButtonSize.s, onPressed: onMore),
                ],
              ),
              ForumMarkdown(r.body ?? '', style: MuType.body),
              const SizedBox(height: MuSpace.s1),
              Row(
                children: [
                  _InlineVote(score: r.score, vote: r.mine.vote, onVote: canReact ? onVote : null),
                  if (onUseful != null)
                    _InlineAction(
                      icon: PhosphorIcons.thumbsUp(r.mine.useful ? PhosphorIconsStyle.fill : PhosphorIconsStyle.regular),
                      label: l10n.forumUtileN(r.useful),
                      pressed: r.mine.useful,
                      onTap: canReact ? () => onUseful!(!r.mine.useful) : null,
                    ),
                  _InlineAction(icon: PhosphorIcons.arrowBendUpLeft(), label: l10n.forumRepondre, onTap: onReply),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// « Auteur » next to the name of the post's author.
class _AuthorBadge extends StatelessWidget {
  const _AuthorBadge();

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: MuSpace.s1 + MuSpace.s1 / 2),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: MuRadius.xsAll,
        border: Border.all(color: c.border),
      ),
      child: Text(l10n.forumAuteur, style: MuType.labelS),
    );
  }
}

/// The compact vote of a reply: the up arrow (a Volt disc when voted) and the score. A long
/// press votes down.
class _InlineVote extends StatelessWidget {
  const _InlineVote({required this.score, required this.vote, required this.onVote});

  final int score;
  final int vote;
  final ValueChanged<int>? onVote;

  static const double _disc = 24;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final up = vote == 1;
    final down = vote == -1;
    return Semantics(
      button: true,
      toggled: up,
      label: l10n.forumVoterPourNVotes(MuVoteCapsule.formatScore(score)),
      excludeSemantics: true,
      child: InkWell(
        borderRadius: MuRadius.fullAll,
        onTap: onVote == null ? null : () => onVote!(up ? 0 : 1),
        onLongPress: onVote == null ? null : () => onVote!(down ? 0 : -1),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: MuSize.touchTarget, minWidth: MuSize.touchTarget),
          child: Padding(
            padding: const EdgeInsetsDirectional.only(end: MuSpace.s3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: MuMotion.durationOf(context, MuMotion.fast),
                  width: _disc,
                  height: _disc,
                  decoration: BoxDecoration(color: up ? c.accent : Colors.transparent, shape: BoxShape.circle),
                  child: Icon(
                    down
                        ? PhosphorIcons.arrowFatDown(PhosphorIconsStyle.fill)
                        : PhosphorIcons.arrowFatUp(up ? PhosphorIconsStyle.fill : PhosphorIconsStyle.regular),
                    size: MuSize.iconXs,
                    color: up ? c.onAccent : (onVote == null ? c.textDisabled : c.textSecondary),
                  ),
                ),
                const SizedBox(width: MuSpace.s1),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(MuVoteCapsule.formatScore(score), style: MuType.numXs.copyWith(color: c.textSecondary)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineAction extends StatelessWidget {
  const _InlineAction({required this.icon, required this.label, required this.onTap, this.pressed});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool? pressed;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final color = onTap == null ? c.textDisabled : c.textSecondary;
    return Semantics(
      button: true,
      toggled: pressed,
      child: InkWell(
        borderRadius: MuRadius.smAll,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: MuSize.touchTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: MuSpace.s2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: MuSize.iconXs, color: pressed == true ? c.text : color),
                const SizedBox(width: MuSpace.s1),
                Text(label, style: MuType.labelS.copyWith(color: color)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── The reply bar ───────────────────────────────────────────────────────────────────────────

class _ReplyBar extends ConsumerWidget {
  const _ReplyBar({
    required this.controller,
    required this.focus,
    required this.hint,
    required this.target,
    required this.onCancelTarget,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final String hint;

  /// « Réponse à Hamza R. » / « Modifier ta réponse », or null.
  final String? target;
  final VoidCallback onCancelTarget;
  final bool sending;
  final VoidCallback onSend;

  static const int _maxLines = 5;

  /// Same limit as a post's message.
  static const int _maxLength = 2000;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final me = ref.watch(forumMeProvider).value;
    final canSend = controller.text.trim().isNotEmpty && !sending;
    return Material(
      color: c.surface,
      child: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: c.border)),
        ),
        padding: EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s2, MuSpace.s4, MuSpace.s2 + MediaQuery.paddingOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (target != null)
              Row(
                children: [
                  Icon(PhosphorIcons.arrowBendUpLeft(), size: MuSize.iconXs, color: c.textSecondary),
                  const SizedBox(width: MuSpace.s2),
                  Expanded(
                    child: Text(target!, style: MuType.labelS.copyWith(color: c.textSecondary)),
                  ),
                  MuIconButton(icon: PhosphorIcons.x(), label: l10n.annuler, size: MuIconButtonSize.s, onPressed: onCancelTarget),
                ],
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: MuSpace.s1),
                  child: MuAvatar(name: me?.name ?? '', size: MuAvatarSize.s),
                ),
                const SizedBox(width: MuSpace.s3),
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(minHeight: MuSize.controlL),
                    decoration: BoxDecoration(
                      color: c.surfaceMuted,
                      borderRadius: MuRadius.lgAll,
                      border: Border.all(color: focus.hasFocus ? c.focus : c.border),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4, vertical: MuSpace.s3),
                    child: TextField(
                      controller: controller,
                      focusNode: focus,
                      minLines: 1,
                      maxLines: _maxLines,
                      maxLength: _maxLength,
                      buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                      textCapitalization: TextCapitalization.sentences,
                      keyboardType: TextInputType.multiline,
                      style: MuType.body.copyWith(color: c.text),
                      decoration: InputDecoration(
                        isCollapsed: true,
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        hintText: hint,
                        hintStyle: MuType.body.copyWith(color: c.textSecondary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: MuSpace.s2),
                MuIconButton(
                  icon: PhosphorIcons.paperPlaneRight(),
                  label: l10n.envoyer,
                  variant: MuIconButtonVariant.primary,
                  onPressed: canSend ? onSend : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
