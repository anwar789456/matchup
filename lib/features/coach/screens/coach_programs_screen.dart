import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/clock.dart';
import '../../../core/format.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../training/data/training_models.dart';
import '../../training/data/training_story.dart';
import '../../training/training_routes.dart';
import '../coach_routes.dart';
import '../controllers/coach_providers.dart';
import '../data/coach_models.dart';
import '../data/coach_story.dart';
import '../widgets/coach_shell.dart';
import '../widgets/coach_widgets.dart';

/// COA-05 · Programmes: the draft to finish, the published programs with their numbers, and
/// « Créer un programme ».
class CoachProgramsScreen extends ConsumerStatefulWidget {
  const CoachProgramsScreen({super.key});

  @override
  ConsumerState<CoachProgramsScreen> createState() => _CoachProgramsScreenState();
}

class _CoachProgramsScreenState extends ConsumerState<CoachProgramsScreen> {
  int _tab = 0;

  Future<void> _create() async {
    await ref.read(coachDraftProvider.notifier).create();
    if (mounted) context.push(CoachRoutes.builder);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final draft = ref.watch(coachDraftProvider).value;
    const published = CoachStory.programStats;
    final showDraft = draft != null && _tab != 1;
    final showPublished = _tab != 2;

    Widget overline(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s5, MuSpace.s4, MuSpace.s2),
      child: Text(text.toUpperCase(), style: MuType.overline.copyWith(color: c.textSecondary)),
    );

    return Scaffold(
      backgroundColor: c.bg,
      body: ListView(
        padding: const EdgeInsets.only(bottom: MuSpace.s8),
        children: [
          CoachHeader(
            title: l10n.coaTabPrograms,
            actions: [
              MuButton.primary(
                label: l10n.coaCreate,
                leading: PhosphorIcons.plus(),
                onPressed: draft == null ? _create : () => context.push(CoachRoutes.builder),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
            child: MuTabs(
              label: l10n.coaFilterPrograms,
              fullWidth: true,
              index: _tab,
              onChanged: (i) => setState(() => _tab = i),
              tabs: [
                MuTab(l10n.coaAll, count: published.length + (draft == null ? 0 : 1)),
                MuTab(l10n.coaPublished, count: published.length),
                MuTab(l10n.coaDrafts, count: draft == null ? 0 : 1),
              ],
            ),
          ),
          if (showDraft) ...[
            overline(l10n.coaToFinish),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
              child: _DraftCard(draft: draft),
            ),
          ],
          if (showPublished) ...[
            overline(l10n.coaPublishedLine(CoachStory.activeEnrollments)),
            for (final (i, s) in published.indexed)
              Padding(
                padding: const EdgeInsets.fromLTRB(MuSpace.s4, 0, MuSpace.s4, MuSpace.s3),
                child: _PublishedCard(
                  stats: s,
                  program: TrainingStory.programs.firstWhere((p) => p.id == s.programId),
                  pattern: i > 0,
                  now: ref.watch(clockProvider)(),
                ),
              ),
          ],
          if (!showDraft && !showPublished)
            Padding(
              padding: const EdgeInsets.all(MuSpace.s4),
              child: MuEmptyState(
                title: l10n.coaNoDraft,
                description: l10n.coaNoDraftText,
                illustration: MuEmptyIllustration.programs,
              ),
            ),
          const SizedBox(height: MuSpace.s2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
            child: DashedAction(
              icon: PhosphorIcons.plus(),
              title: l10n.coaCreateProgram,
              detail: l10n.coaCreateProgramDetail,
              onTap: draft == null ? _create : () => context.push(CoachRoutes.builder),
            ),
          ),
        ],
      ),
    );
  }
}

/// « À terminer »: the draft, its sessions ready, what it lacks to be published.
class _DraftCard extends ConsumerWidget {
  const _DraftCard({required this.draft});

  final ProgramDraft draft;

