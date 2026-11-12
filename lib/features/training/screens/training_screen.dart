import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/clock.dart';
import '../../../core/format.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../subscription/controllers/subscription_controller.dart';
import '../../subscription/data/subscription_repository.dart';
import '../controllers/training_providers.dart';
import '../controllers/video_analysis_controller.dart';
import '../data/training_models.dart';
import '../data/video_analyst.dart';
import '../training_routes.dart';
import '../widgets/training_widgets.dart';

/// ENT-01 · Mon entraînement: the week's streak, today's session, the programs joined, the AI
/// weekly plan, the video analysis and programs to go further.
class TrainingScreen extends ConsumerWidget {
  const TrainingScreen({super.key});

  // ENT-01: sections 32 apart; the page ends above the FAB.
  static const double _sectionGap = MuSpace.s8;
  static const double _bottomRoom = MuSpace.s16 + MuSpace.s16 + MuSpace.s2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final now = ref.watch(clockProvider)();
    final programs = ref.watch(programsProvider);
    final progress = ref.watch(trainingProgressProvider);
    final subscription = ref.watch(subscriptionProvider).value;

    final appBar = MuTopAppBar.large(
      title: l10n.entrainement,
      actions: [
        MuBarAction(
          icon: PhosphorIcons.videoCamera(),
          label: l10n.entAnalyseVideo,
          onPressed: () => context.push(TrainingRoutes.video),
        ),
        MuBarAction(
          icon: PhosphorIcons.magnifyingGlass(),
          label: l10n.entSearchProgram,
          onPressed: () => context.go(TrainingRoutes.programs),
        ),
      ],
    );

    Widget body;
    if ((programs.hasError && !programs.hasValue) || (progress.hasError && !progress.hasValue)) {
      body = Padding(
        padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
        child: TrainingRetry(
          onRetry: () => ref
            ..invalidate(programsProvider)
            ..invalidate(trainingProgressProvider),
        ),
      );
    } else if (!programs.hasValue || !progress.hasValue) {
      body = const _Loading();
    } else {
      body = _Content(
        now: now,
        programs: programs.value!,
        progress: progress.value!,
        subscription: subscription,
      );
    }

    return Scaffold(
      backgroundColor: c.bg,
      body: ListView(
        padding: const EdgeInsets.only(bottom: _bottomRoom),
        children: [appBar, const SizedBox(height: MuSpace.s2), body],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => MuSkeletonGroup(
    label: l10n.entLoadingTraining,
    child: const Padding(
      padding: EdgeInsets.symmetric(horizontal: MuSpace.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MuSkeleton(height: 220),
          SizedBox(height: TrainingScreen._sectionGap),
          MuLessonCard.loading(),
          SizedBox(height: TrainingScreen._sectionGap),
          MuProgramCard.loading(variant: MuCardVariant.compact),
        ],
      ),
    ),
  );
}

class _Content extends ConsumerWidget {
  const _Content({
    required this.now,
    required this.programs,
    required this.progress,
    required this.subscription,
  });

  final DateTime now;
  final List<TrainingProgram> programs;
  final TrainingProgress progress;
  final Subscription? subscription;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final joined = [for (final p in programs) if (progress.isEnrolled(p.id)) p];
    // The program whose next session is today's: the first joined one not finished yet.
    final active = joined.where((p) => progress.nextLesson(p) != null).firstOrNull;
    final next = active == null ? null : progress.nextLesson(active);
    final doneToday = progress.daysDone(now).contains(now.weekday);
    final others = [for (final p in programs) if (!progress.isEnrolled(p.id)) p];

    Widget pad(Widget child) =>
        Padding(padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4), child: child);

    final children = <Widget>[
      pad(
        _WeekCard(
          now: now,
          progress: progress,
          todayLesson: doneToday ? null : next?.index,
        ),
      ),
      if (active != null && next != null) ...[
        const SizedBox(height: TrainingScreen._sectionGap),
        TrainingSectionHeader(
          title: doneToday ? l10n.entNextSession : l10n.entToday,
          caption: l10n.entProgramByCoach(active.title, active.card.coach.label),
        ),
        const SizedBox(height: MuSpace.s3),
        pad(
          MuLessonCard(
            lesson: next.toMu(active.sport),
            status: doneToday ? MuLessonStatus.available : MuLessonStatus.current,
            onTap: () => context.push(TrainingRoutes.lesson(active.id, next.index)),
          ),
        ),
      ],
      const SizedBox(height: TrainingScreen._sectionGap),
      TrainingSectionHeader(
        title: l10n.entMyPrograms,
        action: l10n.entCatalogue,
        onAction: () => context.go(TrainingRoutes.programs),
      ),
      const SizedBox(height: MuSpace.s3),
      if (joined.isEmpty)
        pad(
          MuEmptyState(
            title: l10n.entNoProgramTitle,
            description: l10n.entNoProgramText,
            illustration: MuEmptyIllustration.programs,
            actions: [
              MuButton.primary(
                label: l10n.entCatalogue,
                onPressed: () => context.go(TrainingRoutes.programs),
              ),
            ],
          ),
        )
      else
        for (final (i, p) in joined.indexed) ...[
          if (i > 0) const SizedBox(height: MuSpace.s3),
          pad(
            _MyProgramCard(
              program: p,
              progress: progress,
              onTap: () => context.push(TrainingRoutes.program(p.id)),
            ),
          ),
        ],
      if (!progress.planCardHidden && active != null) ...[
        const SizedBox(height: TrainingScreen._sectionGap),
        pad(_PlanSuggestion(program: active, subscription: subscription)),
      ],
      const SizedBox(height: MuSpace.s6),
      pad(const _VideoCard()),
      if (others.isNotEmpty) ...[
        const SizedBox(height: TrainingScreen._sectionGap),
        TrainingSectionHeader(
          title: l10n.entToProgress,
          caption: l10n.entToProgressCaption,
          action: l10n.voirTout,
          onAction: () => context.go(TrainingRoutes.programs),
        ),
        const SizedBox(height: MuSpace.s3),
        for (final (i, p) in others.take(2).indexed) ...[
          if (i > 0) const SizedBox(height: MuSpace.s3),
          pad(
            MuProgramCard(
              program: p.card,
              variant: MuCardVariant.compact,
              onTap: () => context.push(TrainingRoutes.program(p.id)),
            ),
          ),
        ],
      ],
    ];
    return DefaultTextStyle.merge(
      style: TextStyle(color: c.text),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }
}

