import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/clock.dart';
import '../../../core/connectivity.dart';
import '../../../l10n/l10n.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../controllers/messages_providers.dart';
import '../data/forum_models.dart';
import '../data/messages_repository.dart';
import '../widgets/chat_format.dart';
import '../widgets/forum_actions.dart';
import '../widgets/forum_format.dart';

/// « Messages » (Communauté): the friends to write to in one tap, then the conversations —
/// private ones and groups — the most recent first, with what was said last and the unread
/// count. « Nouveau message » starts one.
class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  String _q = '';

  Future<void> _write(ForumAuthor friend) async {
    try {
      final id = await ref.read(messagesRepositoryProvider).openDirect(friend.id);
      if (mounted) context.push(Routes.chat(id));
    } catch (e) {
      if (mounted) showForumError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final async = ref.watch(conversationsProvider);
    final friends = ref.watch(chatFriendsProvider).value ?? const [];
    final me = ref.read(messagesRepositoryProvider).meId;
    final now = ref.read(clockProvider)();
    final q = _q.toLowerCase();
    final list = (async.value ?? const <Conversation>[])
        .where((cv) => q.isEmpty || cv.title(me).toLowerCase().contains(q) || cv.members.any((m) => m.name.toLowerCase().contains(q)))
        .toList();

    final Widget body;
    if (async.value == null && async.hasError) {
      final offline = async.error is OfflineException;
      body = Padding(
        padding: const EdgeInsets.all(MuSpace.s6),
        child: MuEmptyState(
          title: offline ? l10n.forumHorsLigne : l10n.forumErreur,
          description: offline ? l10n.forumHorsLigneDetail : null,
          actions: [
            MuButton.secondary(
              label: l10n.reessayer,
              leading: PhosphorIcons.arrowsClockwise(),
              onPressed: () => ref.invalidate(conversationsProvider),
            ),
          ],
        ),
      );
    } else if (async.value == null) {
      body = const Padding(padding: EdgeInsets.all(MuSpace.s8), child: Center(child: MuSpinner()));
    } else if (list.isEmpty) {
      body = Padding(
        padding: const EdgeInsets.all(MuSpace.s6),
        child: q.isEmpty
            ? MuEmptyState(
                illustration: MuEmptyIllustration.notifications,
                title: l10n.msgAucuneConversation,
                description: l10n.msgAucuneConversationDetail,
                actions: [
                  MuButton.primary(
                    label: l10n.msgNouveauMessage,
                    leading: PhosphorIcons.notePencil(),
                    onPressed: () => context.push(Routes.messagesNew),
                  ),
                ],
              )
            : MuEmptyState(compact: true, title: l10n.forumAucunResultat(_q), description: l10n.msgAucunResultatDetail),
      );
    } else {
      body = Column(
        children: [
          for (final (i, cv) in list.indexed) ...[
            if (i > 0) Divider(height: 1, thickness: 1, indent: MuSpace.s4 + MuSize.avatarM + MuSpace.s3, color: c.border),
            ConversationTile(conversation: cv, meId: me, now: now, onTap: () => context.push(Routes.chat(cv.id))),
          ],
        ],
      );
    }

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MuTopAppBar.compact(
              title: l10n.msgMessages,
              onBack: () => context.canPop() ? context.pop() : context.go(Routes.community),
              backLabel: l10n.forumRetourALaCommunaute,
              actions: [
                MuBarAction(
                  icon: PhosphorIcons.notePencil(),
                  label: l10n.msgNouveauMessage,
                  onPressed: () => context.push(Routes.messagesNew),
                ),
              ],
            ),
            Expanded(
              child: RefreshIndicator(
                color: c.primary,
                onRefresh: () async {
                  ref.read(messagesChangesProvider.notifier).bump();
                  await ref.read(conversationsProvider.future).catchError((_) => const <Conversation>[]);
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: MuSpace.s8),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s2, MuSpace.s4, MuSpace.s4),
                      child: MuSearchField(
                        label: l10n.msgRechercherUneConversation,
                        placeholder: l10n.msgRechercherUneConversation,
                        onChanged: (v) => setState(() => _q = v.trim()),
                      ),
                    ),
                    if (friends.isNotEmpty && _q.isEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(MuSpace.s4, 0, MuSpace.s4, MuSpace.s2),
                        child: Semantics(header: true, child: Text(l10n.msgTesAmis, style: MuType.h3)),
                      ),
                      _FriendsRow(friends: friends, onTap: _write),
                      const SizedBox(height: MuSpace.s4),
                    ],
                    body,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The friends in one row: a tap opens (or starts) the private conversation.
class _FriendsRow extends StatelessWidget {
  const _FriendsRow({required this.friends, required this.onTap});

  final List<ForumAuthor> friends;
  final ValueChanged<ForumAuthor> onTap;

  static const int _max = 12;

  // Room for the avatar and a first name under it.
  static const double _height = MuSize.avatarL + MuSpace.s8;
  static const double _width = MuSize.avatarL + MuSpace.s6;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return SizedBox(
      height: _height,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: MuSpace.s3),
        children: [
          for (final f in friends.take(_max))
            Semantics(
              button: true,
              label: l10n.msgEcrireA(f.name),
              excludeSemantics: true,
              child: InkWell(
                borderRadius: MuRadius.mdAll,
                onTap: () => onTap(f),
                child: SizedBox(
                  width: _width,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      MuAvatar(name: f.name, imageUrl: f.imageUrl, size: MuAvatarSize.l, level: f.level),
                      const SizedBox(height: MuSpace.s1),
                      Text(
                        firstName(f.name),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: MuType.caption.copyWith(color: c.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One conversation: avatar (the friend, or the group's members), name, the last message and
/// its time, the unread count, muted.
class ConversationTile extends StatelessWidget {
  const ConversationTile({super.key, required this.conversation, required this.meId, required this.now, required this.onTap});

  final Conversation conversation;
  final String meId;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final cv = conversation;
    final unread = cv.unread > 0;
    final preview = conversationPreview(cv, meId);
    return Semantics(
      button: true,
      label: [cv.title(meId), preview, if (unread) l10n.msgNNonLus(cv.unread), if (cv.muted) l10n.msgEnSourdine].join(', '),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4, vertical: MuSpace.s3),
          child: Row(
            children: [
              ConversationAvatar(conversation: cv, meId: meId),
              const SizedBox(width: MuSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            cv.title(meId),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: unread ? MuType.labelL : MuType.label,
                          ),
                        ),
                        if (cv.muted) ...[
                          const SizedBox(width: MuSpace.s1),
                          Icon(PhosphorIcons.bellSlash(), size: MuSize.iconXs, color: c.textSecondary),
                        ],
                        const SizedBox(width: MuSpace.s2),
                        Text(
                          chatListTime(cv.activity, now),
                          style: MuType.caption.copyWith(color: unread ? c.text : c.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: MuSpace.s1),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            preview,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: MuType.body.copyWith(color: unread ? c.text : c.textSecondary),
                          ),
                        ),
                        if (unread) ...[const SizedBox(width: MuSpace.s2), UnreadBadge(count: cv.unread, muted: cv.muted)],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The friend's avatar, or two of the group's members overlapping.
class ConversationAvatar extends StatelessWidget {
  const ConversationAvatar({super.key, required this.conversation, required this.meId, this.size = MuAvatarSize.m});

  final Conversation conversation;
  final String meId;
  final MuAvatarSize size;

  @override
  Widget build(BuildContext context) {
    final cv = conversation;
    final side = size == MuAvatarSize.m ? MuSize.avatarM : MuSize.avatarS;
    if (!cv.group) {
      final o = cv.other(meId);
      return MuAvatar(name: o?.name ?? '', imageUrl: o?.imageUrl, size: size);
    }
    final others = cv.members.where((m) => m.id != meId).take(2).toList();
    return SizedBox(
      width: side,
      height: side,
      child: Stack(
        children: [
          for (final (i, m) in others.indexed)
            PositionedDirectional(
              start: i == 0 ? 0 : null,
              top: i == 0 ? 0 : null,
              end: i == 1 ? 0 : null,
              bottom: i == 1 ? 0 : null,
              child: MuAvatar(name: m.name, imageUrl: m.imageUrl, size: MuAvatarSize.xs, ring: true, short: true),
            ),
        ],
      ),
    );
  }
}

/// The unread count: a filled disc, muted grey when the conversation is muted.
class UnreadBadge extends StatelessWidget {
  const UnreadBadge({super.key, required this.count, this.muted = false});

  final int count;
  final bool muted;

  static const int _cap = 99;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Container(
      constraints: const BoxConstraints(minWidth: MuSize.iconM, minHeight: MuSize.iconM),
      padding: const EdgeInsets.symmetric(horizontal: MuSpace.s1 + MuSpace.s1 / 2),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: muted ? c.textDisabled : c.primary, borderRadius: MuRadius.fullAll),
      child: Text(count > _cap ? '$_cap+' : '$count', style: MuType.numXs.copyWith(color: c.onPrimary)),
    );
  }
}