  static const double _tile = 64;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await MuDialog.show<bool>(
      context,
      tone: MuDialogTone.destructive,
      title: l10n.coaDeleteDraftTitle,
      description: l10n.coaDeleteDraftText(draft.title),
      actions: [
        Builder(
          builder: (context) => MuButton.secondary(
            label: l10n.annuler,
            size: MuButtonSize.l,
            fullWidth: true,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ),
        Builder(
          builder: (context) => MuButton.destructive(
            label: l10n.coaDelete,
            size: MuButtonSize.l,
            fullWidth: true,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ),
      ],
    );
    if (ok == true) await ref.read(coachDraftProvider.notifier).delete();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final now = ref.watch(clockProvider)();
    final d = draft;
    final edited = d.updatedAt;
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final when = DateUtils.isSameDay(edited, now)
        ? l10n.coaEditedToday(formatTime(edited))
        : DateUtils.isSameDay(edited, yesterday)
        ? l10n.coaEditedYesterday(formatTime(edited))
        : l10n.coaEditedOn(formatDay(edited));
    final lastWeek = d.weeks.length;
    final missing = [
      if (d.missingSessions > 0) l10n.coaMissingSessions(d.missingSessions, lastWeek),
      if (!d.priceSet) l10n.coaMissingPrice,
    ];
    return MuCardSurface(
      onTap: () => context.push(CoachRoutes.builder),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: _tile,
                height: _tile,
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
                    DraftBadge(draft: d),
                    const SizedBox(height: MuSpace.s1),
                    Text(d.title, style: MuType.labelL.copyWith(color: c.text)),
                    Text(
                      l10n.coaDraftLine(
                        d.sport.label,
                        ltr('${formatLevel(d.levelMin)} – ${formatLevel(d.levelMax)}'),
                        when,
                      ),
                      style: MuType.caption.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: MuSpace.s4),
          MuProgressBar(
            value: d.sessionCount.toDouble(),
            max: d.targetSessions.toDouble(),
            unit: l10n.entSessionsUnit,
            label: l10n.coaSessionsReadyLabel,
            size: MuProgressSize.s,
          ),
          if (missing.isNotEmpty) ...[
            const SizedBox(height: MuSpace.s3),
            InfoLine(
              withFullStop(l10n.coaToPublish(missing.join(l10n.coaAnd))),
              icon: PhosphorIcons.warningCircle(),
            ),
          ],
          const SizedBox(height: MuSpace.s3),
          Row(
            children: [
              MuButton.tertiary(
                label: l10n.coaDelete,
                leading: PhosphorIcons.trash(),
                onPressed: () => _delete(context, ref),
              ),
              const Spacer(),
              MuButton.primary(
                label: l10n.continuer,
                trailing: PhosphorIcons.arrowRight(),
                onPressed: () => context.push(CoachRoutes.builder),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A published program: cover, « Publié », its numbers, its price, « Voir la page ».
class _PublishedCard extends StatelessWidget {
  const _PublishedCard({
    required this.stats,
    required this.program,
    required this.pattern,
    required this.now,
  });

  final DateTime now;
  final CoachProgramStats stats;
  final TrainingProgram program;
  final bool pattern;

  static const double _thumb = 64;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final p = program;
    final month = formatMonth(now);
    Widget stat(String label, Widget value) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: MuType.caption.copyWith(color: c.textSecondary)),
          const SizedBox(height: MuSpace.s1 / 2),
          value,
        ],
      ),
    );
    return MuCardSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    MuStatusBadge(
                      status: MuStatus.confirmed,
                      label: l10n.coaPublishedOne,
                      size: MuBadgeSize.s,
                    ),
                    const SizedBox(height: MuSpace.s1),
                    Text(p.title, style: MuType.labelL.copyWith(color: c.text)),
                    Text(
                      l10n.coaProgramShape(
                        p.card.weeks,
                        p.card.sessions,
                        ltr('${formatLevel(p.levelMin)} – ${formatLevel(p.levelMax)}'),
                      ),
                      style: MuType.caption.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: MuSpace.s3),
          Divider(height: 1, thickness: 1, color: c.border),
          const SizedBox(height: MuSpace.s3),
          IntrinsicHeight(
            child: Row(
              children: [
                stat(
                  l10n.coaActiveStudents,
                  Text('${stats.activeStudents}', style: MuType.numM.copyWith(color: c.text)),
                ),
                VerticalDivider(width: MuSpace.s4, color: c.border),
                stat(
                  l10n.coaMonthNet(month.isEmpty ? month : month[0].toUpperCase() + month.substring(1)),
                  MoneyHero(amount: stats.monthNet, style: MuType.numM),
                ),
                VerticalDivider(width: MuSpace.s4, color: c.border),
                stat(
                  l10n.coaRating,
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: formatLevel(p.card.rating), style: MuType.numM),
                        TextSpan(
                          text: ' (${p.card.reviews})',
                          style: MuType.caption.copyWith(color: c.textSecondary),
                        ),
                      ],
                    ),
                    style: TextStyle(color: c.text),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: MuSpace.s3),
          Row(
            children: [
              Text(formatDT(p.card.price), style: MuType.numS.copyWith(color: c.text)),
              if (p.card.premium) ...[
                const SizedBox(width: MuSpace.s2),
                Text(l10n.coaOr, style: MuType.caption.copyWith(color: c.textSecondary)),
                const SizedBox(width: MuSpace.s2),
                const MuPremiumBadge(short: true),
              ],
              const Spacer(),
              MuButton.tertiary(
                label: l10n.coaSeePage,
                leading: PhosphorIcons.eye(),
                size: MuButtonSize.s,
                onPressed: () => context.push(TrainingRoutes.program(p.id)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A dashed call to action: icon tile, title, detail.
class DashedAction extends StatelessWidget {
  const DashedAction({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.detail,
  });

  final IconData icon;
  final String title;
  final String? detail;
  final VoidCallback onTap;

  static const double _tile = 40;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Semantics(
      button: true,
      label: detail == null ? title : '$title. $detail',
      excludeSemantics: true,
      child: Material(
        color: c.surface,
        borderRadius: MuRadius.mdAll,
        child: InkWell(
          borderRadius: MuRadius.mdAll,
          onTap: onTap,
          child: CustomPaint(
            painter: _DashedBorder(color: c.borderStrong),
            child: Padding(
              padding: const EdgeInsets.all(MuSpace.s4),
              child: Row(
                children: [
                  Container(
                    width: _tile,
                    height: _tile,
                    decoration: BoxDecoration(color: c.accent, borderRadius: MuRadius.smAll),
                    alignment: Alignment.center,
                    child: Icon(icon, size: MuSize.iconM, color: c.onAccent),
                  ),
                  const SizedBox(width: MuSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: MuType.label.copyWith(color: c.text)),
                        if (detail != null)
                          Text(detail!, style: MuType.caption.copyWith(color: c.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorder extends CustomPainter {
  const _DashedBorder({required this.color});

  final Color color;

  static const double _dash = 6;
  static const double _gap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()..addRRect(MuRadius.mdAll.toRRect(Offset.zero & size).deflate(0.5));
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += _dash + _gap) {
        canvas.drawPath(m.extractPath(d, d + _dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => old.color != color;
}
