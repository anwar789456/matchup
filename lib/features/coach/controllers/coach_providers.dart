import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/theme.dart';

import '../data/coach_models.dart';
import '../data/coach_repository.dart';

final coachStudentsProvider = FutureProvider<List<CoachStudent>>(
  (ref) => ref.watch(coachRepositoryProvider).students(),
);

final coachStudentProvider = Provider.family<CoachStudent?, String>(
  (ref, id) => ref.watch(coachStudentsProvider).value?.where((s) => s.id == id).firstOrNull,
);

/// The « À traiter » items handled (and the AI suggestion when dismissed).
class CoachHandledController extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() => ref.watch(coachRepositoryProvider).handled();

  Future<void> handle(String id) async {
    await ref.read(coachRepositoryProvider).handle(id);
    state = AsyncData({...?state.value, id});
  }
}

final coachHandledProvider = AsyncNotifierProvider<CoachHandledController, Set<String>>(
  CoachHandledController.new,
);

/// Whether the fake server moves uploads and processing forward (off in widget tests).
final coachFakeServerProvider = Provider<bool>((ref) => true);

/// The program being written (COA-06…08), saved after each change (« Brouillon enregistré »).
/// Videos « en traitement » finish on the server; the fake processing ends after [processing].
class CoachDraftController extends AsyncNotifier<ProgramDraft?> {
  Timer? _processing;
  Timer? _upload;

  /// How long the fake server takes to process a video.
  static Duration processing = const Duration(seconds: 8);
  static const _uploadTick = Duration(milliseconds: 250);

  @override
  Future<ProgramDraft?> build() async {
    ref.onDispose(() {
      _processing?.cancel();
      _upload?.cancel();
    });
    final d = await ref.watch(coachRepositoryProvider).draft();
    _scheduleProcessing(d);
    _scheduleUploads(d);
    return d;
  }

  Future<void> edit(ProgramDraft Function(ProgramDraft d) change) async {
    final d = state.value;
    if (d == null) return;
    final next = change(d).copyWith(updatedAt: ref.read(clockProvider)());
    state = AsyncData(next);
    await ref.read(coachRepositoryProvider).saveDraft(next);
    _scheduleProcessing(next);
    _scheduleUploads(next);
  }

  /// Applies [change] to one session.
  Future<void> editSession(String sessionId, DraftSession Function(DraftSession s) change) =>
      edit(
        (d) => d.copyWith(
          weeks: [
            for (final w in d.weeks)
              w.copyWith(
                sessions: [for (final s in w.sessions) s.id == sessionId ? change(s) : s],
              ),
          ],
        ),
      );

  /// « Créer »: a blank program (one empty week) when none is being written.
  Future<void> create() async {
    if (state.value != null) return;
    final now = ref.read(clockProvider)();
    final d = ProgramDraft(
      id: 'programme-${now.millisecondsSinceEpoch}',
      title: l10n.coaNewProgram,
      sport: MuSport.padel,
      levelMin: 2.5,
      levelMax: 4.0,
      updatedAt: now,
      weeks: [DraftWeek(id: 'w-${now.microsecondsSinceEpoch}', title: l10n.coaNewWeek, sessions: const [])],
    );
    state = AsyncData(d);
    await ref.read(coachRepositoryProvider).saveDraft(d);
  }

  Future<void> delete() async {
    await ref.read(coachRepositoryProvider).deleteDraft();
    state = const AsyncData(null);
  }

  void _scheduleProcessing(ProgramDraft? d) {
    _processing?.cancel();
    if (d == null || !ref.read(coachFakeServerProvider)) return;
    final waiting = d.sessions.any(
      (s) =>
          s.video == VideoState.processing ||
          s.exercises.any((e) => e.video == VideoState.processing),
    );
    if (!waiting) return;
    _processing = Timer(processing, () {
      edit(
        (d) => d.copyWith(
          weeks: [
            for (final w in d.weeks)
              w.copyWith(
                sessions: [
                  for (final s in w.sessions)
                    s.copyWith(
                      video: s.video == VideoState.processing ? VideoState.ready : s.video,
                      exercises: [
                        for (final e in s.exercises)
                          e.video == VideoState.processing ? e.copyWith(video: VideoState.ready) : e,
                      ],
                    ),
                ],
              ),
          ],
        ),
      );
    });
  }

  /// Exercise uploads in progress go on (4 % per tick), then turn to processing.
  void _scheduleUploads(ProgramDraft? d) {
    _upload?.cancel();
    if (d == null || !ref.read(coachFakeServerProvider)) return;
    if (!d.sessions.any((s) => s.exercises.any((e) => e.video == VideoState.uploading))) return;
    _upload = Timer(_uploadTick, () {
      final cur = state.value;
      if (cur == null) return;
      final next = cur.copyWith(
        weeks: [
          for (final w in cur.weeks)
            w.copyWith(
              sessions: [
                for (final s in w.sessions)
                  s.copyWith(
                    exercises: [
                      for (final e in s.exercises)
                        if (e.video != VideoState.uploading)
                          e
                        else if (e.uploadProgress + 0.04 >= 1)
                          e.copyWith(video: VideoState.processing, uploadProgress: 1)
                        else
                          e.copyWith(uploadProgress: e.uploadProgress + 0.04),
                    ],
                  ),
              ],
            ),
        ],
      );
      state = AsyncData(next);
      final stillUploading = next.sessions.any(
        (s) => s.exercises.any((e) => e.video == VideoState.uploading),
      );
      if (stillUploading) {
        _scheduleUploads(next);
      } else {
        ref.read(coachRepositoryProvider).saveDraft(next);
        _scheduleProcessing(next);
      }
    });
  }
}

final coachDraftProvider = AsyncNotifierProvider<CoachDraftController, ProgramDraft?>(
  CoachDraftController.new,
);

/// The feedback already sent on a student's video.
final coachFeedbackProvider = FutureProvider.family<CoachFeedback?, String>(
  (ref, studentId) => ref.watch(coachRepositoryProvider).feedback(studentId),
);
