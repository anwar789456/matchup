import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/clock.dart';
import '../../../core/format.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/flow_scaffold.dart';
import '../controllers/training_providers.dart';
import '../data/training_models.dart';
import '../data/training_story.dart';
import '../training_routes.dart';
import '../widgets/training_widgets.dart';

/// ENT-05 · Séance terminée: the session in numbers, the week validated (or what is left), the
/// program's progress and next session, and « Comment c’était ? » to adapt the next one.
class LessonDoneScreen extends ConsumerWidget {
  const LessonDoneScreen({super.key, required this.programId, required this.index});

  final String programId;
  final int index;

  // ENT-05: the success disc is 96 with an 8px ring.
  static const double _disc = 96;
  static const double _ring = MuSpace.s2;
  static const double _check = 40;
  static const double _fire = 32;
  static const double _weekCheck = 24;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final now = ref.watch(clockProvider)();
    final program = ref.watch(programProvider(programId));
    final progress = ref.watch(trainingProgressProvider).value;
    final result = progress?.result(programId, index);
    void close() => context.go(TrainingRoutes.root);

    final lessonOrNull = program?.lessons.where((l) => l.index == index).firstOrNull;
    final loading =
        ref.watch(programsProvider).isLoading || ref.watch(trainingProgressProvider).isLoading;
    if (program == null || progress == null || result == null || lessonOrNull == null) {
      // Still loading; or a stale link: a session that does not exist or is not finished.
      return Scaffold(
        backgroundColor: c.surface,
        body: Column(
          children: [
            MuTopAppBar.compact(title: l10n.entSession, onBack: close),
            Expanded(
              child: loading
                  ? const Center(child: MuSpinner())
                  : Center(
                      child: MuEmptyState(
                        title: lessonOrNull == null
                            ? l10n.entProgramGone
                            : l10n.entLessonNotDone(index),
                        description: lessonOrNull == null
                            ? l10n.entProgramGoneText
                            : l10n.entLessonNotDoneText,
                        illustration: MuEmptyIllustration.programs,
                        actions: [
                          if (lessonOrNull != null && (progress?.isEnrolled(programId) ?? false))
                            MuButton.primary(
                              label: l10n.entStartSession,
                              onPressed: () =>
                                  context.pushReplacement(TrainingRoutes.lesson(programId, index)),
                            )
                          else
                            MuButton.primary(label: l10n.entBackToTraining, onPressed: close),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      );
    }

    final lesson = lessonOrNull;
    final coach = TrainingStory.coach(program.coachId);
    final firstName = coach.name.split(' ').first;
    final done = progress.doneCount(program.id);
    final total = program.card.sessions;
    final percent = (done / total * 100).round();
    final next = progress.nextLesson(program);
    final weekDone = progress.doneThisWeek(now);
    final validated = progress.weekValidated(now);
    final streak = progress.streak(now);
    final key = lesson.exercises.where((e) => e.counted).firstOrNull;
    final keyWords = (key?.counterLabel ?? '').split(' ');
    // The next session: next Monday once the week is validated, else the next day.
    final nextDay = validated
        ? TrainingProgress.weekStart(now).add(const Duration(days: 7))
        : DateTime(now.year, now.month, now.day + 1);

    Widget stat(String label, Widget value, String caption) => Expanded(
      child: Padding(
        padding: const EdgeInsets.all(MuSpace.s3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: MuType.overline.copyWith(color: c.textSecondary)),
            const SizedBox(height: MuSpace.s1),
            value,
            Text(caption, style: MuType.caption.copyWith(color: c.textSecondary)),
          ],
        ),
      ),
    );

    Widget fraction(int a, int b) => Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '$a', style: MuType.numXl),
          TextSpan(text: '/$b', style: MuType.numS.copyWith(color: c.textSecondary)),
        ],
      ),
      style: TextStyle(color: c.text),
    );

