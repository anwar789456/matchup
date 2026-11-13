import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../l10n/l10n.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../controllers/forum_providers.dart';
import '../controllers/messages_providers.dart';
import '../data/forum_repository.dart';
import '../data/messages_repository.dart';
import '../screens/messages_screen.dart' show ConversationAvatar;
import 'forum_actions.dart';
import 'forum_format.dart';

Future<T?> _pop<T>(BuildContext context, [T? value]) async {
  Navigator.of(context, rootNavigator: true).pop(value);
  return null;
}

// ── A message's actions ─────────────────────────────────────────────────────────────────────

sealed class MessageAction {
  const MessageAction();
}

class MessageReact extends MessageAction {
  const MessageReact(this.emoji);
  final String emoji;
}

class MessageReply extends MessageAction {
  const MessageReply();
}

class MessageCopy extends MessageAction {
  const MessageCopy();
}

class MessageDelete extends MessageAction {
  const MessageDelete();
}

class MessageReport extends MessageAction {
  const MessageReport();
}

/// The quick reactions of a message.
const chatEmojis = ['👍', '⚽', '🔥', '😂', '❤️', '🙏'];

/// Long press on a message: a row of reactions, then « Répondre », « Copier », « Supprimer »
/// (own) or « Signaler » (others').
Future<MessageAction?> showMessageActions(BuildContext context, {required ChatMessage message}) {
  final m = message;
  final canCopy = m.kind == ChatKind.text && !m.hidden;
  return MuBottomSheet.show<MessageAction>(
    context,
    title: l10n.msgActionsDuMessage,
    height: MuSheetHeight.auto,
    child: Builder(
      builder: (context) {
        final c = context.mu;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!m.hidden)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4, vertical: MuSpace.s2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (final e in chatEmojis)
                      Semantics(
                        button: true,
                        label: l10n.msgReagirAvec(e),
                        selected: m.reactions.any((r) => r.emoji == e && r.mine),
                        excludeSemantics: true,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => _pop(context, MessageReact(e)),
                          child: Container(
                            width: MuSize.touchTarget,
                            height: MuSize.touchTarget,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: m.reactions.any((r) => r.emoji == e && r.mine) ? c.surfaceMuted : null,
                            ),
                            child: Text(e, style: MuType.h3),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            MuSettingsRow(
              title: l10n.forumRepondre,
              icon: PhosphorIcons.arrowBendUpLeft(),
              chevron: false,
              onTap: () => _pop(context, const MessageReply()),
            ),
            if (canCopy)
              MuSettingsRow(title: l10n.msgCopier, icon: PhosphorIcons.copy(), chevron: false, onTap: () => _pop(context, const MessageCopy())),
            if (m.mine)
              MuSettingsRow(
                title: l10n.supprimer,
                icon: PhosphorIcons.trash(),
                chevron: false,
                destructive: true,
                onTap: () => _pop(context, const MessageDelete()),
              )
            else
              MuSettingsRow(
                title: l10n.forumSignaler,
                icon: PhosphorIcons.flag(),
                chevron: false,
                destructive: true,
                onTap: () => _pop(context, const MessageReport()),
              ),
          ],
        );
      },
    ),
  );
}

// ── « + »: what to add ──────────────────────────────────────────────────────────────────────

enum AttachKind { photo, video, poll, match, share }

Future<AttachKind?> showAttachSheet(BuildContext context) => MuBottomSheet.show<AttachKind>(
  context,
  title: l10n.msgAjouterAuMessage,
  height: MuSheetHeight.auto,
  child: Builder(
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MuSettingsRow(
          title: l10n.msgPhoto,
          description: l10n.msgPhotoDetail,
          icon: PhosphorIcons.image(),
          onTap: () => _pop(context, AttachKind.photo),
        ),
        MuSettingsRow(
          title: l10n.msgVideo,
          description: l10n.msgVideoDetail,
          icon: PhosphorIcons.videoCamera(),
          onTap: () => _pop(context, AttachKind.video),
        ),
        MuSettingsRow(
          title: l10n.msgSondage,
          description: l10n.msgSondageDetail,
          icon: PhosphorIcons.chartBar(),
          onTap: () => _pop(context, AttachKind.poll),
        ),
        MuSettingsRow(
          title: l10n.msgProposerUnMatch,
          description: l10n.msgProposerUnMatchDetail,
          icon: PhosphorIcons.soccerBall(),
          onTap: () => _pop(context, AttachKind.match),
        ),
        MuSettingsRow(
          title: l10n.msgPartagerUneDiscussion,
          description: l10n.msgPartagerUneDiscussionDetail,
          icon: PhosphorIcons.chatsCircle(),
          onTap: () => _pop(context, AttachKind.share),
        ),
      ],
    ),
  ),
);

