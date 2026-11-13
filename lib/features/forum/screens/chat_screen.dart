import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/clock.dart';
import '../../../core/connectivity.dart';
import '../../../core/format.dart';
import '../../../l10n/l10n.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../controllers/messages_providers.dart';
import '../data/forum_repository.dart';
import '../data/messages_repository.dart';
import '../../common/data/pro_providers.dart' show fileSourceProvider;
import '../widgets/chat_composer.dart';
import '../widgets/chat_format.dart';
import '../widgets/chat_sheets.dart';
import '../widgets/forum_actions.dart';
import '../widgets/forum_format.dart';
import '../widgets/forum_image.dart';
import '../widgets/listing_widgets.dart' show ListingSummary;
import '../widgets/media_picker.dart';
import '../widgets/moderation_alert.dart';
import '../widgets/report_sheet.dart';
import 'discussion_screen.dart' show ForumCategoryGlyph;

/// A conversation (Communauté · Messages): the messages by day, in bubbles — the reader's on the
/// end side — with replies, reactions and the chat's cards (poll, match, shared discussion);
/// « + » adds a card, sending runs the forum's FRM-03 check. A long press on a message opens
/// its actions.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.conversationId, this.initialText});

  final String conversationId;

  /// Ready in the bar, not sent (« Bonjour ! Est-ce toujours disponible ? »).
  final String? initialText;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _text = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  ChatMessage? _replyTo;
  bool _sending = false;

  ChatController get _ctrl => ref.read(chatProvider(widget.conversationId).notifier);

  /// Photos sent in one go from the picker.
  static const int _photosAtOnce = 6;

  @override
  void initState() {
    super.initState();
    if (widget.initialText != null) _text.text = widget.initialText!;
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Back to the newest message (the list is reversed: the bottom is 0).
  void _toBottom() {
    if (!_scroll.hasClients) return;
    final duration = MuMotion.durationOf(context, MuMotion.base);
    // Reduced motion: no glide.
    if (duration == Duration.zero) {
      _scroll.jumpTo(0);
    } else {
      _scroll.animateTo(0, duration: duration, curve: MuMotion.move);
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } on ForumAlertException catch (e) {
      // A poll that may hurt: same alert, the poll is not sent.
      if (mounted) await showModerationAlert(context, text: '', analysis: e.analysis);
    } catch (e) {
      if (mounted) showForumError(context, e);
    }
  }

  Future<void> _send(Conversation conversation, {bool confirmed = false}) async {
    final text = _text.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await _ctrl.send(text, replyToId: _replyTo?.id, confirmed: confirmed);
      if (!mounted) return;
      _toBottom();
      _text.clear();
      setState(() => _replyTo = null);
      if (confirmed) MuToast.show(context, tone: MuToastTone.info, title: l10n.forumPublieeMasquee, icon: PhosphorIcons.eyeSlash());
    } on ForumAlertException catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      final choice = await showModerationAlert(
        context,
        text: text,
        analysis: e.analysis,
        answering: _replyTo?.author ?? conversation.other(ref.read(messagesRepositoryProvider).meId),
      );
      if (!mounted) return;
      switch (choice) {
        case PublishAnyway():
          await _send(conversation, confirmed: true);
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

  void _reply(ChatMessage m) {
    setState(() => _replyTo = m);
    _focus.requestFocus();
  }

  Future<void> _actions(ChatMessage m) async {
    final choice = await showMessageActions(context, message: m);
    if (choice == null || !mounted) return;
    switch (choice) {
      case MessageReact(:final emoji):
        await _run(() => _ctrl.react(m.id, emoji));
      case MessageReply():
        _reply(m);
      case MessageCopy():
        await Clipboard.setData(ClipboardData(text: m.body));
        if (mounted) MuToast.show(context, tone: MuToastTone.success, title: l10n.msgMessageCopie, icon: PhosphorIcons.copy());
      case MessageDelete():
        final ok = await MuDialog.show<bool>(
          context,
          tone: MuDialogTone.destructive,
          title: l10n.msgSupprimerCeMessage,
          description: l10n.msgSupprimerCeMessageDetail,
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
        if (ok == true) await _run(() => _ctrl.delete(m.id));
      case MessageReport():
        final report = await showReportSheet(context, target: ForumTarget.reply, author: m.author);
        if (report == null || !mounted) return;
        await _run(() async {
          await _ctrl.report(m.id, report.reason, details: report.details, mute: report.mute);
          if (mounted) MuToast.show(context, tone: MuToastTone.success, title: l10n.forumMerciSignalement);
        });
    }
  }

  Future<void> _attach() async {
    final choice = await showAttachSheet(context);
    if (choice == null || !mounted) return;
    switch (choice) {
      case AttachKind.photo:
        final photos = await pickPhotos(context, ref.read(fileSourceProvider), room: _photosAtOnce);
        for (final src in photos) {
          await _run(() => _ctrl.sendMedia(src).then((_) => _toBottom()));
        }
      case AttachKind.video:
        final video = await pickVideo(context, ref.read(fileSourceProvider));
        if (video != null) await _run(() => _ctrl.sendMedia(video).then((_) => _toBottom()));
      case AttachKind.poll:
        final poll = await showPollSheet(context);
        if (poll != null) await _run(() => _ctrl.sendPoll(poll.question, poll.options).then((_) => _toBottom()));
      case AttachKind.match:
        final match = await showMatchSheet(context, now: ref.read(clockProvider)());
        if (match != null) await _run(() => _ctrl.sendMatch(match).then((_) => _toBottom()));
      case AttachKind.share:
        final postId = await showSharePostPicker(context);
        if (postId != null) await _run(() => _ctrl.sharePost(postId).then((_) => _toBottom()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final me = ref.read(messagesRepositoryProvider).meId;
    final conversation = ref.watch(conversationProvider(widget.conversationId));
    final chat = ref.watch(chatProvider(widget.conversationId));
    final typing = ref.watch(chatTypingProvider(widget.conversationId));
    final cv = conversation.value;
    final now = ref.read(clockProvider)();

    final Widget body;
    final error = chat.error ?? conversation.error;
    if ((chat.value == null || cv == null) && error != null) {
      final offline = error is OfflineException;
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(MuSpace.s6),
          child: MuEmptyState(
            title: offline ? l10n.forumHorsLigne : (error is ForumRuleException ? '$error' : l10n.forumErreur),
            description: offline ? l10n.forumHorsLigneDetail : null,
            actions: [
              MuButton.secondary(
                label: l10n.reessayer,
                leading: PhosphorIcons.arrowsClockwise(),
                onPressed: () => ref.read(messagesChangesProvider.notifier).bump(),
              ),
            ],
          ),
        ),
      );
    } else if (chat.value == null || cv == null) {
      body = const Center(child: MuSpinner());
    } else {
      body = _Messages(
        controller: _scroll,
        messages: chat.value!,
        group: cv.group,
        now: now,
        typing: typing,
        onLongPress: _actions,
        onReply: _reply,
        onReact: (m, e) => _run(() => _ctrl.react(m.id, e)),
        onVote: (m, choice) => _run(() => _ctrl.vote(m.id, choice)),
      );
    }

    final other = cv?.other(me);
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MuTopAppBar.compact(
              title: cv?.title(me) ?? '',
              subtitle: cv == null
                  ? null
                  : cv.group
                  ? l10n.msgNMembres(cv.members.length)
                  : (other == null ? null : forumAuthorLevel(other)),
              onBack: () => context.canPop() ? context.pop() : context.go(Routes.messages),
              backLabel: l10n.msgRetourAuxMessages,
              actions: cv == null
                  ? const []
                  : [
                      MuBarAction(
                        icon: PhosphorIcons.info(),
                        label: cv.group ? l10n.msgInfosDuGroupe : l10n.msgInfosDeLaConversation,
                        onPressed: () => showConversationInfo(context, conversationId: cv.id),
                      ),
                    ],
            ),
            Expanded(child: body),
            if (cv != null)
              ChatComposer(
                controller: _text,
                focus: _focus,
                hint: cv.group ? l10n.msgEcrireAuGroupe : l10n.msgEcrireA(other?.name ?? ''),
                replyTo: _replyTo,
                onCancelReply: () => setState(() => _replyTo = null),
                sending: _sending,
                onAttach: _attach,
                onSend: () => _send(cv),
                onVoice: (clip) => _run(() => _ctrl.sendVoice(clip.src, clip.duration).then((_) => _toBottom())),
              ),
          ],
        ),
      ),
    );
  }
}

