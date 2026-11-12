import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where a training video comes from. The fake one plays public demo clips; the backend will
/// return the coach's real uploads (exercise demos, program previews, students' videos).
abstract interface class TrainingVideoSource {
  /// The video for [key] (« programId/lesson/exercise », « preview/programId », « analysis/id »…).
  Uri urlFor(String key);
}

/// Public sample clips (Flutter's documentation videos), picked from the key so the same
/// exercise always shows the same clip.
class DemoTrainingVideoSource implements TrainingVideoSource {
  const DemoTrainingVideoSource();

  static const _clips = [
    'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
    'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
  ];

  @override
  Uri urlFor(String key) {
    final hash = key.codeUnits.fold(0, (a, b) => (a * 31 + b) & 0x7fffffff);
    return Uri.parse(_clips[hash % _clips.length]);
  }
}

final trainingVideoSourceProvider = Provider<TrainingVideoSource>(
  (ref) => const DemoTrainingVideoSource(),
);