// ── Écrire au vendeur ───────────────────────────────────────────────────────────────────────

/// Équipement « Écrire au vendeur »: the private conversation with the seller, the listing
/// shared in it once, and « Bonjour ! Est-ce toujours disponible ? » ready to send.
Future<void> contactSeller(BuildContext context, WidgetRef ref, ForumPost post) async {
  final repo = ref.read(messagesRepositoryProvider);
  final router = GoRouter.of(context);
  try {
    final id = await repo.openDirect(post.author.id);
    final shared = (await repo.messages(id)).any((m) => m.shared?.postId == post.id);
    if (!shared) await repo.sharePost(id, post.id);
    ref.read(messagesChangesProvider.notifier).bump();
    router.push(Routes.chat(id, text: shared ? null : l10n.mktToujoursDisponible));
  } catch (e) {
    if (context.mounted) showForumError(context, e);
  }
}

// ── Sondage ─────────────────────────────────────────────────────────────────────────────────

class PollDraft {
  const PollDraft(this.question, this.options);
  final String question;
  final List<String> options;
}

Future<PollDraft?> showPollSheet(BuildContext context) =>
    MuBottomSheet.show<PollDraft>(context, title: l10n.msgNouveauSondage, height: MuSheetHeight.full, child: const _PollForm());

class _PollForm extends StatefulWidget {
  const _PollForm();

  @override
  State<_PollForm> createState() => _PollFormState();
}

class _PollFormState extends State<_PollForm> {
  static const int _min = 2;
  static const int _max = 4;
  static const int _questionMax = 120;
  static const int _optionMax = 60;

  final _question = TextEditingController();
  final _options = [TextEditingController(), TextEditingController()];

  @override
  void initState() {
    super.initState();
    for (final c in [_question, ..._options]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_question, ..._options]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _ready => _question.text.trim().isNotEmpty && _options.where((o) => o.text.trim().isNotEmpty).length >= _min;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s2, MuSpace.s4, MuSpace.s6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MuTextField(
            label: l10n.msgQuestion,
            placeholder: l10n.msgQuestionPlaceholder,
            controller: _question,
            maxLength: _questionMax,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: MuSpace.s4),
          for (final (i, o) in _options.indexed) ...[
            MuTextField(
              label: l10n.msgReponseN(i + 1),
              controller: o,
              maxLength: _optionMax,
              optional: i >= _min,
              textCapitalization: TextCapitalization.sentences,
              trailing: i >= _min
                  ? MuIconButton(
                      icon: PhosphorIcons.x(),
                      label: l10n.msgRetirerLaReponse,
                      size: MuIconButtonSize.s,
                      onPressed: () => setState(() => _options.removeAt(i).dispose()),
                    )
                  : null,
            ),
            const SizedBox(height: MuSpace.s3),
          ],
          if (_options.length < _max)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: MuButton.tertiary(
                label: l10n.msgAjouterUneReponse,
                leading: PhosphorIcons.plus(),
                onPressed: () => setState(() {
                  final c = TextEditingController()..addListener(() => setState(() {}));
                  _options.add(c);
                }),
              ),
            ),
          const SizedBox(height: MuSpace.s4),
          MuButton.primary(
            label: l10n.msgEnvoyerLeSondage,
            fullWidth: true,
            size: MuButtonSize.l,
            onPressed: _ready ? () => _pop(context, PollDraft(_question.text, [for (final o in _options) o.text])) : null,
          ),
        ],
      ),
    );
  }
}

// ── Proposer un match ───────────────────────────────────────────────────────────────────────

/// Where the story plays (STORY-DATA « Venues »), one tap to fill the place.
const _places = ['Arena Five', 'Smash Padel Club', 'Hoop Zone'];

Future<ChatMatchDraft?> showMatchSheet(BuildContext context, {required DateTime now}) =>
    MuBottomSheet.show<ChatMatchDraft>(context, title: l10n.msgProposerUnMatch, height: MuSheetHeight.full, child: _MatchForm(now: now));

class _MatchForm extends StatefulWidget {
  const _MatchForm({required this.now});

  final DateTime now;

  @override
  State<_MatchForm> createState() => _MatchFormState();
}

class _MatchFormState extends State<_MatchForm> {
  static const int _days = 7;
  static const _hours = [18, 19, 20, 21, 22];