// ── The messages ────────────────────────────────────────────────────────────────────────────

class _Messages extends StatelessWidget {
  const _Messages({
    required this.controller,
    required this.messages,
    required this.group,
    required this.now,
    required this.typing,
    required this.onLongPress,
    required this.onReply,
    required this.onReact,
    required this.onVote,
  });

  final ScrollController controller;
  final List<ChatMessage> messages;
  final bool group;
  final DateTime now;
  final bool typing;
  final ValueChanged<ChatMessage> onLongPress;
  final ValueChanged<ChatMessage> onReply;
  final void Function(ChatMessage, String) onReact;
  final void Function(ChatMessage, String) onVote;

  static bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    // Oldest → newest, with a day line where the day changes; shown newest at the bottom.
    final items = <Widget>[];
    for (final (i, m) in messages.indexed) {
      final prev = i > 0 ? messages[i - 1] : null;
      final next = i + 1 < messages.length ? messages[i + 1] : null;
      final newDay = prev == null || !_sameDay(prev.createdAt, m.createdAt);
      if (newDay) items.add(_DayLine(label: chatDayLabel(m.createdAt, now)));
      if (m.kind == ChatKind.system) {
        items.add(_SystemLine(text: chatEventLine(m)));
        continue;
      }
      bool sameRun(ChatMessage? o) =>
          o != null && o.kind != ChatKind.system && o.author.id == m.author.id && _sameDay(o.createdAt, m.createdAt);
      items.add(
        _MessageRow(
          message: m,
          group: group,
          first: newDay || !sameRun(prev),
          last: !sameRun(next),
          onLongPress: () => onLongPress(m),
          onReply: () => onReply(m),
          onReact: (e) => onReact(m, e),
          onVote: (choice) => onVote(m, choice),
        ),
      );
    }
    if (typing) items.add(const _Typing());
    if (messages.isEmpty) {
      items.add(
        Padding(
          padding: const EdgeInsets.all(MuSpace.s6),
          child: MuEmptyState(compact: true, title: l10n.msgDisBonjour, description: l10n.msgDisBonjourDetail),
        ),
      );
    }
    final reversed = items.reversed.toList();
    return ListView.builder(
      controller: controller,
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: MuSpace.s3),
      itemCount: reversed.length,
      itemBuilder: (_, i) => reversed[i],
    );
  }
}

