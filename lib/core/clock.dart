import 'package:flutter_riverpod/flutter_riverpod.dart';

/// « Now » in the story the designs tell (design/screens/STORY-DATA.md): ven. 16 oct. 2026, 18h00.
final storyNow = DateTime(2026, 10, 16, 18);

/// The app's clock. While the data is fake it starts at [storyNow] and then runs in real time, so
/// screens match the PNGs (« Ce soir », countdowns) and still tick. With a real backend, override
/// it with `DateTime.now`.
final clockProvider = Provider<DateTime Function()>((ref) {
  final started = DateTime.now();
  return () => storyNow.add(DateTime.now().difference(started));
});