/// « Ta semaine · 12 – 18 oct. »: the streak, sessions this week, the seven days and what to do
/// next — a dark emphasis card in both themes (CLAUDE.md rule 13).
class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.now, required this.progress, required this.todayLesson});

  final DateTime now;
  final TrainingProgress progress;

  /// The session to do today (the dashed dot), null when today's is done or there is none.
  final int? todayLesson;

  static const double _fire = 28;

  @override
  Widget build(BuildContext context) {
    final start = TrainingProgress.weekStart(now);
    final end = start.add(const Duration(days: 6));
    final done = progress.doneThisWeek(now);
    final streak = progress.streak(now);
    final validated = progress.weekValidated(now);
    final days = progress.daysDone(now);
    final range = ltr('${start.day} – ${end.day} ${formatMonth(end)}');

    return TrainingDarkCard(
      semanticLabel: l10n.entWeekSemantics(streak, done, progress.weeklyGoal),
      child: Builder(
        builder: (context) {
          final c = context.mu;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.entYourWeek(range).toUpperCase(),
                          style: MuType.overline.copyWith(color: c.textSecondary),
                        ),
                        const SizedBox(height: MuSpace.s3),
                        Row(
                          children: [
                            Icon(
                              PhosphorIcons.fire(PhosphorIconsStyle.fill),
                              size: _fire,
                              color: c.accent,
                            ),
                            const SizedBox(width: MuSpace.s2),
                            Text('$streak', style: MuType.numXl.copyWith(color: c.text)),
                            const SizedBox(width: MuSpace.s2),
                            Flexible(
                              child: Text(
                                l10n.entWeeksInARow(streak),
                                style: MuType.labelL.copyWith(color: c.text),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: '$done', style: MuType.numL),
                            TextSpan(text: '/${progress.weeklyGoal}', style: MuType.numS),
                          ],
                        ),
                        style: TextStyle(color: c.text),
                      ),
                      Text(
                        l10n.entSessionsUnit,
                        style: MuType.caption.copyWith(color: c.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: MuSpace.s4),
              Semantics(
                label: l10n.entWeekDays,
                child: Row(
                  children: [
                    for (var i = 0; i < 7; i++) ...[
                      if (i > 0) const SizedBox(width: MuSpace.s1),
                      Expanded(
                        child: WeekDayCell(
                          day: start.add(Duration(days: i)),
                          today: start.add(Duration(days: i)).weekday == now.weekday,
                          done: days.contains(i + 1),
                          lesson: start.add(Duration(days: i)).weekday == now.weekday
                              ? todayLesson
                              : null,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: MuSpace.s4),
              Text(
                validated
                    ? l10n.entWeekDone(streak)
                    : todayLesson != null
                    ? l10n.entDoTodayToValidate(todayLesson!, streak + 1)
                    : l10n.entSessionsLeft(progress.weeklyGoal - done),
                style: MuType.body.copyWith(color: c.textSecondary),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A joined program: the 72 ring, « Semaine 2 sur 4 · 42 % », coach and pace, the Premium badge.
class _MyProgramCard extends StatelessWidget {
  const _MyProgramCard({required this.program, required this.progress, required this.onTap});

  final TrainingProgram program;
  final TrainingProgress progress;
  final VoidCallback onTap;

  static const double _ring = 72;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final p = program;
    final done = progress.doneCount(p.id);
    final total = p.card.sessions;
    final percent = total == 0 ? 0 : (done / total * 100).round();
    final next = progress.nextLesson(p);
    final week = next == null ? p.card.weeks : p.weekOf(next.index);
    final eyebrow = next == null
        ? l10n.termine
        : l10n.entWeekOf(week, p.card.weeks, '$percent %');
    return MuCardSurface(
      onTap: onTap,
      semanticLabel: '${p.title}, $eyebrow, ${l10n.entSessionsOf(done, total)}',
      child: Row(
        children: [
          MuProgressRing(
            value: done.toDouble(),
            max: total.toDouble(),
            size: _ring,
            tone: next == null ? MuTone.success : MuTone.primary,
            label: l10n.entProgramLabel(p.title),
          ),
          const SizedBox(width: MuSpace.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(eyebrow.toUpperCase(), style: MuType.overline.copyWith(color: c.textSecondary)),
                const SizedBox(height: MuSpace.s1),
                Text(p.title, style: MuType.labelL.copyWith(color: c.text)),
                const SizedBox(height: MuSpace.s1 / 2),
                Text(
                  l10n.entCoachPace(p.card.coach.label, p.perWeek),
                  style: MuType.caption.copyWith(color: c.textSecondary),
                ),
                if (p.card.premium) ...[
                  const SizedBox(height: MuSpace.s2),
                  const MuPremiumBadge(),
                ],
              ],
            ),
          ),
          const SizedBox(width: MuSpace.s2),
          MuDirectionalIcon(PhosphorIcons.caretRight(), size: MuSize.iconS, color: c.textSecondary),
        ],
      ),
    );
  }
}

/// The AI weekly plan suggestion (« Crée ton plan de la semaine »), Premium.
class _PlanSuggestion extends ConsumerWidget {
  const _PlanSuggestion({required this.program, required this.subscription});

  final TrainingProgram program;
  final Subscription? subscription;

  static const double _crown = 14;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final s = subscription;
    final premiumLine = s != null && s.premium
        ? l10n.entInPremiumTrialUntil(formatDay(s.trialEnds))
        : l10n.entIncludedInPremium;
    void hide() => ref.read(trainingProgressProvider.notifier).hidePlanCard();
    return MuAiSuggestionCard(
      context: l10n.entTrainingPlan,
      title: l10n.entCreateWeekPlan,
      reason: l10n.entPlanReason,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.entPlanPitch(program.shortTitle),
            style: MuType.bodyL.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: MuSpace.s2),
          Row(
            children: [
              Icon(PhosphorIcons.crownSimple(PhosphorIconsStyle.fill), size: _crown, color: c.text),
              const SizedBox(width: MuSpace.s1),
              Expanded(
                child: Text(premiumLine, style: MuType.caption.copyWith(color: c.textSecondary)),
              ),
            ],
          ),
        ],
      ),
      primary: MuAction(l10n.entCreateMyPlan, () => context.push(TrainingRoutes.planGoals)),
      primaryIcon: PhosphorIcons.arrowRight(),
      secondary: MuAction(l10n.entLater, hide),
      secondaryDismisses: true,
      onDismiss: hide,
      onFeedback: (_) {},
    );
  }
}

/// « Analyse ta bandeja »: the entry of the AI video analysis (ENT-08) — or, while one runs in
/// the background (« Me prévenir »), its progress, then « prête » with a link to the result.
class _VideoCard extends ConsumerWidget {
  const _VideoCard();

  static const double _thumbWidth = 100;
  static const double _thumbHeight = 72;
  static const double _disc = 32;
  static const double _discIcon = 16;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final a = ref.watch(videoAnalysisProvider);
    final text = a.done
        ? l10n.entAnalysisReady(a.result!.tips.length)
        : a.uploading
        ? l10n.entAnalysisUploading
        : a.analysing
        ? l10n.entAnalysisRunning(a.step + 1, VideoAnalyst.stepCount)
        : l10n.entAnalyseYourBandejaText;
    return MuCardSurface(
      onTap: () => context.push(a.done ? TrainingRoutes.videoResult : TrainingRoutes.video),
      padding: const EdgeInsets.all(MuSpace.s3),
      semanticLabel: '${l10n.entAnalyseYourBandeja}. $text',
      child: Row(
        children: [
          ClipRRect(
            borderRadius: MuRadius.smAll,
            child: SizedBox(
              width: _thumbWidth,
              height: _thumbHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const MuCourtArt(sport: MuSport.padel),
                  Center(
                    child: Container(
                      width: _disc,
                      height: _disc,
                      decoration: const BoxDecoration(
                        // A media overlay: the same white disc in both themes.
                        color: MuPalette.white,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        PhosphorIcons.videoCamera(PhosphorIconsStyle.fill),
                        size: _discIcon,
                        color: MuPalette.ink900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: MuSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: MuSpace.s2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(l10n.entAnalyseYourBandeja, style: MuType.labelL.copyWith(color: c.text)),
                    MuAiLabel(size: MuAiLabelSize.s),
                  ],
                ),
                const SizedBox(height: MuSpace.s1),
                Text(
                  text,
                  style: MuType.caption.copyWith(
                    color: a.done ? c.successText : c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: MuSpace.s2),
          MuDirectionalIcon(PhosphorIcons.caretRight(), size: MuSize.iconS, color: c.textSecondary),
        ],
      ),
    );
  }
}