class _DayLine extends StatelessWidget {
  const _DayLine({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MuSpace.s3),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: MuSpace.s3, vertical: MuSpace.s1),
          decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: MuRadius.fullAll),
          child: Semantics(header: true, child: Text(label, style: MuType.labelS.copyWith(color: c.textSecondary))),
        ),
      ),
    );
  }
}

class _SystemLine extends StatelessWidget {
  const _SystemLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MuSpace.s6, vertical: MuSpace.s2),
      child: Text(text, textAlign: TextAlign.center, style: MuType.caption.copyWith(color: c.textSecondary)),
    );
  }
}

/// One message: in a group, the author's avatar and name on the first of a run; the bubble or
/// card; its reactions; the time under the last of a run.
class _MessageRow extends StatelessWidget {
  const _MessageRow({
    required this.message,
    required this.group,
    required this.first,
    required this.last,
    required this.onLongPress,
    required this.onReply,
    required this.onReact,
    required this.onVote,
  });

  final ChatMessage message;
  final bool group;
  final bool first;
  final bool last;
  final VoidCallback onLongPress;
  final VoidCallback onReply;
  final ValueChanged<String> onReact;
  final ValueChanged<String> onVote;

  /// A bubble takes at most this share of the width.
  static const double _maxShare = 0.78;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final m = message;
    final showAvatar = group && !m.mine;
    final maxWidth = MediaQuery.sizeOf(context).width.clamp(0, MuSize.frameMobile) * _maxShare;

