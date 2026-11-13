import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/clock.dart';
import '../../../core/format.dart';
import '../../../l10n/l10n.dart';
import '../../../router.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../booking/controllers/booking_controller.dart';
import '../../owner/data/owner_drafts.dart';
import '../../training/controllers/training_providers.dart';
import '../../training/training_routes.dart';
import '../controllers/assistant_checkout.dart';
import '../controllers/assistant_controller.dart';
import '../data/assistant_models.dart';
import '../data/assistant_story.dart';

/// One answer: « MatchUp · IA », what was understood, the search steps or the blocks, then the
/// feedback — or « Je n’ai pas pu répondre » (AI-06).
class AiTurnView extends ConsumerWidget {
  const AiTurnView({
    super.key,
    required this.turn,
    required this.space,
    required this.onAsk,
    required this.onEdit,
  });

  final AiTurn turn;
  final AssistantSpace space;
  final ValueChanged<String> onAsk;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final a = turn.answer;
    final controller = ref.read(assistantProvider(space).notifier);
    const gap = SizedBox(height: MuSpace.s3);
    final confirm = a.blocks.any((b) => b is AiConfirm);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MuAiSender(),
        const SizedBox(height: MuSpace.s2),
        if (a.understood.isNotEmpty) ...[MuAiUnderstood(items: a.understood, onEdit: onEdit), gap],
        if (turn.status == TurnStatus.failed)
          _Failed(
            programs: AssistantStory.normalize(turn.request).contains('programme'),
            onRetry: () => controller.retry(turn.id),
          )
        else ...[
          if (a.searching != null)
            MuAiShimmer.steps(label: a.searching!, steps: a.steps, current: a.step),
          if (a.found != null) ...[
            gap,
            Row(
              children: [
                Icon(
                  PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                  size: MuSize.iconXs,
                  color: c.textSecondary,
                ),
                const SizedBox(width: MuSpace.s1),
                Text(
                  l10n.aiAlreadyFound.toUpperCase(),
                  style: MuType.overline.copyWith(color: c.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: MuSpace.s2),
            _FoundCard(found: a.found!),
          ],
          for (final (i, b) in a.blocks.indexed)
            if (!turn.dismissed.contains(i)) ...[_block(context, ref, i, b), gap],
          if (turn.status == TurnStatus.writing && a.searching == null && a.blocks.isEmpty)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: MuAiShimmer.status(label: l10n.aiWriting),
            ),
          if (turn.status == TurnStatus.writing && a.searching != null) ...[
            gap,
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: MuAiShimmer.status(label: l10n.aiWriting),
            ),
          ],
          if (turn.status == TurnStatus.stopped)
            Text(l10n.aiStopped, style: MuType.caption.copyWith(color: c.textSecondary)),
          if (turn.status == TurnStatus.done)
            MuAiFeedbackRow(
              value: turn.feedback,
              onChanged: (v) => controller.vote(turn.id, v),
              note: space == AssistantSpace.owner
                  ? l10n.aiCheckPlanning
                  : confirm
                  ? l10n.aiCheckSummary
                  : l10n.aiCheckBefore,
            ),
        ],
      ],
    );
  }

  Widget _block(BuildContext context, WidgetRef ref, int i, AiBlock b) {
    final controller = ref.read(assistantProvider(space).notifier);
    return switch (b) {
      AiText() => MuChatBubble.ai(b.text),
      AiSlots() => SlotsCard(
        slots: b,
        onPick: (s) => controller.pickSlot(turn.id, i, s),
        onBook: () => controller.book(b),
        onVenue: () => context.push(Routes.venue(b.venueId)),
        onDismiss: () => controller.dismiss(turn.id, i),
      ),
      AiGame() => _GameBlock(block: b),
      AiNothingFound() => _NothingFound(block: b),
      AiCreateGame() => _CreateGameCard(block: b, onDismiss: () => controller.dismiss(turn.id, i)),
      AiAlert() => _AlertCard(block: b),
      AiFollowUps() => Wrap(
        spacing: MuSpace.s2,
        runSpacing: MuSpace.s2,
        children: [
          for (final (icon, label) in b.items)
            FittedBox(
              fit: BoxFit.scaleDown,
              child: MuChip(label: label, icon: icon, onSelected: (_) => onAsk(label)),
            ),
        ],
      ),
      AiConfirm() => ConfirmCard(slots: b.slots, onEdit: () => controller.dismiss(turn.id, i)),
      AiFound() => _FoundCard(found: b),
      AiPrograms() => _Programs(ids: b.ids),
      AiChart() => _Chart(block: b),
      AiPromo() => _PromoCard(block: b, onDismiss: () => controller.dismiss(turn.id, i)),
    };
  }
}

