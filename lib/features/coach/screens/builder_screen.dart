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
import '../../common/widgets/flow_scaffold.dart';
import '../coach_routes.dart';
import '../controllers/coach_providers.dart';
import '../data/coach_models.dart';
import '../data/draft_ops.dart';
import '../widgets/coach_widgets.dart';
import '../widgets/exercise_widgets.dart';

/// Sessions a week needs before the program can be published.
const sessionsPerWeek = 3;

/// COA-06 · Constructeur: the draft's weeks, sessions and exercises, reorderable by their handle,
/// with « Ajouter un exercice » from the library; then « Continuer vers le prix » (COA-08).
class BuilderScreen extends ConsumerStatefulWidget {
  const BuilderScreen({super.key});

  @override
  ConsumerState<BuilderScreen> createState() => _BuilderScreenState();
}

class _BuilderScreenState extends ConsumerState<BuilderScreen> {
  Set<String>? _openWeeks;
  String? _openSession;

  CoachDraftController get _ctl => ref.read(coachDraftProvider.notifier);

  /// Opens the week of the first session in processing (the one to watch), or the first week.
  void _initOpen(ProgramDraft d) {
    if (_openWeeks != null) return;
    for (final w in d.weeks) {
      for (final s in w.sessions) {
        if (s.processing) {
          _openWeeks = {w.id};
          _openSession = s.id;
          return;
        }
      }
    }
    _openWeeks = {if (d.weeks.isNotEmpty) d.weeks.first.id};
  }

  Future<void> _addExercises(ProgramDraft d, DraftSession s) async {
    final res = await showAddExerciseSheet(
      context,
      sessionLabel: l10n.entLessonLabel(d.numberOf(s), s.title),
    );
    if (res == null) return;
    if (res.createNew) {
      await _ctl.editSession(s.id, DraftOps.addBlankExercise);
      if (mounted) context.push(CoachRoutes.session(s.id));
    } else {
      await _ctl.editSession(s.id, (s) => DraftOps.addExercises(s, res.picked));
      if (mounted) {
        MuToast.show(context, tone: MuToastTone.success, title: l10n.coaExercisesAdded(res.picked.length));
      }
    }
  }

