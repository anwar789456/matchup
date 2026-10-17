import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../router.dart';
import 'notification_models.dart';

/// A simulated push (NOT-08 / NOT-09) until the backend sends real ones (CLAUDE.md rule 11).
@immutable
class PushMessage {
  const PushMessage({
    required this.id,
    required this.category,
    required this.title,
    required this.body,
    required this.route,
    this.actions = const [],
    this.timeSensitive = false,
    this.grouped = false,
  });

  final int id;
  final NotificationCategory category;
  final String title;
  final String body;

  /// Where a tap on the notification leads.
  final String route;

  /// (id, label) of the notification's buttons; each id is also a route or « dismiss ».
  final List<(String, String)> actions;
  final bool timeSensitive;

  /// Stacked under « MatchUp · N nouvelles ».
  final bool grouped;
}

abstract interface class PushService {
  Future<void> show(PushMessage m);
}

/// Shows the push with flutter_local_notifications; a tap or an action opens its route.
class LocalPushService implements PushService {
  LocalPushService(this._open);

  final void Function(String route) _open;
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _group = 'tn.matchup.notifications';

  Future<void> _init() async {
    if (_ready) return;
    _ready = true;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
        macOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (r) {
        final action = r.actionId;
        if (action == 'dismiss') return;
        final route = action != null && action.startsWith('/') ? action : r.payload;
        if (route != null && route.isNotEmpty) _open(route);
      },
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  @override
  Future<void> show(PushMessage m) async {
    await _init();
    await _plugin.show(
      id: m.id,
      title: m.title,
      body: m.body,
      payload: m.route,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'matchup_${m.category.name}',
          m.category.label,
          importance: m.timeSensitive ? Importance.max : Importance.high,
          priority: m.timeSensitive ? Priority.max : Priority.high,
          styleInformation: BigTextStyleInformation(m.body),
          groupKey: m.grouped ? _group : null,
          actions: [
            for (final (id, label) in m.actions)
              AndroidNotificationAction(id, label, showsUserInterface: id != 'dismiss'),
          ],
        ),
        iOS: DarwinNotificationDetails(
          threadIdentifier: m.grouped ? _group : null,
          interruptionLevel: m.timeSensitive
              ? InterruptionLevel.timeSensitive
              : InterruptionLevel.active,
        ),
      ),
    );
  }
}

/// For tests: keeps what would have been shown.
class RecordingPushService implements PushService {
  final shown = <PushMessage>[];

  @override
  Future<void> show(PushMessage m) async => shown.add(m);
}

final pushServiceProvider = Provider<PushService>(
  (ref) => LocalPushService((route) => ref.read(routerProvider).push(route)),
);

/// The texts of NOT-08 (iOS) and NOT-09 (Android), pushed from the debug menu.
abstract final class PushSamples {
  static final spotFreed = PushMessage(
    id: 1,
    category: NotificationCategory.matches,
    title: 'Une place s’est libérée',
    body: 'Foot 5v5 · dim. 18 oct. · 20h00 à Arena Five, Terrain 2 · 15 DT /pers. Sans réponse, elle passe au suivant.',
    route: Routes.game('g1'),
    timeSensitive: true,
    actions: [(Routes.game('g1'), 'Réclamer la place'), ('dismiss', 'Ignorer')],
  );
  static const invitation = PushMessage(
    id: 2,
    category: NotificationCategory.matches,
    title: 'Mariem K. t’invite au padel',
    body: 'Smash Padel Club · ven. 23 oct. · 19h30 · 25 DT /pers.',
    route: Routes.matches,
    grouped: true,
    actions: [(Routes.matches, 'Accepter'), (Routes.matches, 'Refuser')],
  );
  static const shareDue = PushMessage(
    id: 3,
    category: NotificationCategory.payments,
    title: 'Ta part de 15 DT est en attente',
    body: 'À payer avant mer. 21 oct. · 18h00.',
    route: Routes.notifications,
    grouped: true,
  );
  static final joined = PushMessage(
    id: 4,
    category: NotificationCategory.matches,
    title: 'Nour A. et 2 autres ont rejoint ta partie',
    body: 'Arena Five · mer. 21 oct. · 6/10 joueurs',
    route: Routes.booking('MU-48213'),
    grouped: true,
  );
  static final reminder = PushMessage(
    id: 5,
    category: NotificationCategory.matches,
    title: 'Rappel : Foot 5v5 mer. 21 oct. · 21h00',
    body: 'Arena Five, Terrain 1 · encore 4 places.',
    route: Routes.booking('MU-48213'),
  );

  static List<PushMessage> get all => [spotFreed, invitation, shareDue, joined, reminder];
}
