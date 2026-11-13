import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/theme.dart';

/// Where a training video comes from. The demo one plays free stock clips of the sport; the
/// backend will return the coach's real uploads (exercise demos, program previews, students'
/// videos).
abstract interface class TrainingVideoSource {
  /// The video for [key] (« programId/lesson/exercise », « preview/programId », « analysis/id »…)
  /// in [sport].
  Uri urlFor(String key, MuSport sport);
}

/// Free clips from Pexels (Pexels license: free to use, no attribution needed), 960 px wide so
/// they stream light on a phone. The same key always gets the same clip of its sport.
class DemoTrainingVideoSource implements TrainingVideoSource {
  const DemoTrainingVideoSource();

  static const _base = 'https://videos.pexels.com/video-files';

  static const _clips = <MuSport, List<String>>{
    // No padel clip chosen yet: a racket drill (Pexels 10340762) until one is picked.
    MuSport.padel: ['10340762/10340762-sd_960_506_25fps.mp4'],
    // Soccer players training (Pexels 6084027, 6084020, 6084024).
    MuSport.football: [
      '6084027/6084027-sd_960_540_25fps.mp4',
      '6084020/6084020-sd_960_540_25fps.mp4',
      '6084024/6084024-sd_960_540_25fps.mp4',
    ],
    // Playing basketball (Pexels 5586522, 5586524, 8694187).
    MuSport.basketball: [
      '5586522/5586522-sd_960_540_25fps.mp4',
      '5586524/5586524-sd_960_540_25fps.mp4',
      '8694187/8694187-sd_960_506_24fps.mp4',
    ],
  };

  @override
  Uri urlFor(String key, MuSport sport) {
    final clips = _clips[sport] ?? _clips[MuSport.padel]!;
    final hash = key.codeUnits.fold(0, (a, b) => (a * 31 + b) & 0x7fffffff);
    return Uri.parse('$_base/${clips[hash % clips.length]}');
  }
}

final trainingVideoSourceProvider = Provider<TrainingVideoSource>(
  (ref) => const DemoTrainingVideoSource(),
);
