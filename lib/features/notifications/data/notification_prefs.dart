import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/data/draft_store.dart';
import 'notification_models.dart';

enum NotificationChannel { app, push, email }

enum EmailDigest { weekly, never }

/// NOT-10 · where each category notifies, the pause, quiet hours and the email recap. Payments
/// and security always stay in the app.
@immutable
class NotificationPrefs {
  const NotificationPrefs({
    this.channels = defaults,
    this.pauseUntil,
    this.quietHours = true,
    this.quietStart = 23 * 60,
    this.quietEnd = 8 * 60,
    this.digest = EmailDigest.weekly,
  });

  /// NOT-10's defaults.
  static const defaults = <NotificationCategory, Set<NotificationChannel>>{
    NotificationCategory.matches: {NotificationChannel.app, NotificationChannel.push},
    NotificationCategory.bookings: {
      NotificationChannel.app,
      NotificationChannel.push,
      NotificationChannel.email,
    },
    NotificationCategory.payments: {
      NotificationChannel.app,
      NotificationChannel.push,
      NotificationChannel.email,
    },
    NotificationCategory.tournaments: {NotificationChannel.app, NotificationChannel.push},
    NotificationCategory.training: {NotificationChannel.app},
    NotificationCategory.community: {NotificationChannel.app},
    NotificationCategory.security: {
      NotificationChannel.app,
      NotificationChannel.push,
      NotificationChannel.email,
    },
  };

  final Map<NotificationCategory, Set<NotificationChannel>> channels;
  final DateTime? pauseUntil;
  final bool quietHours;

  /// Minutes after midnight (23h00 → 08h00).
  final int quietStart;
  final int quietEnd;
  final EmailDigest digest;

  bool isOn(NotificationCategory c, NotificationChannel ch) =>
      (c.locked && ch == NotificationChannel.app) || (channels[c]?.contains(ch) ?? false);

  NotificationPrefs copyWith({
    Map<NotificationCategory, Set<NotificationChannel>>? channels,
    DateTime? Function()? pauseUntil,
    bool? quietHours,
    int? quietStart,
    int? quietEnd,
    EmailDigest? digest,
  }) => NotificationPrefs(
    channels: channels ?? this.channels,
    pauseUntil: pauseUntil == null ? this.pauseUntil : pauseUntil(),
    quietHours: quietHours ?? this.quietHours,
    quietStart: quietStart ?? this.quietStart,
    quietEnd: quietEnd ?? this.quietEnd,
    digest: digest ?? this.digest,
  );

  Map<String, Object?> toJson() => {
    'channels': {
      for (final e in channels.entries) e.key.name: [for (final ch in e.value) ch.name],
    },
    'pauseUntil': pauseUntil?.toIso8601String(),
    'quietHours': quietHours,
    'quietStart': quietStart,
    'quietEnd': quietEnd,
    'digest': digest.name,
  };

  static NotificationPrefs fromJson(Map<String, Object?> json) {
    final raw = (json['channels'] as Map?) ?? const {};
    return NotificationPrefs(
      channels: {
        for (final c in NotificationCategory.values)
          c: raw[c.name] is List
              ? {
                  for (final n in raw[c.name] as List)
                    ...NotificationChannel.values.where((ch) => ch.name == n),
                }
              : defaults[c] ?? const {},
      },
      pauseUntil: DateTime.tryParse(json['pauseUntil'] as String? ?? ''),
      quietHours: json['quietHours'] as bool? ?? true,
      quietStart: json['quietStart'] as int? ?? 23 * 60,
      quietEnd: json['quietEnd'] as int? ?? 8 * 60,
      digest:
          EmailDigest.values.where((d) => d.name == json['digest']).firstOrNull ??
          EmailDigest.weekly,
    );
  }
}

final notificationPrefsStoreProvider = Provider<DraftStore>((ref) => const LocalDraftStore());

/// The preferences, loaded from the device and saved after every change.
class NotificationPrefsController extends Notifier<NotificationPrefs> {
  static const _key = 'notification_prefs';

  @override
  NotificationPrefs build() {
    _load();
    return const NotificationPrefs();
  }

  Future<void> _load() async {
    try {
      final json = await ref.read(notificationPrefsStoreProvider).load(_key);
      if (json != null) state = NotificationPrefs.fromJson(json);
    } catch (_) {
      // No storage (tests, private mode): keep the defaults.
    }
  }

  Future<void> _save(NotificationPrefs p) async {
    state = p;
    try {
      await ref.read(notificationPrefsStoreProvider).save(_key, p.toJson());
    } catch (_) {
      // The change still applies for this session.
    }
  }

  void toggle(NotificationCategory c, NotificationChannel ch, bool on) {
    if (c.locked && ch == NotificationChannel.app) return;
    final set = {...?state.channels[c]};
    on ? set.add(ch) : set.remove(ch);
    _save(state.copyWith(channels: {...state.channels, c: set}));
  }

  void pause(DateTime? until) => _save(state.copyWith(pauseUntil: () => until));
  void setQuiet(bool on) => _save(state.copyWith(quietHours: on));
  void setQuietStart(int minutes) => _save(state.copyWith(quietStart: minutes));
  void setQuietEnd(int minutes) => _save(state.copyWith(quietEnd: minutes));
  void setDigest(EmailDigest d) => _save(state.copyWith(digest: d));
}

final notificationPrefsProvider = NotifierProvider<NotificationPrefsController, NotificationPrefs>(
  NotificationPrefsController.new,
);
