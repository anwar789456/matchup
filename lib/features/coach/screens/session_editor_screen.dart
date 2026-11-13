import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../../common/data/pro_providers.dart' show fileSourceProvider;
import '../../common/widgets/flow_scaffold.dart';
import '../coach_routes.dart';
import '../controllers/coach_providers.dart';
import '../data/coach_models.dart';
import '../data/draft_ops.dart';
import '../widgets/exercise_widgets.dart';
import 'builder_screen.dart';

/// COA-07 · Séance · vidéo: the session's title, its main video (sent, processed, replaced), its
/// exercises (duration or repetitions, sets, a video each), the note for the students.
class SessionEditorScreen extends ConsumerStatefulWidget {
  const SessionEditorScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<SessionEditorScreen> createState() => _SessionEditorScreenState();
}

class _SessionEditorScreenState extends ConsumerState<SessionEditorScreen> {
  TextEditingController? _title;
  TextEditingController? _note;
  String? _open;
  bool _openSet = false;

  // COA-07: title 60, note 280; videos MP4/MOV, 500 Mo max for an exercise.
  static const _titleMax = 60;
  static const _noteMax = 280;
  static const _maxBytes = 500 * 1000 * 1000;

  CoachDraftController get _ctl => ref.read(coachDraftProvider.notifier);

  @override
  void dispose() {
    _title?.dispose();
    _note?.dispose();
    super.dispose();
  }

  Future<void> _edit(DraftSession Function(DraftSession s) change) =>
      _ctl.editSession(widget.sessionId, change);

  Future<void> _pickSessionVideo() async {
    final f = await ref.read(fileSourceProvider).pickOne(const ['mp4', 'mov']);
    if (f == null) return;
    // Sent at once on the fake server, then processed (« Traitement de la vidéo… »).
    await _edit(
      (s) => s.copyWith(
        video: VideoState.processing,
        videoName: f.name,
        videoBytes: f.sizeBytes,
        videoLength: const Duration(minutes: 2, seconds: 14),
      ),
    );
  }

  Future<void> _pickExerciseVideo(DraftExercise e) async {
    final f = await ref.read(fileSourceProvider).pickOne(const ['mp4', 'mov']);
    if (f == null) return;
    if (f.sizeBytes > _maxBytes) {
      if (mounted) MuToast.show(context, tone: MuToastTone.error, title: l10n.coaVideoTooBig);
      return;
    }
    await _edit(
      (s) => DraftOps.editExercise(
        s,
        e.id,
        (e) => e.copyWith(
          video: VideoState.uploading,
          uploadProgress: 0,
          fileName: f.name,
          fileBytes: f.sizeBytes,
          videoLength: const Duration(seconds: 45),
        ),
      ),
    );
  }

  Future<void> _addExercises(DraftSession s, int number) async {
    final res = await showAddExerciseSheet(context, sessionLabel: l10n.entLessonLabel(number, s.title));
    if (res == null) return;
    if (res.createNew) {
      await _edit(DraftOps.addBlankExercise);
      final added = ref.read(coachDraftProvider).value;
      final last = added == null ? null : DraftOps.find(added, widget.sessionId)?.$2.exercises.lastOrNull;
      if (last != null) setState(() => _open = last.id);
    } else {
      await _edit((s) => DraftOps.addExercises(s, res.picked));
    }
  }