    final Widget content = switch (m.kind) {
      _ when m.deleted => _Note(icon: PhosphorIcons.trash(), text: l10n.forumMessageSupprime, mine: m.mine),
      _ when m.hidden && !m.mine => _Note(icon: PhosphorIcons.eyeSlash(), text: l10n.msgMessageMasque, mine: false),
      ChatKind.poll => _PollCard(message: m, onVote: onVote),
      ChatKind.match => _MatchCard(message: m, onVote: onVote),
      ChatKind.share => _SharedCard(message: m),
      ChatKind.image || ChatKind.video => _MediaBubble(message: m),
      ChatKind.voice => _VoiceBubble(message: m),
      _ => _Bubble(message: m),
    };

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(MuSpace.s4, first ? MuSpace.s2 : MuSpace.s1 / 2, MuSpace.s4, last ? MuSpace.s2 : 0),
      child: Row(
        mainAxisAlignment: m.mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (showAvatar) ...[
            SizedBox(
              width: MuSize.avatarS,
              child: last ? MuAvatar(name: m.author.name, imageUrl: m.author.imageUrl, size: MuAvatarSize.s) : null,
            ),
            const SizedBox(width: MuSpace.s2),
          ],
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                crossAxisAlignment: m.mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (showAvatar && first)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(start: MuSpace.s3, bottom: MuSpace.s1),
                      child: Text(m.author.name, style: MuType.labelS.copyWith(color: c.textSecondary)),
                    ),
                  Semantics(
                    onLongPressHint: l10n.msgActionsDuMessage,
                    child: GestureDetector(
                      onLongPress: m.deleted ? null : onLongPress,
                      // A swipe toward the middle answers (as in most messaging apps).
                      onHorizontalDragEnd: m.deleted
                          ? null
                          : (d) {
                              final v = d.primaryVelocity ?? 0;
                              final rtl = Directionality.of(context) == TextDirection.rtl;
                              final towardMiddle = (m.mine ? -v : v) * (rtl ? -1 : 1);
                              if (towardMiddle > 0) onReply();
                            },
                      child: content,
                    ),
                  ),
                  if (m.reactions.isNotEmpty) _Reactions(reactions: m.reactions, onTap: onReact),
                  if (last)
                    Padding(
                      padding: const EdgeInsets.only(top: MuSpace.s1),
                      child: Text(
                        [
                          formatTime(m.createdAt),
                          if (m.hidden && m.mine) l10n.msgMasqueSeulToi,
                        ].join(' · '),
                        style: MuType.caption.copyWith(color: c.textSecondary),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A text bubble: the reader's in the primary colour on the end side, the others' on a
/// surface; a reply shows what it answers above the text.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final ChatMessage message;

  // The quote's rule is 3 px.
  static const double _rule = 3;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final m = message;
    final fg = m.mine ? c.onPrimary : c.text;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: MuSpace.s3, vertical: MuSpace.s2),
      decoration: BoxDecoration(
        color: m.mine ? c.primary : c.surface,
        borderRadius: MuRadius.lgAll,
        border: m.mine ? null : Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (m.quote != null)
            Container(
              margin: const EdgeInsets.only(bottom: MuSpace.s2),
              padding: const EdgeInsetsDirectional.only(start: MuSpace.s2),
              decoration: BoxDecoration(
                border: BorderDirectional(start: BorderSide(color: fg.withValues(alpha: MuOpacity.disabled), width: _rule)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.quote!.author.name, style: MuType.labelS.copyWith(color: fg)),
                  Text(
                    m.quote!.excerpt.isEmpty ? l10n.forumMessageSupprime : m.quote!.excerpt,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: MuType.caption.copyWith(color: fg),
                  ),
                ],
              ),
            ),
          if (m.hidden)
            Padding(
              padding: const EdgeInsets.only(bottom: MuSpace.s1),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(PhosphorIcons.eyeSlash(), size: MuSize.iconXs, color: fg),
                  const SizedBox(width: MuSpace.s1),
                  Flexible(child: Text(l10n.forumMasqueParLaModeration, style: MuType.labelS.copyWith(color: fg))),
                ],
              ),
            ),
          Text(m.body, style: MuType.body.copyWith(color: fg)),
        ],
      ),
    );
  }
}

