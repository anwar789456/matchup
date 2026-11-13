import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../../../ui/ui.dart';
import '../../common/data/file_services.dart';
import '../../common/data/pro_providers.dart' show fileSourceProvider;
import '../data/training_models.dart';
import '../data/training_repository.dart';
import '../data/video_analyst.dart';

/// Where the video analysis stands (ENT-08): the move, the clip being sent, the AI's steps, and
/// the result (ENT-09) once the last step is done.
@immutable
class VideoAnalysisState {
  const VideoAnalysisState({
    this.move = VideoMove.bandeja,
    this.file,
    this.share = false,
    this.step = idle,
    this.result,
    this.error,
  });

  /// No clip sent yet.
  static const idle = -1;

  final VideoMove move;
  final MuUploadFile? file;
  final bool share;

  /// The running step (0-based) of the [VideoAnalyst.stepCount]; the count once done.
  final int step;
  final VideoAnalysis? result;

  /// Why the clip was refused (too big, wrong format).
  final String? error;

  bool get uploading => file?.status == MuUploadStatus.uploading;
  bool get analysing => step >= 0 && step < VideoAnalyst.stepCount;
  bool get done => result != null && step >= VideoAnalyst.stepCount;

  VideoAnalysisState copyWith({
    VideoMove? move,
    MuUploadFile? Function()? file,
    bool? share,
    int? step,
    VideoAnalysis? Function()? result,
    String? Function()? error,
  }) => VideoAnalysisState(
    move: move ?? this.move,
    file: file == null ? this.file : file(),
    share: share ?? this.share,
    step: step ?? this.step,
    result: result == null ? this.result : result(),
    error: error == null ? this.error : error(),
  );
}

/// The pace of the fake upload and AI steps (shorter in tests).
@immutable
class VideoAnalysisTiming {
  const VideoAnalysisTiming({
    this.upload = const Duration(milliseconds: 1500),
    this.step = const Duration(milliseconds: 1800),
  });

  final Duration upload;
  final Duration step;
}

final videoAnalysisTimingProvider = Provider<VideoAnalysisTiming>(
  (ref) => const VideoAnalysisTiming(),
);

/// Runs one analysis at a time and keeps running when the player leaves ENT-08 (« Me
/// prévenir »): ENT-01's video card shows the progress, then « prête ».
class VideoAnalysisController extends Notifier<VideoAnalysisState> {
  Timer? _timer;

  // ENT-08: « MP4, MOV · 60 s · 100 Mo max ».
  static const maxBytes = 100 * 1000 * 1000;
  static const extensions = ['mp4', 'mov'];
  static const _uploadTicks = 10;

  @override
  VideoAnalysisState build() {
    ref.onDispose(() => _timer?.cancel());
    return const VideoAnalysisState();
  }

  void setMove(VideoMove move) {
    if (state.step != VideoAnalysisState.idle) return;
    state = state.copyWith(move: move);
  }

  void setShare(bool share) => state = state.copyWith(share: share);

  /// « Filme ou choisis une vidéo »: picks, checks, then sends the clip.
  Future<void> pick(String tooBig, String wrongFormat) async {
    final picked = await ref.read(fileSourceProvider).pickOne(extensions);
    if (picked == null) return;
    final ext = picked.name.split('.').last.toLowerCase();
    if (!extensions.contains(ext)) {
      state = state.copyWith(error: () => wrongFormat);
      return;
    }
    if (picked.sizeBytes > maxBytes) {
      state = state.copyWith(error: () => tooBig);
      return;
    }
    _start(picked);
  }

  void _start(PickedFile picked) {
    _timer?.cancel();
    final timing = ref.read(videoAnalysisTimingProvider);
    state = state.copyWith(
      file: () => MuUploadFile(
        id: picked.name,
        name: picked.name,
        sizeBytes: picked.sizeBytes,
        status: MuUploadStatus.uploading,
      ),
      step: VideoAnalysisState.idle,
      result: () => null,
      error: () => null,
    );
    var tick = 0;
    _timer = Timer.periodic(timing.upload ~/ _uploadTicks, (t) {
      tick++;
      final f = state.file;
      if (f == null) return t.cancel();
      if (tick < _uploadTicks) {
        state = state.copyWith(file: () => f.copyWith(progress: tick / _uploadTicks));
        return;
      }
      t.cancel();
      state = state.copyWith(
        file: () => f.copyWith(status: MuUploadStatus.done, progress: 1),
        // « Vidéo envoyée » is done: detection runs.
        step: 1,
      );
      _analyse(picked);
    });
  }

  Future<void> _analyse(PickedFile picked) async {
    final timing = ref.read(videoAnalysisTimingProvider);
    final result = await ref
        .read(trainingRepositoryProvider)
        .analyseVideo(
          move: state.move,
          fileName: picked.name,
          sizeBytes: picked.sizeBytes,
          share: state.share,
          now: ref.read(clockProvider)(),
        );
    if (state.file?.name != picked.name) return; // cancelled meanwhile
    _timer = Timer.periodic(timing.step, (t) {
      final next = state.step + 1;
      if (next >= VideoAnalyst.stepCount) {
        t.cancel();
        state = state.copyWith(step: VideoAnalyst.stepCount, result: () => result);
      } else {
        state = state.copyWith(step: next);
      }
    });
  }

  /// « Annuler » or the bin on the clip: stops everything, the move and the choice stay.
  void cancel() {
    _timer?.cancel();
    state = VideoAnalysisState(move: state.move, share: state.share);
  }

  /// « Demander l’avis de Karim J. » (ENT-09).
  Future<void> shareWithCoach() async {
    final r = state.result;
    if (r == null) return;
    final shared = await ref.read(trainingRepositoryProvider).shareWithCoach(r);
    state = state.copyWith(result: () => shared, share: true);
  }

  /// The player's edit of « Ce que l’IA a vu ».
  void editSummary(String text) {
    final r = state.result;
    if (r == null || text.isEmpty) return;
    state = state.copyWith(result: () => r.copyWith(summary: text));
  }
}

final videoAnalysisProvider = NotifierProvider<VideoAnalysisController, VideoAnalysisState>(
  VideoAnalysisController.new,
);
