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
import '../../training/data/training_story.dart';
import '../../training/training_routes.dart';
import '../coach_routes.dart';
import '../controllers/coach_providers.dart';
import '../data/coach_models.dart';
import '../data/coach_story.dart';
import '../widgets/coach_shell.dart';
import '../widgets/coach_widgets.dart';

/// COA-04 · Tableau de bord: the month's net earnings, students and enrolments, what to handle,
/// the AI suggestion, the programs and the latest review.
class CoachHomeScreen extends ConsumerWidget {
  const CoachHomeScreen({super.key});

  static const double _sectionGap = MuSpace.s8;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final now = ref.watch(clockProvider)();
    final students = ref.watch(coachStudentsProvider).value ?? const [];
    final handled = ref.watch(coachHandledProvider).value ?? const <String>{};
    final draft = ref.watch(coachDraftProvider).value;
    final todos = [for (final t in CoachStory.todos) if (!handled.contains(t.id)) t];
    final net = CoachStory.monthlyNet.last;

    Widget pad(Widget child) =>
        Padding(padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4), child: child);

    return Scaffold(
      backgroundColor: c.bg,
      body: ListView(
        padding: const EdgeInsets.only(bottom: MuSpace.s8),
        children: [
          CoachHeader(
            title: l10n.coaHello(CoachStory.firstName),
            subtitle: l10n.coaHelloLine(
              _capitalize(formatDay(now)),
              MuSport.padel.label.toLowerCase(),
              CoachStory.zone,
            ),
            actions: [
              MuIconButton(
                icon: PhosphorIcons.bell(),
                label: l10n.coaNotifications(CoachStory.notifications),
                size: MuIconButtonSize.l,
                badge: CoachStory.notifications,
                onPressed: () => showComingSoon(context),
              ),
            ],
          ),
          const SizedBox(height: MuSpace.s3),
          pad(
            MuCardSurface(
              onTap: () => context.go(CoachRoutes.earnings),
              semanticLabel: l10n.coaRevenueSemantics(formatDT(net)),
              padding: const EdgeInsets.all(MuSpace.s5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.coaRevenueMonth(deMonth(now)),
                          style: MuType.label.copyWith(color: c.textSecondary),
                        ),
                        const SizedBox(height: MuSpace.s2),
                        MoneyHero(amount: net, style: MuType.numXl),
                        const SizedBox(height: MuSpace.s1),
                        DeltaLine(
                          percent: CoachStory.revenueDelta,
                          period: l10n.coaVsLastMonthSameDay(formatMonth(DateTime(now.year, now.month - 1))),
                        ),
                      ],
                    ),
                  ),
                  MuSparkline(
                    values: [for (final v in CoachStory.monthlyNet.skip(4)) v.toDouble()],
                    tone: MuSparkTone.accent,
                    semanticLabel: l10n.coaRevenueTrend,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: MuSpace.s3),
          pad(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _Tappable(
                    onTap: () => context.go(CoachRoutes.students),
                    child: MuKpiCard(
                      label: l10n.coaStudents,
                      value: '${students.length}',
                      delta: CoachStory.studentsDelta.toDouble(),
                      deltaText: '+${CoachStory.studentsDelta}',
                      period: l10n.coaVsLastMonth(formatMonth(DateTime(now.year, now.month - 1))),
                    ),
                  ),
                ),
                const SizedBox(width: MuSpace.s3),
                Expanded(
                  child: _Tappable(
                    onTap: () => context.go(CoachRoutes.programs),
                    child: MuKpiCard(
                      label: l10n.coaActiveEnrollments,
                      value: '${CoachStory.activeEnrollments}',
                      delta: CoachStory.enrollmentsDelta.toDouble(),
                      deltaText: '+${CoachStory.enrollmentsDelta}',
                      period: l10n.coaVsLastMonth(formatMonth(DateTime(now.year, now.month - 1))),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: MuSpace.s3),
          pad(InfoLine(l10n.coaCommissionInfo)),
          if (todos.isNotEmpty) ...[
            const SizedBox(height: _sectionGap),
            CoachSection(title: l10n.coaToHandle, badge: todos.length),
            const SizedBox(height: MuSpace.s3),
            pad(
              MuCardSurface(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (final (i, t) in todos.indexed) ...[
                      if (i > 0) Divider(height: 1, thickness: 1, color: c.border),
                      _TodoRow(todo: t, now: now),
                    ],
                  ],
                ),
              ),
            ),
          ],
          if (!handled.contains('ai-suggestion')) ...[
            const SizedBox(height: _sectionGap),
            pad(
              MuAiSuggestionCard(
                context: TrainingStory.bandeja.title,
                title: l10n.coaAiTitle,
                content: l10n.coaAiContent,
                reason: l10n.coaAiReason,
                primary: MuAction(
                  l10n.coaAiSee,
                  () => context.push(TrainingRoutes.program(TrainingStory.bandeja.id)),
                ),
                primaryIcon: PhosphorIcons.sparkle(),
                secondary: MuAction(
                  l10n.coaIgnore,
                  () => ref.read(coachHandledProvider.notifier).handle('ai-suggestion'),
                ),
                secondaryDismisses: true,
                onDismiss: () => ref.read(coachHandledProvider.notifier).handle('ai-suggestion'),
                onFeedback: (_) {},
              ),
            ),
          ],
          const SizedBox(height: _sectionGap),
          CoachSection(
            title: l10n.coaMyPrograms,
            action: l10n.voirTout,
            onAction: () => context.go(CoachRoutes.programs),
          ),
          const SizedBox(height: MuSpace.s3),
          pad(
            MuCardSurface(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final (i, s) in CoachStory.programStats.indexed) ...[
                    if (i > 0) Divider(height: 1, thickness: 1, color: c.border),
                    _ProgramRow(stats: s, pattern: i > 0),
                  ],
                  if (draft != null) ...[
                    Divider(height: 1, thickness: 1, color: c.border),
                    _DraftRow(draft: draft),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: _sectionGap),
          CoachSection(
            title: l10n.coaLatestReviews,
            trailing: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '${l10n.coaAverageRating} '),
                  TextSpan(
                    text: formatLevel(CoachStory.rating),
                    style: MuType.numS.copyWith(color: c.text),
                  ),
                  TextSpan(text: ' · ${l10n.entReviews(CoachStory.reviewCount)}'),
                ],
              ),
              style: MuType.caption.copyWith(color: c.textSecondary),
            ),
          ),
          const SizedBox(height: MuSpace.s3),
          pad(ReviewCard(review: CoachStory.latestReview)),
        ],
      ),
    );
  }

  static String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _Tappable extends StatelessWidget {
  const _Tappable({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => MuFocusRing(
    borderRadius: MuRadius.mdAll,
    child: Material(
      type: MaterialType.transparency,
      child: InkWell(borderRadius: MuRadius.mdAll, onTap: onTap, child: child),
    ),
  );
}

/// One item of « À traiter »: a video to comment, a student who dropped, a review to answer.
class _TodoRow extends ConsumerWidget {
  const _TodoRow({required this.todo, required this.now});

  final CoachTodo todo;
  final DateTime now;

  Future<void> _remind(BuildContext context, WidgetRef ref) async {
    await ref.read(coachHandledProvider.notifier).handle(todo.id);
    if (context.mounted) {
      MuToast.show(context, tone: MuToastTone.success, title: l10n.coaReminderSent(todo.who));
    }
  }

  Future<void> _reply(BuildContext context, WidgetRef ref) async {
    final sent = await showReplySheet(context, who: todo.who, quote: todo.detail);
    if (sent != true || !context.mounted) return;
    await ref.read(coachHandledProvider.notifier).handle(todo.id);
    if (context.mounted) {
      MuToast.show(context, tone: MuToastTone.success, title: l10n.coaReplyPublished);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final video = ref.watch(coachStudentProvider(todo.studentId))?.videoAt;
    final (title, detail, Widget action) = switch (todo.kind) {
      TodoKind.video => (
        l10n.coaTodoVideo(elideDeName(todo.who)),
        video == null ? todo.detail : '${todo.detail} · ${formatSince(video, now)}',
        Semantics(
          button: true,
          label: l10n.coaComment,
          excludeSemantics: true,
          child: Material(
            color: c.accent,
            shape: const StadiumBorder(),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () => context.push(CoachRoutes.feedback(todo.studentId)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: MuSize.touchTarget - MuSpace.s3),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: MuSpace.s3, vertical: MuSpace.s1),
                  child: Center(
                    widthFactor: 1,
                    child: Text(l10n.coaComment, style: MuType.labelS.copyWith(color: c.onAccent)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      TodoKind.dropped => (
        l10n.coaTodoDropped(todo.who),
        todo.detail,
        MuButton.secondary(
          label: l10n.coaRemind,
          size: MuButtonSize.s,
          onPressed: () => _remind(context, ref),
        ),
      ),
      TodoKind.review => (
        l10n.coaTodoReview(todo.stars ?? 0, elideDeName(todo.who)),
        todo.detail,
        MuButton.secondary(
          label: l10n.coaReply,
          size: MuButtonSize.s,
          onPressed: () => _reply(context, ref),
        ),
      ),
    };
    return InkWell(
      onTap: todo.kind == TodoKind.video
          ? () => context.push(CoachRoutes.feedback(todo.studentId))
          : null,
      child: Padding(
        padding: const EdgeInsets.all(MuSpace.s4),
        child: Row(
          children: [
            MuAvatar(name: todo.who, size: MuAvatarSize.m, level: todo.level),
            const SizedBox(width: MuSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: MuType.label.copyWith(color: c.text)),
                  Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MuType.caption.copyWith(color: c.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: MuSpace.s2),
            action,
          ],
        ),
      ),
    );
  }
}

/// A published program: cover, active students and rating, average progress.
class _ProgramRow extends StatelessWidget {
  const _ProgramRow({required this.stats, required this.pattern});

  final CoachProgramStats stats;
  final bool pattern;

  static const double _thumb = 52;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final p = TrainingStory.programs.firstWhere((p) => p.id == stats.programId);
    return InkWell(
      onTap: () => context.go(CoachRoutes.programs),
      child: Padding(
        padding: const EdgeInsets.all(MuSpace.s4),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: MuRadius.smAll,
              child: SizedBox.square(
                dimension: _thumb,
                child: MuCourtArt(
                  sport: p.sport,
                  variant: pattern ? MuCourtArtVariant.pattern : MuCourtArtVariant.photo,
                ),
              ),
            ),
            const SizedBox(width: MuSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.title, style: MuType.label.copyWith(color: c.text)),
                  Text(
                    l10n.coaProgramLine(
                      stats.activeStudents,
                      formatLevel(p.card.rating),
                      p.card.reviews,
                    ),
                    style: MuType.caption.copyWith(color: c.textSecondary),
                  ),
                  const SizedBox(height: MuSpace.s2),
                  Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          label: l10n.coaAverageProgress(stats.averageProgress),
                          excludeSemantics: true,
                          child: MuProgressBar(
                            value: stats.averageProgress.toDouble(),
                            size: MuProgressSize.s,
                            showValue: false,
                          ),
                        ),
                      ),
                      const SizedBox(width: MuSpace.s3),
                      Text(
                        l10n.coaAverage(stats.averageProgress),
                        style: MuType.numXs.copyWith(color: c.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The program being written: « Brouillon » · « 10/12 séances » → the builder.
class _DraftRow extends StatelessWidget {
  const _DraftRow({required this.draft});

  final ProgramDraft draft;

  static const double _thumb = 52;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return InkWell(
      onTap: () => context.push(CoachRoutes.builder),
      child: Padding(
        padding: const EdgeInsets.all(MuSpace.s4),
        child: Row(
          children: [
            Container(
              width: _thumb,
              height: _thumb,
              decoration: BoxDecoration(
                color: c.surfaceMuted,
                borderRadius: MuRadius.smAll,
                border: Border.all(color: c.border),
              ),
              alignment: Alignment.center,
              child: Icon(PhosphorIcons.notePencil(), size: MuSize.iconM, color: c.text),
            ),
            const SizedBox(width: MuSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(draft.title, style: MuType.label.copyWith(color: c.text)),
                  const SizedBox(height: MuSpace.s1),
                  Row(
                    children: [
                      DraftBadge(draft: draft),
                      const SizedBox(width: MuSpace.s2),
                      Text(
                        l10n.coaSessionsReady(draft.sessionCount, draft.targetSessions),
                        style: MuType.caption.copyWith(color: c.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            MuDirectionalIcon(PhosphorIcons.caretRight(), size: MuSize.iconS, color: c.textSecondary),
          ],
        ),
      ),
    );
  }
}
