import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/clock.dart';
import '../../../core/format.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/widgets/coming_soon.dart';
import '../../training/data/training_models.dart';
import '../../training/data/training_story.dart';
import '../coach_routes.dart';
import '../controllers/coach_providers.dart';
import '../data/coach_models.dart';
import '../data/coach_story.dart';

/// COA-10 · Détail élève: who they are, their program (progress, week, streak, next session),
/// the video waiting for feedback with the AI's reading, their training minutes, their sessions,
/// their notes and the coach's feedback.
class StudentScreen extends ConsumerWidget {
  const StudentScreen({super.key, required this.studentId});

  final String studentId;

  static const double _ring = 120;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final now = ref.watch(clockProvider)();
    final s = ref.watch(coachStudentProvider(studentId));
    final students = ref.watch(coachStudentsProvider);
    final feedback = ref.watch(coachFeedbackProvider(studentId)).value;
    void back() => context.canPop() ? context.pop() : context.go(CoachRoutes.students);

    if (s == null) {
      return Scaffold(
        backgroundColor: c.bg,
        body: Column(
          children: [
            MuTopAppBar.compact(title: l10n.coaStudent, onBack: back),
            Expanded(
              child: students.isLoading
                  ? const Center(child: MuSpinner())
                  : Center(
                      child: MuEmptyState(
                        title: l10n.coaStudentGone,
                        description: l10n.coaStudentGoneText,
                        illustration: MuEmptyIllustration.results,
                      ),
                    ),
            ),
          ],
        ),
      );
    }

    final program = TrainingStory.programs.where((p) => p.id == s.programId).firstOrNull;
    final yassine = s.id == CoachStory.yassine.id;
    final since = yassine
        ? TrainingStory.bandejaJoined
        : s.lastActivity.subtract(Duration(days: s.done * 2 + 3));
    final week = program == null ? 1 : program.weekOf(s.current.clamp(1, program.lessons.length));
    final thisWeek = yassine ? 2 : (s.activeThisWeek ? 1 : 0);
    final seed = s.id.codeUnits.fold(0, (a, b) => a + b);
    final streak = yassine ? 6 : 1 + seed % 5;
    final weeks = [for (var i = 5; i >= 0; i--) _weekStart(now).subtract(Duration(days: 7 * i))];
    final next = program?.lessons.where((l) => l.index == s.current).firstOrNull;