  final _place = TextEditingController();
  MuSport _sport = MuSport.football;
  int _day = 0;
  int _hour = 20;

  @override
  void initState() {
    super.initState();
    _place.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _place.dispose();
    super.dispose();
  }

  DateTime _date(int offset) => DateTime(widget.now.year, widget.now.month, widget.now.day + offset);

  String _dayLabel(int offset) => switch (offset) {
    0 => l10n.msgAujourdhui,
    1 => l10n.msgDemain,
    _ => formatDay(_date(offset)),
  };

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final at = _date(_day).add(Duration(hours: _hour));
    final past = !at.isAfter(widget.now);
    return Padding(
      padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s2, MuSpace.s4, MuSpace.s6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.msgSport, style: MuType.label),
          const SizedBox(height: MuSpace.s2),
          Wrap(
            spacing: MuSpace.s2,
            runSpacing: MuSpace.s2,
            children: [
              for (final s in MuSport.values)
                MuChip.sport(s, selected: s == _sport, onSelected: (_) => setState(() => _sport = s)),
            ],
          ),
          const SizedBox(height: MuSpace.s5),
          MuTextField(
            label: l10n.msgLieu,
            placeholder: l10n.msgLieuPlaceholder,
            controller: _place,
            leadingIcon: PhosphorIcons.mapPin(),
          ),
          const SizedBox(height: MuSpace.s2),
          Wrap(
            spacing: MuSpace.s2,
            runSpacing: MuSpace.s2,
            children: [
              for (final p in _places)
                MuChip(
                  label: p,
                  size: MuChipSize.s,
                  selected: _place.text == p,
                  onSelected: (_) => _place.text = p,
                ),
            ],
          ),
          const SizedBox(height: MuSpace.s5),
          Text(l10n.msgQuand, style: MuType.label),
          const SizedBox(height: MuSpace.s2),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var d = 0; d < _days; d++)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: MuSpace.s2),
                    child: MuChip(label: _dayLabel(d), kind: MuChipKind.choice, selected: d == _day, onSelected: (_) => setState(() => _day = d)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: MuSpace.s2),
          Wrap(
            spacing: MuSpace.s2,
            runSpacing: MuSpace.s2,
            children: [
              for (final h in _hours)
                MuChip(
                  label: formatHour(h * Duration.minutesPerHour),
                  kind: MuChipKind.choice,
                  selected: h == _hour,
                  onSelected: (_) => setState(() => _hour = h),
                ),
            ],
          ),
          if (past) ...[
            const SizedBox(height: MuSpace.s2),
            Text(l10n.msgHeurePassee, style: MuType.caption.copyWith(color: c.errorText)),
          ],
          const SizedBox(height: MuSpace.s6),
          MuButton.primary(
            label: l10n.msgProposer,
            fullWidth: true,
            size: MuButtonSize.l,
            onPressed: _place.text.trim().isEmpty || past
                ? null
                : () => _pop(context, ChatMatchDraft(sport: _sport, place: _place.text, at: at)),
          ),
        ],
      ),
    );
  }
}

// ── Partager une discussion ─────────────────────────────────────────────────────────────────

/// The latest Communauté discussions; a tap picks one.
Future<String?> showSharePostPicker(BuildContext context) => MuBottomSheet.show<String>(
  context,
  title: l10n.msgPartagerUneDiscussion,
  height: MuSheetHeight.full,
  child: Consumer(
    builder: (context, ref, _) {
      final c = context.mu;
      final feed = ref.watch(forumFeedProvider(const ForumQuery(sort: ForumSort.recent))).value;
      if (feed == null) return const Center(child: MuSpinner());
      return _SheetList(
        children: [
          for (final p in feed.posts)
            if (!p.hidden)
              MuSettingsRow(
                title: p.title,
                description: [p.category.label, p.author.name].join(' · '),
                icon: p.category.icon ?? PhosphorIcons.chatsCircle(),
                chevron: false,
                onTap: () => _pop(context, p.id),
              ),
          if (feed.posts.isEmpty)
            Padding(
              padding: const EdgeInsets.all(MuSpace.s6),
              child: Text(l10n.forumAucuneDiscussion, style: MuType.body.copyWith(color: c.textSecondary)),
            ),
        ],
      );
    },
  ),
);

