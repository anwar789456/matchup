import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/flow_scaffold.dart';
import '../controllers/training_providers.dart';
import '../data/training_models.dart';
import '../training_routes.dart';
import '../widgets/plan_labels.dart';

/// ENT-07 · Plan IA: the proposed week around the matches and the tournament, its sessions, why
/// the AI chose them — then « Régénérer », « Modifier » or « Accepter le plan ». Nothing enters
/// the agenda before « Accepter ».
class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  bool _accepting = false;
  bool? _liked;

  Future<void> _accept() async {
    setState(() => _accepting = true);
    final count = ref.read(planProvider).value?.sessions.length ?? 0;
    await ref.read(planProvider.notifier).accept();
    if (!mounted) return;
    MuToast.show(
      context,
      tone: MuToastTone.success,
      title: l10n.entPlanAdded,
      description: l10n.entPlanAddedText(count),
    );
    context.go(TrainingRoutes.root);
  }

  void _feedback(bool liked) {
    setState(() => _liked = _liked == liked ? null : liked);
    if (_liked != null) MuToast.show(context, title: l10n.entThanksFeedback);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final plan = ref.watch(planProvider);
    final p = plan.value;
    final loading = plan.isLoading;

    final header = SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(MuSpace.s1, MuSpace.s2, MuSpace.s4, 0),
        child: Row(
          children: [
            MuIconButton(
              icon: PhosphorIcons.arrowLeft(),
              label: l10n.entBackToGoals,
              size: MuIconButtonSize.l,
              onPressed: () => context.canPop() ? context.pop() : context.go(TrainingRoutes.planGoals),
            ),
            const SizedBox(width: MuSpace.s1),
            Expanded(
              child: Text(l10n.entTrainingPlan, style: MuType.labelL.copyWith(color: c.text)),
            ),
            MuAiLabel(),
          ],
        ),
      ),
    );

    Widget body;
    if (plan.hasError && p == null) {
      body = Padding(
        padding: const EdgeInsets.all(MuSpace.s4),
        child: MuBanner(
          title: l10n.entPlanFailed,
          detail: l10n.verifieTaConnexionPuisReessaie,
          tone: MuBannerTone.warning,
          icon: PhosphorIcons.wifiSlash(),
          action: MuAction(l10n.reessayer, () => ref.read(planProvider.notifier).regenerate()),
        ),
      );
    } else if (loading || p == null) {
      body = MuSkeletonGroup(
        label: l10n.entAiPreparing,
        child: Padding(
          padding: const EdgeInsets.all(MuSpace.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(PhosphorIcons.sparkle(PhosphorIconsStyle.fill), size: MuSize.iconS, color: c.ai500),
                  const SizedBox(width: MuSpace.s2),
                  Text(l10n.entAiPreparing, style: MuType.label.copyWith(color: c.aiText)),
                ],
              ),
              const SizedBox(height: MuSpace.s4),
              const MuSkeleton.text(lines: 2),
              const SizedBox(height: MuSpace.s4),
              const MuSkeleton(height: 180),
              const SizedBox(height: MuSpace.s4),
              const MuSkeleton(height: 240),
            ],
          ),
        ),
      );
    } else {
      body = _Plan(plan: p, liked: _liked, onFeedback: _feedback);
    }

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          header,
          Expanded(
            child: ListView(padding: const EdgeInsets.only(bottom: MuSpace.s6), children: [body]),
          ),
          StickyActionBar(
            children: [
              Row(
                children: [
                  Expanded(
                    child: MuButton.secondary(
                      label: l10n.entRegenerate,
                      leading: PhosphorIcons.arrowsClockwise(),
                      size: MuButtonSize.l,
                      fullWidth: true,
                      onPressed: loading || _accepting
                          ? null
                          : () => ref.read(planProvider.notifier).regenerate(),
                    ),
                  ),
                  const SizedBox(width: MuSpace.s3),
                  Expanded(
                    child: MuButton.secondary(
                      label: l10n.entEdit,
                      leading: PhosphorIcons.pencilSimple(),
                      size: MuButtonSize.l,
                      fullWidth: true,
                      onPressed: _accepting
                          ? null
                          : () => context.canPop()
                                ? context.pop()
                                : context.go(TrainingRoutes.planGoals),
                    ),
                  ),
                ],
              ),
              MuButton.primary(
                label: l10n.entAcceptPlan,
                leading: PhosphorIcons.check(PhosphorIconsStyle.bold),
                size: MuButtonSize.xl,
                fullWidth: true,
                loading: _accepting,
                onPressed: p == null || loading || _accepting ? null : _accept,
              ),
              Text(
                l10n.entAcceptDetail(p?.sessions.length ?? 0),
                textAlign: TextAlign.center,
                style: MuType.caption.copyWith(color: c.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Plan extends StatelessWidget {
  const _Plan({required this.plan, required this.liked, required this.onFeedback});

  final TrainingPlan plan;
  final bool? liked;
  final ValueChanged<bool> onFeedback;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final r = plan.request;
    final end = plan.weekStart.add(const Duration(days: 6));
    final goals = [for (final g in r.goals) planGoalLabel(g)];
    final summary = l10n.entPlanSummary(
      goals.isEmpty ? '' : '${goals.first}${goals.skip(1).map((g) => ' + ${g.toLowerCase()}').join()}',
      intensityLabel(r.intensity).toLowerCase(),
      plan.sessions.length,
      dayMomentLabel(r.moment).toLowerCase(),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s3, MuSpace.s4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.entWeekOfRange(ltr('${plan.weekStart.day}'), ltr('${end.day}'), formatMonth(end)),
              style: MuType.h2.copyWith(color: c.text),
            ),
          ),
          const SizedBox(height: MuSpace.s2),
          Text(summary, style: MuType.body.copyWith(color: c.textSecondary)),
          const SizedBox(height: MuSpace.s5),
          _Calendar(plan: plan),
          const SizedBox(height: MuSpace.s8),
          Semantics(
            header: true,
            child: Text(
              l10n.entYourSessions(plan.sessions.length),
              style: MuType.h2.copyWith(color: c.text),
            ),
          ),
          const SizedBox(height: MuSpace.s3),
          MuCardSurface(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (i, s) in plan.sessions.indexed) ...[
                  if (i > 0) Divider(height: 1, thickness: 1, color: c.border),
                  _SessionRow(item: s),
                ],
              ],
            ),
          ),
          const SizedBox(height: MuSpace.s6),
          MuCardSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(l10n.entWhyThisPlan, style: MuType.h3.copyWith(color: c.text)),
                      ),
                    ),
                    Text(
                      l10n.entGeneratedAt(formatTime(plan.generatedAt)),
                      style: MuType.caption.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: MuSpace.s3),
                Container(
                  padding: const EdgeInsets.all(MuSpace.s3),
                  decoration: BoxDecoration(color: c.aiSoft, borderRadius: MuRadius.smAll),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        PhosphorIcons.lightbulb(PhosphorIconsStyle.fill),
                        size: MuSize.iconXs,
                        color: c.ai500,
                      ),
                      const SizedBox(width: MuSpace.s2),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: l10n.recommandeCar, style: MuType.label),
                              TextSpan(text: ' ${plan.reason}'),
                            ],
                          ),
                          style: MuType.body.copyWith(color: c.aiText),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MuSpace.s3),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.entAiCanBeWrong,
                        style: MuType.caption.copyWith(color: c.textSecondary),
                      ),
                    ),
                    MuIconButton(
                      icon: PhosphorIcons.thumbsUp(),
                      selectedIcon: PhosphorIcons.thumbsUp(PhosphorIconsStyle.fill),
                      label: l10n.entPlanSuitsMe,
                      pressed: liked == true,
                      onPressed: () => onFeedback(true),
                    ),
                    MuIconButton(
                      icon: PhosphorIcons.thumbsDown(),
                      selectedIcon: PhosphorIcons.thumbsDown(PhosphorIconsStyle.fill),
                      label: l10n.entPlanDoesNotSuit,
                      pressed: liked == false,
                      onPressed: () => onFeedback(false),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The week as seven columns: the sessions to accept and the matches and tournament they fit
/// around, then the legend (colour + icon + label).
class _Calendar extends StatelessWidget {
  const _Calendar({required this.plan});

  final TrainingPlan plan;

  static const double _column = 92;
  static const double _legendSwatch = 10;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final days = [for (var i = 0; i < 7; i++) plan.weekStart.add(Duration(days: i))];
    List<PlanItem> on(DateTime d) => [
      for (final i in plan.items)
        if (i.start.year == d.year && i.start.month == d.month && i.start.day == d.day) i,
    ];
    final legend = [
      (MuTone.info, l10n.entLegendProgram),
      (MuTone.ai, l10n.entLegendAi),
      (MuTone.success, l10n.entLegendMatch),
      (MuTone.warning, l10n.entLegendTournament),
    ];
    return MuCardSurface(
      padding: const EdgeInsets.all(MuSpace.s3),
      semanticLabel: l10n.entWeekCalendar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, d) in days.indexed) ...[
                if (i > 0) const SizedBox(width: MuSpace.s1),
                Expanded(
                  child: Column(
                    children: [
                      Text(formatWeekday(d), style: MuType.caption.copyWith(color: c.textSecondary)),
                      Text(
                        '${d.day}',
                        style: MuType.numS.copyWith(
                          color: on(d).isEmpty ? c.textSecondary : c.text,
                        ),
                      ),
                      const SizedBox(height: MuSpace.s1),
                      ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: _column),
                        child: on(d).isEmpty
                            ? Semantics(
                                label: l10n.entDayRest,
                                child: Container(
                                  height: _column,
                                  decoration: BoxDecoration(
                                    borderRadius: MuRadius.smAll,
                                    border: Border.all(color: c.border),
                                  ),
                                ),
                              )
                            : Column(
                                children: [
                                  for (final (j, item) in on(d).indexed) ...[
                                    if (j > 0) const SizedBox(height: MuSpace.s1),
                                    _CalendarEntry(item: item, tall: on(d).length == 1),
                                  ],
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: MuSpace.s3),
          Wrap(
            spacing: MuSpace.s3,
            runSpacing: MuSpace.s1,
            children: [
              for (final (tone, label) in legend)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: _legendSwatch,
                      height: _legendSwatch,
                      decoration: BoxDecoration(
                        color: tone.soft(c),
                        borderRadius: MuRadius.xsAll,
                        border: Border.all(color: tone.color(c)),
                      ),
                    ),
                    const SizedBox(width: MuSpace.s1),
                    Text(label, style: MuType.caption.copyWith(color: c.textSecondary)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One entry in a day column: icon, time, and « Bandeja » or « Tournoi » when there is room.
class _CalendarEntry extends StatelessWidget {
  const _CalendarEntry({required this.item, required this.tall});

  final PlanItem item;

  /// Alone in its day: as tall as the column, with its short name.
  final bool tall;

  static const double _short = 44;
  static const double _tall = 92;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final tone = planItemTone(item.kind);
    final ink = tone.text(c);
    final name = switch (item.kind) {
      PlanItemKind.program => item.calendarLabel,
      PlanItemKind.tournament => l10n.entCalendarTournament,
      _ => null,
    };
    final time = formatTime(item.start);
    // A tournament day that already has a session shows « Tournoi », not the time.
    final showTime = !(item.kind == PlanItemKind.tournament && !tall);
    return Semantics(
      label: '${item.title}, $time',
      excludeSemantics: true,
      child: Container(
        height: tall ? _tall : _short,
        padding: const EdgeInsets.symmetric(horizontal: MuSpace.s1 / 2, vertical: MuSpace.s1),
        decoration: BoxDecoration(color: tone.soft(c), borderRadius: MuRadius.smAll),
        child: Column(
          mainAxisAlignment: tall ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            Icon(planItemIcon(item), size: MuSize.iconXs, color: ink),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                showTime ? time : name ?? time,
                style: MuType.numXs.copyWith(color: ink),
              ),
            ),
            if (tall && name != null)
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(name, style: MuType.caption.copyWith(color: ink)),
              ),
          ],
        ),
      ),
    );
  }
}

/// A session of « Tes 3 séances »: date, tag, title, time and details.
class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.item});

  final PlanItem item;

  static const double _dateColumn = 52;
  static const double _tagIcon = 14;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final tone = planItemTone(item.kind);
    final tag = item.kind == PlanItemKind.program ? l10n.entYourProgram : item.tag ?? '';
    final caption = MuType.caption.copyWith(color: c.textSecondary);
    return Padding(
      padding: const EdgeInsets.all(MuSpace.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _dateColumn,
            child: Column(
              children: [
                Text(
                  formatWeekday(item.start).toUpperCase(),
                  style: MuType.overline.copyWith(color: c.textSecondary),
                ),
                Text('${item.start.day}', style: MuType.numL.copyWith(color: c.text)),
              ],
            ),
          ),
          const SizedBox(width: MuSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: MuSpace.s2, vertical: MuSpace.s1 / 2),
                  decoration: ShapeDecoration(color: tone.soft(c), shape: const StadiumBorder()),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(planItemIcon(item), size: _tagIcon, color: tone.text(c)),
                      const SizedBox(width: MuSpace.s1),
                      Text(tag, style: MuType.labelS.copyWith(color: tone.text(c))),
                    ],
                  ),
                ),
                const SizedBox(height: MuSpace.s2),
                Text(item.title, style: MuType.labelL.copyWith(color: c.text)),
                const SizedBox(height: MuSpace.s1),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: formatTime(item.start),
                        style: MuType.labelS.copyWith(color: c.text),
                      ),
                      if (item.details != null) TextSpan(text: ' · ${item.details}'),
                    ],
                  ),
                  style: caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
