import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../l10n/l10n.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../controllers/messages_providers.dart';
import '../data/forum_models.dart';
import '../data/messages_repository.dart';
import '../widgets/forum_actions.dart';
import '../widgets/forum_format.dart';

/// « Nouveau message »: pick one friend for a private conversation, or several for a group
/// (then its name). With [addTo], adds friends to that group instead.
class NewConversationScreen extends ConsumerStatefulWidget {
  const NewConversationScreen({super.key, this.addTo});

  /// The group to add friends to, or null to start a conversation.
  final String? addTo;

  @override
  ConsumerState<NewConversationScreen> createState() => _NewConversationScreenState();
}

class _NewConversationScreenState extends ConsumerState<NewConversationScreen> {
  static const int _groupNameMax = 40;

  final _name = TextEditingController();
  final _picked = <String, ForumAuthor>{};
  String _q = '';
  bool _busy = false;

  bool get _adding => widget.addTo != null;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// « Padel du jeudi » style suggestion: the first names of the group.
  String get _suggestedName => [for (final f in _picked.values.take(3)) firstName(f.name)].join(', ');

  Future<void> _go() async {
    if (_busy || _picked.isEmpty) return;
    setState(() => _busy = true);
    final repo = ref.read(messagesRepositoryProvider);
    try {
      final ids = _picked.keys.toList();
      if (_adding) {
        await repo.addMembers(widget.addTo!, ids);
        ref.read(messagesChangesProvider.notifier).bump();
        if (mounted) context.pop();
        return;
      }
      final id = ids.length == 1
          ? await repo.openDirect(ids.single)
          : await repo.createGroup(_name.text.trim().isEmpty ? _suggestedName : _name.text, ids);
      ref.read(messagesChangesProvider.notifier).bump();
      if (mounted) context.pushReplacement(Routes.chat(id));
    } catch (e) {
      if (mounted) showForumError(context, e);
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final friends = ref.watch(chatFriendsProvider);
    final already = _adding ? {for (final m in ref.watch(conversationProvider(widget.addTo!)).value?.members ?? const <ForumAuthor>[]) m.id} : const <String>{};
    final q = _q.toLowerCase();
    final list = [
      for (final f in friends.value ?? const <ForumAuthor>[])
        if (!already.contains(f.id) && (q.isEmpty || f.name.toLowerCase().contains(q) || (f.handle ?? '').contains(q))) f,
    ];
    final n = _picked.length;
    final group = !_adding && n >= 2;

    final String label;
    if (_adding) {
      label = n == 0 ? l10n.msgChoisisDesAmis : l10n.msgAjouterNAmis(n);
    } else if (n == 0) {
      label = l10n.msgChoisisDesAmis;
    } else if (n == 1) {
      label = l10n.msgEcrireA(_picked.values.single.name);
    } else {
      label = l10n.msgCreerLeGroupeN(n + 1);
    }

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MuTopAppBar.compact(
              title: _adding ? l10n.msgAjouterDesAmis : l10n.msgNouveauMessage,
              onBack: () => context.canPop() ? context.pop() : context.go(Routes.messages),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s2, MuSpace.s4, MuSpace.s2),
              child: MuSearchField(
                label: l10n.msgRechercherUnAmi,
                placeholder: l10n.msgRechercherUnAmi,
                autofocus: false,
                onChanged: (v) => setState(() => _q = v.trim()),
              ),
            ),
            if (_picked.isNotEmpty)
              SizedBox(
                height: MuSize.controlL,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
                  children: [
                    for (final f in _picked.values)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: MuSpace.s2),
                        child: Center(
                          child: MuChip(
                            label: f.name,
                            kind: MuChipKind.input,
                            onRemove: () => setState(() => _picked.remove(f.id)),
                            removeLabel: l10n.msgRetirerX(f.name),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            if (group)
              Padding(
                padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s2, MuSpace.s4, 0),
                child: MuTextField(
                  label: l10n.msgNomDuGroupe,
                  placeholder: _suggestedName,
                  helper: l10n.msgNomDuGroupeAide,
                  controller: _name,
                  maxLength: _groupNameMax,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
            Expanded(
              child: friends.value == null
                  ? const Center(child: MuSpinner())
                  : list.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(MuSpace.s6),
                      child: MuEmptyState(compact: true, title: l10n.msgAucunAmi, description: l10n.msgAucunAmiDetail),
                    )
                  : ListView(
                      padding: const EdgeInsets.only(bottom: MuSpace.s4),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s3, MuSpace.s4, MuSpace.s1),
                          child: Text(l10n.msgTesAmisDetail, style: MuType.caption.copyWith(color: c.textSecondary)),
                        ),
                        for (final f in list)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4, vertical: MuSpace.s1),
                            child: Row(
                              children: [
                                MuAvatar(name: f.name, imageUrl: f.imageUrl, level: f.level),
                                const SizedBox(width: MuSpace.s3),
                                Expanded(
                                  child: MuCheckbox(
                                    value: _picked.containsKey(f.id),
                                    label: f.name,
                                    description: forumAuthorLevel(f),
                                    onChanged: (on) => setState(() => on == true ? _picked[f.id] = f : _picked.remove(f.id)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
            Container(
              decoration: BoxDecoration(
                color: c.surface,
                border: Border(top: BorderSide(color: c.border)),
              ),
              padding: EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s3, MuSpace.s4, MuSpace.s3 + MediaQuery.paddingOf(context).bottom),
              child: MuButton.primary(
                label: label,
                leading: n >= 2 && !_adding ? PhosphorIcons.usersThree() : PhosphorIcons.chatCircle(),
                fullWidth: true,
                size: MuButtonSize.l,
                loading: _busy,
                onPressed: n == 0 ? null : _go,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
