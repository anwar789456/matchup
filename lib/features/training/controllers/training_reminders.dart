import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../../../l10n/l10n.dart';
import '../../notifications/data/notification_models.dart';
import '../../notifications/data/notification_prefs.dart';
import '../../notifications/data/push_service.dart';
import '../data/training_models.dart';
import '../training_routes.dart';
import 'training_providers.dart';

/// The push of « Rappels de séance »: the next session of a joined program, or the streak.
PushMessage trainingReminderMessage(TrainingProgress progress, List<TrainingProgram> programs) {
  final next = [
    for (final p in programs)
      if (progress.isEnrolled(p.id))
        if (progress.nextLesson(p) case final l?) (p, l),
  ].firstOrNull;
  final route = next == null
      ? TrainingRoutes.root
      : TrainingRoutes.lesson(next.$1.id, next.$2.index);
  return PushMessage(
    id: _pushId,
    category: NotificationCategory.training,
    title: l10n.entReminderTitle,
    body: next == null
        ? l10n.entReminderNoSession
        : l10n.entReminderBody(next.$2.index, next.$2.title, next.$2.minutes),
    route: route,
    actions: [(route, l10n.entReminderStart), ('dismiss', l10n.entReminderLater)],
  );
}

const _pushId = 60;

/// Sends the reminder now (« Tester le rappel », and the timer below).
final sendTrainingReminderProvider = Provider<Future<void> Function()>(
  (ref) => () async {
    final progress = await ref.read(trainingProgressProvider.future);
    final programs = await ref.read(programsProvider.future);
    await ref.read(pushServiceProvider).show(trainingReminderMessage(progress, programs));
  },
);

/// Tests turn the timer off (a pending timer fails a widget test).
final trainingRemindersLiveProvider = Provider<bool>((ref) => true);

/// While the app runs, waits for the next reminder and sends it, unless the session of the day
/// is already done or notifications are paused (NOT-10). The backend will send real pushes.
final trainingReminderSchedulerProvider = Provider<DateTime?>((ref) {
  if (!ref.watch(trainingRemindersLiveProvider)) return null;
  final progress = ref.watch(trainingProgressProvider).value;
  final now = ref.watch(clockProvider)();
  final at = progress?.reminder.next(now);
  if (at == null) return null;
  final timer = Timer(at.difference(now), () async {
    final fired = ref.read(clockProvider)();
    final p = await ref.read(trainingProgressProvider.future);
    final paused = ref.read(notificationPrefsProvider).pauseUntil?.isAfter(fired) ?? false;
    if (!p.doneOn(fired) && !paused) await ref.read(sendTrainingReminderProvider)();
    ref.invalidateSelf();
  });
  ref.onDispose(timer.cancel);
  return at;
});