/// « Message supprimé », « Message masqué par la modération ».
class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text, required this.mine});

  final IconData icon;
  final String text;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: MuSpace.s3, vertical: MuSpace.s2),
      decoration: BoxDecoration(
        borderRadius: MuRadius.lgAll,
        border: Border.all(color: c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: MuSize.iconXs, color: c.textSecondary),
          const SizedBox(width: MuSpace.s2),
          Flexible(
            child: Text(text, style: MuType.caption.copyWith(color: c.textSecondary, fontStyle: FontStyle.italic)),
          ),
        ],
      ),
    );
  }
}

class _Reactions extends StatelessWidget {
  const _Reactions({required this.reactions, required this.onTap});

  final List<ChatReaction> reactions;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Padding(
      padding: const EdgeInsets.only(top: MuSpace.s1),
      child: Wrap(
        spacing: MuSpace.s1,
        runSpacing: MuSpace.s1,
        children: [
          for (final r in reactions)
            Semantics(
              button: true,
              toggled: r.mine,
              label: l10n.msgReactionN(r.emoji, r.count),
              excludeSemantics: true,
              child: InkWell(
                borderRadius: MuRadius.fullAll,
                onTap: () => onTap(r.emoji),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: MuSize.controlS),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: MuSpace.s2),
                    decoration: BoxDecoration(
                      color: r.mine ? c.surfaceMuted : c.surface,
                      borderRadius: MuRadius.fullAll,
                      border: Border.all(color: r.mine ? c.borderStrong : c.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(r.emoji, style: MuType.labelS),
                        if (r.count > 1) ...[
                          const SizedBox(width: MuSpace.s1),
                          Text('${r.count}', style: MuType.numXs.copyWith(color: c.textSecondary)),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// « … est en train d’écrire »: three dots in a bubble.
class _Typing extends StatelessWidget {
  const _Typing();

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(MuSpace.s4, MuSpace.s1, MuSpace.s4, MuSpace.s2),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Semantics(
          liveRegion: true,
          label: l10n.msgEnTrainDEcrire,
          excludeSemantics: true,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: MuSpace.s3, vertical: MuSpace.s2),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: MuRadius.lgAll,
              border: Border.all(color: c.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(PhosphorIcons.dotsThree(PhosphorIconsStyle.bold), size: MuSize.iconS, color: c.textSecondary),
                const SizedBox(width: MuSpace.s1),
                Text(l10n.msgEnTrainDEcrire, style: MuType.caption.copyWith(color: c.textSecondary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── The chat's cards ────────────────────────────────────────────────────────────────────────

/// The frame of a card in the chat: a surface with a border and an overline.
class _CardFrame extends StatelessWidget {
  const _CardFrame({required this.icon, required this.overline, required this.child, this.glyph});

  final IconData? icon;
  final Widget? glyph;
  final String overline;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Container(
      padding: const EdgeInsets.all(MuSpace.s3),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: MuRadius.lgAll,
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              glyph ?? Icon(icon, size: MuSize.iconXs, color: c.textSecondary),
              const SizedBox(width: MuSpace.s2),
              Expanded(child: Text(overline.toUpperCase(), style: MuType.overline.copyWith(color: c.textSecondary))),
            ],
          ),
          const SizedBox(height: MuSpace.s2),
          child,
        ],
      ),
    );
  }
}

/// « Sondage »: the question, each answer as a bar filled by its share of the votes; a tap
/// votes, the same answer again removes the vote.
class _PollCard extends StatelessWidget {
  const _PollCard({required this.message, required this.onVote});

  final ChatMessage message;
  final ValueChanged<String> onVote;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final poll = message.poll!;
    final total = poll.votes;
    return _CardFrame(
      icon: PhosphorIcons.chartBar(),
      overline: l10n.msgSondage,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(poll.question, style: MuType.h3),
          const SizedBox(height: MuSpace.s3),
          for (final (i, o) in poll.options.indexed) ...[
            _PollOption(
              label: o.label,
              votes: o.voters.length,
              share: total == 0 ? 0 : o.voters.length / total,
              chosen: poll.myChoice == i,
              voters: o.voters,
              onTap: () => onVote('$i'),
            ),
            const SizedBox(height: MuSpace.s2),
          ],
          Text(
            [l10n.msgNVotes(total), if (poll.myChoice == null) l10n.msgTapePourVoter].join(' · '),
            style: MuType.caption.copyWith(color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _PollOption extends StatelessWidget {
  const _PollOption({
    required this.label,
    required this.votes,
    required this.share,
    required this.chosen,
    required this.voters,
    required this.onTap,
  });

  final String label;
  final int votes;
  final double share;
  final bool chosen;
  final List<ForumAuthor> voters;
  final VoidCallback onTap;

  static const int _faces = 3;

  // The reader's answer has a 2 px primary border.
  static const double _border = 1;
  static const double _chosenBorder = 2;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Semantics(
      button: true,
      selected: chosen,
      label: l10n.msgOptionNVotes(label, votes),
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: MuRadius.mdAll,
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: MuSize.touchTarget),
            decoration: BoxDecoration(
              borderRadius: MuRadius.mdAll,
              border: Border.all(color: chosen ? c.primary : c.border, width: chosen ? _chosenBorder : _border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned.fill(
                  child: FractionallySizedBox(
                    alignment: AlignmentDirectional.centerStart,
                    widthFactor: share,
                    child: ColoredBox(color: c.surfaceMuted),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: MuSpace.s3, vertical: MuSpace.s2),
                  child: Row(
                    children: [
                      if (chosen) ...[
                        Icon(PhosphorIcons.checkCircle(PhosphorIconsStyle.fill), size: MuSize.iconS, color: c.primary),
                        const SizedBox(width: MuSpace.s2),
                      ],
                      Expanded(child: Text(label, style: MuType.label)),
                      if (voters.isNotEmpty) ...[
                        MuAvatarStack(
                          people: [for (final v in voters) MuPerson(v.name, imageUrl: v.imageUrl)],
                          max: _faces,
                          size: MuAvatarSize.xs,
                        ),
                        const SizedBox(width: MuSpace.s2),
                      ],
                      Text('$votes', style: MuType.numS.copyWith(color: c.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// « Proposer un match »: the sport, the place, the day and time, who comes, and the reader's
/// answer « Je viens » / « Pas dispo ».
class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.message, required this.onVote});

  final ChatMessage message;
  final ValueChanged<String> onVote;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final match = message.match!;
    return _CardFrame(
      icon: null,
      glyph: MuSportIcon(match.sport, size: MuSize.iconXs),
      overline: l10n.msgMatchPropose(match.sport.label),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(match.place, style: MuType.h3),
          const SizedBox(height: MuSpace.s1),
          Row(
            children: [
              Icon(PhosphorIcons.calendarBlank(), size: MuSize.iconXs, color: c.textSecondary),
              const SizedBox(width: MuSpace.s1),
              Text(formatDateTime(match.at), style: MuType.body.copyWith(color: c.textSecondary)),
            ],
          ),
          const SizedBox(height: MuSpace.s3),
          Row(
            children: [
              if (match.going.isNotEmpty) ...[
                MuAvatarStack(people: [for (final p in match.going) MuPerson(p.name, imageUrl: p.imageUrl)], size: MuAvatarSize.xs),
                const SizedBox(width: MuSpace.s2),
              ],
              Expanded(
                child: Text(
                  [
                    l10n.msgNViennent(match.going.length),
                    if (match.notGoing.isNotEmpty) l10n.msgNPasDispo(match.notGoing.length),
                  ].join(' · '),
                  style: MuType.labelS.copyWith(color: c.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: MuSpace.s3),
          Row(
            children: [
              Expanded(
                child: MuToggleButton(
                  size: MuToggleSize.s,
                  pressed: match.myAnswer == true,
                  icon: PhosphorIcons.check(),
                  label: l10n.msgJeViens,
                  onChanged: (_) => onVote('oui'),
                ),
              ),
              const SizedBox(width: MuSpace.s2),
              Expanded(
                child: MuToggleButton(
                  size: MuToggleSize.s,
                  pressed: match.myAnswer == false,
                  icon: PhosphorIcons.x(),
                  label: l10n.msgPasDispo,
                  onChanged: (_) => onVote('non'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A shared Communauté discussion: its category, sport and title; a tap opens FRM-04.
class _SharedCard extends StatelessWidget {
  const _SharedCard({required this.message});

  final ChatMessage message;

  static const double _photoRatio = 4 / 3;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final s = message.shared!;
    return Semantics(
      button: true,
      label: l10n.msgOuvrirLaDiscussion(s.title),
      excludeSemantics: true,
      child: InkWell(
        borderRadius: MuRadius.lgAll,
        onTap: s.category == null ? null : () => context.push(Routes.forumPost(s.postId)),
        child: _CardFrame(
          icon: s.category == null ? PhosphorIcons.chatsCircle() : null,
          glyph: s.category == null ? null : ForumCategoryGlyph(category: s.category!, color: c.textSecondary),
          overline: s.listing != null ? l10n.mktAnnonce : (s.category?.label ?? l10n.msgDiscussion),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (s.image != null) ...[
                ClipRRect(
                  borderRadius: MuRadius.mdAll,
                  child: AspectRatio(aspectRatio: _photoRatio, child: ForumImage(s.image!)),
                ),
                const SizedBox(height: MuSpace.s2),
              ],
              if (s.sport != null) ...[MuChip.sport(s.sport!, size: MuChipSize.s), const SizedBox(height: MuSpace.s2)],
              Text(s.title, style: MuType.label),
              if (s.listing != null) ...[const SizedBox(height: MuSpace.s1), ListingSummary(listing: s.listing!)],
              if (s.category != null) ...[
                const SizedBox(height: MuSpace.s2),
                Row(
                  children: [
                    Text(s.listing != null ? l10n.mktVoirLAnnonce : l10n.msgVoirLaDiscussion, style: MuType.labelS.copyWith(color: c.link)),
                    const SizedBox(width: MuSpace.s1),
                    MuDirectionalIcon(PhosphorIcons.arrowRight(), size: MuSize.iconXs, color: c.link),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A photo or a video in the chat (a tap opens it full screen), with its caption.
class _MediaBubble extends StatelessWidget {
  const _MediaBubble({required this.message});

  final ChatMessage message;

  // Photos and videos in a chat are 4:5 portrait tiles.
  static const double _ratio = 4 / 5;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final m = message;
    final src = m.media!.src;
    return Column(
      crossAxisAlignment: m.mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: MuRadius.lgAll,
          child: AspectRatio(
            aspectRatio: _ratio,
            child: Semantics(
              button: true,
              label: m.kind == ChatKind.video ? l10n.mediaVideo : l10n.msgPhoto,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ForumMediaTile(src),
                  Material(
                    type: MaterialType.transparency,
                    child: InkWell(onTap: () => ForumMediaViewer.open(context, [src], 0)),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (m.body.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: MuSpace.s1),
            child: Text(m.body, style: MuType.body.copyWith(color: c.text)),
          ),
      ],
    );
  }
}

/// A voice message: the player in a bubble of the sender's colour.
class _VoiceBubble extends StatelessWidget {
  const _VoiceBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final m = message;
    return Container(
      padding: const EdgeInsetsDirectional.only(end: MuSpace.s3),
      decoration: BoxDecoration(
        color: m.mine ? c.primary : c.surface,
        borderRadius: MuRadius.lgAll,
        border: m.mine ? null : Border.all(color: c.border),
      ),
      child: ForumVoicePlayer(
        src: m.media!.src,
        duration: m.media!.duration ?? Duration.zero,
        foreground: m.mine ? c.onPrimary : c.text,
      ),
    );
  }
}