    Widget heading(String text, {String? aside}) => Padding(
      padding: const EdgeInsets.only(bottom: MuSpace.s3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Semantics(header: true, child: Text(text, style: MuType.h3.copyWith(color: c.text))),
          ),
          if (aside != null) Text(aside, style: MuType.caption.copyWith(color: c.textSecondary)),
        ],
      ),
    );

    Widget stat(String label, Widget value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: MuSpace.s2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: MuType.caption.copyWith(color: c.textSecondary))),
          value,
        ],
      ),
    );

    return Scaffold(
      backgroundColor: c.bg,
      body: ListView(
        padding: const EdgeInsets.only(bottom: MuSpace.s8),
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: MuSpace.s1, vertical: MuSpace.s2),
              child: Row(
                children: [
                  MuIconButton(
                    icon: PhosphorIcons.arrowLeft(),
                    label: l10n.coaBackToStudents,
                    size: MuIconButtonSize.l,
                    onPressed: back,
                  ),
                  const Spacer(),
                  MuIconButton(
                    icon: PhosphorIcons.dotsThreeVertical(),
                    label: l10n.coaMoreActions,
                    size: MuIconButtonSize.l,
                    onPressed: () => showComingSoon(context),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    MuAvatar(name: s.name, size: MuAvatarSize.l, level: s.level),
                    const SizedBox(width: MuSpace.s4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            header: true,
                            child: Text(s.name, style: MuType.h1.copyWith(color: c.text)),
                          ),
                          Text(
                            [?s.handle, s.zone].join(' · '),
                            style: MuType.caption.copyWith(color: c.textSecondary),
                          ),
                          const SizedBox(height: MuSpace.s2),
                          Wrap(
                            spacing: MuSpace.s2,
                            runSpacing: MuSpace.s2,
                            children: [
                              if (program != null)
                                MuChip(
                                  kind: MuChipKind.sport,
                                  sport: program.sport,
                                  label: s.side == null ? program.sport.label : '${program.sport.label} · ${s.side}',
                                  size: MuChipSize.s,
                                ),
                              MuChip.level(s.level, size: MuChipSize.s),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: MuSpace.s4),
                Row(
                  children: [
                    Expanded(
                      child: MuButton.secondary(
                        label: l10n.coaMessage,
                        leading: PhosphorIcons.chatCircleDots(),
                        fullWidth: true,
                        onPressed: () => showComingSoon(context),
                      ),
                    ),
                    if (s.videoAt != null) ...[
                      const SizedBox(width: MuSpace.s3),
                      Expanded(
                        child: MuButton.primary(
                          label: l10n.coaGiveFeedback,
                          leading: PhosphorIcons.notePencil(),
                          fullWidth: true,
                          onPressed: () => context.push(CoachRoutes.feedback(s.id)),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: MuSpace.s8),
                heading(s.programTitle, aside: l10n.coaSince(formatDay(since))),
                MuCardSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          MuProgressRing(
                            value: s.done.toDouble(),
                            max: s.total.toDouble(),
                            size: _ring,
                            unit: l10n.entSessionsUnit,
                            tone: s.finished ? MuTone.success : MuTone.primary,
                            label: l10n.coaProgramOf(s.programTitle, s.name),
                          ),
                          const SizedBox(width: MuSpace.s4),
                          Expanded(
                            child: Column(
                              children: [
                                stat(l10n.coaProgress, Text('${s.percent} %', style: MuType.numS.copyWith(color: c.text))),
                                Divider(height: 1, thickness: 1, color: c.border),
                                stat(
                                  l10n.coaWeekLabel,
                                  Text(l10n.coaWeekOutOf(week, program?.card.weeks ?? 4), style: MuType.labelS.copyWith(color: c.text)),
                                ),
                                Divider(height: 1, thickness: 1, color: c.border),
                                stat(
                                  l10n.coaThisWeek,
                                  Text(
                                    l10n.coaThisWeekValue(thisWeek, program?.perWeek ?? 3),
                                    style: MuType.labelS.copyWith(color: c.text),
                                  ),
                                ),
                                Divider(height: 1, thickness: 1, color: c.border),
                                stat(l10n.coaStreak, Text(l10n.coaStreakWeeks(streak), style: MuType.labelS.copyWith(color: c.text))),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (next != null && !s.finished) ...[
                        const SizedBox(height: MuSpace.s3),
                        _NextSession(
                          lesson: next,
                          today: s.activeThisWeek,
                        ),
                      ],
                    ],
                  ),
                ),
                if (s.videoAt != null) ...[
                  const SizedBox(height: MuSpace.s8),
                  heading(l10n.coaVideoToComment),
                  _VideoCard(student: s, feedbackSent: feedback != null),
                ],
                const SizedBox(height: MuSpace.s8),
                MuCardSurface(
                  child: MuBarChart(
                    title: l10n.coaTrainingMinutes,
                    subtitle: l10n.coaTrainingMinutesDetail,
                    categories: [for (final d in weeks) '${d.day} ${formatMonth(d)}'],
                    tooltipCategories: [for (final d in weeks) l10n.coaWeekOf(formatDay(d))],
                    series: [
                      MuBarSeries(
                        label: l10n.coaMinutes,
                        data: yassine
                            ? CoachStory.yassineMinutes
                            : [
                                for (var i = 0; i < 6; i++)
                                  (20 + (seed * (i + 3)) % 50).toDouble(),
                              ],
                        color: c.chart1,
                      ),
                    ],
                    format: (v) => l10n.entMinutes(v.round()),
                    compact: (v) => '${v.round()}',
                    categoryLabel: l10n.coaWeekLabel,
                    height: 200,
                  ),
                ),
                if (program != null) ...[
                  const SizedBox(height: MuSpace.s8),
                  heading(
                    l10n.coaSessionsTitle,
                    aside: l10n.coaSessionsDone(s.done, s.total),
                  ),
                  for (final l in _window(program, s)) ...[
                    MuLessonCard(
                      lesson: l.toMu(program.sport),
                      variant: MuCardVariant.compact,
                      status: l.index <= s.done
                          ? MuLessonStatus.done
                          : l.index == s.current && s.activeThisWeek
                          ? MuLessonStatus.current
                          : MuLessonStatus.available,
                    ),
                    const SizedBox(height: MuSpace.s2),
                  ],
                ],
                if (yassine || feedback != null) ...[
                  const SizedBox(height: MuSpace.s6),
                  heading(l10n.coaNotesAndFeedback),
                  if (feedback != null)
                    _Note(
                      note: StudentNote(
                        fromCoach: true,
                        session: CoachStory.videoSession,
                        date: feedback.sentAt ?? now,
                        text: feedback.message.replaceAll('**', ''),
                      ),
                      who: s.name,
                    ),
                  if (yassine)
                    for (final n in CoachStory.yassineNotes) _Note(note: n, who: s.name),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static DateTime _weekStart(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  /// The two sessions before the next one, the next one and the one after.
  static List<TrainingLesson> _window(TrainingProgram p, CoachStudent s) {
    final from = (s.current - 2).clamp(1, p.lessons.length);
    final to = (s.current + 1).clamp(1, p.lessons.length);
    return [for (final l in p.lessons) if (l.index >= from && l.index <= to) l];
  }
}

/// « ▶ Séance 5 · Bandeja croisée — À faire aujourd’hui · 4 exercices ».
class _NextSession extends StatelessWidget {
  const _NextSession({required this.lesson, required this.today});

  final TrainingLesson lesson;
  final bool today;

  static const double _disc = 32;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Container(
      padding: const EdgeInsets.all(MuSpace.s3),
      decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: MuRadius.smAll),
      child: Row(
        children: [
          Container(
            width: _disc,
            height: _disc,
            decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(PhosphorIcons.play(PhosphorIconsStyle.fill), size: MuSize.iconXs, color: c.onAccent),
          ),
          const SizedBox(width: MuSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.entLessonLabel(lesson.index, lesson.title),
                  style: MuType.label.copyWith(color: c.text),
                ),
                Text(
                  '${today ? l10n.entToday : l10n.entNextSession} · ${l10n.entDrills(lesson.exercises.length)}',
                  style: MuType.caption.copyWith(color: c.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The video waiting for feedback: thumbnail, when it was sent, its state, the AI's reading,
/// « Commenter la vidéo ».
class _VideoCard extends StatelessWidget {
  const _VideoCard({required this.student, required this.feedbackSent});

  final CoachStudent student;
  final bool feedbackSent;

  static const double _thumbW = 112;
  static const double _thumbH = 72;
  static const double _disc = 32;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final s = student;
    final clip = formatClock(CoachStory.videoLength);
    final first = s.name.split(' ').first;
    return MuCardSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                button: true,
                label: l10n.coaPlayClip(CoachStory.videoLength.inSeconds),
                excludeSemantics: true,
                child: InkWell(
                  onTap: () => context.push(CoachRoutes.feedback(s.id)),
                  child: ClipRRect(
                    borderRadius: MuRadius.smAll,
                    child: SizedBox(
                      width: _thumbW,
                      height: _thumbH,
                      child: MuCourtArt(
                        sport: MuSport.padel,
                        child: Stack(
                          children: [
                            Center(
                              child: Container(
                                width: _disc,
                                height: _disc,
                                decoration: const BoxDecoration(color: MuPalette.white, shape: BoxShape.circle),
                                alignment: Alignment.center,
                                child: Icon(
                                  PhosphorIcons.play(PhosphorIconsStyle.fill),
                                  size: MuSize.iconXs,
                                  color: MuPalette.ink900,
                                ),
                              ),
                            ),
                            PositionedDirectional(
                              end: MuSpace.s1,
                              bottom: MuSpace.s1 / 2,
                              child: Text(clip, style: MuType.numXs.copyWith(color: MuPalette.white)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: MuSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${l10n.entMoveBandeja} · $clip', style: MuType.labelL.copyWith(color: c.text)),
                    Text(
                      l10n.coaVideoSentOn(formatDateTime(s.videoAt!), CoachStory.videoSession),
                      style: MuType.caption.copyWith(color: c.textSecondary),
                    ),
                    const SizedBox(height: MuSpace.s1),
                    feedbackSent
                        ? MuStatusBadge(status: MuStatus.confirmed, label: l10n.coaFeedbackSent, size: MuBadgeSize.s)
                        : MuStatusBadge(status: MuStatus.pending, label: l10n.coaAwaitsFeedback, size: MuBadgeSize.s),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: MuSpace.s3),
          Container(
            padding: const EdgeInsets.all(MuSpace.s3),
            decoration: BoxDecoration(color: c.aiSoft, borderRadius: MuRadius.smAll),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    MuAiLabel(size: MuAiLabelSize.s, onAiSurface: true),
                    const SizedBox(width: MuSpace.s2),
                    Expanded(
                      child: Text(
                        l10n.coaAiVideoOf(first, 3),
                        style: MuType.labelS.copyWith(color: c.text),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: MuSpace.s1),
                Text(CoachStory.yassineAi, style: MuType.caption.copyWith(color: c.text)),
              ],
            ),
          ),
          const SizedBox(height: MuSpace.s3),
          MuButton.primary(
            label: feedbackSent ? l10n.coaSeeMyFeedback : l10n.coaCommentVideo,
            leading: PhosphorIcons.videoCamera(),
            size: MuButtonSize.l,
            fullWidth: true,
            onPressed: () => context.push(CoachRoutes.feedback(s.id)),
          ),
        ],
      ),
    );
  }
}

/// A note of the student or a feedback of the coach.
class _Note extends StatelessWidget {
  const _Note({required this.note, required this.who});

  final StudentNote note;
  final String who;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final n = note;
    return Padding(
      padding: const EdgeInsets.only(bottom: MuSpace.s3),
      child: MuCardSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  n.fromCoach ? PhosphorIcons.notePencil() : PhosphorIcons.chatCenteredText(),
                  size: MuSize.iconXs,
                  color: c.textSecondary,
                ),
                const SizedBox(width: MuSpace.s1),
                Expanded(
                  child: Text(
                    n.fromCoach
                        ? l10n.coaYourFeedbackOn(n.session, formatDay(n.date))
                        : l10n.coaNoteOf(who.split(' ').first, n.session, formatDay(n.date)),
                    style: MuType.caption.copyWith(color: c.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: MuSpace.s2),
            Text('« ${n.text} »', style: MuType.body.copyWith(color: c.text)),
          ],
        ),
      ),
    );
  }
}