    return Scaffold(
      backgroundColor: c.surface,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Padding(
                padding: const EdgeInsets.all(MuSpace.s2),
                child: MuIconButton(
                  icon: PhosphorIcons.x(),
                  label: l10n.fermer,
                  size: MuIconButtonSize.l,
                  onPressed: close,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(MuSpace.s4, 0, MuSpace.s4, MuSpace.s6),
              children: [
                Semantics(
                  liveRegion: true,
                  label: l10n.entLessonDoneTitle(index),
                  child: Column(
                    children: [
                      Container(
                        width: _disc + _ring * 2,
                        height: _disc + _ring * 2,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: c.accent, width: _ring / 4),
                        ),
                        alignment: Alignment.center,
                        child: Container(
                          width: _disc,
                          height: _disc,
                          decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: Icon(
                            PhosphorIcons.check(PhosphorIconsStyle.bold),
                            size: _check,
                            color: c.onAccent,
                          ),
                        ),
                      ),
                      const SizedBox(height: MuSpace.s4),
                      Text(
                        l10n.entLessonDoneTitle(index),
                        textAlign: TextAlign.center,
                        style: MuType.h1.copyWith(color: c.text),
                      ),
                      const SizedBox(height: MuSpace.s1),
                      Text(
                        l10n.entProgramByCoach(lesson.title, program.title),
                        textAlign: TextAlign.center,
                        style: MuType.bodyL.copyWith(color: c.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MuSpace.s5),
                Semantics(
                  container: true,
                  label: l10n.entSessionInNumbers,
                  child: Container(
                    decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: MuRadius.mdAll),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          stat(
                            l10n.entDuration,
                            Text(
                              l10n.entMinutes(result.minutes),
                              style: MuType.numXl.copyWith(color: c.text),
                            ),
                            l10n.entPlanned(lesson.minutes),
                          ),
                          VerticalDivider(width: 1, thickness: 1, color: c.border),
                          if (result.reps != null && result.target != null) ...[
                            stat(
                              keyWords.first,
                              fraction(result.reps!, result.target!),
                              keyWords.skip(1).join(' '),
                            ),
                            VerticalDivider(width: 1, thickness: 1, color: c.border),
                          ],
                          stat(
                            l10n.entExercises,
                            fraction(result.drillsDone, result.drillsTotal),
                            l10n.entDoneWord(result.drillsDone),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: MuSpace.s4),
                TrainingDarkCard(
                  semanticLabel: validated
                      ? '${l10n.entWeekValidated(weekDone, progress.weeklyGoal)}. ${l10n.entStreakNow(streak)}'
                      : '${l10n.entWeekSoFar(weekDone, progress.weeklyGoal)}. ${l10n.entSessionsLeft(progress.weeklyGoal - weekDone)}',
                  child: Builder(
                    builder: (context) {
                      final n = context.mu;
                      return Row(
                        children: [
                          Icon(PhosphorIcons.fire(PhosphorIconsStyle.fill), size: _fire, color: n.accent),
                          const SizedBox(width: MuSpace.s3),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  validated
                                      ? l10n.entWeekValidated(weekDone, progress.weeklyGoal)
                                      : l10n.entWeekSoFar(weekDone, progress.weeklyGoal),
                                  style: MuType.labelL.copyWith(color: n.text),
                                ),
                                const SizedBox(height: MuSpace.s1 / 2),
                                Text(
                                  validated
                                      ? l10n.entStreakNow(streak)
                                      : l10n.entSessionsLeft(progress.weeklyGoal - weekDone),
                                  style: MuType.caption.copyWith(color: n.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: MuSpace.s2),
                          for (var i = 0; i < progress.weeklyGoal; i++)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(start: MuSpace.s1),
                              child: Container(
                                width: _weekCheck,
                                height: _weekCheck,
                                decoration: BoxDecoration(
                                  color: i < weekDone ? n.accent : null,
                                  border: i < weekDone ? null : Border.all(color: n.border),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: i < weekDone
                                    ? Icon(
                                        PhosphorIcons.check(PhosphorIconsStyle.bold),
                                        size: MuSize.iconXs,
                                        color: n.onAccent,
                                      )
                                    : null,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: MuSpace.s4),
                MuCardSurface(
                  onTap: () => context.push(TrainingRoutes.program(program.id)),
                  semanticLabel: l10n.entProgramLabel(program.title),
                  child: Row(
                    children: [
                      MuProgressRing(
                        value: done.toDouble(),
                        max: total.toDouble(),
                        size: 48,
                        tone: next == null ? MuTone.success : MuTone.primary,
                        label: l10n.entProgramLabel(program.title),
                      ),
                      const SizedBox(width: MuSpace.s3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${l10n.entSessionsOf(done, total)} · $percent %',
                              style: MuType.label.copyWith(color: c.text),
                            ),
                            const SizedBox(height: MuSpace.s1 / 2),
                            Text(
                              next == null
                                  ? l10n.entProgramFinished(total)
                                  : l10n.entNextOn(next.index, next.title, formatDay(nextDay)),
                              style: MuType.caption.copyWith(color: c.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      MuDirectionalIcon(
                        PhosphorIcons.caretRight(),
                        size: MuSize.iconS,
                        color: c.textSecondary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MuSpace.s5),
                Semantics(
                  header: true,
                  child: Text(l10n.entHowWasIt, style: MuType.h3.copyWith(color: c.text)),
                ),
                const SizedBox(height: MuSpace.s1),
                Text(
                  next == null
                      ? l10n.entFeelingCoachSees(firstName)
                      : l10n.entFeelingAdapts(next.index, firstName),
                  style: MuType.caption.copyWith(color: c.textSecondary),
                ),
                const SizedBox(height: MuSpace.s3),
                Semantics(
                  container: true,
                  label: l10n.entDifficulty,
                  child: Wrap(
                    spacing: MuSpace.s2,
                    runSpacing: MuSpace.s2,
                    children: [
                      for (final f in LessonFeeling.values)
                        MuChip(
                          kind: MuChipKind.choice,
                          label: switch (f) {
                            LessonFeeling.easy => l10n.entTooEasy,
                            LessonFeeling.right => l10n.entJustRight,
                            LessonFeeling.hard => l10n.entTooHard,
                          },
                          selected: result.feeling == f,
                          onSelected: (_) => ref
                              .read(trainingProgressProvider.notifier)
                              .rateLesson(program.id, index, f),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          StickyActionBar(
            children: [
              MuButton.secondary(
                label: program.nickname == null
                    ? l10n.entAnalyseMyMoveGeneric
                    : l10n.entAnalyseMyMove(program.nickname!.toLowerCase()),
                leading: PhosphorIcons.videoCamera(),
                size: MuButtonSize.l,
                fullWidth: true,
                onPressed: () => context.push(TrainingRoutes.video),
              ),
              MuButton.primary(
                label: l10n.entBackToTraining,
                size: MuButtonSize.xl,
                fullWidth: true,
                onPressed: close,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
