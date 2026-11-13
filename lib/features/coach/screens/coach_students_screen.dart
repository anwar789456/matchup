import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/clock.dart';
import '../../../core/format.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../coach_routes.dart';
import '../controllers/coach_providers.dart';
import '../data/coach_models.dart';
import '../data/coach_story.dart';
import '../widgets/coach_shell.dart';

enum _Filter { all, late, active, finished }

/// COA-09 · Élèves: search, quick filters, every student with their program, session, last
/// activity and progress; the most recent first, or by name.
class CoachStudentsScreen extends ConsumerStatefulWidget {
  const CoachStudentsScreen({super.key});

  @override
  ConsumerState<CoachStudentsScreen> createState() => _CoachStudentsScreenState();
}

class _CoachStudentsScreenState extends ConsumerState<CoachStudentsScreen> {
  _Filter _filter = _Filter.all;
  String _query = '';
  bool _byName = false;

  bool _keep(CoachStudent s) => switch (_filter) {
    _Filter.all => true,
    _Filter.late => s.late,
    _Filter.active => s.activeThisWeek,
    _Filter.finished => s.finished,
  };

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final now = ref.watch(clockProvider)();
    final all = ref.watch(coachStudentsProvider).value ?? const <CoachStudent>[];
    final sent = {
      for (final s in all)
        if (ref.watch(coachFeedbackProvider(s.id)).value != null) s.id,
    };
    final q = _query.trim().toLowerCase();
    final shown = [
      for (final s in all)
        if (_keep(s) && (q.isEmpty || s.name.toLowerCase().contains(q))) s,
    ]..sort((a, b) => _byName ? a.name.compareTo(b.name) : b.lastActivity.compareTo(a.lastActivity));

    final counts = {
      _Filter.all: all.length,
      _Filter.late: all.where((s) => s.late).length,
      _Filter.active: all.where((s) => s.activeThisWeek).length,
      _Filter.finished: all.where((s) => s.finished).length,
    };
    final labels = {
      _Filter.all: l10n.coaAll,
      _Filter.late: l10n.coaLate,
      _Filter.active: l10n.coaActiveThisWeek,
      _Filter.finished: l10n.coaFinished,
    };

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          CoachHeader(title: l10n.coaTabStudents, count: all.length),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
            child: MuSearchField<String>(
              label: l10n.coaSearchStudent,
              placeholder: l10n.coaSearchStudent,
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          const SizedBox(height: MuSpace.s3),
          Semantics(
            container: true,
            label: l10n.coaFilterStudents,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
              child: Row(
                children: [
                  for (final f in _Filter.values) ...[
                    if (f != _Filter.all) const SizedBox(width: MuSpace.s2),
                    MuChip(
                      kind: MuChipKind.choice,
                      label: labels[f],
                      count: counts[f],
                      selected: _filter == f,
                      onSelected: (_) => setState(() => _filter = f),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(MuSpace.s4, MuSpace.s2, MuSpace.s1, MuSpace.s1),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.coaProgramsLine(
                      CoachStory.programStats.length,
                      CoachStory.activeEnrollments,
                    ),
                    style: MuType.caption.copyWith(color: c.textSecondary),
                  ),
                ),
                MuButton.tertiary(
                  label: _byName ? l10n.coaSortName : l10n.coaSortRecent,
                  leading: PhosphorIcons.arrowsDownUp(),
                  size: MuButtonSize.s,
                  onPressed: () => setState(() => _byName = !_byName),
                ),
              ],
            ),
          ),
          Expanded(
            child: shown.isEmpty
                ? Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(MuSpace.s4),
                      child: MuEmptyState(
                        title: l10n.coaNoStudent,
                        description: l10n.coaNoStudentText,
                        illustration: MuEmptyIllustration.results,
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s1, MuSpace.s4, MuSpace.s8),
                    children: [
                      MuCardSurface(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            for (final (i, s) in shown.indexed) ...[
                              if (i > 0) Divider(height: 1, thickness: 1, color: c.border),
                              StudentRow(student: s, now: now, feedbackSent: sent.contains(s.id)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// A student: avatar with level, name, program and session, last activity, progress ring.
class StudentRow extends StatelessWidget {
  const StudentRow({
    super.key,
    required this.student,
    required this.now,
    this.feedbackSent = false,
  });

  final CoachStudent student;
  final DateTime now;
  final bool feedbackSent;

  static const double _ring = 48;
  static const double _icon = 14;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final s = student;
    final days = DateTime(now.year, now.month, now.day)
        .difference(DateTime(s.lastActivity.year, s.lastActivity.month, s.lastActivity.day))
        .inDays;
    final (IconData? icon, Color ink, String text) = s.finished
        ? (PhosphorIcons.checkCircle(), c.successText, l10n.coaFinishedOn(formatDay(s.lastActivity)))
        : s.late
        ? (PhosphorIcons.warningCircle(), c.warningText, l10n.coaLateSince(days))
        : s.videoAt != null && !feedbackSent
        ? (PhosphorIcons.videoCamera(), c.textSecondary, l10n.coaVideoSent(formatSince(s.videoAt!, now)))
        : s.videoAt != null
        ? (PhosphorIcons.checkCircle(), c.textSecondary, l10n.coaFeedbackSent)
        : (
            null,
            c.textSecondary,
            days == 0
                ? l10n.coaSessionToday
                : days == 1
                ? l10n.coaSessionYesterday
                : l10n.coaSessionOn(formatDay(s.lastActivity)),
          );
    final line = s.finished
        ? l10n.coaProgramFinishedLine(s.programTitle, s.done, s.total)
        : l10n.coaProgramSessionLine(s.programTitle, s.current, s.total);
    return InkWell(
      onTap: () => context.push(CoachRoutes.student(s.id)),
      child: Semantics(
        label: '${s.name}, $line, $text, ${s.percent} %',
        excludeSemantics: true,
        child: Padding(
          padding: const EdgeInsets.all(MuSpace.s4),
          child: Row(
            children: [
              MuAvatar(name: s.name, size: MuAvatarSize.m, level: s.level),
              const SizedBox(width: MuSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.name, style: MuType.label.copyWith(color: c.text)),
                    Text(
                      line,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MuType.caption.copyWith(color: c.textSecondary),
                    ),
                    Row(
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: _icon, color: ink),
                          const SizedBox(width: MuSpace.s1),
                        ],
                        Flexible(
                          child: Text(
                            text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: MuType.caption.copyWith(color: ink),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: MuSpace.s3),
              MuProgressRing(
                value: s.percent.toDouble(),
                size: _ring,
                percent: true,
                tone: s.finished
                    ? MuTone.success
                    : s.late
                    ? MuTone.warning
                    : MuTone.primary,
                label: l10n.coaProgressOf(s.name),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