  Future<void> _editInfo(ProgramDraft d) async {
    final title = TextEditingController(text: d.title);
    final saved = await MuBottomSheet.show<bool>(
      context,
      title: l10n.coaProgramInfo,
      child: Padding(
        padding: const EdgeInsets.all(MuSpace.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MuTextField(label: l10n.coaProgramTitle, controller: title, maxLength: 60),
            const SizedBox(height: MuSpace.s3),
            Builder(
              builder: (context) => MuButton.primary(
                label: l10n.enregistrer,
                size: MuButtonSize.l,
                fullWidth: true,
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ),
          ],
        ),
      ),
    );
    if (saved == true && title.text.trim().isNotEmpty) {
      await _ctl.edit((d) => d.copyWith(title: title.text.trim()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final now = ref.watch(clockProvider)();
    final draft = ref.watch(coachDraftProvider);
    final d = draft.value;
    void back() => context.canPop() ? context.pop() : context.go(CoachRoutes.programs);

    if (d == null) {
      return Scaffold(
        backgroundColor: c.bg,
        body: Column(
          children: [
            MuTopAppBar.compact(title: l10n.coaBuilder, onBack: back),
            Expanded(
              child: draft.isLoading
                  ? const Center(child: MuSpinner())
                  : Center(
                      child: MuEmptyState(
                        title: l10n.coaNoDraft,
                        description: l10n.coaNoDraftText,
                        illustration: MuEmptyIllustration.programs,
                        actions: [
                          MuButton.primary(label: l10n.coaCreate, onPressed: _ctl.create),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      );
    }
    _initOpen(d);
    final open = _openWeeks!;

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          CoachPageHeader(
            title: d.title,
            saved: l10n.coaDraftSaved(formatSince(d.updatedAt, now)),
            onBack: back,
            onPreview: () => showComingSoon(context),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(MuSpace.s4, 0, MuSpace.s4, MuSpace.s2),
            child: MuStepIndicator(step: 1, total: 2, title: l10n.coaContent, showLabel: true),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s2, MuSpace.s4, MuSpace.s6),
              children: [
                _Summary(draft: d, onInfo: () => _editInfo(d)),
                const SizedBox(height: MuSpace.s3),
                InfoLine(l10n.coaDragHint, icon: PhosphorIcons.dotsSixVertical()),
                const SizedBox(height: MuSpace.s3),
                ReorderableListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  onReorderItem: (a, b) => _ctl.edit((d) => DraftOps.reorderWeeks(d, a, b)),
                  children: [
                    for (final (i, w) in d.weeks.indexed)
                      Padding(
                        key: ValueKey(w.id),
                        padding: const EdgeInsets.only(bottom: MuSpace.s3),
                        child: _WeekCard(
                          index: i,
                          week: w,
                          draft: d,
                          open: open.contains(w.id),
                          openSession: _openSession,
                          onToggle: () => setState(() => open.contains(w.id) ? open.remove(w.id) : open.add(w.id)),
                          onToggleSession: (id) => setState(() => _openSession = _openSession == id ? null : id),
                          onAddExercises: (s) => _addExercises(d, s),
                          onAddSession: () async {
                            String? id;
                            await _ctl.edit((d) {
                              final (next, newId) = DraftOps.addSession(d, w.id);
                              id = newId;
                              return next;
                            });
                            if (id != null && context.mounted) context.push(CoachRoutes.session(id!));
                          },
                        ),
                      ),
                  ],
                ),
                OutlinedAdd(
                  label: l10n.coaAddWeek,
                  dashed: true,
                  onPressed: () => _ctl.edit(DraftOps.addWeek),
                ),
              ],
            ),
          ),
          StickyActionBar(
            children: [
              MuButton.primary(
                label: l10n.coaContinueToPrice,
                trailing: PhosphorIcons.arrowRight(),
                size: MuButtonSize.xl,
                fullWidth: true,
                onPressed: () => context.push(CoachRoutes.publish),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Back, the program's title and « Brouillon enregistré · il y a 1 min », the student preview.
class CoachPageHeader extends StatelessWidget {
  const CoachPageHeader({
    super.key,
    required this.title,
    required this.saved,
    required this.onBack,
    this.onPreview,
    this.savedIcon,
    this.trailing,
  });

  final String title;
  final String saved;
  final VoidCallback onBack;
  final VoidCallback? onPreview;
  final IconData? savedIcon;

  /// Instead of the preview button (« ☁ Enregistrée »).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(MuSpace.s1, MuSpace.s2, MuSpace.s1, MuSpace.s2),
        child: Row(
          children: [
            MuIconButton(
              icon: PhosphorIcons.arrowLeft(),
              label: l10n.coaBackToPrograms,
              size: MuIconButtonSize.l,
              onPressed: onBack,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MuType.labelL.copyWith(color: c.text),
                  ),
                  Row(
                    children: [
                      Icon(savedIcon ?? PhosphorIcons.cloudCheck(), size: MuSize.iconXs, color: c.textSecondary),
                      const SizedBox(width: MuSpace.s1),
                      Flexible(
                        child: Text(
                          saved,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: MuType.caption.copyWith(color: c.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (onPreview != null)
              MuIconButton(
                icon: PhosphorIcons.eye(),
                label: l10n.coaStudentPreview,
                size: MuIconButtonSize.l,
                onPressed: onPreview,
              ),
          ],
        ),
      ),
    );
  }
}

/// The program at a glance: cover, sport and level, weeks · sessions · exercises, « Infos ».
class _Summary extends StatelessWidget {
  const _Summary({required this.draft, required this.onInfo});

  final ProgramDraft draft;
  final VoidCallback onInfo;

  static const double _cover = 56;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final d = draft;
    return MuCardSurface(
      padding: const EdgeInsets.all(MuSpace.s3),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: MuRadius.smAll,
            child: SizedBox.square(dimension: _cover, child: MuCourtArt(sport: d.sport)),
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
                    MuChip.sport(d.sport, size: MuChipSize.s),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: '${l10n.coaLevel} '),
                          TextSpan(
                            text: ltr('${formatLevel(d.levelMin)} – ${formatLevel(d.levelMax)}'),
                            style: MuType.numXs.copyWith(color: c.text),
                          ),
                        ],
                      ),
                      style: MuType.caption.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: MuSpace.s1),
                Text(
                  l10n.coaDraftShape(d.weeks.length, d.sessionCount, d.exerciseCount),
                  style: MuType.caption.copyWith(color: c.textSecondary),
                ),
              ],
            ),
          ),
          MuButton.tertiary(label: l10n.coaInfo, size: MuButtonSize.s, onPressed: onInfo),
        ],
      ),
    );
  }
}

/// A week: handle, « SEMAINE 2 », title, what it holds (or what it lacks), its sessions.
class _WeekCard extends ConsumerWidget {
  const _WeekCard({
    required this.index,
    required this.week,
    required this.draft,
    required this.open,
    required this.openSession,
    required this.onToggle,
    required this.onToggleSession,
    required this.onAddExercises,
    required this.onAddSession,
  });

  final int index;
  final DraftWeek week;
  final ProgramDraft draft;
  final bool open;
  final String? openSession;
  final VoidCallback onToggle;
  final ValueChanged<String> onToggleSession;
  final ValueChanged<DraftSession> onAddExercises;
  final VoidCallback onAddSession;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final w = week;
    final ctl = ref.read(coachDraftProvider.notifier);
    final lacking = sessionsPerWeek - w.sessions.length;
    return MuCardSurface(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(MuSpace.s2, MuSpace.s3, MuSpace.s2, MuSpace.s3),
            child: Row(
              children: [
                DragHandle(index: index, label: l10n.coaMoveWeek(index + 1)),
                const SizedBox(width: MuSpace.s1),
                Expanded(
                  child: InkWell(
                    onTap: onToggle,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.coaWeekN(index + 1).toUpperCase(),
                          style: MuType.overline.copyWith(color: c.textSecondary),
                        ),
                        Text(w.title, style: MuType.labelL.copyWith(color: c.text)),
                        lacking > 0
                            ? Row(
                                children: [
                                  Icon(PhosphorIcons.warningCircle(), size: MuSize.iconXs, color: c.warningText),
                                  const SizedBox(width: MuSpace.s1),
                                  Flexible(
                                    child: Text(
                                      l10n.coaWeekLacking(w.sessions.length, lacking),
                                      style: MuType.caption.copyWith(color: c.warningText),
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                l10n.coaWeekShape(w.sessions.length, w.exercises, w.minutes),
                                style: MuType.caption.copyWith(color: c.textSecondary),
                              ),
                      ],
                    ),
                  ),
                ),
                MuIconButton(
                  icon: open ? PhosphorIcons.caretUp() : PhosphorIcons.caretDown(),
                  label: open ? l10n.coaFoldWeek(index + 1) : l10n.coaUnfoldWeek(index + 1),
                  variant: MuIconButtonVariant.secondary,
                  onPressed: onToggle,
                ),
              ],
            ),
          ),
          if (open) ...[
            Divider(height: 1, thickness: 1, color: c.border),
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              onReorderItem: (a, b) => ctl.edit((d) => DraftOps.reorderSessions(d, w.id, a, b)),
              children: [
                for (final (i, s) in w.sessions.indexed)
                  _SessionRow(
                    key: ValueKey(s.id),
                    index: i,
                    number: draft.numberOf(s),
                    session: s,
                    open: openSession == s.id,
                    onToggle: () => onToggleSession(s.id),
                    onAddExercises: () => onAddExercises(s),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(MuSpace.s2, 0, MuSpace.s2, MuSpace.s2),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: MuButton.tertiary(
                  label: l10n.coaAddSession,
                  leading: PhosphorIcons.plus(),
                  onPressed: onAddSession,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A session: handle, number, title, exercises · minutes · video state, and its exercises when
/// unfolded.
class _SessionRow extends ConsumerWidget {
  const _SessionRow({
    super.key,
    required this.index,
    required this.number,
    required this.session,
    required this.open,
    required this.onToggle,
    required this.onAddExercises,
  });

  final int index;
  final int number;
  final DraftSession session;
  final bool open;
  final VoidCallback onToggle;
  final VoidCallback onAddExercises;

  static const double _circle = 32;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final s = session;
    final ctl = ref.read(coachDraftProvider.notifier);
    final caption = MuType.caption.copyWith(color: c.textSecondary);
    final Widget? state = s.processing
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(PhosphorIcons.hourglassMedium(), size: MuSize.iconXs, color: c.warningText),
              const SizedBox(width: MuSpace.s1 / 2),
              Text(l10n.coaProcessing, style: MuType.caption.copyWith(color: c.warningText)),
            ],
          )
        : s.video == VideoState.ready
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(PhosphorIcons.checkCircle(), size: MuSize.iconXs, color: c.successText),
              const SizedBox(width: MuSpace.s1 / 2),
              Text(l10n.coaVideo, style: MuType.caption.copyWith(color: c.successText)),
            ],
          )
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => context.push(CoachRoutes.session(s.id)),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(MuSpace.s2, MuSpace.s2, MuSpace.s2, MuSpace.s2),
            child: Row(
              children: [
                DragHandle(index: index, label: l10n.coaMoveSession(number)),
                const SizedBox(width: MuSpace.s1),
                Container(
                  width: _circle,
                  height: _circle,
                  decoration: BoxDecoration(
                    color: open ? c.accent : c.surfaceMuted,
                    shape: BoxShape.circle,
                    border: open ? null : Border.all(color: c.border),
                  ),
                  alignment: Alignment.center,
                  child: Text('$number', style: MuType.numS.copyWith(color: open ? c.onAccent : c.text)),
                ),
                const SizedBox(width: MuSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.title, style: MuType.label.copyWith(color: c.text)),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '${l10n.entDrills(s.exercises.length)} · ${l10n.entMinutes(s.minutes)}',
                            style: caption,
                          ),
                          if (state != null) ...[Text(' · ', style: caption), state],
                        ],
                      ),
                    ],
                  ),
                ),
                MuIconButton(
                  icon: open ? PhosphorIcons.caretUp() : PhosphorIcons.caretDown(),
                  label: open ? l10n.coaFoldSession(number) : l10n.coaUnfoldSession(number),
                  onPressed: onToggle,
                ),
              ],
            ),
          ),
        ),
        if (open)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(MuSpace.s8, 0, MuSpace.s3, MuSpace.s3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ReorderableListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  onReorderItem: (a, b) => ctl.editSession(s.id, (s) => DraftOps.reorderExercises(s, a, b)),
                  children: [
                    for (final (i, e) in s.exercises.indexed)
                      Container(
                        key: ValueKey(e.id),
                        margin: const EdgeInsets.only(bottom: MuSpace.s2),
                        padding: const EdgeInsetsDirectional.fromSTEB(0, MuSpace.s1, 0, MuSpace.s1),
                        decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: MuRadius.smAll),
                        child: Row(
                          children: [
                            DragHandle(index: i, label: l10n.coaMoveExercise(e.name)),
                            Icon(drillIcon(e.mode), size: MuSize.iconXs, color: c.text),
                            const SizedBox(width: MuSpace.s2),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(e.name, style: MuType.label.copyWith(color: c.text)),
                                  Text(exerciseMeta(e), style: caption),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              tooltip: l10n.coaExerciseOptions(e.name),
                              icon: Icon(PhosphorIcons.dotsThreeVertical(), size: MuSize.iconS, color: c.textSecondary),
                              onSelected: (v) {
                                if (v == 'edit') context.push(CoachRoutes.session(s.id));
                                if (v == 'delete') {
                                  ctl.editSession(s.id, (s) => DraftOps.removeExercise(s, e.id));
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(value: 'edit', child: Text(l10n.coaEdit)),
                                PopupMenuItem(value: 'delete', child: Text(l10n.coaDelete)),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                OutlinedAdd(label: l10n.coaAddExercise, onPressed: onAddExercises),
              ],
            ),
          ),
      ],
    );
  }
}

/// « + Ajouter un exercice » / « + Ajouter une semaine »: an outlined (or dashed) full-width add.
class OutlinedAdd extends StatelessWidget {
  const OutlinedAdd({super.key, required this.label, required this.onPressed, this.dashed = false});

  final String label;
  final VoidCallback onPressed;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: MuRadius.smAll,
          side: BorderSide(color: dashed ? c.borderStrong : c.text, width: dashed ? 1 : 1.5),
        ),
        child: InkWell(
          borderRadius: MuRadius.smAll,
          onTap: onPressed,
          child: SizedBox(
            height: MuSize.controlL,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(PhosphorIcons.plus(), size: MuSize.iconS, color: c.text),
                const SizedBox(width: MuSpace.s2),
                Text(label, style: MuType.label.copyWith(color: c.text)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
