import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/api/session.dart';
import '../../../core/format.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../l10n/l10n.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../home/controllers/home_providers.dart';
import '../controllers/assistant_controller.dart';
import '../data/assistant_models.dart';
import '../data/assistant_repository.dart';
import '../data/assistant_story.dart';
import '../widgets/assistant_blocks.dart';

/// The AI assistant (AI-01…06 for the player, AI-07 in the owner's space): the greeting and
/// suggestions, then the conversation. Every action comes back as a card to confirm.
class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key, this.space = AssistantSpace.player});

  final AssistantSpace space;

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final _scroll = ScrollController();
  final _text = TextEditingController();

  @override
  void dispose() {
    _scroll.dispose();
    _text.dispose();
    super.dispose();
  }

  void _toEnd() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!_scroll.hasClients) return;
    final end = _scroll.position.maxScrollExtent;
    if (MediaQuery.disableAnimationsOf(context)) {
      _scroll.jumpTo(end);
    } else {
      _scroll.animateTo(end, duration: MuMotion.base, curve: MuMotion.enter);
    }
  });

  void _close() => context.canPop()
      ? context.pop()
      : context.go(widget.space == AssistantSpace.owner ? Routes.ownerToday : Routes.home);

  @override
  Widget build(BuildContext context) {
    final provider = assistantProvider(widget.space);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    ref.listen(provider, (prev, next) => _toEnd());
    final owner = widget.space == AssistantSpace.owner;
    final firstUser = state.turns.whereType<UserTurn>().firstOrNull;

    return MuAssistantTakeover(
      subtitle: owner ? l10n.aiOwnerSpace(AssistantStory.ownerVenue) : null,
      onClose: _close,
      banner: state.offline
          ? MuBanner(
              variant: MuBannerVariant.strip,
              tone: MuBannerTone.warning,
              icon: PhosphorIcons.wifiSlash(),
              title: l10n.aiUnstable,
              detail: l10n.aiBackSoon,
            )
          : null,
      thread: ListView(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s2, MuSpace.s4, MuSpace.s6),
        children: [
          if (state.turns.isEmpty)
            _Welcome(space: widget.space, onAsk: controller.send)
          else
            for (final t in state.turns) ...[
              if (t == firstUser) ...[
                Center(
                  child: Text(
                    l10n.aiTodayAt(formatTime(firstUser!.at)),
                    style: MuType.caption.copyWith(color: context.mu.textSecondary),
                  ),
                ),
                const SizedBox(height: MuSpace.s3),
              ],
              switch (t) {
                UserTurn() => MuChatBubble.mine(t.text),
                AiTurn() => AiTurnView(
                  turn: t,
                  space: widget.space,
                  onAsk: controller.send,
                  onEdit: () => _text.text = t.request,
                ),
              },
              const SizedBox(height: MuSpace.s4),
            ],
        ],
      ),
      composer: MuAssistantComposer(
        controller: _text,
        busy: state.busy,
        onSend: controller.send,
        onStop: controller.stop,
        disclaimer: state.turns.isEmpty ? l10n.aiDisclaimerLong : l10n.aiDisclaimer,
      ),
    );
  }
}

/// AI-01: greeting, three suggestions, « Ce que j’utilise pour te répondre ».
class _Welcome extends ConsumerWidget {
  const _Welcome({required this.space, required this.onAsk});

  final AssistantSpace space;
  final ValueChanged<String> onAsk;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final owner = space == AssistantSpace.owner;
    final me = ref.watch(meProvider).value;
    // As on Home: with real accounts and nobody signed in, nobody is named (the phone's saved
    // answers may be someone else's).
    final anonymous = SupabaseConfig.configured && ref.watch(sessionProvider) == null;
    final name = anonymous ? null : me?.firstName;
    final welcome = ref.watch(_welcomeProvider(space)).value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: MuSpace.s4),
        const MuAiSender(),
        const SizedBox(height: MuSpace.s2),
        MuChatBubble.ai(
          owner
              ? l10n.aiOwnerGreeting
              : name == null || name.isEmpty
              ? l10n.aiGreetingAnonymous
              : l10n.aiGreeting(name),
          large: true,
        ),
        const SizedBox(height: MuSpace.s4),
        if (welcome != null) ...[
          Wrap(
            spacing: MuSpace.s2,
            runSpacing: MuSpace.s2,
            children: [
              for (final s in welcome.suggestions)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: MuChip(
                    label: s,
                    icon: PhosphorIcons.sparkle(),
                    onSelected: (_) => onAsk(s),
                  ),
                ),
            ],
          ),
          const SizedBox(height: MuSpace.s5),
          MuCardSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.aiWhatIUse.toUpperCase(),
                        style: MuType.overline.copyWith(color: c.textSecondary),
                      ),
                    ),
                    if (!owner)
                      MuButton.link(
                        label: l10n.entEdit,
                        onPressed: () => context.push(Routes.profileEdit),
                      ),
                  ],
                ),
                const SizedBox(height: MuSpace.s3),
                Wrap(
                  runSpacing: MuSpace.s3,
                  children: [
                    for (final item in welcome.context)
                      FractionallySizedBox(
                        widthFactor: 0.5,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(item.icon, size: MuSize.iconS, color: c.text),
                            const SizedBox(width: MuSpace.s2),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.title, style: MuType.label.copyWith(color: c.text)),
                                  Text(
                                    item.detail,
                                    style: MuType.caption.copyWith(color: c.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: MuSpace.s3),
                Divider(height: 1, color: c.border),
                const SizedBox(height: MuSpace.s3),
                Row(
                  children: [
                    Icon(PhosphorIcons.lockSimple(), size: MuSize.iconXs, color: c.textSecondary),
                    const SizedBox(width: MuSpace.s2),
                    Expanded(
                      child: Text(
                        l10n.aiPrivate,
                        style: MuType.caption.copyWith(color: c.textSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

final _welcomeProvider = FutureProvider.family<AiWelcome, AssistantSpace>(
  (ref, space) => ref.watch(assistantRepositoryProvider).welcome(space),
);
