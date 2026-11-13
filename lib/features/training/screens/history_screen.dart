import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/clock.dart';
import '../../../core/format.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../controllers/training_providers.dart';
import '../data/training_models.dart';
import '../training_routes.dart';
import '../widgets/reminder_widgets.dart';
import '../widgets/training_widgets.dart';

/// « Historique »: what the player trained (totals, then the sessions week by week, latest
/// first) and the « Rappels de séance ». A session reopens its summary (ENT-05).
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  /// The program to show (null: all).
  String? _program;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final now = ref.watch(clockProvider)();
    final progress = ref.watch(trainingProgressProvider);
    final programs = ref.watch(programsProvider);
    void back() => context.canPop() ? context.pop() : context.go(TrainingRoutes.root);

    Widget body;
    if ((progress.hasError && !progress.hasValue) || (programs.hasError && !programs.hasValue)) {
      body = Padding(
        padding: const EdgeInsets.all(MuSpace.s4),
        child: TrainingRetry(
          onRetry: () => ref
            ..invalidate(trainingProgressProvider)
            ..invalidate(programsProvider),
        ),
      );
    } else if (!progress.hasValue || !programs.hasValue) {
      body = const Center(child: MuSpinner());
    } else {
      final p = progress.value!;
      final byId = {for (final x in programs.value!) x.id: x};
      final all = [
        for (final r in p.results)
          if (byId.containsKey(r.programId)) r,
      ]..sort((a, b) => b.doneAt.compareTo(a.doneAt));
      final trained = {for (final r in all) r.programId};
      final shown = [
        for (final r in all)
          if (_program == null || r.programId == _program) r,
      ];
      final weeks = <DateTime, List<LessonResult>>{};
      for (final r in shown) {
        weeks.putIfAbsent(TrainingProgress.weekStart(r.doneAt), () => []).add(r);
      }

      body = ListView(
        padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s2, MuSpace.s4, MuSpace.s8),
        children: [
          _Totals(sessions: all.length, minutes: p.totalMinutes, streak: p.streak(now)),
          const SizedBox(height: MuSpace.s3),
          ReminderCard(reminder: p.reminder),
          const SizedBox(height: MuSpace.s5),
          if (all.isEmpty)
            MuEmptyState(
              title: l10n.entNoHistory,
              description: l10n.entNoHistoryHelp,
              compact: true,
              actions: [
                MuButton.primary(
                  label: l10n.entSeePrograms,
                  onPressed: () => context.go(TrainingRoutes.programs),
                ),
              ],
            )
          else ...[
            if (trained.length > 1) ...[
              Wrap(
                spacing: MuSpace.s2,
                runSpacing: MuSpace.s2,
                children: [
                  MuChip(
                    kind: MuChipKind.choice,
                    label: l10n.coaAll,
                    selected: _program == null,
                    onSelected: (_) => setState(() => _program = null),
                  ),
                  for (final id in trained)
                    MuChip(
                      kind: MuChipKind.choice,
                      label: byId[id]!.shortTitle,
                      selected: _program == id,
                      onSelected: (_) => setState(() => _program = id),
                    ),
                ],
              ),
              const SizedBox(height: MuSpace.s4),
            ],
            for (final MapEntry(key: start, value: list) in weeks.entries) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      l10n.entHistoryWeek('${start.day} ${formatMonth(start)}').toUpperCase(),
                      style: MuType.overline.copyWith(color: c.textSecondary),
                    ),
                  ),
                  Text(
                    l10n.entWeekTotal(
                      list.length,
                      l10n.entMinutesTotal(list.fold<int>(0, (a, r) => a + r.minutes)),
                    ),
                    style: MuType.caption.copyWith(color: c.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: MuSpace.s2),
              for (final r in list) ...[
                _SessionTile(result: r, program: byId[r.programId]!),
                const SizedBox(height: MuSpace.s2),
              ],
              const SizedBox(height: MuSpace.s3),
            ],
          ],
        ],
      );
    }

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          MuTopAppBar.compact(title: l10n.entHistory, onBack: back),
          Expanded(child: body),
        ],
      ),
    );
  }
}

/// « 4 séances · 1 h 36 · 6 semaines de suite », on the dark emphasis card.
class _Totals extends StatelessWidget {
  const _Totals({required this.sessions, required this.minutes, required this.streak});

  final int sessions;
  final int minutes;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final time = minutes < 60
        ? l10n.entMinutesTotal(minutes)
        : l10n.entHoursTotal(minutes ~/ 60, (minutes % 60).toString().padLeft(2, '0'));
    return TrainingDarkCard(
      semanticLabel: l10n.entHistoryTotals(sessions, time, streak),
      child: Builder(
        builder: (context) {
          final c = context.mu;
          Widget stat(String value, String unit) => Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: MuType.numL.copyWith(color: c.text)),
                Text(unit, style: MuType.caption.copyWith(color: c.textSecondary)),
              ],
            ),
          );
          return ExcludeSemantics(
            child: Row(
              children: [
                stat('$sessions', l10n.entSessionsDone(sessions)),
                stat(time, l10n.entTrainedTime),
                stat('$streak', l10n.entWeeksInARow(streak)),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// One session done: sport, « Séance 4 · Monter au filet », when, how long, the feeling.
class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.result, required this.program});

  final LessonResult result;
  final TrainingProgram program;

  static const double _disc = 40;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final r = result;
    final lesson = program.lessons.where((l) => l.index == r.index).firstOrNull;
    final feeling = switch (r.feeling) {
      LessonFeeling.easy => l10n.entTooEasy,
      LessonFeeling.right => l10n.entJustRight,
      LessonFeeling.hard => l10n.entTooHard,
      null => null,
    };
    final meta = [
      formatDateTime(r.doneAt),
      l10n.entMinutesTotal(r.minutes),
      if (r.reps != null && r.target != null) l10n.entHistoryReps(r.reps!, r.target!),
      ?feeling,
    ].join(' · ');
    return MuCardSurface(
      onTap: () => context.push(TrainingRoutes.lessonDone(program.id, r.index)),
      child: Row(
        children: [
          Container(
            width: _disc,
            height: _disc,
            decoration: BoxDecoration(color: c.surfaceMuted, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: MuSportIcon(program.sport, size: MuSize.iconS),
          ),
          const SizedBox(width: MuSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.entLessonLabel(r.index, lesson?.title ?? program.title),
                  style: MuType.label.copyWith(color: c.text),
                ),
                Text(program.title, style: MuType.caption.copyWith(color: c.textSecondary)),
                const SizedBox(height: MuSpace.s1),
                Text(meta, style: MuType.caption.copyWith(color: c.textSecondary)),
              ],
            ),
          ),
          Icon(PhosphorIcons.caretRight(), size: MuSize.iconS, color: c.textSecondary),
        ],
      ),
    );
  }
}