/// « Envoyer à un ami » on a discussion: the recent conversations and the friends; one tap
/// sends it, then « Ouvrir » goes to the chat.
Future<void> showShareToFriend(BuildContext context, {required String postId}) async {
  final target = await MuBottomSheet.show<(String?, ForumAuthor?)>(
    context,
    title: l10n.msgEnvoyerAUnAmi,
    height: MuSheetHeight.full,
    child: Consumer(
      builder: (context, ref, _) {
        final me = ref.read(messagesRepositoryProvider).meId;
        final conversations = ref.watch(conversationsProvider).value ?? const <Conversation>[];
        final friends = ref.watch(chatFriendsProvider).value ?? const <ForumAuthor>[];
        final direct = {for (final cv in conversations) if (!cv.group) cv.other(me)?.id};
        return _SheetList(
          children: [
            if (conversations.isNotEmpty) _SheetHeading(l10n.msgConversationsRecentes),
            for (final cv in conversations.take(5))
              ListTile(
                minTileHeight: MuSize.touchTarget,
                leading: ConversationAvatar(conversation: cv, meId: me),
                title: Text(cv.title(me), style: MuType.label),
                onTap: () => _pop(context, (cv.id, null)),
              ),
            _SheetHeading(l10n.msgTesAmis),
            for (final f in friends)
              if (!direct.contains(f.id))
                ListTile(
                  minTileHeight: MuSize.touchTarget,
                  leading: MuAvatar(name: f.name, imageUrl: f.imageUrl, level: f.level),
                  title: Text(f.name, style: MuType.label),
                  subtitle: Text(forumAuthorLevel(f), style: MuType.caption),
                  onTap: () => _pop(context, (null, f)),
                ),
          ],
        );
      },
    ),
  );
  if (target == null || !context.mounted) return;
  final container = ProviderScope.containerOf(context, listen: false);
  final repo = container.read(messagesRepositoryProvider);
  final router = GoRouter.of(context);
  try {
    final (conversationId, friend) = target;
    final id = conversationId ?? await repo.openDirect(friend!.id);
    await repo.sharePost(id, postId);
    container.read(messagesChangesProvider.notifier).bump();
    final name = friend?.name ?? (await repo.conversation(id)).title(repo.meId);
    if (!context.mounted) return;
    MuToast.show(
      context,
      tone: MuToastTone.success,
      title: l10n.msgEnvoyeeA(name),
      icon: PhosphorIcons.paperPlaneRight(),
      action: MuAction(l10n.msgOuvrir, () => router.push(Routes.chat(id))),
    );
  } catch (e) {
    if (context.mounted) showForumError(context, e);
  }
}

/// A sheet's rows: the sheet scrolls, so they are a plain column.
class _SheetList extends StatelessWidget {
  const _SheetList({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: MuSpace.s6),
    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
  );
}

class _SheetHeading extends StatelessWidget {
  const _SheetHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s4, MuSpace.s4, MuSpace.s2),
    child: Semantics(header: true, child: Text(text, style: MuType.h3)),
  );
}

// ── The conversation's info ─────────────────────────────────────────────────────────────────

/// The (i) of a chat: who is in it, « Mettre en sourdine », and for a group « Renommer »,
/// « Ajouter des amis » (its creator) and « Quitter le groupe »; for a private conversation
/// « Ne plus voir ses messages ».
Future<void> showConversationInfo(BuildContext context, {required String conversationId}) => MuBottomSheet.show<void>(
  context,
  title: l10n.msgInfos,
  height: MuSheetHeight.full,
  child: _ConversationInfo(conversationId: conversationId),
);

class _ConversationInfo extends ConsumerWidget {
  const _ConversationInfo({required this.conversationId});

  final String conversationId;

  Future<void> _rename(BuildContext context, WidgetRef ref, Conversation cv) async {
    final text = TextEditingController(text: cv.name);
    final name = await MuDialog.show<String>(
      context,
      title: l10n.msgRenommerLeGroupe,
      showIcon: false,
      content: MuTextField(label: l10n.msgNomDuGroupe, controller: text, autofocus: true, maxLength: _groupNameMax),
      actions: [
        Builder(
          builder: (context) => MuButton.secondary(label: l10n.annuler, fullWidth: true, size: MuButtonSize.l, onPressed: () => _pop(context)),
        ),
        Builder(
          builder: (context) => MuButton.primary(
            label: l10n.msgRenommer,
            fullWidth: true,
            size: MuButtonSize.l,
            onPressed: () => _pop(context, text.text),
          ),
        ),
      ],
    );
    text.dispose();
    if (name == null || !context.mounted) return;
    await _do(context, ref, () => ref.read(messagesRepositoryProvider).rename(cv.id, name));
  }

