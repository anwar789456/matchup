import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/data/story_data.dart';
import '../../common/widgets/flow_scaffold.dart';
import '../controllers/training_providers.dart';
import '../data/training_models.dart';
import '../training_routes.dart';
import '../widgets/plan_labels.dart';

/// ENT-06 · Plan IA · objectifs: goals (2 max), free days and moment, session length,
/// intensity, and what the AI uses — then « Générer mon plan » (shown before it is applied).
class PlanGoalsScreen extends ConsumerWidget {
  const PlanGoalsScreen({super.key});

  // ENT-06: day toggles are 44 high; source rows have 28 icon circles.
  static const double _sourceIcon = 28;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final r = ref.watch(planRequestProvider);
    final requests = ref.read(planRequestProvider.notifier);
    final programs = ref.watch(programsProvider).value ?? const [];
    final progress = ref.watch(trainingProgressProvider).value;
    final active = [
      for (final p in programs)
        if ((progress?.isEnrolled(p.id) ?? false) && progress!.nextLesson(p) != null) p,
    ].firstOrNull;
    final next = active == null ? null : progress!.nextLesson(active);
    final padelLevel = Story.myLevels[MuSport.padel] ?? Story.myLevels.values.first;

    Widget section(String title, {String? aside, String? caption, required Widget child}) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(title, style: MuType.h3.copyWith(color: c.text)),
              ),
            ),
            if (aside != null) Text(aside, style: MuType.caption.copyWith(color: c.textSecondary)),
          ],
        ),
        if (caption != null) ...[
          const SizedBox(height: MuSpace.s1),
          Text(caption, style: MuType.caption.copyWith(color: c.textSecondary)),
        ],
        const SizedBox(height: MuSpace.s3),
        child,
      ],
    );

    Widget source(IconData icon, String text) => Row(
      children: [
        Container(
          width: _sourceIcon,
          height: _sourceIcon,
          decoration: BoxDecoration(color: c.aiSoft, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Icon(icon, size: MuSize.iconXs, color: c.aiText),
        ),
        const SizedBox(width: MuSpace.s3),
        Expanded(child: Text(text, style: MuType.body.copyWith(color: c.text))),
      ],
    );

    return FlowScaffold(
      onBack: () => context.canPop() ? context.pop() : context.go(TrainingRoutes.root),
      topAction: const Padding(
        padding: EdgeInsetsDirectional.only(end: MuSpace.s2),
        child: MuPremiumBadge(),
      ),
      body: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(l10n.entYourWeekPlan, style: MuType.h1.copyWith(color: c.text)),
            ),
            const SizedBox(height: MuSpace.s2),
            Text(l10n.entPlanIntro, style: MuType.bodyL.copyWith(color: c.textSecondary)),
          ],
        ),
        section(
          l10n.entYourGoal,
          aside: l10n.entMaxGoals(PlanRequest.maxGoals),
          child: Wrap(
            spacing: MuSpace.s2,
            runSpacing: MuSpace.s2,
            children: [
              for (final g in PlanGoal.values)
                MuChip(
                  kind: MuChipKind.choice,
                  label: planGoalLabel(g),
                  icon: planGoalIcon(g),
                  selected: r.goals.contains(g),
                  onSelected: (_) {
                    if (!r.goals.contains(g) && r.goals.length >= PlanRequest.maxGoals) {
                      MuToast.show(context, title: l10n.entMaxGoalsReached(PlanRequest.maxGoals));
                      return;
                    }
                    requests.toggleGoal(g);
                  },
                ),
            ],
          ),
        ),
        section(
          l10n.entYourFreeDays,
          aside: l10n.entDaysCount(r.days.length),
          caption: null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  for (var d = DateTime.monday; d <= DateTime.sunday; d++) ...[
                    if (d > DateTime.monday) const SizedBox(width: MuSpace.s1 + MuSpace.s1 / 2),
                    Expanded(
                      child: _DayToggle(
                        // A Monday of the story's month: 12 oct. 2026 + d − 1.
                        day: DateTime(2026, 10, 11 + d),
                        selected: r.days.contains(d),
                        onTap: () => requests.toggleDay(d),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: MuSpace.s3),
              Semantics(
                container: true,
                label: l10n.entMomentOfDay,
                child: Wrap(
                  spacing: MuSpace.s2,
                  runSpacing: MuSpace.s2,
                  children: [
                    for (final m in DayMoment.values)
                      MuChip(
                        kind: MuChipKind.choice,
                        label: dayMomentLabel(m),
                        icon: dayMomentIcon(m),
                        selected: r.moment == m,
                        onSelected: (_) => requests.set(r.copyWith(moment: m)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: MuSpace.s2),
              Text(l10n.entPrefilled, style: MuType.caption.copyWith(color: c.textSecondary)),
            ],
          ),
        ),
        section(
          l10n.entSessionLength,
          child: Wrap(
            spacing: MuSpace.s2,
            runSpacing: MuSpace.s2,
            children: [
              for (final m in PlanRequest.durations)
                MuChip(
                  kind: MuChipKind.choice,
                  label: l10n.entMinutes(m),
                  selected: r.minutes == m,
                  onSelected: (_) => requests.set(r.copyWith(minutes: m)),
                ),
            ],
          ),
        ),
        section(
          l10n.entIntensity,
          caption: intensityCaption(r.intensity),
          child: MuSegmentedControl<PlanIntensity>(
            semanticLabel: l10n.entIntensity,
            expand: true,
            value: r.intensity,
            onChanged: (v) => requests.set(r.copyWith(intensity: v)),
            segments: [
              for (final i in PlanIntensity.values) MuSegment(value: i, label: intensityLabel(i)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(MuSpace.s4),
          decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: MuRadius.mdAll),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Semantics(
                    header: true,
                    child: Text(l10n.entWhatAiUses, style: MuType.labelL.copyWith(color: c.text)),
                  ),
                  const SizedBox(width: MuSpace.s2),
                  MuAiLabel(size: MuAiLabelSize.s),
                ],
              ),
              const SizedBox(height: MuSpace.s3),
              source(
                PhosphorIcons.tennisBall(),
                l10n.entAiSourceMatches(18, formatLevel(padelLevel)),
              ),
              const SizedBox(height: MuSpace.s3),
              source(PhosphorIcons.usersThree(), l10n.entAiSourceReviews(9)),
              if (active != null && next != null) ...[
                const SizedBox(height: MuSpace.s3),
                Divider(height: 1, thickness: 1, color: c.border),
                const SizedBox(height: MuSpace.s3),
                MuSwitch(
                  value: r.includeProgram,
                  labelAtStart: true,
                  label: l10n.entIncludeProgram(active.shortTitle),
                  description: l10n.entIncludeProgramDetail(r.days.length, next.index),
                  onChanged: (v) => requests.set(r.copyWith(includeProgram: v)),
                ),
              ],
            ],
          ),
        ),
      ],
      bottomBar: [
        Text(
          l10n.entSeePlanFirst,
          textAlign: TextAlign.center,
          style: MuType.caption.copyWith(color: c.textSecondary),
        ),
        MuButton.primary(
          label: l10n.entGeneratePlan,
          leading: PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
          size: MuButtonSize.xl,
          fullWidth: true,
          onPressed: r.complete ? () => context.push(TrainingRoutes.plan) : null,
        ),
      ],
    );
  }
}

/// A free-day toggle: « lun. », Volt when picked.
class _DayToggle extends StatelessWidget {
  const _DayToggle({required this.day, required this.selected, required this.onTap});

  final DateTime day;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Semantics(
      button: true,
      toggled: selected,
      label: formatWeekdayLong(day),
      excludeSemantics: true,
      child: MuFocusRing(
        borderRadius: MuRadius.smAll,
        child: Material(
          color: selected ? c.accent : c.surface,
          shape: RoundedRectangleBorder(
            borderRadius: MuRadius.smAll,
            side: BorderSide(color: selected ? c.accent : c.borderStrong),
          ),
          child: InkWell(
            borderRadius: MuRadius.smAll,
            onTap: onTap,
            child: SizedBox(
              height: MuSize.touchTarget,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    formatWeekday(day),
                    style: MuType.labelS.copyWith(color: selected ? c.onAccent : c.text),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
