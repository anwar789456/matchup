import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/clock.dart';
import '../../../core/format.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../controllers/training_providers.dart';
import '../data/training_models.dart';
import '../data/training_story.dart';
import '../training_routes.dart';
import '../widgets/training_video_player.dart';

/// ENT-04 · Séance: the exercise's video, instructions and coach tip, the set counter and rest
/// timer, private notes, what comes next, and « Marquer comme fait ». Night match in both themes.
class LessonScreen extends ConsumerWidget {
  const LessonScreen({super.key, required this.programId, required this.index});

  final String programId;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final program = ref.watch(programProvider(programId));
    final lesson = program?.lessons.where((l) => l.index == index).firstOrNull;
    return MuNightTheme(
      child: Builder(
        builder: (context) {
          if (program == null || lesson == null) {
            final c = context.mu;
            return Scaffold(
              backgroundColor: c.bg,
              body: Column(
                children: [
                  MuTopAppBar.compact(
                    title: l10n.entSession,
                    onBack: () => context.canPop() ? context.pop() : context.go(TrainingRoutes.root),
                  ),
                  if (ref.watch(programsProvider).isLoading)
                    const Expanded(child: Center(child: MuSpinner()))
                  else
                    Expanded(
                      child: Center(
                        child: MuEmptyState(
                          title: l10n.entProgramGone,
                          description: l10n.entProgramGoneText,
                          illustration: MuEmptyIllustration.programs,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }
          return _Player(program: program, lesson: lesson);
        },
      ),
    );
  }
}

class _Player extends ConsumerStatefulWidget {
  const _Player({required this.program, required this.lesson});

  final TrainingProgram program;
  final TrainingLesson lesson;

  @override
  ConsumerState<_Player> createState() => _PlayerState();
}

class _PlayerState extends ConsumerState<_Player> {
  final _started = DateTime.now();
  final _notes = TextEditingController();
  final _scroll = ScrollController();
  Timer? _ticker;

  int _current = 0;

  /// Exercises marked done (not skipped).
  final Set<int> _done = {};

  /// Reps of each finished set, per exercise.
  final Map<int, List<int>> _sets = {};

  /// Reps of the set in progress, per exercise.
  final Map<int, int> _reps = {};

  /// When the rest in progress ends (null: no rest running).
  DateTime? _restEnds;
  bool _saving = false;

  // ENT-04: notes up to 280 characters; « 9 min sur 22 » refreshed every few seconds.
  static const _notesMax = 280;
  static const _tick = Duration(seconds: 1);

  List<Exercise> get _exercises => widget.lesson.exercises;
  Exercise get _exercise => _exercises[_current];

  int get _setIndex => (_sets[_current] ?? const []).length;

  int get _elapsedMinutes => DateTime.now().difference(_started).inMinutes;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(_tick, (_) {
      if (!mounted) return;
      final ends = _restEnds;
      if (ends != null && !DateTime.now().isBefore(ends)) _restEnds = null;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _notes.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _show(int i) {
    if (i < 0 || i >= _exercises.length) return;
    setState(() {
      _current = i;
      _restEnds = null;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  /// « Lancer »: the set is recorded and the rest starts; the next set's counter starts at 0.
  void _startRest() {
    final e = _exercise;
    setState(() {
      if (e.reps != null && _setIndex < e.sets) {
        _sets[_current] = [...?_sets[_current], _reps[_current] ?? 0];
        _reps[_current] = 0;
      }
      _restEnds = DateTime.now().add(e.rest);
    });
  }

  /// Reps of [i] counting the set in progress.
  int _total(int i) =>
      (_sets[i] ?? const []).fold(0, (a, b) => a + b) +
      ((_sets[i]?.length ?? 0) < _exercises[i].sets ? (_reps[i] ?? 0) : 0);

  Future<void> _next({required bool done}) async {
    if (done) _done.add(_current);
    if (_current < _exercises.length - 1) {
      _show(_current + 1);
      return;
    }
    await _finish();
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    final key = _exercises.indexWhere((e) => e.counted);
    final result = LessonResult(
      programId: widget.program.id,
      index: widget.lesson.index,
      doneAt: ref.read(clockProvider)(),
      minutes: _elapsedMinutes < 1 ? 1 : _elapsedMinutes,
      drillsDone: _done.length,
      drillsTotal: _exercises.length,
      reps: key < 0 ? null : _total(key),
      target: key < 0 ? null : _exercises[key].target,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );
    await ref.read(trainingProgressProvider.notifier).completeLesson(result);
    if (!mounted) return;
    context.pushReplacement(TrainingRoutes.lessonDone(widget.program.id, widget.lesson.index));
  }

  void _quit() => context.canPop() ? context.pop() : context.go(TrainingRoutes.root);

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final e = _exercise;
    final coach = TrainingStory.coach(widget.program.coachId);
    final firstName = coach.name.split(' ').first;
    final next = _current + 1 < _exercises.length ? _exercises[_current + 1] : null;

    final details = <String>[
      e.reps == null ? e.dose : l10n.entSetsOf(e.sets, e.reps!),
      if (e.rest > Duration.zero) l10n.entRestBetween(e.rest.inSeconds),
      ?e.setup,
    ].join(' · ');

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: EdgeInsets.zero,
              children: [
                _VideoHeader(
                  exercises: _exercises,
                  current: _current,
                  sport: widget.program.sport,
                  label: l10n.entSessionVideos(widget.lesson.index, widget.lesson.title),
                  onClose: _quit,
                  onShare: () => SharePlus.instance.share(
                    ShareParams(text: l10n.entShareExercise(e.title, widget.program.title)),
                  ),
                  onPlay: () => showTrainingVideo(
                    context,
                    title: e.title,
                    videoKey: '${widget.program.id}/${widget.lesson.index}/$_current',
                    sport: widget.program.sport,
                    loop: true,
                  ),
                  onIndex: _show,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s5, MuSpace.s4, MuSpace.s6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.entLessonLabel(widget.lesson.index, widget.lesson.title).toUpperCase(),
                              style: MuType.overline.copyWith(color: c.textSecondary),
                            ),
                          ),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: l10n.entMinutes(_elapsedMinutes),
                                  style: MuType.labelS.copyWith(color: c.text),
                                ),
                                TextSpan(
                                  text: ' ${l10n.entOutOf(widget.lesson.minutes)}',
                                  style: MuType.caption.copyWith(color: c.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: MuSpace.s2),
                      Semantics(
                        label: l10n.entDrillsDone(_done.length, _exercises.length),
                        excludeSemantics: true,
                        child: MuProgressBar(
                          value: _done.length.toDouble(),
                          max: _exercises.length.toDouble(),
                          variant: MuProgressVariant.segmented,
                          size: MuProgressSize.s,
                          showValue: false,
                          tone: MuTone.primary,
                        ),
                      ),
                      const SizedBox(height: MuSpace.s5),
                      Semantics(
                        header: true,
                        child: Text(e.title, style: MuType.h2.copyWith(color: c.text)),
                      ),
                      const SizedBox(height: MuSpace.s2),
                      Text(details, style: MuType.body.copyWith(color: c.textSecondary)),
                      if (e.steps.isNotEmpty) ...[
                        const SizedBox(height: MuSpace.s4),
                        for (final (i, step) in e.steps.indexed)
                          Padding(
                            padding: const EdgeInsets.only(bottom: MuSpace.s3),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: MuSize.iconM,
                                  height: MuSize.iconM,
                                  decoration: BoxDecoration(
                                    color: c.surfaceMuted,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text('${i + 1}', style: MuType.labelS.copyWith(color: c.text)),
                                ),
                                const SizedBox(width: MuSpace.s3),
                                Expanded(
                                  child: Text(step, style: MuType.body.copyWith(color: c.text)),
                                ),
                              ],
                            ),
                          ),
                      ],
                      if (e.tip != null) ...[
                        const SizedBox(height: MuSpace.s1),
                        _CoachTip(coach: coach, firstName: firstName, tip: e.tip!),
                      ],
                      const SizedBox(height: MuSpace.s5),
                      if (e.reps != null) ...[
                        _SetCounter(
                          exercise: e,
                          setIndex: _setIndex,
                          reps: _reps[_current] ?? 0,
                          onChanged: (v) => setState(() => _reps[_current] = v),
                        ),
                        const SizedBox(height: MuSpace.s3),
                      ],
                      if (e.rest > Duration.zero) ...[
                        _RestTimer(
                          rest: e.rest,
                          endsAt: _restEnds,
                          canStart: e.reps == null || _setIndex < e.sets,
                          onStart: _startRest,
                          onSkip: () => setState(() => _restEnds = null),
                        ),
                        const SizedBox(height: MuSpace.s5),
                      ],
                      MuTextField(
                        label: l10n.entMyNotes,
                        controller: _notes,
                        multiline: true,
                        minLines: 2,
                        maxLines: 6,
                        maxLength: _notesMax,
                        helper: l10n.entNotesHelper(firstName),
                      ),
                      if (next != null) ...[
                        const SizedBox(height: MuSpace.s5),
                        _NextCard(
                          index: _current + 2,
                          exercise: next,
                          onTap: () => context.push(TrainingRoutes.program(widget.program.id)),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: c.bg,
              border: Border(top: BorderSide(color: c.border)),
            ),
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: MuSpace.s3),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(MuSpace.s4, MuSpace.s3, MuSpace.s4, 0),
                child: Row(
                  children: [
                    MuIconButton(
                      icon: PhosphorIcons.skipForward(),
                      label: l10n.entSkipExercise,
                      variant: MuIconButtonVariant.secondary,
                      size: MuIconButtonSize.l,
                      onPressed: _saving ? null : () => _next(done: false),
                    ),
                    const SizedBox(width: MuSpace.s3),
                    Expanded(
                      child: MuButton.primary(
                        label: l10n.entMarkDone,
                        leading: PhosphorIcons.check(PhosphorIconsStyle.bold),
                        size: MuButtonSize.l,
                        fullWidth: true,
                        loading: _saving,
                        onPressed: _saving ? null : () => _next(done: true),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The exercise's video (poster until playback comes with the backend): close, « 2 / 4 », share,
/// previous / next, play, duration, then the page dots.
class _VideoHeader extends StatelessWidget {
  const _VideoHeader({
    required this.exercises,
    required this.current,
    required this.sport,
    required this.label,
    required this.onClose,
    required this.onShare,
    required this.onPlay,
    required this.onIndex,
  });

  final List<Exercise> exercises;
  final int current;
  final MuSport sport;
  final String label;
  final VoidCallback onClose;
  final VoidCallback onShare;
  final VoidCallback onPlay;
  final ValueChanged<int> onIndex;

  // ENT-04: video 16:9 under the bar; play disc 56, arrows 40, dots 6 (current 20 wide).
  static const double _play = 56;
  static const double _playIcon = 28;
  static const double _dot = 6;
  static const double _dotCurrent = 20;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final e = exercises[current];
    return Semantics(
      container: true,
      label: label,
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: SizedBox(
              height: MuSize.appBar,
              child: Row(
                children: [
                  const SizedBox(width: MuSpace.s1),
                  MuIconButton(
                    icon: PhosphorIcons.x(),
                    label: l10n.entQuitSession,
                    size: MuIconButtonSize.l,
                    onPressed: onClose,
                  ),
                  Expanded(
                    child: Text(
                      ltr('${current + 1} / ${exercises.length}'),
                      textAlign: TextAlign.center,
                      style: MuType.labelS.copyWith(color: c.text),
                    ),
                  ),
                  MuIconButton(
                    icon: PhosphorIcons.shareNetwork(),
                    label: l10n.entShareExerciseLabel,
                    size: MuIconButtonSize.l,
                    onPressed: onShare,
                  ),
                  const SizedBox(width: MuSpace.s1),
                ],
              ),
            ),
          ),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                MuCourtArt(sport: sport, semanticLabel: l10n.entVideoOf(e.title)),
                Center(
                  child: Semantics(
                    button: true,
                    label: l10n.entPlayVideo(formatClock(e.video)),
                    excludeSemantics: true,
                    child: Material(
                      // A media overlay: the same white disc in both themes.
                      color: MuPalette.white,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onPlay,
                        child: SizedBox.square(
                          dimension: _play,
                          child: Icon(
                            PhosphorIcons.play(PhosphorIconsStyle.fill),
                            size: _playIcon,
                            color: MuPalette.ink900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                PositionedDirectional(
                  start: MuSpace.s3,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: MuIconButton(
                      icon: PhosphorIcons.caretLeft(),
                      label: l10n.entPreviousExercise,
                      variant: MuIconButtonVariant.onMedia,
                      onPressed: current == 0 ? null : () => onIndex(current - 1),
                    ),
                  ),
                ),
                PositionedDirectional(
                  end: MuSpace.s3,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: MuIconButton(
                      icon: PhosphorIcons.caretRight(),
                      label: l10n.entNextExercise,
                      variant: MuIconButtonVariant.onMedia,
                      onPressed: current == exercises.length - 1 ? null : () => onIndex(current + 1),
                    ),
                  ),
                ),
                PositionedDirectional(
                  end: MuSpace.s3,
                  bottom: MuSpace.s3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: MuSpace.s2, vertical: MuSpace.s1 / 2),
                    decoration: const ShapeDecoration(
                      color: MuPalette.white,
                      shape: StadiumBorder(),
                    ),
                    child: Text(
                      formatClock(e.video),
                      style: MuType.numXs.copyWith(color: MuPalette.ink900),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: MuSpace.s4),
          ExcludeSemantics(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < exercises.length; i++)
                  Container(
                    width: i == current ? _dotCurrent : _dot,
                    height: _dot,
                    margin: const EdgeInsets.symmetric(horizontal: MuSpace.s1 / 2),
                    decoration: ShapeDecoration(
                      color: i == current ? c.accent : c.textSecondary,
                      shape: const StadiumBorder(),
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

/// « Le conseil de Karim ».
class _CoachTip extends StatelessWidget {
  const _CoachTip({required this.coach, required this.firstName, required this.tip});

  final MuCoach coach;
  final String firstName;
  final String tip;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Container(
      padding: const EdgeInsets.all(MuSpace.s3),
      decoration: BoxDecoration(color: c.surface, borderRadius: MuRadius.mdAll),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MuAvatar(name: coach.name, size: MuAvatarSize.s),
          const SizedBox(width: MuSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.entCoachTip(firstName), style: MuType.caption.copyWith(color: c.textSecondary)),
                const SizedBox(height: MuSpace.s1 / 2),
                Text(tip, style: MuType.body.copyWith(color: c.text)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// « Série 2 sur 3 », the sets as dashes, and the reps stepper with its target.
class _SetCounter extends StatelessWidget {
  const _SetCounter({
    required this.exercise,
    required this.setIndex,
    required this.reps,
    required this.onChanged,
  });

  final Exercise exercise;
  final int setIndex;
  final int reps;
  final ValueChanged<int> onChanged;

  static const double _dashW = 20;
  static const double _dashH = 6;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final e = exercise;
    final finished = setIndex >= e.sets;
    final shown = finished ? e.sets : setIndex + 1;
    final noun = e.counterNoun ?? l10n.entOneRep;
    return Container(
      padding: const EdgeInsets.all(MuSpace.s4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: MuRadius.mdAll,
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  finished ? l10n.entAllSetsDone : l10n.entSetOf(shown, e.sets),
                  style: MuType.labelL.copyWith(color: c.text),
                ),
              ),
              ExcludeSemantics(
                child: Row(
                  children: [
                    for (var i = 0; i < e.sets; i++)
                      Container(
                        width: _dashW,
                        height: _dashH,
                        margin: const EdgeInsetsDirectional.only(start: MuSpace.s1),
                        decoration: ShapeDecoration(
                          color: i < setIndex
                              ? c.accent
                              : i == setIndex
                              ? c.text
                              : c.border,
                          shape: const StadiumBorder(),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (!finished) ...[
            const SizedBox(height: MuSpace.s3),
            MuStepper(
              value: reps,
              min: 0,
              max: e.reps!,
              label: e.counterLabel ?? l10n.entRepsDone,
              helper: (_) => l10n.entTarget(e.reps!),
              decrementLabel: l10n.entRemoveRep(noun),
              incrementLabel: l10n.entAddRep(noun),
              onChanged: onChanged,
            ),
          ],
        ],
      ),
    );
  }
}

/// « Repos entre les séries · 00:45 » and « Lancer » (then the countdown and « Passer »).
class _RestTimer extends StatelessWidget {
  const _RestTimer({
    required this.rest,
    required this.endsAt,
    required this.canStart,
    required this.onStart,
    required this.onSkip,
  });

  final Duration rest;
  final DateTime? endsAt;
  final bool canStart;
  final VoidCallback onStart;
  final VoidCallback onSkip;

  static String _clock(Duration d) {
    final s = d.inSeconds < 0 ? 0 : d.inSeconds;
    return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final running = endsAt != null;
    final left = running ? endsAt!.difference(DateTime.now()) + const Duration(milliseconds: 999) : rest;
    return Container(
      padding: const EdgeInsets.all(MuSpace.s4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: MuRadius.mdAll,
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(PhosphorIcons.timer(), size: MuSize.iconS, color: c.textSecondary),
                    const SizedBox(width: MuSpace.s2),
                    Text(l10n.entRestBetweenSets, style: MuType.caption.copyWith(color: c.textSecondary)),
                  ],
                ),
                const SizedBox(height: MuSpace.s1),
                Semantics(
                  liveRegion: running,
                  label: l10n.entRestLeft(left.inSeconds < 0 ? 0 : left.inSeconds),
                  excludeSemantics: true,
                  child: Text(
                    _clock(left),
                    style: MuType.numL.copyWith(color: running ? c.accent : c.text),
                  ),
                ),
              ],
            ),
          ),
          running
              ? MuButton.secondary(label: l10n.entSkipRest, onPressed: onSkip)
              : MuButton.secondary(
                  label: l10n.entStartRest,
                  leading: PhosphorIcons.play(PhosphorIconsStyle.fill),
                  onPressed: canStart ? onStart : null,
                ),
        ],
      ),
    );
  }
}

/// « Ensuite »: the next exercise.
class _NextCard extends StatelessWidget {
  const _NextCard({required this.index, required this.exercise, required this.onTap});

  final int index;
  final Exercise exercise;
  final VoidCallback onTap;

  static const double _circle = 36;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final e = exercise;
    final line = l10n.entNextLine(
      e.reps == null ? e.dose : l10n.entSetsOf(e.sets, e.reps!),
      formatClock(e.video),
    );
    return Material(
      color: c.surface,
      borderRadius: MuRadius.mdAll,
      child: InkWell(
        borderRadius: MuRadius.mdAll,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(MuSpace.s3),
          decoration: BoxDecoration(
            borderRadius: MuRadius.mdAll,
            border: Border.all(color: c.border),
          ),
          child: Semantics(
            label: '${l10n.entNext}, ${e.title}, $line',
            excludeSemantics: true,
            child: Row(
              children: [
                Container(
                  width: _circle,
                  height: _circle,
                  decoration: BoxDecoration(color: c.surfaceMuted, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text('$index', style: MuType.numS.copyWith(color: c.text)),
                ),
                const SizedBox(width: MuSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.entNext, style: MuType.caption.copyWith(color: c.textSecondary)),
                      Text(e.title, style: MuType.label.copyWith(color: c.text)),
                      Text(line, style: MuType.caption.copyWith(color: c.textSecondary)),
                    ],
                  ),
                ),
                Icon(PhosphorIcons.listChecks(), size: MuSize.iconS, color: c.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