  Future<void> _save() async {
    final title = _title!.text.trim();
    final note = _note!.text.trim();
    await _edit((s) => s.copyWith(title: title.isEmpty ? s.title : title, instruction: note));
    if (!mounted) return;
    MuToast.show(context, tone: MuToastTone.success, title: l10n.coaSessionSaved);
    context.canPop() ? context.pop() : context.go(CoachRoutes.builder);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final d = ref.watch(coachDraftProvider).value;
    final found = d == null ? null : DraftOps.find(d, widget.sessionId);
    void back() => context.canPop() ? context.pop() : context.go(CoachRoutes.builder);

    if (d == null || found == null) {
      return Scaffold(
        backgroundColor: c.bg,
        body: Column(
          children: [
            MuTopAppBar.compact(title: l10n.entSession, onBack: back),
            Expanded(
              child: Center(
                child: MuEmptyState(
                  title: l10n.coaSessionGone,
                  description: l10n.coaSessionGoneText,
                  illustration: MuEmptyIllustration.programs,
                ),
              ),
            ),
          ],
        ),
      );
    }
    final (week, s) = found;
    final number = d.numberOf(s);
    _title ??= TextEditingController(text: s.title);
    _note ??= TextEditingController(text: s.instruction);
    if (!_openSet) {
      _openSet = true;
      _open = s.exercises
          .where((e) => e.video == VideoState.uploading || e.video == VideoState.processing)
          .firstOrNull
          ?.id;
    }

    final statusBadge = switch (s.video) {
      VideoState.processing || VideoState.uploading => MuStatusBadge(
        status: MuStatus.pending,
        label: l10n.coaProcessing,
        size: MuBadgeSize.s,
      ),
      VideoState.ready => MuStatusBadge(
        status: MuStatus.confirmed,
        label: l10n.coaReady,
        size: MuBadgeSize.s,
      ),
      VideoState.none => null,
    };

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          CoachPageHeader(
            title: l10n.entLessonEyebrow(number),
            saved: l10n.coaWeekOfProgram(week, d.title),
            onBack: back,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(PhosphorIcons.cloudCheck(), size: MuSize.iconXs, color: c.textSecondary),
                const SizedBox(width: MuSpace.s1),
                Text(l10n.coaSaved, style: MuType.caption.copyWith(color: c.textSecondary)),
                const SizedBox(width: MuSpace.s3),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s2, MuSpace.s4, MuSpace.s6),
              children: [
                MuTextField(
                  label: l10n.coaSessionTitle,
                  controller: _title,
                  maxLength: _titleMax,
                ),
                const SizedBox(height: MuSpace.s6),
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(l10n.coaSessionVideo, style: MuType.h2.copyWith(color: c.text)),
                      ),
                    ),
                    ?statusBadge,
                  ],
                ),
                const SizedBox(height: MuSpace.s3),
                _SessionVideo(session: s, onPick: _pickSessionVideo),
                const SizedBox(height: MuSpace.s6),
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(l10n.entExercises, style: MuType.h2.copyWith(color: c.text)),
                      ),
                    ),
                    Text(
                      '${l10n.entDrills(s.exercises.length)} · ${l10n.entMinutes(s.minutes)}',
                      style: MuType.caption.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: MuSpace.s3),
                ReorderableListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  onReorderItem: (a, b) => _edit((s) => DraftOps.reorderExercises(s, a, b)),
                  children: [
                    for (final (i, e) in s.exercises.indexed)
                      Padding(
                        key: ValueKey(e.id),
                        padding: const EdgeInsets.only(bottom: MuSpace.s3),
                        child: _ExerciseCard(
                          index: i,
                          exercise: e,
                          open: _open == e.id,
                          onToggle: () => setState(() => _open = _open == e.id ? null : e.id),
                          onChanged: (change) => _edit((s) => DraftOps.editExercise(s, e.id, change)),
                          onPickVideo: () => _pickExerciseVideo(e),
                          onRemoveVideo: () => _edit(
                            (s) => DraftOps.editExercise(
                              s,
                              e.id,
                              (e) => DraftExercise(
                                id: e.id,
                                name: e.name,
                                mode: e.mode,
                                sets: e.sets,
                                seconds: e.seconds,
                                reps: e.reps,
                              ),
                            ),
                          ),
                          onDelete: () => _edit((s) => DraftOps.removeExercise(s, e.id)),
                        ),
                      ),
                  ],
                ),
                OutlinedAdd(label: l10n.coaAddExercise, dashed: true, onPressed: () => _addExercises(s, number)),
                const SizedBox(height: MuSpace.s6),
                MuTextField(
                  label: l10n.coaInstruction,
                  optional: true,
                  controller: _note,
                  multiline: true,
                  minLines: 3,
                  maxLength: _noteMax,
                  helper: l10n.coaInstructionHelper,
                ),
              ],
            ),
          ),
          StickyActionBar(
            children: [
              MuButton.primary(
                label: l10n.coaSaveSession,
                size: MuButtonSize.xl,
                fullWidth: true,
                onPressed: _save,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The session's main video: none yet (drop zone), processing, or ready, with its file and
/// « Remplacer ».
class _SessionVideo extends StatelessWidget {
  const _SessionVideo({required this.session, required this.onPick});

  final DraftSession session;
  final VoidCallback onPick;

  static const double _disc = 44;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final s = session;
    if (s.video == VideoState.none) {
      return MuFileUpload.dropzone(
        label: l10n.coaSessionVideo,
        title: l10n.coaAddVideo,
        hint: l10n.coaVideoHintSession,
        onAdd: onPick,
      );
    }
    final processing = s.video == VideoState.processing || s.video == VideoState.uploading;
    return MuCardSurface(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(MuRadius.md)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const MuCourtArt(sport: MuSport.padel),
                  if (processing) ColoredBox(color: c.scrim),
                  Semantics(
                    liveRegion: processing,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: _disc,
                          height: _disc,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: MuPalette.white.withValues(alpha: processing ? 0.2 : 1),
                            border: processing ? Border.all(color: MuPalette.white) : null,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            processing
                                ? PhosphorIcons.hourglassMedium()
                                : PhosphorIcons.play(PhosphorIconsStyle.fill),
                            size: MuSize.iconS,
                            color: processing ? MuPalette.white : MuPalette.ink900,
                          ),
                        ),
                        if (processing) ...[
                          const SizedBox(height: MuSpace.s2),
                          Text(l10n.coaProcessingVideo, style: MuType.labelL.copyWith(color: MuPalette.white)),
                          Text(l10n.coaProcessingDetail, style: MuType.caption.copyWith(color: MuPalette.white)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(MuSpace.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: MuSize.controlM,
                      height: MuSize.controlM,
                      decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: MuRadius.smAll),
                      alignment: Alignment.center,
                      child: Icon(PhosphorIcons.fileVideo(), size: MuSize.iconS, color: c.text),
                    ),
                    const SizedBox(width: MuSpace.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.videoName ?? l10n.coaSessionVideo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: MuType.label.copyWith(color: c.text),
                          ),
                          Text(
                            [
                              if (s.videoBytes != null) formatFileSize(s.videoBytes!),
                              if (s.videoLength != null) formatClock(s.videoLength!),
                              l10n.coaSent,
                            ].join(' · '),
                            style: MuType.caption.copyWith(color: c.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    MuButton.tertiary(label: l10n.coaReplace, size: MuButtonSize.s, onPressed: onPick),
                  ],
                ),
                if (processing) ...[
                  const SizedBox(height: MuSpace.s3),
                  MuProgressBar(
                    indeterminate: true,
                    size: MuProgressSize.s,
                    label: l10n.coaProcessingLabel,
                    valueLabel: l10n.coaAboutAMinute,
                  ),
                  const SizedBox(height: MuSpace.s2),
                  Text(l10n.coaKeepEditing, style: MuType.caption.copyWith(color: c.textSecondary)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// An exercise: handle, video thumbnail (or upload), name, how it is measured; unfolded, its
/// type, duration or repetitions, sets and video.
class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.index,
    required this.exercise,
    required this.open,
    required this.onToggle,
    required this.onChanged,
    required this.onPickVideo,
    required this.onRemoveVideo,
    required this.onDelete,
  });

  final int index;
  final DraftExercise exercise;
  final bool open;
  final VoidCallback onToggle;
  final ValueChanged<DraftExercise Function(DraftExercise e)> onChanged;
  final VoidCallback onPickVideo;
  final VoidCallback onRemoveVideo;
  final VoidCallback onDelete;

  static const double _thumbW = 64;
  static const double _thumbH = 44;
  static const double _ring = 2;
  static const int _secStep = 15;
  static const int _secMax = 180;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final e = exercise;
    final kind = e.mode == DrillMode.time ? l10n.coaDuration : l10n.coaRepetitions;
    final dose = e.mode == DrillMode.time
        ? (e.sets == 1 && e.seconds >= 60
              ? l10n.entMinutes(e.seconds ~/ 60)
              : l10n.coaSecSets(e.seconds, e.sets))
        : l10n.coaRepsSets(e.reps, e.sets);
    final thumb = e.video == VideoState.ready
        ? ClipRRect(
            borderRadius: MuRadius.xsAll,
            child: SizedBox(
              width: _thumbW,
              height: _thumbH,
              child: MuCourtArt(
                sport: MuSport.padel,
                child: e.videoLength == null
                    ? null
                    : Align(
                        alignment: AlignmentDirectional.bottomEnd,
                        child: Padding(
                          padding: const EdgeInsets.all(MuSpace.s1 / 2),
                          child: Text(
                            formatClock(e.videoLength!),
                            style: MuType.numXs.copyWith(color: MuPalette.white),
                          ),
                        ),
                      ),
              ),
            ),
          )
        : Container(
            width: _thumbW,
            height: _thumbH,
            decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: MuRadius.xsAll),
            alignment: Alignment.center,
            child: Icon(
              e.video == VideoState.none ? PhosphorIcons.uploadSimple() : PhosphorIcons.hourglassMedium(),
              size: MuSize.iconS,
              color: c.text,
            ),
          );

    final card = MuCardSurface(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(MuSpace.s1, MuSpace.s2, MuSpace.s1, MuSpace.s2),
              child: Row(
                children: [
                  DragHandle(index: index, label: l10n.coaMoveExercise(e.name)),
                  thumb,
                  const SizedBox(width: MuSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.name, style: MuType.label.copyWith(color: c.text)),
                        Text('$kind · $dose', style: MuType.caption.copyWith(color: c.textSecondary)),
                      ],
                    ),
                  ),
                  MuIconButton(
                    icon: open ? PhosphorIcons.caretUp() : PhosphorIcons.caretDown(),
                    label: open ? l10n.coaFoldExercise(e.name) : l10n.coaEditExercise(e.name),
                    onPressed: onToggle,
                  ),
                ],
              ),
            ),
          ),
          if (open)
            Padding(
              padding: const EdgeInsets.fromLTRB(MuSpace.s4, 0, MuSpace.s4, MuSpace.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _NameField(
                    initial: e.name,
                    onCommit: (v) => onChanged((e) => e.copyWith(name: v)),
                  ),
                  const SizedBox(height: MuSpace.s3),
                  MuSegmentedControl<DrillMode>(
                    semanticLabel: l10n.coaExerciseType,
                    expand: true,
                    value: e.mode,
                    onChanged: (m) => onChanged((e) => e.copyWith(mode: m)),
                    segments: [
                      MuSegment(value: DrillMode.time, label: l10n.coaDuration, icon: PhosphorIcons.timer()),
                      MuSegment(value: DrillMode.reps, label: l10n.coaRepetitions, icon: PhosphorIcons.repeat()),
                    ],
                  ),
                  const SizedBox(height: MuSpace.s3),
                  Row(
                    children: [
                      Expanded(
                        child: e.mode == DrillMode.time
                            ? MuStepper(
                                label: l10n.coaDurationSeconds,
                                // Seconds, by steps of 15: the stepper moves ±1, we jump to the next
                                // multiple of 15.
                                value: e.seconds.clamp(_secStep, _secMax),
                                min: _secStep,
                                max: _secMax,
                                layout: MuStepperLayout.stacked,
                                size: MuStepperSize.s,
                                decrementLabel: l10n.coaRemoveSeconds(_secStep),
                                incrementLabel: l10n.coaAddSeconds(_secStep),
                                onChanged: (v) => onChanged(
                                  (e) => e.copyWith(
                                    seconds: (v > e.seconds
                                            ? (e.seconds ~/ _secStep + 1) * _secStep
                                            : ((e.seconds - 1) ~/ _secStep) * _secStep)
                                        .clamp(_secStep, _secMax),
                                  ),
                                ),
                              )
                            : MuStepper(
                                label: l10n.coaRepetitions,
                                value: e.reps,
                                min: 1,
                                max: 50,
                                layout: MuStepperLayout.stacked,
                                size: MuStepperSize.s,
                                decrementLabel: l10n.entRemoveRep(l10n.entOneRep),
                                incrementLabel: l10n.entAddRep(l10n.entOneRep),
                                onChanged: (v) => onChanged((e) => e.copyWith(reps: v)),
                              ),
                      ),
                      const SizedBox(width: MuSpace.s3),
                      Expanded(
                        child: MuStepper(
                          label: l10n.coaSets,
                          value: e.sets,
                          min: 1,
                          max: 10,
                          layout: MuStepperLayout.stacked,
                          size: MuStepperSize.s,
                          decrementLabel: l10n.coaRemoveSet,
                          incrementLabel: l10n.coaAddSet,
                          onChanged: (v) => onChanged((e) => e.copyWith(sets: v)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: MuSpace.s3),
                  MuFileUpload.dropzone(
                    label: l10n.coaExerciseVideo,
                    title: l10n.coaAddVideo,
                    hint: l10n.coaVideoHintExercise,
                    onAdd: e.video == VideoState.uploading ? null : onPickVideo,
                    files: [
                      if (e.fileName != null)
                        MuUploadFile(
                          id: e.id,
                          name: e.fileName!,
                          sizeBytes: e.fileBytes ?? 0,
                          status: e.video == VideoState.uploading
                              ? MuUploadStatus.uploading
                              : MuUploadStatus.done,
                          progress: e.uploadProgress,
                        ),
                    ],
                    onRemove: (_) => onRemoveVideo(),
                  ),
                  const SizedBox(height: MuSpace.s2),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: MuButton.tertiary(
                      label: l10n.coaDeleteExercise,
                      leading: PhosphorIcons.trash(),
                      size: MuButtonSize.s,
                      onPressed: onDelete,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
    if (!open) return card;
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: MuRadius.mdAll,
        border: Border.all(color: c.primary, width: _ring),
      ),
      child: card,
    );
  }
}

/// The exercise's name, kept while typing; saved on « Entrée » or when the field loses focus.
class _NameField extends StatefulWidget {
  const _NameField({required this.initial, required this.onCommit});

  final String initial;
  final ValueChanged<String> onCommit;

  @override
  State<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<_NameField> {
  late final _text = TextEditingController(text: widget.initial);
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) _commit();
    });
  }

  void _commit() {
    final v = _text.text.trim();
    if (v.isNotEmpty && v != widget.initial) widget.onCommit(v);
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MuTextField(
    label: l10n.coaExerciseName,
    size: MuFieldSize.m,
    controller: _text,
    focusNode: _focus,
    maxLength: 60,
    onSubmitted: (_) => _commit(),
  );
}
