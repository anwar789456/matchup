import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/format.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../data/coach_models.dart';
import '../data/coach_story.dart';

IconData drillIcon(DrillMode m) =>
    m == DrillMode.time ? PhosphorIcons.timer() : PhosphorIcons.repeat();

/// « 45 s × 6 », « 12 rép. × 3 », « 3 min » (a single long set).
String drillDose(DrillMode mode, {required int seconds, required int reps, required int sets}) {
  if (mode == DrillMode.reps) return l10n.coaRepsTimes(reps, sets);
  if (sets == 1 && seconds >= 60) return l10n.entMinutes(seconds ~/ 60);
  return seconds >= 60 && seconds % 60 == 0
      ? l10n.coaMinTimes(seconds ~/ 60, sets)
      : l10n.coaSecTimes(seconds, sets);
}

/// « 45 s × 6 · vidéo 0:52 », « … · vidéo : envoi 64 % », « … · sans vidéo ».
String exerciseMeta(DraftExercise e) {
  final dose = drillDose(e.mode, seconds: e.seconds, reps: e.reps, sets: e.sets);
  final video = switch (e.video) {
    VideoState.none => l10n.coaNoVideo,
    VideoState.uploading => l10n.coaVideoUploading((e.uploadProgress * 100).round()),
    VideoState.processing => l10n.coaVideoProcessing,
    VideoState.ready => e.videoLength == null
        ? l10n.coaVideoReady
        : l10n.coaVideoLength(formatClock(e.videoLength!)),
  };
  return '$dose · $video';
}

/// « Ajouter un exercice »: the coach's library with search and categories, several picks at
/// once, or « Créer un nouvel exercice » (returns an empty list and [createNew] true).
Future<({List<LibraryExercise> picked, bool createNew})?> showAddExerciseSheet(
  BuildContext context, {
  required String sessionLabel,
}) {
  return MuBottomSheet.show<({List<LibraryExercise> picked, bool createNew})>(
    context,
    title: l10n.coaAddExercise,
    height: MuSheetHeight.full,
    child: _AddExercise(sessionLabel: sessionLabel),
  );
}

class _AddExercise extends StatefulWidget {
  const _AddExercise({required this.sessionLabel});

  final String sessionLabel;

  @override
  State<_AddExercise> createState() => _AddExerciseState();
}

class _AddExerciseState extends State<_AddExercise> {
  final Set<String> _picked = {};
  String _query = '';
  String? _category;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    const lib = CoachStory.library;
    final q = _query.trim().toLowerCase();
    final shown = [
      for (final e in lib)
        if ((_category == null || e.category == _category) &&
            (q.isEmpty || e.name.toLowerCase().contains(q)))
          e,
    ];
    final n = _picked.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(MuSpace.s4, 0, MuSpace.s4, MuSpace.s3),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '${l10n.coaIn} '),
                TextSpan(text: widget.sessionLabel, style: MuType.label),
              ],
            ),
            style: MuType.body.copyWith(color: c.textSecondary),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
          child: MuSearchField<String>(
            label: l10n.coaSearchExercise,
            placeholder: l10n.coaSearchExercise,
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        const SizedBox(height: MuSpace.s3),
        Semantics(
          container: true,
          label: l10n.coaExerciseCategory,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
            child: Row(
              children: [
                MuChip(
                  kind: MuChipKind.choice,
                  label: l10n.coaAllCount(lib.length),
                  selected: _category == null,
                  onSelected: (_) => setState(() => _category = null),
                ),
                for (final cat in CoachStory.categories) ...[
                  const SizedBox(width: MuSpace.s2),
                  MuChip(
                    kind: MuChipKind.choice,
                    label: cat,
                    selected: _category == cat,
                    onSelected: (_) => setState(() => _category = cat),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: MuSpace.s2),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: MuSpace.s4),
            children: [
              for (final (i, e) in shown.indexed) ...[
                if (i > 0) Divider(height: 1, thickness: 1, color: c.border),
                InkWell(
                  onTap: () => setState(() => _picked.contains(e.id) ? _picked.remove(e.id) : _picked.add(e.id)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: MuSpace.s3),
                    child: Row(
                      children: [
                        Container(
                          width: MuSize.controlM,
                          height: MuSize.controlM,
                          decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: MuRadius.smAll),
                          alignment: Alignment.center,
                          child: Icon(drillIcon(e.mode), size: MuSize.iconS, color: c.text),
                        ),
                        const SizedBox(width: MuSpace.s3),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.name, style: MuType.label.copyWith(color: c.text)),
                              Text(
                                '${drillDose(e.mode, seconds: e.seconds, reps: e.reps, sets: e.sets)} · '
                                '${e.videoLength == null ? l10n.coaNoVideo : l10n.coaVideoLength(formatClock(e.videoLength!))}',
                                style: MuType.caption.copyWith(color: c.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        MuCheckbox(
                          value: _picked.contains(e.id),
                          semanticLabel: l10n.coaAddThis(e.name),
                          onChanged: (v) => setState(() => v == true ? _picked.add(e.id) : _picked.remove(e.id)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              Divider(height: 1, thickness: 1, color: c.border),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: MuButton.tertiary(
                  label: l10n.coaCreateExercise,
                  leading: PhosphorIcons.plusCircle(),
                  onPressed: () => Navigator.of(context).pop((picked: <LibraryExercise>[], createNew: true)),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(MuSpace.s4),
          child: MuButton.primary(
            label: n == 0 ? l10n.coaPickExercise : l10n.coaAddExercises(n),
            size: MuButtonSize.xl,
            fullWidth: true,
            onPressed: n == 0
                ? null
                : () => Navigator.of(context).pop((
                    picked: [for (final e in lib) if (_picked.contains(e.id)) e],
                    createNew: false,
                  )),
          ),
        ),
      ],
    );
  }
}

/// A drag handle for the reorderable lists (« Maintiens la poignée… »).
class DragHandle extends StatelessWidget {
  const DragHandle({super.key, required this.index, required this.label});

  final int index;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    return Semantics(
      label: label,
      child: ReorderableDragStartListener(
        index: index,
        child: SizedBox(
          width: MuSpace.s6,
          height: MuSize.touchTarget,
          child: Icon(PhosphorIcons.dotsSixVertical(), size: MuSize.iconS, color: c.textSecondary),
        ),
      ),
    );
  }
}