/// AI-06 « Je n’ai pas pu répondre »: the message is kept, nothing was done.
class _Failed extends StatelessWidget {
  const _Failed({required this.programs, required this.onRetry});

  final bool programs;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(MuSpace.s4),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: MuRadius.mdAll,
          border: Border.all(color: c.ai500),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  PhosphorIcons.warningCircle(PhosphorIconsStyle.fill),
                  size: MuSize.iconS,
                  color: c.errorText,
                ),
                const SizedBox(width: MuSpace.s2),
                Text(l10n.aiCouldNotAnswer, style: MuType.labelL.copyWith(color: c.text)),
              ],
            ),
            const SizedBox(height: MuSpace.s2),
            Text(l10n.aiCutOff, style: MuType.body.copyWith(color: c.text)),
            const SizedBox(height: MuSpace.s3),
            Wrap(
              spacing: MuSpace.s2,
              runSpacing: MuSpace.s2,
              children: [
                MuButton.primary(
                  label: l10n.reessayer,
                  leading: PhosphorIcons.arrowsClockwise(),
                  size: MuButtonSize.s,
                  onPressed: onRetry,
                ),
                if (programs)
                  MuButton.secondary(
                    label: l10n.aiSeePrograms,
                    size: MuButtonSize.s,
                    onPressed: () => context.push(TrainingRoutes.programs),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The 48 court thumbnail of the cards.
class _Thumb extends StatelessWidget {
  const _Thumb(this.sport);

  final MuSport sport;

  static const double _size = 48;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: MuRadius.smAll,
    child: SizedBox.square(
      dimension: _size,
      child: MuCourtArt(sport: sport, variant: MuCourtArtVariant.pattern),
    ),
  );
}

/// « Arena Five · La Marsa » + « ✓ Vérifié · 4,7 (128 avis) · 1,4 km ».
class _VenueLine extends StatelessWidget {
  const _VenueLine({required this.sport, required this.title, required this.meta});

  final MuSport sport;
  final String title;
  final String meta;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Row(
      children: [
        _Thumb(sport),
        const SizedBox(width: MuSpace.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: MuType.label.copyWith(color: c.text)),
              Text.rich(
                TextSpan(
                  children: [
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Icon(
                        PhosphorIcons.sealCheck(PhosphorIconsStyle.fill),
                        size: MuSize.iconXs,
                        color: c.successText,
                      ),
                    ),
                    TextSpan(
                      text: ' ${l10n.aiVerified}',
                      style: MuType.caption.copyWith(color: c.successText),
                    ),
                    TextSpan(text: ' · $meta'),
                  ],
                ),
                style: MuType.caption.copyWith(color: c.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// « 1 h · 150 DT le terrain » … « 15 DT par joueur à 10 ».
class _PriceLine extends StatelessWidget {
  const _PriceLine({required this.left, required this.price, required this.unit});

  final String left;
  final String price;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Text(left, style: MuType.caption.copyWith(color: c.textSecondary)),
        ),
        Text(price, style: MuType.numM.copyWith(color: c.text)),
        const SizedBox(width: MuSpace.s1),
        Text(unit, style: MuType.caption.copyWith(color: c.textSecondary)),
      ],
    );
  }
}

/// AI-02: the free slots of a venue; the picked one is booked by « Réserver 20h00 ».
class SlotsCard extends StatelessWidget {
  const SlotsCard({
    super.key,
    required this.slots,
    required this.onPick,
    required this.onBook,
    required this.onVenue,
    required this.onDismiss,
  });

  final AiSlots slots;
  final ValueChanged<int> onPick;
  final VoidCallback onBook;
  final VoidCallback onVenue;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final s = slots.slot;
    final day = formatDay(s.start);
    final time = formatTime(s.start);
    return MuAiSuggestionCard(
      showFeedback: false,
      context: l10n.aiFreeSlots(day),
      title: l10n.aiSlotTitle(s.court, day, time),
      reason: slots.reason,
      primary: MuAction(l10n.aiBookAt(time), onBook),
      primaryIcon: PhosphorIcons.arrowRight(),
      secondary: MuAction(l10n.aiSeeVenue, onVenue),
      onDismiss: onDismiss,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _VenueLine(
            sport: slots.sport,
            title: '${slots.venue} · ${slots.place}',
            meta: l10n.aiRatingDistance(
              formatLevel(slots.rating),
              slots.reviews,
              '${formatLevel(slots.distanceKm)} km',
            ),
          ),
          const SizedBox(height: MuSpace.s3),
          Semantics(
            container: true,
            label: l10n.aiFreeSlotsOn(
              '${formatWeekdayLong(s.start)} ${s.start.day} ${formatMonth(s.start)}',
            ),
            child: Row(
              children: [
                for (final (i, slot) in slots.slots.indexed) ...[
                  if (i > 0) const SizedBox(width: MuSpace.s2),
                  Expanded(
                    child: _SlotBox(
                      slot: slot,
                      selected: i == slots.picked,
                      onTap: () => onPick(i),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: MuSpace.s3),
          Divider(height: 1, color: c.border),
          const SizedBox(height: MuSpace.s3),
          _PriceLine(
            left: l10n.aiHourCourtPrice(formatDT(slots.price)),
            price: formatDT(slots.share),
            unit: l10n.aiPerPlayerAt(slots.players),
          ),
        ],
      ),
    );
  }
}

/// « 20h00 / Terrain 2 »: Volt when picked (with `on-accent` text).
class _SlotBox extends StatelessWidget {
  const _SlotBox({required this.slot, required this.selected, required this.onTap});

  final AiSlot slot;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final fg = selected ? c.onAccent : c.text;
    final court = slot.indoor ? l10n.aiIndoorCourt(slot.court) : slot.court;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: '${formatTime(slot.start)}, $court',
      excludeSemantics: true,
      child: Material(
        color: selected ? c.accent : c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: MuRadius.smAll,
          side: BorderSide(color: selected ? c.text : c.borderStrong),
        ),
        child: InkWell(
          borderRadius: MuRadius.smAll,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: MuSpace.s2, horizontal: MuSpace.s1),
            child: Column(
              children: [
                Text(formatTime(slot.start), style: MuType.numS.copyWith(color: fg)),
                Text(
                  court,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MuType.caption.copyWith(color: fg),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// An open game with its match fit (« 85 % compatible ») and why.
class _GameBlock extends StatelessWidget {
  const _GameBlock({required this.block});

  final AiGame block;

  @override
  Widget build(BuildContext context) {
    final g = block.game;
    final c = context.mu;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MuGameCard(
          game: g,
          variant: MuGameCardVariant.compact,
          onTap: g.id == null ? null : () => context.push(Routes.game(g.id!)),
        ),
        if (g.matchFit != null) ...[
          const SizedBox(height: MuSpace.s2),
          Row(
            children: [
              MuMatchFitScore.pill(value: g.matchFit!),
              const SizedBox(width: MuSpace.s2),
              if (g.matchFitReason != null)
                Expanded(
                  child: Text(
                    g.matchFitReason!,
                    style: MuType.caption.copyWith(color: c.textSecondary),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// AI-05 « Aucune partie ouverte demain soir à ton niveau, à moins de 10 km. »
class _NothingFound extends StatelessWidget {
  const _NothingFound({required this.block});

  final AiNothingFound block;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return MuCardSurface(
      padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4, vertical: MuSpace.s3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(PhosphorIcons.magnifyingGlass(), size: MuSize.iconS, color: c.text),
          const SizedBox(width: MuSpace.s3),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: block.bold, style: MuType.label),
                  TextSpan(text: ' ${block.text}'),
                ],
              ),
              style: MuType.body.copyWith(color: c.text),
            ),
          ),
        ],
      ),
    );
  }
}

/// AI-05 « Crée ta partie demain à 19h30 »: opens the venue's slots on that day (VEN-02), where
/// the player books and publishes the game.
class _CreateGameCard extends ConsumerWidget {
  const _CreateGameCard({required this.block, required this.onDismiss});

  final AiCreateGame block;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = block;
    final time = formatTime(b.start);
    final now = ref.watch(clockProvider)();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final isTomorrow = DateUtils.isSameDay(b.start, tomorrow);
    return MuAiSuggestionCard(
      showFeedback: false,
      context: l10n.aiFreeCourt(formatDay(b.start), time),
      title: isTomorrow ? l10n.aiCreateTomorrow(time) : l10n.aiCreateOn(formatDay(b.start), time),
      reason: b.reason,
      primary: MuAction(l10n.aiCreateGame, () {
        ref.read(bookingProvider.notifier)
          ..openVenue(b.venueId)
          ..setDay(DateTime(b.start.year, b.start.month, b.start.day));
        context.push(Routes.venueSlots(b.venueId));
      }),
      primaryIcon: PhosphorIcons.arrowRight(),
      onDismiss: onDismiss,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _VenueLine(sport: b.sport, title: b.venue, meta: b.meta),
          const SizedBox(height: MuSpace.s3),
          Divider(height: 1, color: context.mu.border),
          const SizedBox(height: MuSpace.s3),
          _PriceLine(
            left: l10n.aiDurationCourtPrice(formatDuration(b.minutes), formatDT(b.price)),
            price: formatDT(b.price / b.players),
            unit: l10n.aiPerPlayerAt(b.players),
          ),
        ],
      ),
    );
  }
}

/// « 1h30 » / « 1 h ».
String formatDuration(int minutes) => minutes % 60 == 0
    ? l10n.aiHours(minutes ~/ 60)
    : '${minutes ~/ 60}h${(minutes % 60).toString().padLeft(2, '0')}';

/// AI-05 « Préviens-moi si ça s’ouvre » + « Activer ».
class _AlertCard extends StatefulWidget {
  const _AlertCard({required this.block});

  final AiAlert block;

  @override
  State<_AlertCard> createState() => _AlertCardState();
}

class _AlertCardState extends State<_AlertCard> {
  bool _on = false;

  static const double _disc = 40;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return MuCardSurface(
      padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4, vertical: MuSpace.s3),
      child: Row(
        children: [
          Container(
            width: _disc,
            height: _disc,
            decoration: BoxDecoration(color: c.surfaceMuted, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(PhosphorIcons.bellRinging(), size: MuSize.iconS, color: c.text),
          ),
          const SizedBox(width: MuSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.aiNotifyMe, style: MuType.label.copyWith(color: c.text)),
                Text(widget.block.detail, style: MuType.caption.copyWith(color: c.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: MuSpace.s2),
          if (_on)
            MuStatusBadge(status: MuStatus.confirmed, label: l10n.aiAlertOn)
          else
            MuButton.secondary(
              label: l10n.entTurnOn,
              size: MuButtonSize.s,
              onPressed: () {
                setState(() => _on = true);
                MuToast.show(context, title: l10n.aiAlertSaved, tone: MuToastTone.success);
              },
            ),
        ],
      ),
    );
  }
}

/// AI-04: the court already found while the search goes on.
class _FoundCard extends StatelessWidget {
  const _FoundCard({required this.found});

  final AiFound found;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final f = found;
    return MuCardSurface(
      child: Row(
        children: [
          _Thumb(f.sport),
          const SizedBox(width: MuSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(f.venue, style: MuType.label.copyWith(color: c.text)),
                Text(f.when, style: MuType.caption.copyWith(color: c.textSecondary)),
                Text(f.meta, style: MuType.caption.copyWith(color: c.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatDT(f.price), style: MuType.numM.copyWith(color: c.text)),
              Text(
                l10n.aiPerPlayerShort(f.players),
                style: MuType.caption.copyWith(color: c.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// AI-03: what « Confirmer » books; it opens our checkout (PAY-01).
class ConfirmCard extends ConsumerStatefulWidget {
  const ConfirmCard({super.key, required this.slots, required this.onEdit});

  final AiSlots slots;
  final VoidCallback onEdit;

  @override
  ConsumerState<ConfirmCard> createState() => _ConfirmCardState();
}

class _ConfirmCardState extends ConsumerState<ConfirmCard> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final b = widget.slots;
    final s = b.slot;
    final end = s.start.add(const Duration(hours: 1));
    final policy = policyFor(s.start);
    final now = ref.watch(clockProvider)();
    String when(DateTime d) => DateUtils.isSameDay(d, now)
        ? l10n.aiTonightAt(formatTime(d))
        : '${formatWeekday(d)} ${formatTime(d)}';

    Widget row(String label, Widget value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: MuSpace.s3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: MuType.body.copyWith(color: c.textSecondary)),
          const SizedBox(width: MuSpace.s4),
          Expanded(
            child: Align(alignment: AlignmentDirectional.centerEnd, child: value),
          ),
        ],
      ),
    );

    return MuCardSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _Thumb(b.sport),
              const SizedBox(width: MuSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${b.venue} · ${s.court}', style: MuType.labelL.copyWith(color: c.text)),
                    Text(
                      '${b.place} · ${b.surface}',
                      style: MuType.caption.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: MuSpace.s2),
          Divider(height: 1, color: c.border),
          row(
            l10n.quand,
            Text(
              '${formatDay(s.start)} · ${ltr('${formatTime(s.start)}–${formatTime(end)}')}',
              style: MuType.label.copyWith(color: c.text),
            ),
          ),
          Divider(height: 1, color: c.border),
          row(
            l10n.aiYourShare,
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: formatDT(b.share), style: MuType.numM),
                  TextSpan(
                    text: ' ${l10n.aiShareOf(formatDT(b.price), b.players)}',
                    style: MuType.caption.copyWith(color: c.textSecondary),
                  ),
                ],
              ),
              style: TextStyle(color: c.text),
            ),
          ),
          Divider(height: 1, color: c.border),
          row(
            l10n.aiCancellation,
            Text(
              '${l10n.aiFreeUntil(when(policy.freeUntil))}\n${l10n.aiHalfUntil(when(policy.halfUntil))}',
              textAlign: TextAlign.end,
              style: MuType.caption.copyWith(color: c.text),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(MuSpace.s3),
            decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: MuRadius.smAll),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(PhosphorIcons.lockSimple(), size: MuSize.iconXs, color: c.text),
                const SizedBox(width: MuSpace.s2),
                Expanded(
                  child: Text(l10n.aiNothingWithout, style: MuType.caption.copyWith(color: c.text)),
                ),
              ],
            ),
          ),
          const SizedBox(height: MuSpace.s4),
          Row(
            children: [
              Expanded(
                child: MuButton.secondary(
                  label: l10n.entEdit,
                  leading: PhosphorIcons.pencilSimple(),
                  fullWidth: true,
                  onPressed: widget.onEdit,
                ),
              ),
              const SizedBox(width: MuSpace.s2),
              Expanded(
                child: MuButton.primary(
                  label: l10n.aiConfirm,
                  leading: PhosphorIcons.check(),
                  fullWidth: true,
                  loading: _busy,
                  onPressed: () async {
                    setState(() => _busy = true);
                    try {
                      await startAssistantCheckout(ref, b);
                      if (context.mounted) context.push(Routes.checkout);
                    } finally {
                      if (mounted) setState(() => _busy = false);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// « Service et retour »: the programs the assistant advises, opening ENT-03.
class _Programs extends ConsumerWidget {
  const _Programs({required this.ids});

  final List<String> ids;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final id in ids)
        if (ref.watch(programProvider(id)) case final p?)
          Padding(
            padding: const EdgeInsets.only(bottom: MuSpace.s2),
            child: MuProgramCard(
              program: p.card,
              variant: MuCardVariant.compact,
              onTap: () => context.push(TrainingRoutes.program(id)),
            ),
          ),
    ],
  );
}

/// AI-07 « Créneaux les plus vides ».
class _Chart extends StatelessWidget {
  const _Chart({required this.block});

  final AiChart block;

  @override
  Widget build(BuildContext context) => MuBarChart(
    title: block.title,
    subtitle: block.subtitle,
    categories: block.categories,
    series: [MuBarSeries(label: l10n.aiFillRate, data: block.values)],
    format: (v) => l10n.aiPercent(v.round()),
    orientation: Axis.horizontal,
    mode: MuBarMode.grouped,
    categoryLabel: l10n.aiSlot,
  );
}

/// AI-07 « Proposer −20 % ? »: « Préparer l’offre » opens the tariffs with the promo (OWN-16).
class _PromoCard extends StatelessWidget {
  const _PromoCard({required this.block, required this.onDismiss});

  final AiPromo block;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final b = block;
    return MuAiSuggestionCard(
      showFeedback: false,
      context: l10n.aiTariffsOf(AssistantStory.ownerVenue),
      title: b.title,
      reason: b.reason,
      primary: MuAction(
        l10n.aiPrepareOffer,
        () => context.push(
          Routes.ownerTariffs,
          extra: PromoDraft(
            weekday: b.weekday,
            fromHour: b.fromHour,
            toHour: b.toHour,
            percent: b.percent,
            priceBefore: b.priceBefore,
          ),
        ),
      ),
      secondary: MuAction(l10n.aiIgnore, onDismiss),
      secondaryDismisses: true,
      onDismiss: onDismiss,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                formatDT(b.priceBefore),
                style: MuType.numM.copyWith(
                  color: c.textSecondary,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(width: MuSpace.s2),
              Icon(PhosphorIcons.arrowRight(), size: MuSize.iconXs, color: c.textSecondary),
              const SizedBox(width: MuSpace.s2),
              Text(formatDT(b.priceAfter), style: MuType.numM.copyWith(color: c.text)),
            ],
          ),
          Text(
            l10n.aiPromoMeta(b.slots, formatDay(b.date)),
            style: MuType.caption.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: MuSpace.s2),
          Text(
            l10n.aiPromoDetail(formatDT(b.priceAfter / b.players), b.players),
            style: MuType.body.copyWith(color: c.text),
          ),
        ],
      ),
    );
  }
}
