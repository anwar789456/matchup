import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/clock.dart';
import '../../../core/format.dart';
import '../../../l10n/l10n.dart';
import '../../../theme/theme.dart';
import '../../../ui/ui.dart';
import '../controllers/training_providers.dart';
import '../controllers/training_reminders.dart';
import '../data/training_models.dart';

/// A Monday, to name the weekdays (1 = Monday) with [formatWeekday].
DateTime _weekday(int d) => DateTime(2024, 1, d);

/// « lun., mer., ven. · 19h00 ».
String reminderSummary(TrainingReminder r) =>
    '${[for (var d = 1; d <= 7; d++)
      if (r.days.contains(d)) formatWeekday(_weekday(d))].join(', ')}'
    ' · ${formatHour(r.minutes)}';

/// « aujourd’hui à 19h00 », « demain à 19h00 », « lun. 19 oct. à 19h00 ».
String reminderNext(DateTime at, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final days = DateTime(at.year, at.month, at.day).difference(today).inDays;
  final time = formatTime(at);
  return switch (days) {
    0 => l10n.entTodayAt(time),
    1 => l10n.entTomorrowAt(time),
    _ => l10n.entDayAt(formatDay(at), time),
  };
}

/// The « Rappels de séance » card of the history page: what is set, the next one, « Modifier ».
class ReminderCard extends ConsumerWidget {
  const ReminderCard({super.key, required this.reminder});

  final TrainingReminder reminder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mu;
    final now = ref.watch(clockProvider)();
    final next = reminder.next(now);
    return MuCardSurface(
      child: Row(
        children: [
          Icon(
            reminder.on ? PhosphorIcons.bellRinging() : PhosphorIcons.bellSlash(),
            size: MuSize.iconM,
            color: c.text,
          ),
          const SizedBox(width: MuSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.entReminders, style: MuType.label.copyWith(color: c.text)),
                Text(
                  reminder.on && next != null ? reminderSummary(reminder) : l10n.entRemindersOff,
                  style: MuType.caption.copyWith(color: c.textSecondary),
                ),
                if (reminder.on && next != null)
                  Text(
                    l10n.entNextReminder(reminderNext(next, now)),
                    style: MuType.caption.copyWith(color: c.textSecondary),
                  ),
              ],
            ),
          ),
          MuButton.tertiary(
            label: reminder.on ? l10n.entEdit : l10n.entTurnOn,
            size: MuButtonSize.s,
            onPressed: () => showReminderSheet(context, ref),
          ),
        ],
      ),
    );
  }
}

/// « Rappels de séance »: on/off, the days, the time; « Tester le rappel » sends it now.
Future<void> showReminderSheet(BuildContext context, WidgetRef ref) async {
  final saved = ref.read(trainingProgressProvider).value?.reminder ?? const TrainingReminder();
  // The first opening turns them on: that is why the player came.
  final draft = ValueNotifier(saved.on ? saved : saved.copyWith(on: true));
  final done = await MuBottomSheet.show<bool>(
    context,
    title: l10n.entReminders,
    height: MuSheetHeight.auto,
    footer: ValueListenableBuilder<TrainingReminder>(
      valueListenable: draft,
      builder: (context, r, _) => Row(
        children: [
          MuButton.tertiary(
            label: l10n.entTestReminder,
            onPressed: () async {
              await ref.read(sendTrainingReminderProvider)();
              if (context.mounted) {
                MuToast.show(context, title: l10n.entReminderSent, tone: MuToastTone.neutral);
              }
            },
          ),
          const SizedBox(width: MuSpace.s3),
          Expanded(
            child: MuButton.primary(
              label: l10n.entSave,
              size: MuButtonSize.l,
              fullWidth: true,
              onPressed: r.on && r.days.isEmpty ? null : () => Navigator.of(context).pop(true),
            ),
          ),
        ],
      ),
    ),
    child: ValueListenableBuilder<TrainingReminder>(
      valueListenable: draft,
      builder: (context, r, _) {
        final c = context.mu;
        return Padding(
          padding: const EdgeInsets.fromLTRB(MuSpace.s4, 0, MuSpace.s4, MuSpace.s4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MuSwitch(
                value: r.on,
                label: l10n.entRemindMe,
                description: l10n.entRemindMeHelp,
                onChanged: (v) => draft.value = r.copyWith(on: v),
              ),
              if (r.on) ...[
                const SizedBox(height: MuSpace.s4),
                Text(l10n.entReminderDays, style: MuType.label.copyWith(color: c.text)),
                const SizedBox(height: MuSpace.s2),
                Wrap(
                  spacing: MuSpace.s2,
                  runSpacing: MuSpace.s2,
                  children: [
                    for (var d = 1; d <= 7; d++)
                      MuChip(
                        kind: MuChipKind.filter,
                        label: formatWeekday(_weekday(d)),
                        selected: r.days.contains(d),
                        onSelected: (on) => draft.value = r.copyWith(
                          days: on ? {...r.days, d} : ({...r.days}..remove(d)),
                        ),
                      ),
                  ],
                ),
                if (r.days.isEmpty) ...[
                  const SizedBox(height: MuSpace.s1),
                  Text(l10n.entPickADay, style: MuType.caption.copyWith(color: c.errorText)),
                ],
                const SizedBox(height: MuSpace.s4),
                MuSettingsRow(
                  icon: PhosphorIcons.clock(),
                  title: l10n.entReminderTime,
                  value: formatHour(r.minutes),
                  onTap: () async {
                    final t = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(hour: r.minutes ~/ 60, minute: r.minutes % 60),
                      helpText: l10n.entReminderTime,
                    );
                    if (t != null) {
                      draft.value = draft.value.copyWith(minutes: t.hour * 60 + t.minute);
                    }
                  },
                ),
              ],
            ],
          ),
        );
      },
    ),
  );
  final value = draft.value;
  draft.dispose();
  if (done != true) return;
  await ref.read(trainingProgressProvider.notifier).saveReminder(value);
  if (context.mounted) {
    MuToast.show(
      context,
      title: value.on ? l10n.entRemindersSaved : l10n.entRemindersOffSaved,
      tone: MuToastTone.success,
    );
  }
}