  Future<void> _do(BuildContext context, WidgetRef ref, Future<void> Function() action) async {
    try {
      await action();
      ref.read(messagesChangesProvider.notifier).bump();
    } catch (e) {
      if (context.mounted) showForumError(context, e);
    }
  }

  Future<void> _leave(BuildContext context, WidgetRef ref, Conversation cv) async {
    final ok = await MuDialog.show<bool>(
      context,
      tone: MuDialogTone.destructive,
      title: l10n.msgQuitterLeGroupeQ(cv.name ?? ''),
      description: l10n.msgQuitterLeGroupeDetail,
      actions: [
        Builder(
          builder: (context) => MuButton.secondary(label: l10n.annuler, fullWidth: true, size: MuButtonSize.l, onPressed: () => _pop(context, false)),
        ),
        Builder(
          builder: (context) => MuButton.destructive(
            label: l10n.msgQuitter,
            fullWidth: true,
            size: MuButtonSize.l,
            onPressed: () => _pop(context, true),
          ),
        ),
      ],
    );
    if (ok != true || !context.mounted) return;
    final router = GoRouter.of(context);
    await _do(context, ref, () => ref.read(messagesRepositoryProvider).leave(cv.id));
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    router.go(Routes.messages);
  }

  static const int _groupNameMax = 40;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final cv = ref.watch(conversationProvider(conversationId)).value;
    if (cv == null) return const Center(child: MuSpinner());
    final me = ref.read(messagesRepositoryProvider).meId;
    final other = cv.other(me);
    return _SheetList(
      children: [
        Padding(
          padding: const EdgeInsets.all(MuSpace.s4),
          child: Column(
            children: [
              ConversationAvatar(conversation: cv, meId: me),
              const SizedBox(height: MuSpace.s2),
              Text(cv.title(me), style: MuType.h2, textAlign: TextAlign.center),
              Text(
                cv.group ? l10n.msgGroupeCreeLe(formatDay(cv.createdAt)) : forumAuthorLevel(other!),
                style: MuType.caption.copyWith(color: c.textSecondary),
              ),
            ],
          ),
        ),
        MuSwitch(
          label: l10n.msgMettreEnSourdine,
          description: l10n.msgMettreEnSourdineDetail,
          icon: PhosphorIcons.bellSlash(),
          value: cv.muted,
          onChanged: (on) => _do(context, ref, () => ref.read(messagesRepositoryProvider).mute(cv.id, on: on)),
        ),
        if (cv.group) ...[
          _SheetHeading(l10n.msgNMembres(cv.members.length)),
          for (final m in cv.members)
            ListTile(
              minTileHeight: MuSize.touchTarget,
              leading: MuAvatar(name: m.name, imageUrl: m.imageUrl, level: m.level, size: MuAvatarSize.s),
              title: Text(m.id == me ? l10n.msgToiNom(m.name) : m.name, style: MuType.label),
              subtitle: m.level == null ? null : Text(forumAuthorLevel(m), style: MuType.caption),
            ),
          if (cv.admin) ...[
            MuSettingsRow(
              title: l10n.msgAjouterDesAmis,
              icon: PhosphorIcons.userPlus(),
              onTap: () {
                Navigator.of(context, rootNavigator: true).pop();
                context.push(Routes.messagesAdd(cv.id));
              },
            ),
            MuSettingsRow(title: l10n.msgRenommerLeGroupe, icon: PhosphorIcons.pencilSimple(), onTap: () => _rename(context, ref, cv)),
          ],
          MuSettingsRow(
            title: l10n.msgQuitterLeGroupe,
            icon: PhosphorIcons.signOut(),
            destructive: true,
            chevron: false,
            onTap: () => _leave(context, ref, cv),
          ),
        ] else if (other != null) ...[
          MuSettingsRow(
            title: l10n.forumNePlusVoirLesMessagesDe(other.name),
            icon: PhosphorIcons.eyeSlash(),
            destructive: true,
            chevron: false,
            onTap: () => _do(context, ref, () async {
              await ref.read(forumRepositoryProvider).block(other.id, on: true);
              ref.read(forumChangesProvider.notifier).bump();
              if (context.mounted) {
                MuToast.show(context, tone: MuToastTone.success, title: l10n.msgTuNeVerrasPlus(other.name));
              }
            }),
          ),
        ],
        Padding(
          padding: const EdgeInsets.all(MuSpace.s4),
          child: Text(l10n.msgConfidentialite, style: MuType.caption.copyWith(color: c.textSecondary)),
        ),
      ],
    );
  }
}
